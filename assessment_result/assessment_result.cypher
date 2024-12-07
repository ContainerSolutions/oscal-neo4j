WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ar/json/ifa_assessment-results-example-min.json" AS url
CALL apoc.load.json(url) YIELD value

// Extract the assessment results
WITH value['assessment-results'] AS ar
MERGE (assessmentResults:AssessmentResult {uuid: ar.uuid})
SET assessmentResults.title = ar.metadata.title,
    assessmentResults.lastModified = ar.metadata['last-modified'],
    assessmentResults.version = ar.metadata.version,
    assessmentResults.oscalVersion = ar.metadata['oscal-version']

// Create roles and link them to the assessment results
WITH ar, assessmentResults
UNWIND ar.metadata.roles AS role
MERGE (roleNode:Role {id: role.id})
SET roleNode.title = role.title
MERGE (roleNode)-[:BELONGS_TO]->(assessmentResults)

// Create parties and link them to the assessment results
WITH ar, assessmentResults
UNWIND ar.metadata.parties AS party
MERGE (partyNode:Party {uuid: party.uuid})
SET partyNode.type = party.type,
    partyNode.name = party.name
MERGE (partyNode)-[:BELONGS_TO]->(assessmentResults)

// Link members to organizations
WITH ar, assessmentResults
UNWIND ar.metadata.parties AS party
UNWIND CASE WHEN party['member-of-organizations'] IS NULL THEN [] ELSE party['member-of-organizations'] END AS orgUuid
MATCH (orgNode:Party {uuid: orgUuid})
MERGE (partyNode:Party {uuid: party.uuid})-[:MEMBER_OF]->(orgNode)

// Create activities and link them to the assessment results
WITH ar, assessmentResults
UNWIND ar['local-definitions'].activities AS activity
MERGE (activityNode:Activity {uuid: activity.uuid})
SET activityNode.title = activity.title,
    activityNode.description = activity.description
MERGE (assessmentResults)-[:HAS_ACTIVITY]->(activityNode)

// Link steps to activities and the assessment results
WITH ar, activity, activityNode, assessmentResults
UNWIND activity.steps AS step
MERGE (stepNode:Step {uuid: step.uuid})
SET stepNode.title = step.title,
    stepNode.description = step.description
MERGE (stepNode)-[:PART_OF]->(activityNode)

// Link responsible roles to activities WITH ar, activity, assessmentResults
WITH ar, activity, activityNode, assessmentResults
UNWIND activity['responsible-roles'] AS responsibleRole
UNWIND responsibleRole['party-uuids'] AS partyUuid
MATCH (partyNode:Party {uuid: partyUuid})
MERGE (partyNode)-[:RESPONSIBLE_FOR]->(activityNode)

// Link related controls to activities
WITH ar, activity, assessmentResults
UNWIND activity['related-controls']['control-selections'] AS controlSelection
UNWIND controlSelection['include-controls'] AS control
MERGE (controlNode:Control {id: control['control-id']})
MERGE (activityNode)-[:RELATED_TO]->(controlNode)

WITH ar, assessmentResults
UNWIND ar['results'] AS results
MERGE (resultsNode:Results {uuid: results.uuid})
SET resultsNode.title       = results.title,
    resultsNode.description = results.description
MERGE (resultsNode)-[:BELONGS_TO]->(assessmentResults);


