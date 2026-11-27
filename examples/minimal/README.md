# Minimal pattern

Illustrates the hostile runner as a **client on the network**, not a recipe
for a full product stack.

```bash
# From the hostile-e2e-runner repo root:
docker build -t hostile-e2e-runner:local .

# Suites live in the *product* repo. Here, a toy suite next to this README:
docker run --rm \
  -v "$PWD:/e2e:ro" \
  -w /e2e \
  -e E2E_BASE_URL=http://example.invalid \
  hostile-e2e-runner:local \
  pytest -q test_runner_smoke.py
```

`test_runner_smoke.py` only checks that pytest and httpx import — it does not
need a live server. Replace `E2E_BASE_URL` and add real HTTP tests when you
attach this image to compose.
