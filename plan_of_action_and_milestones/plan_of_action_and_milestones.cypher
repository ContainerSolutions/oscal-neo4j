WITH "https://raw.githubusercontent.com/usnistgov/oscal-content/refs/heads/main/examples/poam/json/ifa_plan-of-action-and-milestones.json" AS url
CALL apoc.load.json(url) YIELD value

WITH value AS data
MERGE (poam:PlanOfActionAndMilestones {uuid: data.`plan-of-action-and-milestones`.uuid})
SET poam.title = data.`plan-of-action-and-milestones`.metadata.title,
    poam.lastModified = data.`plan-of-action-and-milestones`.metadata.`last-modified`,
    poam.version = data.`plan-of-action-and-milestones`.metadata.version,
    poam.oscalVersion = data.`plan-of-action-and-milestones`.metadata.`oscal-version`

// Import-ssp
WITH poam, data
MERGE (ssp:ImportedSSP {href: data.`plan-of-action-and-milestones`.`import-ssp`.href})
MERGE (poam)-[:IMPORTS_SSP]->(ssp)

// System ID
WITH poam, data
MERGE (system:SystemID {id: data.`plan-of-action-and-milestones`.`system-id`.id})
SET system.identifierType = data.`plan-of-action-and-milestones`.`system-id`.`identifier-type`
MERGE (poam)-[:HAS_SYSTEM_ID]->(system)

// Observations
WITH poam, data
UNWIND data.`plan-of-action-and-milestones`.observations AS observation
MERGE (obs:Observation {uuid: observation.uuid})
SET obs.title = observation.title,
    obs.description = observation.description,
    obs.collected = observation.collected,
    obs.expires = observation.expires,
    obs.remarks = observation.remarks
MERGE (poam)-[:HAS_OBSERVATION]->(obs)
FOREACH (method IN observation.methods |
  MERGE (m:Method {name: method})
  MERGE (obs)-[:USES_METHOD]->(m)
)
FOREACH (type IN observation.types |
  MERGE (t:Type {name: type})
  MERGE (obs)-[:HAS_TYPE]->(t)
)
FOREACH (subject IN observation.subjects |
  MERGE (subj:Subject {uuid: subject.`subject-uuid`, type: subject.type})
  MERGE (obs)-[:HAS_SUBJECT]->(subj)
)

// Risks
WITH poam, data
UNWIND data.`plan-of-action-and-milestones`.risks AS risk
MERGE (r:Risk {uuid: risk.uuid})
SET r.title = risk.title,
    r.description = risk.description,
    r.statement = risk.statement,
    r.status = risk.status,
    r.deadline = risk.deadline
MERGE (poam)-[:HAS_RISK]->(r)

// Risk characterizations
FOREACH (characterization IN risk.characterizations |
  FOREACH (actor IN characterization.origin.actors |
    MERGE (act:Actor {type: actor.type, uuid: actor.`actor-uuid`})
    MERGE (r)-[:INVOLVES_ACTOR]->(act)
  )
  FOREACH (facet IN characterization.facets |
    MERGE (f:Facet {name: facet.name, system: facet.system, value: facet.value})
    MERGE (r)-[:HAS_FACET]->(f)
  )
)

// Risk mitigations
FOREACH (mitigation IN risk.`mitigating-factors` |
  MERGE (m:Mitigation {uuid: mitigation.uuid, description: mitigation.description})
  MERGE (r)-[:HAS_MITIGATION]->(m)
)

// Risk remediations
FOREACH (remediation IN risk.remediations |
  MERGE (rm:Remediation {uuid: remediation.uuid, lifecycle: remediation.lifecycle})
  SET rm.title = remediation.title,
      rm.description = remediation.description
  MERGE (r)-[:HAS_REMEDIATION]->(rm)
  FOREACH (prop IN remediation.props |
    MERGE (p:Property {name: prop.name, value: prop.value})
    MERGE (rm)-[:HAS_PROPERTY]->(p)
  )
  FOREACH (task IN remediation.tasks |
    MERGE (t:Task {uuid: task.uuid, type: task.type})
    SET t.title = task.title,
        t.description = task.description,
        t.startDate = task.timing.`within-date-range`.start,
        t.endDate = task.timing.`within-date-range`.end
    MERGE (rm)-[:HAS_TASK]->(t)
  )
)

// POA&M Items
WITH poam, data
UNWIND data.`plan-of-action-and-milestones`.`poam-items` AS item
MERGE (pi:PoamItem {uuid: item.uuid})
SET pi.title = item.title,
    pi.description = item.description
MERGE (poam)-[:HAS_ITEM]->(pi)

// POA&M related observations and risks
FOREACH (relatedObservation IN item.`related-observations` |
  MERGE (ro:Observation {uuid: relatedObservation.`observation-uuid`})
  MERGE (pi)-[:RELATED_TO_OBSERVATION]->(ro)
)
FOREACH (relatedRisk IN item.`related-risks` |
  MERGE (rr:Risk {uuid: relatedRisk.`risk-uuid`})
  MERGE (pi)-[:RELATED_TO_RISK]->(rr)
)

