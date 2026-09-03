# EtherEver BlockScout Explorer

[![Docker Build Check](https://github.com/makewalletfirst/EtherEver-BlockScout8/actions/workflows/docker-ci.yml/badge.svg)](https://github.com/makewalletfirst/EtherEver-BlockScout8/actions/workflows/docker-ci.yml)
[![Ecosystem](https://img.shields.io/badge/Ecosystem-EtherEver-blue)](https://etherever.ever-chain.xyz)
[![License](https://img.shields.io/badge/License-GPL--3.0-green.svg)](./LICENSE)

Official repository for the **EtherEver BlockScout Explorer** — a customized
deployment of [BlockScout](https://github.com/blockscout/blockscout) tailored
specifically for **EtherEver (ETE)**, a custom Layer-1 Proof-of-Work blockchain
hardforked from Ethereum mainnet at block **#1,919,999**.

---

## 🌟 About EtherEver Explorer

The EtherEver Explorer provides transparent, real-time data indexing and
visualization for the EtherEver network. It is built upon BlockScout's robust
Elixir/Phoenix backend and Next.js frontend, pre-configured to interface
seamlessly with our customized L1 chain node.

### Core Customizations for EtherEver

- **Preconfigured Environment (`fixed_envs.js`)** — Tailored variables to
  correctly identify the `ETE` symbol, Chain ID `58051`, and our RPC endpoints
- **Custom Branding** — Fully customized logos and visual elements to align
  with the EtherEver ecosystem (logo update note: BlockScout's frontend
  Docker image expects PNGs hosted online — local PNGs are not auto-bundled,
  so brand assets are loaded from public URLs)
- **Dynamic Stats Synchronization** — A dedicated shell script
  (`update_stats.sh`) managed via **PM2** to continuously compute and sync
  transaction metrics (e.g., daily transaction counts) from the main
  BlockScout index database to the stats microservice database
- **SSL Configuration** — Optimized for secure Cloudflare-proxied SSL
  connections using WebSocket Secure (`wss://`) and secure HTTP (`https://`)

---

## 🛠️ Technology Stack

- **Backend Indexer & Engine**: Elixir / Erlang, Phoenix Framework
- **Frontend App**: Next.js, React, TailwindCSS
- **Database Engine**: PostgreSQL 14 (separate databases for primary index and stats)
- **Caching Layer**: Redis
- **Gateway & Load Balancer**: Nginx (orchestrating API paths, frontend, and microservices)
- **Process Manager**: PM2 (node/script management)
- **Rust Microservices**:
  - **Stats** — aggregates and serves analytics charts
  - **Visualizer (Sol2UML)** — compiles smart contracts into UML models
  - **Sig-provider** — resolves method/event signatures
  - **User-ops-indexer** — tracks ERC-4337 transaction flows

---

## 📁 Repository Structure

```
├── apps/                         # Phoenix/Elixir apps — core indexing and Web API logic
├── config/                       # Elixir configuration environment files
├── docker-compose/               # Primary deployment environment
│   ├── envs/                     # Environment variable overrides (.env templates)
│   ├── fixed_envs.js             # Pre-built React frontend configurations for EtherEver
│   ├── etherever-logo.png        # Brand assets
│   ├── update_stats.sh           # Stats DB synchronization daemon script
│   └── docker-compose.yml        # Orchestration: DBs, indexers, frontend
└── .github/workflows/
    └── docker-ci.yml             # GitHub Action — docker compose config validation
```

---

## 🚀 Getting Started (Build & Run)

### Prerequisites
- **Docker** v20.10+
- **Docker Compose** v2.x+
- **PM2** (for stats updater process management)
- Access to an active **EtherEver Geth node**
  (RPC URL `https://rpc-ether.ever-chain.xyz` via Cloudflare,
  or direct internal endpoint)

---

### Step 1: Clone and Set Up Environment Configuration
Change into the `docker-compose` folder and prepare your `.env`:
```bash
cd docker-compose
cp envs/common-blockscout.env .env
```
*(Ensure all RPC endpoints and DB credentials inside `.env` match your
execution environment.)*

---

### Step 2: Spin Up Docker Services
Start the stack. The backend indexer compiles from source automatically on
first run:
```bash
docker compose up -d --build
```

This builds and initializes **9 micro-containers**:
1. `db` — main PostgreSQL DB for explorer indexes
2. `redis` — core cache layer
3. `backend` — Phoenix-based blockchain indexing and API engine
4. `frontend` — Next.js explorer UI
5. `stats-db` — separate PostgreSQL DB for metrics
6. `stats` — Rust-based stats API service
7. `visualizer` — contract UML generation service
8. `sig-provider` — signature translation service
9. `user-ops-indexer` — ERC-4337 tracker

---

### Step 3: Inject Custom Frontend Configuration
Map the explorer UI to EtherEver's chain configuration by copying the
pre-built env file into the running frontend container:
```bash
docker cp ./fixed_envs.js frontend:/app/public/assets/envs.js
```
Verify:
```bash
docker exec frontend cat /app/public/assets/envs.js
```

---

### Step 4: Run the PM2 Stats Synchronizer
BlockScout aggregates daily transaction statistics. A persistent worker feeds
live data from the primary indexing DB into the stats DB:

```bash
pm2 start update_stats.sh --interpreter bash --name update-stats
```

The script queries transaction counts every 3 minutes (180 s) and inserts
them into the stats database with the correct `chart_id = 123` so they
immediately appear on the frontend charts.

---

## 🔒 Production Security (SSL & Proxying)

In a secure production environment proxied behind Cloudflare:
- The frontend uses secure protocols. `fixed_envs.js` maps
  `NEXT_PUBLIC_APP_PROTOCOL = https` and
  `NEXT_PUBLIC_API_WEBSOCKET_PROTOCOL = wss`
- If WebSocket proxy errors occur, verify that Cloudflare's **WebSockets**
  toggle is enabled in the Network settings
- Force-fix for legacy `ws://` clients: rewrite to `wss://` at the nginx
  layer

---

## ⚠️ Important Precautions & Troubleshooting

- **First Sync Lag** — BlockScout indexes blocks sequentially from genesis.
  Preserving the historical blocks up to `#1,919,999` means indexing can take
  significant time depending on your RPC throughput
- **Port Mapping Conflicts** — Ensure ports `80`, `443`, `7432` (Postgres),
  and `6379` (Redis) are unoccupied on the host before `docker compose up`
- **Database Migrations** — Tables are initialized automatically during
  backend container startup. Do not modify schema tables manually except via
  Elixir migrations

---

## 📜 License & Credits

Based on the open-source [BlockScout Explorer](https://github.com/blockscout/blockscout).
Distributed under the **GPL-3.0 License**. Feel free to audit, tweak, or contribute!
