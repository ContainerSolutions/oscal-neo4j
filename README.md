# oscal-neo4j

A repo to help visualise OSCAL documents in Neo4J.

## Getting Started

Run `make` to see how to run this.

Examples are from [here](https://github.com/usnistgov/oscal-content/tree/main/examples)

## Project Structure

Each example from the [OSCAL repo](https://github.com/usnistgov/oscal-content/tree/main/examples) has a corresponding folder. In that folder is:

- a Neo4J `FOLDER.cypher` file

- the example `FOLDER.json` file

- a `load_FOLDER.sh` file, which loads the `.json` file using the `.cypher` file into the Neo4J database
