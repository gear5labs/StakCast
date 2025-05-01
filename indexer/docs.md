## StakCast Indexer Documentation
### Overview
This document provides a detailed overview of the StakCast indexer, including the changes made, how to use The Graph for querying indexed data, and the available GraphQL endpoints.

### How to Use The Graph

1. Access the GraphQL Playground
   Open the GraphQL endpoint provided after deployment in your browser or a GraphQL client (e.g., GraphiQL).
   Example endpoint: https://api.thegraph.com/subgraphs/name/your-username/stakcast
2. Querying Data
   Use GraphQL queries to fetch data from the subgraph. Below are some examples:

   Query: Fetch All Markets

    ```
    {
        marketCreateds(first: 10) {
            id
            market_id
            creator
            title
            startTime
            endTime
        }
    }
    ```

    Query: Fetch Positions by User

    ```
    {
        positionTakens(where: { user: "0x123..." }) {
            id
            market_id
            user
            outcome_index
            amount
        }
    }
    ```
    Query: Fetch Market Resolutions
    ```
    {
        marketResolveds(first: 5) {
            id
            market_id
            outcome
            resolver
            resolution_details
        }
    }
    ```

### Endpoints
GraphQL Endpoint
- URL: https://api.studio.thegraph.com/query/107462/stakcast/v0.0.1

- Use this endpoint to query indexed data using GraphQL.
Setup and Maintenance

1. Local Development
- Clone the repository:

``` bash
git clone https://github.com/your-username/stakcast
cd indexer/stakcast/subgraph
```

- Install dependencies

```bash
npm install
```

- Build the subgraph:

```bash
graph codegen && graph build
```

- Deploy the subgraph:

```bash
graph deploy --product hosted-service your-username/stakcast
```

2. Updating the Subgraph

- Make changes to the mappings or schema.
- Rebuild and deploy the subgraph:

```bash
graph codegen && graph build
graph deploy --product hosted-service your-username/stakcast
```









