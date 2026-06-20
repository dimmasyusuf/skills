#!/usr/bin/env bash
# work skill - aggregate reusable helpers for issue work.

WORK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"

# shellcheck disable=SC1091
source "$WORK_LIB_DIR/text.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/git.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/core.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/github.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/github-project.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/hooks.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/project.sh"
# shellcheck disable=SC1091
source "$WORK_LIB_DIR/superpowers.sh"
