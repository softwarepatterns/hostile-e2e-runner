# hostile-e2e-runner

**Python HTTP client image for sealed-application tests.**  
It exercises a **shipped binary over the network only**. It never mounts or
imports product source. The name is the policy: the runner is **hostile** to
the implementation — a black-box client, not a friend with a debugger.

Use this pattern whenever agents (or humans) keep “fixing” isolation by
writing in-process tests against Rust types. A language wall plus a network
wall makes cheating expensive and obvious.

## Why it exists

| Pressure | Failure mode | This image |
|---|---|---|
| Agents ignore “don’t import the server” | Rust tests call internal APIs and pass while the process is wrong | **Python only** — no cargo, no crates, no apps tree |
| Tests coupled to compile | Every test edit rebuilds the SUT | **Suites stay outside** — volume/bind the product’s `e2e/` tree; change a test and re-run |
| Tests live “inside” the app | Fixture code becomes another module of the product | **Client on the compose network** — tacked on from outside a normal stack |

**Product value:** unfakeable, outside-in proof that the **shippable process**
behaves, with tests cheap to change and structurally unable to reach into the
implementation language.

## Contract (non-negotiable)

1. **SUT is a process** (usually a production container image), not a library
   under test in-process.
2. **Contact is HTTP** (or other wire protocols) via service DNS on a shared
   network — e.g. `E2E_BASE_URL=http://server:8080`.
3. **Suites are not baked into this image.** Mount or copy the product’s test
   tree at run time (prefer a **volume** for fast iteration).
4. **Never mount product source** (`apps/`, `crates/`, `src/` meant for build)
   into this container as the normal path.
5. **Tooling is an allowlist** (`requirements.txt`). Suites do not `pip install`
   ad hoc at runtime.

## Image

```text
forgejo.softwarepatterns.com/softwarepatterns/hostile-e2e-runner:latest
```

(Publish tags from CI or local `docker build` + push. Pin a digest or version
tag in product CI.)

### Build locally

```bash
docker build -t hostile-e2e-runner:local .
```

### What’s inside

| Tool | Role |
|---|---|
| pytest | Suite runner |
| httpx | HTTP client |
| schemathesis | OpenAPI property / negative testing |
| cryptography | JWT and crypto helpers in black-box tests |

Default working directory: `/e2e`. Default command: `pytest -q`.

## How a product uses it

```text
┌──────────────────────────────────────┐
│  compose (product runtime)           │
│  deps + server (shipped binary)      │
└──────────────────▲───────────────────┘
                   │ HTTP (compose DNS)
┌──────────────────┴───────────────────┐
│  hostile-e2e-runner                  │
│  -v ./e2e:/e2e:ro                    │
│  -e E2E_BASE_URL=http://server:PORT  │
│  pytest -q <suite>                   │
└──────────────────────────────────────┘
```

Example (same-host dockerd; suites as a volume):

```bash
# 1. Bring up the product stack (server = production image)
docker compose -f apps/my-server/docker-compose.yml --profile dev up -d

# 2. Run hostile client against it
docker run --rm \
  --network <compose-project>_default \
  -e E2E_BASE_URL=http://server:8080 \
  -v "$PWD/e2e:/e2e:ro" \
  -w /e2e \
  hostile-e2e-runner:local \
  pytest -q my-server
```

**Prefer volume mounts** for the suite tree so editing a test does not rebuild
this image. Rebuilding the runner is only for allowlist/tooling changes.

## What this image is not

- Not a place to compile Rust or run `cargo test`
- Not a substitute for unit or hermetic module tests
- Not a grab-bag of every product’s fixtures (those live in each product’s
  `e2e/` tree)
- Not permission to `docker exec` into the server as the default “test API”

## Strategy others can copy

1. **Define sealed application** as: production binary + real deps + external
   client over the wire.
2. **Pick a client language that cannot import the SUT** (here, Python vs Rust).
3. **Keep suites outside the runner image** so iteration is cheap.
4. **Name the runner so the stance cannot be ignored** (`hostile-…`).
5. **Share one runner across products**; keep product-specific tests in each
   repo.

## License

MIT — see [LICENSE](LICENSE).
