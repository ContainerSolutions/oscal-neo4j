WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ap/json/ifa_assessment-plan-example-min.json" AS url
CALL apoc.load.json(url) YIELD value

// Extract the assessment plan
WITH value['assessment-plan'] AS ap
MERGE (assessmentPlan:AssessmentPlan {uuid: ap.uuid})
SET assessmentPlan.title = ap.metadata.title,
    assessmentPlan.lastModified = ap.metadata['last-modified'],
    assessmentPlan.version = ap.metadata.version,
    assessmentPlan.oscalVersion = ap.metadata['oscal-version']

// Create roles and link them to the assessment plan
WITH ap, assessmentPlan
UNWIND ap.metadata.roles AS role
MERGE (roleNode:Role {id: role.id})
SET roleNode.title = role.title
MERGE (roleNode)-[:BELONGS_TO]->(assessmentPlan)

// Create parties and link them to the assessment plan
WITH ap, assessmentPlan
UNWIND ap.metadata.parties AS party
MERGE (partyNode:Party {uuid: party.uuid})
SET partyNode.type = party.type,
    partyNode.name = party.name
MERGE (partyNode)-[:BELONGS_TO]->(assessmentPlan)

// Link members to organizations
WITH ap, assessmentPlan
UNWIND ap.metadata.parties AS party
UNWIND CASE WHEN party['member-of-organizations'] IS NULL THEN [] ELSE party['member-of-organizations'] END AS orgUuid
MATCH (orgNode:Party {uuid: orgUuid})
MERGE (partyNode:Party {uuid: party.uuid})-[:MEMBER_OF]->(orgNode)

// Create activities and link them to the assessment plan
WITH ap, assessmentPlan
UNWIND ap['local-definitions'].activities AS activity
MERGE (activityNode:Activity {uuid: activity.uuid})
SET activityNode.title = activity.title,
    activityNode.description = activity.description
MERGE (assessmentPlan)-[:HAS_ACTIVITY]->(activityNode)

// Link steps to activities and the assessment plan
WITH ap, activity, activityNode, assessmentPlan
UNWIND activity.steps AS step
MERGE (stepNode:Step {uuid: step.uuid})
SET stepNode.title = step.title,
    stepNode.description = step.description
MERGE (stepNode)-[:PART_OF]->(activityNode)
//MERGE (stepNode)-[:BELONGS_TO]->(assessmentPlan)

// Link responsible roles to activities
WITH ap, activity, assessmentPlan
UNWIND activity['responsible-roles'] AS responsibleRole
UNWIND responsibleRole['party-uuids'] AS partyUuid
MATCH (partyNode:Party {uuid: partyUuid})
MERGE (partyNode)-[:RESPONSIBLE_FOR]->(activityNode)

// Link related controls to activities
WITH ap, activity, assessmentPlan
UNWIND activity['related-controls']['control-selections'] AS controlSelection
UNWIND controlSelection['include-controls'] AS control
MERGE (controlNode:Control {id: control['control-id']})
MERGE (activityNode)-[:RELATED_TO]->(controlNode)

// Create tasks and associate them with activities
WITH ap, assessmentPlan
UNWIND ap.tasks AS task
MERGE (taskNode:Task {uuid: task.uuid})
SET taskNode.type = task.type,
    taskNode.title = task.title,
    taskNode.remarks = task.remarks
MERGE (assessmentPlan)-[:HAS_TASK]->(taskNode)

WITH task
UNWIND task['associated-activities'] AS associatedActivity
MATCH (activityNode:Activity {uuid: associatedActivity['activity-uuid']})
MERGE (taskNode)-[:ASSOCIATED_WITH]->(activityNode);

