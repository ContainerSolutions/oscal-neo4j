// JSON from: https//raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ap/json/ifa_assessment-plan-example-min.json
CALL apoc.load.json('file:///assessment_plan/assessment_plan.json') YIELD value

WITH value AS data
MERGE (ap:AssessmentPlan {uuid: data.`assessment-plan`.uuid})
SET ap.title = data.`assessment-plan`.metadata.title,
    ap.lastModified = data.`assessment-plan`.metadata.`last-modified`,
    ap.version = data.`assessment-plan`.metadata.version,
    ap.oscalVersion = data.`assessment-plan`.metadata.`oscal-version`

// Roles
WITH ap, data
UNWIND data.`assessment-plan`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (ap)-[:HAS_ROLE]->(r)

// Parties
WITH ap, data
UNWIND data.`assessment-plan`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
WITH ap, p, data, party
FOREACH (orgUuid IN party.`member-of-organizations` |
  MERGE (org:Organization {uuid: orgUuid})
  MERGE (p)-[:MEMBER_OF]->(org)
)
WITH ap, p, data, party
FOREACH (link IN party.links |
  MERGE (l:Link {href: link.href, rel: link.rel})
  MERGE (p)-[:HAS_LINK]->(l)
)
MERGE (ap)-[:HAS_PARTY]->(p)

// Responsible Parties
WITH ap, data
UNWIND data.`assessment-plan`.metadata.`responsible-parties` AS respParty
MATCH (r:Role {id: respParty.`role-id`})
UNWIND respParty.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (r)-[:RESPONSIBLE_PARTY]->(p)

// Import SSP
WITH ap, data
MERGE (ssp:ImportedSSP {href: data.`assessment-plan`.`import-ssp`.href})
MERGE (ap)-[:IMPORTS_SSP]->(ssp)

// Local Definitions: Activities
WITH ap, data
UNWIND data.`assessment-plan`.`local-definitions`.activities AS activityData
MERGE (act:Activity {uuid: activityData.uuid})
SET act.title = activityData.title,
    act.description = activityData.description
MERGE (ap)-[:HAS_ACTIVITY]->(act)
WITH act, activityData, ap, data
FOREACH (prop IN activityData.props |
  MERGE (p:Property {name: prop.name, value: prop.value})
  MERGE (act)-[:HAS_PROPERTY]->(p)
)
WITH act, activityData, ap, data
FOREACH (step IN activityData.steps |
  MERGE (s:Step {uuid: step.uuid})
  SET s.title = step.title,
      s.description = step.description
  MERGE (act)-[:HAS_STEP]->(s)
)
WITH act, activityData, ap, data
FOREACH (control IN activityData.`related-controls`.`control-selections` |
  FOREACH (includedControl IN control.`include-controls` |
    MERGE (c:Control {id: includedControl.`control-id`})
    MERGE (act)-[:RELATES_TO_CONTROL]->(c)
  )
)

// Responsible Roles for Activities
WITH ap, data
UNWIND data.`assessment-plan`.`local-definitions`.activities AS activityData
MATCH (act:Activity {uuid: activityData.uuid})
UNWIND activityData.`responsible-roles` AS respRole
MATCH (r:Role {id: respRole.`role-id`})
UNWIND respRole.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (r)-[:RESPONSIBLE_PARTY]->(p)
MERGE (act)-[:RESPONSIBLE_FOR]->(r)

// Reviewed Controls
WITH ap, data
UNWIND data.`assessment-plan`.`reviewed-controls`.`control-selections` AS reviewedControl
FOREACH (includedControl IN reviewedControl.`include-controls` |
  MERGE (c:Control {id: includedControl.`control-id`})
  MERGE (ap)-[:REVIEWED_CONTROL]->(c)
)

// Assessment Subjects
WITH ap, data
UNWIND data.`assessment-plan`.`assessment-subjects` AS subject
MERGE (subj:Subject {type: subject.type})
SET subj.description = subject.description
MERGE (ap)-[:HAS_SUBJECT]->(subj)

// Tasks
WITH ap, data
UNWIND data.`assessment-plan`.tasks AS taskData
MERGE (t:Task {uuid: taskData.uuid})
SET t.type = taskData.type,
    t.title = taskData.title,
    t.remarks = taskData.remarks
MERGE (ap)-[:HAS_TASK]->(t)
WITH t, taskData
FOREACH (activity IN taskData.`associated-activities` |
  MERGE (act:Activity {uuid: activity.`activity-uuid`})
  MERGE (t)-[:ASSOCIATED_WITH]->(act)
  FOREACH (subject IN activity.subjects |
    MERGE (subj:Subject {type: subject.type})
    MERGE (act)-[:HAS_SUBJECT]->(subj)
  )
)
WITH t, taskData
UNWIND taskData.`responsible-roles` AS respRole
MATCH (r:Role {id: respRole.`role-id`})
MERGE (t)-[:RESPONSIBLE_FOR]->(r)

