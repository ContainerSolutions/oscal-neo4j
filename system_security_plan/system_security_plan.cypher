// JSON from https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/ssp/json/ssp-example.json
CALL apoc.load.json('file:///system_security_plan/system_security_plan.json') YIELD value

WITH value AS data

// Create System Security Plan Node
MERGE (ssp:SystemSecurityPlan {uuid: data.`system-security-plan`.uuid})
SET ssp.title = data.`system-security-plan`.metadata.title,
    ssp.lastModified = data.`system-security-plan`.metadata.`last-modified`,
    ssp.version = data.`system-security-plan`.metadata.version,
    ssp.oscalVersion = data.`system-security-plan`.metadata.`oscal-version`

// Metadata: Roles
WITH ssp, data
UNWIND data.`system-security-plan`.metadata.roles AS role
MERGE (r:Role {id: role.id})
SET r.title = role.title
MERGE (ssp)-[:HAS_ROLE]->(r)

// Metadata: Parties
WITH ssp, data
UNWIND data.`system-security-plan`.metadata.parties AS party
MERGE (p:Party {uuid: party.uuid})
SET p.type = party.type,
    p.name = party.name
MERGE (ssp)-[:HAS_PARTY]->(p)

// Import Profile
WITH ssp, data
MERGE (profile:ImportedProfile {href: data.`system-security-plan`.`import-profile`.href})
MERGE (ssp)-[:IMPORTS_PROFILE]->(profile)

// System Characteristics
WITH ssp, data
MERGE (sc:SystemCharacteristics)
SET sc.systemName = data.`system-security-plan`.`system-characteristics`.`system-name`,
    sc.description = data.`system-security-plan`.`system-characteristics`.description,
    sc.securitySensitivityLevel = data.`system-security-plan`.`system-characteristics`.`security-sensitivity-level`
MERGE (ssp)-[:HAS_SYSTEM_CHARACTERISTICS]->(sc)

// System Characteristics: System IDs
WITH sc, data, ssp
UNWIND data.`system-security-plan`.`system-characteristics`.`system-ids` AS systemId
MERGE (id:SystemId {id: systemId.id})
SET id.identifierType = systemId.`identifier-type`
MERGE (sc)-[:HAS_SYSTEM_ID]->(id)

// System Characteristics: Props
WITH sc, data, ssp
UNWIND data.`system-security-plan`.`system-characteristics`.props AS prop
MERGE (pr:Property {name: prop.name, value: prop.value})
MERGE (sc)-[:HAS_PROPERTY]->(pr)

// System Characteristics: Information Types
WITH sc, data, ssp
UNWIND data.`system-security-plan`.`system-characteristics`.`system-information`.`information-types` AS infoType
MERGE (it:InformationType {uuid: infoType.uuid})
SET it.title = infoType.title,
    it.description = infoType.description
MERGE (sc)-[:HAS_INFORMATION_TYPE]->(it)

// Information Type Categorizations
WITH it, data, sc, ssp
UNWIND it.categorizations AS cat
MERGE (c:Categorization {system: cat.system})
FOREACH (infoId IN cat.`information-type-ids` |
  MERGE (cId:InformationTypeId {id: infoId})
  MERGE (c)-[:HAS_INFORMATION_TYPE_ID]->(cId)
)
MERGE (it)-[:HAS_CATEGORIZATION]->(c)

// Confidentiality, Integrity, Availability
WITH it, data, sc, ssp
SET it.confidentialityImpact = it.`confidentiality-impact`.base,
    it.integrityImpact = it.`integrity-impact`.base,
    it.availabilityImpact = it.`availability-impact`.base

// Security Impact Levels
WITH sc, data, ssp
MERGE (sil:SecurityImpactLevel)
SET sil.confidentiality = sc.`security-impact-level`.`security-objective-confidentiality`,
    sil.integrity = sc.`security-impact-level`.`security-objective-integrity`,
    sil.availability = sc.`security-impact-level`.`security-objective-availability`
MERGE (sc)-[:HAS_SECURITY_IMPACT_LEVEL]->(sil)

// Status
WITH sc, data, ssp
MERGE (status:Status {state: sc.status.state})
SET status.remarks = sc.status.remarks
MERGE (sc)-[:HAS_STATUS]->(status)

// Authorization Boundary
WITH sc, data, ssp
MERGE (authBoundary:AuthorizationBoundary)
SET authBoundary.description = sc.`authorization-boundary`.description
MERGE (sc)-[:HAS_AUTHORIZATION_BOUNDARY]->(authBoundary)

// System Implementation: Users
WITH ssp, data
UNWIND data.`system-security-plan`.`system-implementation`.users AS user
MERGE (u:User {uuid: user.uuid})
SET u.title = user.title
MERGE (ssp)-[:HAS_USER]->(u)
FOREACH (prop IN user.props |
  MERGE (p:Property {name: prop.name, value: prop.value})
  MERGE (u)-[:HAS_PROPERTY]->(p)
)

WITH u, user, ssp, data
UNWIND user.`role-ids` AS roleId
MATCH (r:Role {id: roleId})
MERGE (u)-[:HAS_ROLE]->(r)

// System Implementation: Components
WITH ssp, data
UNWIND data.`system-security-plan`.`system-implementation`.components AS component
MERGE (c:Component {uuid: component.uuid})
SET c.type = component.type,
    c.title = component.title,
    c.description = component.description
MERGE (ssp)-[:HAS_COMPONENT]->(c)

// Component Status
WITH c, component, ssp, data
MERGE (status:Status {state: component.status.state})
MERGE (c)-[:HAS_STATUS]->(status)

// Component Responsible Roles
WITH c, component, ssp, data
UNWIND component.`responsible-roles` AS respRole
MATCH (r:Role {id: respRole.`role-id`})
MERGE (c)-[:HAS_RESPONSIBLE_ROLE]->(r)

WITH c, component, ssp, data, respRole
UNWIND respRole.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (r)-[:RESPONSIBLE_FOR]->(p)

// Inventory Items
WITH ssp, data
UNWIND data.`system-security-plan`.`system-implementation`.`inventory-items` AS item
MERGE (inv:InventoryItem {uuid: item.uuid})
SET inv.description = item.description
MERGE (ssp)-[:HAS_INVENTORY_ITEM]->(inv)

WITH inv, item
UNWIND item.`responsible-parties` AS respParty
MATCH (r:Role {id: respParty.`role-id`})
MERGE (inv)-[:HAS_RESPONSIBLE_ROLE]->(r)

WITH inv, item, respParty
UNWIND respParty.`party-uuids` AS partyUuid
MATCH (p:Party {uuid: partyUuid})
MERGE (r)-[:RESPONSIBLE_FOR]->(p)

// Inventory Item Components
WITH inv, item
FOREACH (implComp IN item.`implemented-components` |
  MERGE (c:Component {uuid: implComp.`component-uuid`})
  MERGE (inv)-[:IMPLEMENTS_COMPONENT]->(c)
)

