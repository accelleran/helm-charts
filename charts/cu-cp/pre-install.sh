#!/bin/bash

set -euo pipefail

GIT_ROOT="$(realpath "$(dirname "$0")/../..")"

# renovate: github_repository=metallb/metallb versioning=semver
export METALLB_VERSION="v0.15.3"
"$GIT_ROOT"/bin/install-metallb
