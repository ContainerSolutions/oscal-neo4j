WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/component-definition/json/example-component-definition.json" AS url
CALL apoc.load.json(url) YIELD value

WITH value AS data
MERGE (cd:ComponentDefinition {uuid: data.`component-definition`.uuid})
SET cd.title = data.`component-definition`.metadata.title,
    cd.lastModified = data.`component-definition`.metadata.`last-modified`,
    cd.version = data.`component-definition`.metadata.version,
    cd.oscalVersion = data.`component-definition`.metadata.`oscal-version`

// Roles
WITH cd, data
UNWIND data.`component-definition`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (cd)-[:HAS_ROLE]->(r)

// Parties
WITH cd, data
UNWIND data.`component-definition`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
FOREACH (link IN party.links |
  MERGE (l:Link {href: link.href, rel: link.rel})
  MERGE (p)-[:HAS_LINK]->(l)
)
MERGE (cd)-[:HAS_PARTY]->(p)

// Components
WITH cd, data
UNWIND data.`component-definition`.components AS componentData
MERGE (component:Component {uuid: componentData.uuid})
SET component.type = componentData.type,
    component.title = componentData.title,
    component.description = componentData.description,
    component.purpose = componentData.purpose
MERGE (cd)-[:HAS_COMPONENT]->(component)

// Responsible Roles for Components
WITH cd, component, componentData, data
UNWIND componentData.`responsible-roles` AS respRole
MERGE (role:Role {id: respRole.`role-id`})
MERGE (component)-[:RESPONSIBLE_FOR]->(role)

// Match and Connect Parties to Responsible Roles
WITH cd, component, respRole, role, componentData, data
UNWIND respRole.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (role)-[:ASSOCIATED_WITH]->(p)

// Protocols
WITH cd, component, componentData, data
UNWIND componentData.protocols AS protocol
MERGE (prot:Protocol {uuid: protocol.uuid})
SET prot.name = protocol.name,
    prot.title = protocol.title
MERGE (component)-[:USES_PROTOCOL]->(prot)

WITH cd, prot, protocol, component, componentData, data
UNWIND protocol.`port-ranges` AS portRange
MERGE (pr:PortRange {start: portRange.start, end: portRange.end, transport: portRange.transport})
MERGE (prot)-[:HAS_PORT_RANGE]->(pr)

// Control Implementations
WITH cd, component, componentData, data
UNWIND componentData.`control-implementations` AS controlImpl
MERGE (ci:ControlImplementation {uuid: controlImpl.uuid, source: controlImpl.source})
SET ci.description = controlImpl.description
MERGE (component)-[:IMPLEMENTS_CONTROL]->(ci)

// Requirements and Parameters
WITH cd, ci, controlImpl, data
UNWIND controlImpl.`implemented-requirements` AS req
MERGE (ir:ImplementedRequirement {uuid: req.uuid, controlId: req.`control-id`})
SET ir.description = req.description
MERGE (ci)-[:HAS_REQUIREMENT]->(ir)

// Parameters
WITH cd, ir, req, data
UNWIND req.`set-parameters` AS param
MERGE (paramNode:Parameter {id: param.`param-id`})
SET paramNode.values = param.values
MERGE (ir)-[:HAS_PARAMETER]->(paramNode)

// Statements
WITH cd, ir, req, data
UNWIND req.statements AS stmt
MERGE (s:Statement {id: stmt.`statement-id`, uuid: stmt.uuid})
SET s.description = stmt.description
MERGE (ir)-[:HAS_STATEMENT]->(s)

// Responsible Roles for Statements
WITH cd, s, stmt, data
UNWIND stmt.`responsible-roles` AS respRole
MATCH (role:Role {id: respRole.`role-id`})
MERGE (s)-[:RESPONSIBLE_ROLE]->(role)

// Back Matter Resources
WITH cd, data
UNWIND data.`component-definition`.`back-matter`.resources AS resource
MERGE (res:Resource {uuid: resource.uuid})
SET res.description = resource.description
MERGE (cd)-[:HAS_RESOURCE]->(res)
WITH res, resource
UNWIND resource.rlinks AS rlink
MERGE (rl:ResourceLink {href: rlink.href, mediaType: rlink.`media-type`})
MERGE (res)-[:HAS_LINK]->(rl)

