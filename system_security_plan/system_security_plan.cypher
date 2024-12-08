WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ssp/json/ssp-example.json" AS url
CALL apoc.load.json(url) YIELD value

// Extract the system security plan (ssp)
WITH value AS data
MERGE (ssp:SystemSecurityPlan {uuid: data.`system-security-plan`.uuid})
SET ssp.title = data.`system-security-plan`.metadata.title,
    ssp.lastModified = data.`system-security-plan`.metadata.`last-modified`,
    ssp.version = data.`system-security-plan`.metadata.version,
    ssp.oscalVersion = data.`system-security-plan`.metadata.`oscal-version`

// Extract roles
WITH ssp, data
UNWIND data.`system-security-plan`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (ssp)-[:HAS_ROLE]->(r)

// Extract parties
WITH ssp, data
UNWIND data.`system-security-plan`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
FOREACH (link IN party.links |
  MERGE (l:Link {href: link.href, rel: link.rel})
  MERGE (p)-[:HAS_LINK]->(l)
)
MERGE (ssp)-[:HAS_PARTY]->(p)

// Extract system characteristics
WITH ssp, data
MERGE (sysChar:SystemCharacteristics {uuid: data.`system-security-plan`.`system-characteristics`.`system-name`})
SET sysChar.name = data.`system-security-plan`.`system-characteristics`.name,
    sysChar.description = data.`system-security-plan`.`system-characteristics`.description
MERGE (ssp)-[:HAS_CHARACTERISTICS]->(sysChar)

// Extract system IDs
WITH ssp, sysChar, data
UNWIND data.`system-security-plan`.`system-characteristics`.`system-ids` AS sysId
MERGE (id:SystemID {id: sysId.id})
SET id.idType = sysId.type
MERGE (sysChar)-[:HAS_ID]->(id)

// Extract system implementation
WITH ssp, data
MERGE (sysImpl:SystemImplementation)
MERGE (ssp)-[:HAS_IMPLEMENTATION]->(sysImpl)

// Extract components
WITH ssp, sysImpl, data
UNWIND data.`system-security-plan`.`system-implementation`.components AS component
MERGE (comp:Component {uuid: component.uuid})
SET comp.title = component.title,
    comp.type = component.type,
    comp.description = component.description
MERGE (sysImpl)-[:HAS_COMPONENT]->(comp)

// Extract implemented requirements
WITH ssp, data
UNWIND data.`system-security-plan`.`control-implementation`.`implemented-requirements` AS req
MERGE (ir:ImplementedRequirement {uuid: req.uuid, controlId: req.`control-id`})
SET ir.description = req.description
MERGE (ssp)-[:HAS_IMPLEMENTED_REQUIREMENT]->(ir)

// Extract statements and parameters from requirements
WITH ssp, ir, data, req
FOREACH (param IN req.`set-parameters` |
  MERGE (paramNode:Parameter {id: param.`param-id`})
  SET paramNode.values = param.values
  MERGE (ir)-[:HAS_PARAMETER]->(paramNode)
)
FOREACH (stmt IN req.statements |
  MERGE (stmtNode:Statement {id: stmt.`statement-id`})
  SET stmtNode.description = stmt.description
  MERGE (ir)-[:HAS_STATEMENT]->(stmtNode)
)

// Extract back-matter resources
WITH ssp, data
UNWIND data.`system-security-plan`.`back-matter`.resources AS resource
MERGE (res:Resource {uuid: resource.uuid})
SET res.description = resource.description
MERGE (ssp)-[:HAS_RESOURCE]->(res)
FOREACH (rlink IN resource.rlinks |
  MERGE (rl:ResourceLink {href: rlink.href, mediaType: rlink.`media-type`})
  MERGE (res)-[:HAS_LINK]->(rl)
)

