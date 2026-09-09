# Proxy Build-Argument Test Design

## Goal

Make the RD-V3-R1 proxy build-argument check reflect the existing `container.sh` syntax.

## Scope

`tests/test_container_proxy_build_args.sh` will assert the three quoted build arguments emitted by `build_image()`: `HTTP_PROXY`, `HTTPS_PROXY`, and `ALL_PROXY`. Production scripts and Docker behavior remain unchanged.

## Verification

The focused shell test must pass, followed by the repository's shell test suite.
