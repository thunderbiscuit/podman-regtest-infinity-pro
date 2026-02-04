# Using in CI/CD Pipelines

The _Podman Regtest Infinity Pro_ publishes pre-built container images to the GitHub Container Registry, making it easy to use in your CI/CD pipelines without the overhead of building from source.

## Quick Start

Pull and run the latest pre-built image:

```bash
# Using Docker
docker pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.3.0
docker run -d -p 18443:18443 -p 18444:18444 -p 3002:3002 -p 3003:3003 -p 60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.3.0

# Using Podman
podman pull ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.3.0
podman run -d -p 18443:18443 -p 18444:18444 -p 3002:3002 -p 3003:3003 -p 60401:60401 \
  ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:v0.3.0
```

## GitHub Actions

Use the pre-built container as a service in your GitHub Actions workflow:

```yaml
name: Test with Bitcoin Regtest

on: [push, pull_request]

jobs:
  test-with-regtest:
    runs-on: ubuntu-24.04

    services:
      bitcoin-regtest:
        image: ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
        ports:
          - 18443:18443
          - 18444:18444
          - 3002:3002
          - 3003:3003
          - 60401:60401
        # The container initialization step will wait until everything is ready before allowing other steps to run
        options: >-
          --health-cmd "test $(bitcoin-cli -regtest -rpcuser=regtest -rpcpassword=password getblockcount) -gt 0"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 6

    steps:
      - name: Test Bitcoin RPC
        run: |
          echo "Testing connection to Bitcoin regtest node..."
          curl --user regtest:password --data-binary '{"jsonrpc":"1.0","id":"test","method":"getblockchaininfo","params":[]}' \
            -H 'content-type: text/plain;' http://localhost:18443/ | jq

      - name: Run your tests here
        run: |
          echo "This is where you would run your actual test suite"
          echo "The regtest environment is fully operational!"
```

Always pin to a specific full version in production:

```yaml
services:
  bitcoin-regtest:
    image: ghcr.io/thunderbiscuit/podman-regtest-infinity-pro:0.3.0
```

## Available Services

Once the container is running, the following services are available:

| Service | Port | Description |
|---------|------|-------------|
| Bitcoin Core RPC | 18443 | JSON-RPC interface for bitcoin-cli |
| Bitcoin P2P | 18444 | Peer-to-peer network port |
| Esplora | 3002 | REST API for blockchain queries |
| Block Explorer | 3003 | Web-based block explorer |
| Electrum | 60401 | Electrum protocol server |

## Default Configuration

The container starts with:
- Bitcoin Core running in regtest mode
- Username: `regtest`, password: `password`
- Faucet wallet with 101 blocks pre-mined (mature coins ready to spend)
- Compact block filters enabled
- All services started automatically

## Benefits of Pre-built Images

- **Fast**: No compilation time - just pull and run
- **Reproducible**: Same environment across all developers and CI runs
- **Resource-efficient**: Save CI minutes by skipping the build step
- **Reliable**: Images are built and tested before publishing

## Building Your Own Images

If you need a custom configuration or different Bitcoin Core version, you can still build from source. See the main README for build instructions.
