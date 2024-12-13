// JSON from: https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/catalog/json/basic-catalog.json
CALL apoc.load.json('file:///catalog/catalog.json') YIELD value

WITH value AS data
MERGE (catalog:Catalog {uuid: data.catalog.uuid})
SET catalog.title = data.catalog.metadata.title,
    catalog.published = data.catalog.metadata.published,
    catalog.lastModified = data.catalog.metadata.`last-modified`,
    catalog.version = data.catalog.metadata.version,
    catalog.oscalVersion = data.catalog.metadata.`oscal-version`,
    catalog.remarks = data.catalog.metadata.remarks

// Groups
WITH catalog, data
UNWIND data.catalog.groups AS groupData
MERGE (group:Group {id: groupData.id})
SET group.title = groupData.title
MERGE (catalog)-[:HAS_GROUP]->(group)

// Group Properties
WITH catalog, group, groupData
FOREACH (prop IN groupData.props |
  MERGE (property:Property {name: prop.name, value: prop.value})
  MERGE (group)-[:HAS_PROPERTY]->(property)
)

// Subgroups and Controls
WITH catalog, group, groupData
UNWIND groupData.groups AS subgroupData
MERGE (subgroup:Group {id: subgroupData.id})
SET subgroup.title = subgroupData.title
MERGE (group)-[:HAS_SUBGROUP]->(subgroup)

// Subgroup Properties
WITH catalog, group, subgroup, subgroupData
FOREACH (subProp IN subgroupData.props |
  MERGE (subGroupProp:Property {name: subProp.name, value: subProp.value})
  MERGE (subgroup)-[:HAS_PROPERTY]->(subGroupProp)
)

// Controls within Subgroups
WITH catalog, group, subgroup, subgroupData
FOREACH (control IN subgroupData.controls |
  MERGE (c:Control {id: control.id})
  SET c.title = control.title
  MERGE (subgroup)-[:HAS_CONTROL]->(c)

  // Control Properties
  FOREACH (controlProp IN control.props |
    MERGE (controlProperty:Property {name: controlProp.name, value: controlProp.value})
    MERGE (c)-[:HAS_PROPERTY]->(controlProperty)
  )

  // Control Parameters
  FOREACH (param IN control.params |
    MERGE (p:Parameter {id: param.id})
    SET p.label = param.label
    MERGE (c)-[:HAS_PARAMETER]->(p)

    // Parameter Selections
    FOREACH (choice IN param.select.choice |
      MERGE (sel:Selection {howMany: param.select.`how-many`, choice: choice})
      MERGE (p)-[:HAS_SELECTION]->(sel)
    )
  )

  // Control Parts
  FOREACH (part IN control.parts |
    MERGE (partNode:Part {id: part.id, name: part.name})
    SET partNode.prose = part.prose
    MERGE (c)-[:HAS_PART]->(partNode)

    // Subparts
    FOREACH (subpart IN part.parts |
      MERGE (subPartNode:Part {id: subpart.id, name: subpart.name})
      SET subPartNode.prose = subpart.prose
      MERGE (partNode)-[:HAS_PART]->(subPartNode)
    )
  )
)

// Nested Subgroups
WITH catalog, subgroup, subgroupData
FOREACH (nestedGroup IN subgroupData.groups |
  MERGE (nested:Group {id: nestedGroup.id})
  SET nested.title = nestedGroup.title
  MERGE (subgroup)-[:HAS_SUBGROUP]->(nested)
)

