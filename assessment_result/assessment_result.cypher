// JSON from: https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ar/json/ifa_assessment-results-example-min.json
CALL apoc.load.json('file:///assessment_result/assessment_result.json') YIELD value

WITH value AS data
MERGE (ar:AssessmentResults {uuid: data.`assessment-results`.uuid})
SET ar.title = data.`assessment-results`.metadata.title,
    ar.lastModified = data.`assessment-results`.metadata.`last-modified`,
    ar.version = data.`assessment-results`.metadata.version,
    ar.oscalVersion = data.`assessment-results`.metadata.`oscal-version`

// Roles
WITH ar, data
UNWIND data.`assessment-results`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (ar)-[:HAS_ROLE]->(r)

// Parties
WITH ar, data
UNWIND data.`assessment-results`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
FOREACH (orgUuid IN party.`member-of-organizations` |
  MERGE (org:Organization {uuid: orgUuid})
  MERGE (p)-[:MEMBER_OF]->(org)
)
FOREACH (link IN party.links |
  MERGE (l:Link {href: link.href, rel: link.rel})
  MERGE (p)-[:HAS_LINK]->(l)
)
MERGE (ar)-[:HAS_PARTY]->(p)

// Responsible Parties
WITH ar, data
UNWIND data.`assessment-results`.metadata.`responsible-parties` AS respParty
UNWIND respParty.`party-uuids` AS partyUuid
MATCH (role:Role {id: respParty.`role-id`})
MATCH (p:Party {uuid: partyUuid})
MERGE (role)-[:RESPONSIBLE_PARTY]->(p)

// Import AP
WITH ar, data
MERGE (ap:ImportedAP {href: data.`assessment-results`.`import-ap`.href})
MERGE (ar)-[:IMPORTS_AP]->(ap)

// Local Definitions: Activities
WITH ar, data
UNWIND data.`assessment-results`.`local-definitions`.activities AS activityData
MERGE (act:Activity {uuid: activityData.uuid})
SET act.title = activityData.title,
    act.description = activityData.description
MERGE (ar)-[:HAS_ACTIVITY]->(act)
FOREACH (prop IN activityData.props |
  MERGE (pr:Property {name: prop.name, value: prop.value})
  MERGE (act)-[:HAS_PROPERTY]->(pr)
)
FOREACH (step IN activityData.steps |
  MERGE (s:Step {uuid: step.uuid})
  SET s.title = step.title,
      s.description = step.description,
      s.remarks = step.remarks
  MERGE (act)-[:HAS_STEP]->(s)
)
FOREACH (control IN activityData.`related-controls`.`control-selections` |
  FOREACH (includedControl IN control.`include-controls` |
    MERGE (c:Control {id: includedControl.`control-id`})
    MERGE (act)-[:RELATES_TO_CONTROL]->(c)
  )
)
WITH act, activityData, ar, data
UNWIND activityData.`responsible-roles` AS respRole
MATCH (role:Role {id: respRole.`role-id`})
UNWIND respRole.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (role)-[:RESPONSIBLE_PARTY]->(p)
MERGE (act)-[:RESPONSIBLE_FOR]->(role)

// Results
WITH ar, data
UNWIND data.`assessment-results`.results AS resultData
MERGE (res:Result {uuid: resultData.uuid})
SET res.title = resultData.title,
    res.description = resultData.description,
    res.start = resultData.start,
    res.end = resultData.end
MERGE (ar)-[:HAS_RESULT]->(res)

// Local Definitions in Results: Tasks
WITH res, resultData
UNWIND resultData.`local-definitions`.tasks AS taskData
MERGE (task:Task {uuid: taskData.uuid})
SET task.type = taskData.type,
    task.title = taskData.title,
    task.description = taskData.description
MERGE (res)-[:HAS_TASK]->(task)
FOREACH (activity IN taskData.`associated-activities` |
  MERGE (act:Activity {uuid: activity.`activity-uuid`})
  MERGE (task)-[:ASSOCIATED_WITH]->(act)
)

// Reviewed Controls
WITH res, resultData
UNWIND resultData.`reviewed-controls`.`control-selections` AS reviewedControl
FOREACH (includedControl IN reviewedControl.`include-controls` |
  MERGE (c:Control {id: includedControl.`control-id`})
  MERGE (res)-[:REVIEWED_CONTROL]->(c)
)

// Observations
WITH res, resultData
UNWIND resultData.observations AS obs
MERGE (o:Observation {uuid: obs.uuid})
SET o.title = obs.title,
    o.description = obs.description,
    o.collected = obs.collected,
    o.expires = obs.expires,
    o.remarks = obs.remarks
MERGE (res)-[:HAS_OBSERVATION]->(o)

// Risks
WITH res, resultData
UNWIND resultData.risks AS risk
MERGE (r:Risk {uuid: risk.uuid})
SET r.title = risk.title,
    r.description = risk.description,
    r.statement = risk.statement,
    r.status = risk.status
MERGE (res)-[:HAS_RISK]->(r)

// Findings
WITH res, resultData
UNWIND resultData.findings AS finding
MERGE (f:Finding {uuid: finding.uuid})
SET f.title = finding.title,
    f.description = finding.description
MERGE (res)-[:HAS_FINDING]->(f)

// Relate Findings to Observations
WITH f, finding
UNWIND finding.`related-observations` AS relatedObs
MATCH (o:Observation {uuid: relatedObs.`observation-uuid`})
MERGE (f)-[:RELATES_TO_OBSERVATION]->(o)

// Relate Findings to Risks
WITH f, finding
UNWIND finding.`related-risks` AS relatedRisk
MATCH (r:Risk {uuid: relatedRisk.`risk-uuid`})
MERGE (f)-[:RELATES_TO_RISK]->(r)
