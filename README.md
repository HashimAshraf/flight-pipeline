# \# OpenSky Flight Data Pipeline (Internship Weeks 1–2)

#

# An end-to-end data engineering project built around the OpenSky Network REST API.

#

# This project progresses from manual ELT foundations in Week 1 to an Airflow-orchestrated, Dockerized pipeline in Week 2. It intentionally stops before the Week 3 Kafka/streaming and BI-dashboard milestones.

#

# \## Internship Roadmap Alignment

#

# \### Week 1 — ETL Foundations

#

# \- Design PostgreSQL layers: `raw`, `staging`, and `warehouse`.

# \- Fetch live aircraft state vectors from OpenSky's REST API.

# \- Store each original API response in PostgreSQL as JSONB.

# \- Transform state-vector arrays into typed staging records.

# \- Validate coordinates and position timestamps; retain rejected rows with a reason.

# \- Load a star-schema warehouse (`dim\_aircraft`, `dim\_date`, `fact\_flight\_position`).

# \- Run analytical SQL with CTEs, `LAG`, and `LEAD`.

# \- Use Git feature branches and document setup/run steps.

#

# \### Week 2 — Pipeline Orchestration

#

# \- Define an Airflow DAG with Python and PostgreSQL operators.

# \- Schedule hourly API ingestion and SQL transformation.

# \- Use PostgreSQL `ON CONFLICT` UPSERTs to make staging and warehouse loads re-runnable.

# \- Run PostgreSQL and Airflow in Docker Compose.

# \- Diagnose DAG imports, SQL mounts, service networking, and connection failures.

# \- Maintain a troubleshooting reference in `docs/troubleshooting.md`.

#

# \## Architecture

#

# ```text

# OpenSky Network REST API

# &#x20;       |

# &#x20;       v

# Python requests extractor

# &#x20;       |

# &#x20;       v

# raw.opensky\_api\_response  (full JSONB response; one row per API request)

# &#x20;       |

# &#x20;       v

# staging.opensky\_states    (typed state vectors + validation flags)

# &#x20;       |

# &#x20;       +-----------------------+

# &#x20;       |                       |

# &#x20;       v                       v

# warehouse.dim\_aircraft   warehouse.dim\_date

# &#x20;       \\                       /

# &#x20;        \\                     /

# &#x20;         v                   v

# &#x20;         warehouse.fact\_flight\_position

# ```

#

# Airflow orchestrates initialization → API extraction/raw load → staging and warehouse transformation.

#

# PostgreSQL is shared by the Airflow metadata database and the project database in the local Docker Compose environment.

#

# \## Repository Structure

#

# ```text

# dags/

# &#x20; opensky\_elt\_dag.py        # Week 2 Airflow DAG

# src/

# &#x20; config.py                 # Environment configuration

# &#x20; opensky\_client.py         # OpenSky REST API client

# &#x20; load\_raw.py               # Week 1 manual/API raw ingestion

# &#x20; transform.py              # Week 1 manual SQL transformation

# sql/

# &#x20; 00\_init.sql               # Idempotent schema/table creation

# &#x20; 05\_transform.sql          # Staging + warehouse transformation and UPSERTs

# &#x20; 06\_analytics.sql          # CTE, LAG, LEAD and data-quality queries

# scripts/

# &#x20; init-databases.sh         # Creates project and Airflow databases/roles

# docs/

# &#x20; evidence/

# &#x20;   airflow-success.png     # Airflow DAG execution evidence

# &#x20;   postgres-warehouse-results.png  # PostgreSQL warehouse query evidence

# &#x20; troubleshooting.md        # Week 2 diagnostics and issue log

# Dockerfile

# docker-compose.yml

# .env.example

# requirements.txt

# README.md

# ```

#

# \## Prerequisites

#

# \- Git and GitHub account

# \- Docker Desktop with Compose (Windows: WSL2 backend recommended)

# \- Python 3.10+ for the optional manual Week 1 run

# \- PostgreSQL client / DBeaver (optional, for inspecting tables)

# \- OpenSky account and OAuth client credentials if required for your API access

#

# \## Configuration

#

# Copy `.env.example` to `.env`.

#

# \*\*Windows PowerShell\*\*

#

# ```powershell

# Copy-Item .env.example .env

# ```

#

# \*\*macOS/Linux\*\*

#

# ```bash

# cp .env.example .env

# ```

#

# Edit `.env` and set non-default development passwords. Add your OpenSky API client ID and secret.

#

# OpenSky's REST API supports OAuth2 client credentials; anonymous requests may be available with reduced limits. Never commit `.env`, tokens, passwords, or private keys.

#

# The default bounding box is a small region over Pakistan. Adjust it only within the provider's current API/credit limits. OpenSky response availability and access rules may change; consult the provider's current API documentation.

#

# \## Week 1 — Manual ETL Workflow

#

# Start PostgreSQL only:

#

# ```bash

# docker compose up -d postgres

# ```

#

# Create a local Python virtual environment and install dependencies:

#

# ```bash

# python -m venv .venv

#

# \# Windows

# .venv\\Scripts\\activate

#

# \# macOS/Linux

# source .venv/bin/activate

#

# pip install -r requirements.txt

# ```

#

# Run the API extractor and store the raw JSON response:

#

# ```bash

# python -m src.load\_raw

# ```

#

# The command prints the generated `raw\_id`.

#

# Transform that response into staging and warehouse tables:

#

# ```bash

# python -m src.transform --raw-id 1

# ```

#

# Replace `1` with the actual `raw\_id` printed by extraction.

#

# Inspect the `raw`, `staging`, and `warehouse` schemas in DBeaver.

#

# Run `sql/06\_analytics.sql` to review CTE, `LAG`, `LEAD`, and quality-check examples.

#

# \## Week 2 — Dockerized Airflow Workflow

#

# Ensure `.env` exists and Docker Desktop is running.

#

# Build the Airflow image and initialize the Airflow metadata database:

#

# ```bash

# docker compose build

# docker compose up airflow-init

# ```

#

# Start Airflow:

#

# ```bash

# docker compose up -d airflow-webserver airflow-scheduler

# ```

#

# Open `http://localhost:8080`.

#

# Default local development login is `admin` / `admin` unless changed in `.env`.

#

# Unpause `opensky\_flight\_elt` and trigger it. The DAG is scheduled hourly.

#

# Confirm all three tasks succeed:

#

# \- `initialize\_database\_objects`

# \- `extract\_load\_raw`

# \- `transform\_to\_warehouse`

#

# Inspect the PostgreSQL tables using DBeaver or the diagnostic commands in the troubleshooting guide.

#

# \## Week 2 — Local Execution Results

#

# The Dockerized pipeline was successfully initialized and executed locally.

#

# \### Airflow Execution

#

# \- Airflow version: 2.10.5

# \- DAG: `opensky\_flight\_elt`

# \- DAG tasks: 3

# \- Successful DAG runs observed: 2

# \- Task statuses: all three tasks completed successfully.

#

# \### PostgreSQL Verification

#

# The following records were observed after pipeline execution:

#

# | Schema | Table | Observed rows |

# |---|---|---:|

# | `raw` | `opensky\_api\_response` | 2 |

# | `staging` | `opensky\_states` | 2 |

# | `warehouse` | `dim\_aircraft` | 1 |

# | `warehouse` | `fact\_flight\_position` | 2 |

# | `warehouse` | `dim\_date` | 1 |

#

# The warehouse fact table contained two flight-position observations associated with one aircraft dimension record.

#

# The observed position records included timestamps, longitude, latitude, altitude, velocity, true track, vertical rate, and on-ground status.

#

# These are local test results from the development environment, not a guarantee of future API response volume.

#

# \### Evidence Screenshots

#

# \*\*Airflow DAG execution\*\*

#

# !\[Airflow DAG successful execution](docs/evidence/airflow-success.png)

#

# \*\*PostgreSQL warehouse records\*\*

#

# !\[PostgreSQL warehouse query results](docs/evidence/postgres-warehouse-results.png)

#

# \## Database Connections

#

# \### From Your Host Machine / DBeaver

#

# \- Host: `localhost`

# \- Port: `5432`

# \- Database: `flights\_dw`

# \- User: value of `POSTGRES\_USER` in `.env`

# \- Password: value of `POSTGRES\_PASSWORD` in `.env`

#

# \### From Airflow Containers

#

# \- Host: `postgres` (Docker service name, not `localhost`)

# \- Port: `5432`

# \- Database: `flights\_dw`

# \- Airflow connection ID: `flights\_postgres` (created from `AIRFLOW\_CONN\_FLIGHTS\_POSTGRES`)

#

# \## Data Model and Idempotency

#

# \- \*\*Raw layer:\*\* preserves every API response as JSONB. A new extraction intentionally creates a new raw audit record.

# \- \*\*Staging layer:\*\* unique partial index on `(icao24, time\_position)`; the UPSERT updates an existing observation when the same aircraft/time key is encountered again.

# \- \*\*Warehouse aircraft dimension:\*\* natural key `icao24`, protected by a unique constraint.

# \- \*\*Warehouse date dimension:\*\* `date\_key` (`YYYYMMDD`) is unique; repeated dates are ignored.

# \- \*\*Warehouse fact:\*\* unique `(aircraft\_key, position\_ts)` and `ON CONFLICT DO UPDATE`.

#

# Records with missing/out-of-range coordinates or missing position timestamps remain in staging with `is\_valid = false` and a `reject\_reason`; only valid rows enter the warehouse.

#

# The raw table grows with every API call by design. Idempotency applies to staging and warehouse business records, not to the raw audit log.

#

# \## Troubleshooting

#

# See `docs/troubleshooting.md` for CLI diagnostics and a troubleshooting log.

#

# Record only errors you actually reproduce and fix.

#

# \## Git Workflow

#

# Example feature-branch workflow:

#

# ```bash

# git switch -c feature/week1-opensky-etl

# git add .

# git commit -m "Build OpenSky API ETL foundations"

# git push -u origin feature/week1-opensky-etl

#

# git switch -c feature/week2-airflow-orchestration

# git add .

# git commit -m "Orchestrate OpenSky ELT with Airflow and Docker"

# git push -u origin feature/week2-airflow-orchestration

# ```

#

# Open pull requests on GitHub, review the changes, then merge them into `main`.

#

# For the exact steps to update your existing repository safely, see `docs/github\_upload.md`.

#

# \## Data Source

#

# OpenSky Network: https://opensky-network.org/

#

# Respect OpenSky's current terms, API documentation, authentication requirements, and rate/credit limits.

#

# The configured 4° × 4° bounding box covers 16 square degrees; the current API documentation lists this area band as a one-credit `/states/all` request.

#

# Never commit API credentials.
