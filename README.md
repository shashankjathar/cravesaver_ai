# CraveSaver AI

> **Querying a food delivery dataset by user mood, budget, and delivery wait times.**

CraveSaver AI is a modern food recommendation engine that maps subjective user cravings, budgets, and dietary restrictions to specific dishes. Instead of using complex backend translation layers, this project uses **Google Cloud AlloyDB's AI Natural Language extension** (`alloydb_ai_nl`) to perform Natural Language-to-SQL translation directly inside the database.

## Architecture
- **Backend**: Python / Flask
- **Database**: Google Cloud AlloyDB for PostgreSQL
- **AI Vector Search**: Vertex AI (`textembedding-gecko@003`)
- **Deployment**: Google Cloud Run

## Prerequisites
1. A Google Cloud Platform (GCP) Project.
2. Google Cloud SDK (`gcloud` CLI) installed and authenticated.
3. An existing AlloyDB Cluster & Primary Instance configured with a private IP in a VPC named `easy-alloydb-vpc`.

## Setup & Deployment Guide

### 1. Environment Configuration
First, copy the `.env_sample` to a new `.env` file and fill in your specific Google Cloud details:
```bash
cp .env_sample .env
# Edit .env and supply your Region, AlloyDB Cluster Names, and Password.
```

### 2. Infrastructure & Networking
Run the setup script. This script enables required APIs, configures VPC peering for `easy-alloydb-vpc`, and grants Vertex AI permissions to your AlloyDB service account.
```bash
./setup_gcp.sh
```

### 3. Enable AI Database Flags
Before running the SQL scripts, you must explicitly enable the AI extension flag on your database instance. Run this command (replacing with your exact instance details):
```bash
gcloud alloydb instances update YOUR_INSTANCE_ID \
    --cluster=YOUR_CLUSTER_ID \
    --region=YOUR_REGION \
    --database-flags=alloydb_ai_nl.enabled=on
```
*(Alternatively, you can edit your Primary Instance in the GCP Console and add the `alloydb_ai_nl.enabled=on` database flag manually).*

### 4. Database Initialization
Connect to your AlloyDB instance using `psql` or AlloyDB Studio in the Google Cloud Console.
Run the two SQL scripts found in the `database/` folder in this exact order:

1. **`schema.sql`**: Enables the vector/ML extensions, creates the `cravesaver.dishes` schema, and seeds the restaurant data.
2. **`setup_nl.sql`**: Enables the natural language AI extension, adds metadata comments to teach the AI about your schema, and sets a prescriptive rule for sorting by `mood_embedding`.

### 5. Deploy to Cloud Run
Deploy the Flask application to Google Cloud Run. The script automatically handles connecting Cloud Run securely to your private network.
```bash
./deploy.sh
```

Once deployment finishes, the terminal will output a public URL where you can access the live web interface!
