WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/component-definition/json/example-component-definition.json" AS url
CALL apoc.load.json(url) YIELD value

WITH value AS data
MERGE (def:ComponentDefinition {uuid: data.`component-definition`.uuid})
SET def.title = data.`component-definition`.metadata.title,
    def.lastModified = data.`component-definition`.metadata.`last-modified`,
    def.version = data.`component-definition`.metadata.version,
    def.oscalVersion = data.`component-definition`.metadata.`oscal-version`

// Handle roles
WITH def, data
UNWIND data.`component-definition`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (def)-[:HAS_ROLE]->(r)

// Handle parties
WITH def, data
UNWIND data.`component-definition`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
FOREACH (link IN party.links |
  MERGE (l:Link {href: link.href, rel: link.rel})
  MERGE (p)-[:HAS_LINK]->(l)
)
MERGE (def)-[:HAS_PARTY]->(p)

// Handle components
WITH def, data
UNWIND data.`component-definition`.components AS component
MERGE (c:Component {uuid: component.uuid})
SET c.type = component.type,
    c.title = component.title,
    c.description = component.description,
    c.purpose = component.purpose
MERGE (def)-[:HAS_COMPONENT]->(c)

// Link responsible roles
WITH c, component, def, data
FOREACH (role IN component.`responsible-roles` |
  MERGE (r:Role {id: role.`role-id`})
  MERGE (c)-[:RESPONSIBLE_FOR]->(r)
  FOREACH (partyUuid IN role.`party-uuids` |
    MERGE (p:Party {uuid: partyUuid})
    MERGE (r)-[:ASSOCIATED_WITH]->(p)
  )
)

// Handle protocols
WITH c, component, def, data
FOREACH (protocol IN component.protocols |
  MERGE (prot:Protocol {uuid: protocol.uuid})
  SET prot.name = protocol.name,
      prot.title = protocol.title
  MERGE (c)-[:USES_PROTOCOL]->(prot)
  FOREACH (portRange IN protocol.`port-ranges` |
    MERGE (pr:PortRange {start: portRange.start, end: portRange.end, transport: portRange.transport})
    MERGE (prot)-[:HAS_PORT_RANGE]->(pr)
  )
)

// Handle control implementations
WITH c, component, def, data
FOREACH (controlImpl IN component.`control-implementations` |
  MERGE (ci:ControlImplementation {uuid: controlImpl.uuid, source: controlImpl.source})
  SET ci.description = controlImpl.description
  MERGE (c)-[:IMPLEMENTS_CONTROL]->(ci)
  FOREACH (req IN controlImpl.`implemented-requirements` |
    MERGE (ir:ImplementedRequirement {uuid: req.uuid, controlId: req.`control-id`})
    SET ir.description = req.description
    MERGE (ci)-[:HAS_REQUIREMENT]->(ir)
    FOREACH (param IN req.`set-parameters` |
      MERGE (paramNode:Parameter {id: param.`param-id`})
      SET paramNode.values = param.values
      MERGE (ir)-[:HAS_PARAMETER]->(paramNode)
    )
    FOREACH (stmt IN req.statements |
      MERGE (s:Statement {id: stmt.`statement-id`, uuid: stmt.uuid})
      SET s.description = stmt.description
      MERGE (ir)-[:HAS_STATEMENT]->(s)
      FOREACH (respRole IN stmt.`responsible-roles` |
        MERGE (r:Role {id: respRole.`role-id`})
        MERGE (s)-[:RESPONSIBLE_ROLE]->(r)
      )
    )
  )
)


