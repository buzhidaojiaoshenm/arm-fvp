# Proxy Build-Argument Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align the proxy build-argument test with the existing quoted shell syntax.

**Architecture:** The production build path already appends quoted `--build-arg` arguments. The test performs static checks, so its expected strings must match that source syntax exactly.

**Tech Stack:** Bash, `grep -Fq`.

---

### Task 1: Correct proxy build-argument assertions

**Files:**
- Modify: `tests/test_container_proxy_build_args.sh:7-9`
- Test: `tests/test_container_proxy_build_args.sh`

- [ ] **Step 1: Verify the current test fails**

Run: `bash tests/test_container_proxy_build_args.sh`
Expected: exit status 1 because each current expected build argument omits the double quotes used in `stack/container-scripts/container.sh`.

- [ ] **Step 2: Match the quoted build-argument syntax**

Replace each expected argument with the matching source string:

```bash
grep -Fq -- '--build-arg "HTTP_PROXY=${HTTP_PROXY}"' "$script"
grep -Fq -- '--build-arg "HTTPS_PROXY=${HTTPS_PROXY}"' "$script"
grep -Fq -- '--build-arg "ALL_PROXY=${ALL_PROXY}"' "$script"
```

- [ ] **Step 3: Verify the focused test passes**

Run: `bash tests/test_container_proxy_build_args.sh`
Expected: exit status 0.

- [ ] **Step 4: Verify all repository shell tests pass**

Run: `for test in tests/test_*.sh; do bash "$test"; done`
Expected: exit status 0.
