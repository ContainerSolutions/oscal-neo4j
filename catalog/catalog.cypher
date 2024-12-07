WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/catalog/json/basic-catalog.json" AS url
CALL apoc.load.json(url) YIELD value

WITH value AS data
UNWIND data.catalog.groups AS outerGroup
MERGE (og:Group {id: outerGroup.id})
SET og.title = outerGroup.title

FOREACH (prop IN outerGroup.props |
  MERGE (p:Property {name: prop.name, value: prop.value})
  MERGE (og)-[:HAS_PROPERTY]->(p)
)

FOREACH (innerGroup IN outerGroup.groups |
  MERGE (ig:Group {id: innerGroup.id})
  SET ig.title = innerGroup.title
  MERGE (og)-[:CONTAINS_GROUP]->(ig)

  FOREACH (prop IN innerGroup.props |
    MERGE (p:Property {name: prop.name, value: prop.value})
    MERGE (ig)-[:HAS_PROPERTY]->(p)
  )

  FOREACH (control IN innerGroup.controls |
    MERGE (c:Control {id: control.id})
    SET c.title = control.title
    MERGE (ig)-[:CONTAINS_CONTROL]->(c)

    FOREACH (prop IN control.props |
      MERGE (p:Property {name: prop.name, value: prop.value})
      MERGE (c)-[:HAS_PROPERTY]->(p)
    )

    FOREACH (part IN control.parts |
      MERGE (pt:Part {id: part.id, name: part.name})
      SET pt.prose = part.prose
      MERGE (c)-[:HAS_PART]->(pt)

      FOREACH (subpart IN part.parts |
        MERGE (sp:Part {id: subpart.id, name: subpart.name})
        SET sp.prose = subpart.prose
        MERGE (pt)-[:HAS_PART]->(sp)
      )
    )
  )
)





//// Extract the catalog
//WITH value['catalog'] AS c
//MERGE (catalog:Catalog {uuid: c.uuid})
//SET catalog.title        = c.metadata.title,
//    catalog.lastModified = c.metadata['last-modified'],
//    catalog.version      = c.metadata.version,
//    catalog.oscalVersion = c.metadata['oscal-version']
//
//WITH c, catalog
//UNWIND c.groups AS group_outer
//MERGE (groupNode:Group {id: group_outer.id})
//SET groupNode.title = group_outer.title
//MERGE (groupNode)-[:BELONGS_TO]->(catalog)
//
//WITH c, group_outer
//UNWIND group_outer.groups AS control_group
//MERGE (controlGroupNode:ControlGroup {id: control_group.id})
//SET controlGroupNode.title = control_group.title
//MERGE (controlGroupNode)-[:BELONGS_TO]->(group_outer);






//// Create parties and link them to the assessment plan
//WITH ap, assessmentPlan
//UNWIND ap.metadata.parties AS party
//MERGE (partyNode:Party {uuid: party.uuid})
//SET partyNode.type = party.type,
//    partyNode.name = party.name
//MERGE (partyNode)-[:BELONGS_TO]->(assessmentPlan)
//
//// Link members to organizations
//WITH ap, assessmentPlan
//UNWIND ap.metadata.parties AS party
//UNWIND CASE WHEN party['member-of-organizations'] IS NULL THEN [] ELSE party['member-of-organizations'] END AS orgUuid
//MATCH (orgNode:Party {uuid: orgUuid})
//MERGE (partyNode:Party {uuid: party.uuid})-[:MEMBER_OF]->(orgNode)
//
//// Create activities and link them to the assessment plan
//WITH ap, assessmentPlan
//UNWIND ap['local-definitions'].activities AS activity
//MERGE (activityNode:Activity {uuid: activity.uuid})
//SET activityNode.title = activity.title,
//    activityNode.description = activity.description
//MERGE (assessmentPlan)-[:HAS_ACTIVITY]->(activityNode)
//
//// Link steps to activities and the assessment plan
//WITH ap, activity, activityNode, assessmentPlan
//UNWIND activity.steps AS step
//MERGE (stepNode:Step {uuid: step.uuid})
//SET stepNode.title = step.title,
//    stepNode.description = step.description
//MERGE (stepNode)-[:PART_OF]->(activityNode)
////MERGE (stepNode)-[:BELONGS_TO]->(assessmentPlan)
//
//// Link responsible roles to activities
//WITH ap, activity, assessmentPlan
//UNWIND activity['responsible-roles'] AS responsibleRole
//UNWIND responsibleRole['party-uuids'] AS partyUuid
//MATCH (partyNode:Party {uuid: partyUuid})
//MERGE (partyNode)-[:RESPONSIBLE_FOR]->(activityNode)
//
//// Link related controls to activities
//WITH ap, activity, assessmentPlan
//UNWIND activity['related-controls']['control-selections'] AS controlSelection
//UNWIND controlSelection['include-controls'] AS control
//MERGE (controlNode:Control {id: control['control-id']})
//MERGE (activityNode)-[:RELATED_TO]->(controlNode)
//
//// Create tasks and associate them with activities
//WITH ap, assessmentPlan
//UNWIND ap.tasks AS task
//MERGE (taskNode:Task {uuid: task.uuid})
//SET taskNode.type = task.type,
//    taskNode.title = task.title,
//    taskNode.remarks = task.remarks
//MERGE (assessmentPlan)-[:HAS_TASK]->(taskNode)
//
//WITH task
//UNWIND task['associated-activities'] AS associatedActivity
//MATCH (activityNode:Activity {uuid: associatedActivity['activity-uuid']})
//MERGE (taskNode)-[:ASSOCIATED_WITH]->(activityNode);
//
