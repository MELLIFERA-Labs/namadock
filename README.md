# Namadock

A Docker-based solution for running Namada blockchain nodes with automated configuration using Ansible.

## Overview

Namadock provides a containerized environment for running Namada blockchain nodes with flexible configuration options. It supports different network types, node configurations, and bootstrap methods including snapshot-based initialization.

## Features

- 🐳 **Dockerized Namada nodes** - Easy deployment and management
- ⚙️ **Ansible automation** - Automated node configuration and setup
- 🌐 **Multi-network support** - Mainnet, testnet 


## Prerequisites

- Docker Engine 20.10.0 or higher
- Docker Compose (optional, for multi-container setups)
- At least 8GB RAM
- 100GB+ storage space for blockchain data

## Build Instructions

### Option 1: Build from Source

#### 1. Clone the Repository
```bash
git clone https://github.com/your-org/namadock.git
cd namadock
```

#### 2. Build the Docker Image
```bash
# Build with default Namada version
docker build -t mellifera/namadock .

# Build with specific Namada version
docker build --build-arg NAMADA_VERSION=v101.1.2 -t mellifera/namadock:v101.1.2 .

# Build with custom tag
docker build --build-arg NAMADA_VERSION=v101.1.2 -t your-registry/namadock:latest .
```

#### 3. Verify the Build
```bash
docker images | grep namadock
docker run --rm mellifera/namadock namada --version
```

### Option 2: Use Pre-built Images

#### Pull from image registry 
```bash
docker pull ghcr.io/mellifera-labs/namadock:v101.1.2-1beta
```

### Build Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `NAMADA_VERSION` | Namada binary version to install | `v101.1.2` | `v101.1.2`, `v100.2.1` |

#### Build Examples

```bash
# Build with specific version
docker build \
  --build-arg NAMADA_VERSION=v101.1.2 \
  -t mellifera/namadock .
```

## Quick Start

### Run a Node

```bash
# Basic mainnet node
docker run -d \
  --name namada-node \
  -p 26657:26657 \
  mellifera/namadock

# Testnet node with custom configuration
docker run -d \
  --name namada-testnet \
  -e TYPE=testnet \
  -e SEEDS=no \
  -e EXTERNAL_ADDRESS=IP:26656
  -p 26657:26657 \
  -p 26656:26656
  mellifera/namadock
```

## Configuration

### Environment Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `TYPE` | Network type | `mainnet` | `mainnet`, `testnet` |
| `USE_SERVICES` | Service configuration | `MELLIFERA` | `MELLIFERA`, `itrocket`, `mandragora` |
| `SNAPSHOT` | Snapshot URL for fast sync | from `USE_SERVICES` | `https://example.com/snapshot.tar.lz4` |
| `ADDRBOOK` | Address book URL | from `USE_SERVICES` | `https://example.com/addrbook.json` |
| `PEERS` | Persistent peers | from `USE_SERVICES` | `node1@ip1:port1,node2@ip2:port2` |
| `SEEDS` | Seed nodes | from `USE_SERVICES` | `seed1@ip1:port1,seed2@ip2:port2` |
| `STATE_SYNC_RPC` | State sync RPC endpoint | from `USE_SERVICES` | `https://rpc.example.com:443` |
| `STATE_SYNC_PEER` | State sync peer | from `USE_SERVICES` | `peer@ip:port` |
| `EXTERNAL_ADDRESS` | External address | - | `IP:26656` or `domain.com:26656` with IP var it will get ip address from internet |
| `MONIKER` | Node moniker | `namadock` | `my-namada-node` |
| `VALIDATOR_PORT` | External validator port | - | `26633` |
| `PORTS_PREFIX` | Port prefix for custom port configuration | - | `266`, `270` |
| `ENABLE_SEED_MODE` | Configure node as seed node | `false` | `true`, `false` |
| `ENABLE_PROMETHEUS` | Enable Prometheus metrics | `false` | `true`, `false` |
| `INDEXER` | Indexer configuration | `null` | `null`, `kv` |
| `MAX_NUM_INBOUND_PEERS` | Maximum inbound peer connections | - | `40`, `100` |
| `MAX_NUM_OUTBOUND_PEERS` | Maximum outbound peer connections | - | `10`, `20` |
| `RUN_FROM` | Bootstrap method | `none` | `state_sync`, `snapshot` |
| `RUN_CONFIGURE` | When to run configuration | `once` | `always`, `skip` |



### Advanced Configuration

#### Snapshot Bootstrap
Use a snapshot for faster synchronization:

```bash
docker run -d \
  --name namada-snapshot \
  -e SNAPSHOT="https://snapshots.example.com/namada-latest.tar.lz4" \
  -p 26657:26657 \
  mellifera/namadock
```


#### External Validator
For external validator setups:

```bash
docker run -d \
  --name namada-node \
  -e VALIDATOR_PORT=26659 \
  -p 26657:26657 \
  -p 26659:26659 \
  mellifera/namadock
```

## Network Types

### Mainnet
```bash
docker run -d -e TYPE=mainnet mellifera/namadock
```

### Testnet
```bash
docker run -d -e TYPE=testnet mellifera/namadock
```

## File Structure

```
namadock/
├── Dockerfile                          # Docker image definition
├── ansible/
│   ├── bootstrap.yml                   # Main Ansible playbook
│   ├── group_vars/                     # Network-specific variables
│   │   ├── mainnet.yml
│   │   └── testnet.yml
│   └── roles/
│       └── namada_configure/
│           └── tasks/
│               └── main.yml            # Node configuration tasks
└── README.md
```

## Volumes

The container uses the following important paths:
- `/home/namada/.local/share/namada/` - Namada data directory
- Node configuration is stored within the chain-specific subdirectory

To persist data:
```bash
docker run -d \
  -v namada-data:/home/namada/.local/share/namada \
  mellifera/namadock
```

## Ports

| Port | Description |
|------|-------------|
| 26656 | P2P networking |
| 26657 | RPC server |
| 26660 | Promethues metrics (if configured) |
| 26659 | External validator (if configured) |

## Troubleshooting

### Check Logs
```bash
docker logs namada-node
```

### Access Container
```bash
docker exec -it namada-node /bin/bash
```

### Check Node Status
```bash
docker compose exec --user namada node namadac  status
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
- Create an issue in this repository
- Check the [Namada documentation](https://docs.namada.net/)
- Join the Namada community Discord


# Future work 
- More `USE_SERVICES`
- `RUN_CONFIGURE=on_change` configuration 

---

**Note**: This is a beta version.


