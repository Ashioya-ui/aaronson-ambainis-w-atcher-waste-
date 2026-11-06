#!/usr/bin/env bash
# A stand-in for `landrun` that does NOT sandbox anything.
#
# Comparator runs each of its steps through `landrun`, which confines the step with Linux
# Landlock. This script accepts the same command line, drops the flags, and runs the command
# as it is. It exists to test the comparator setup on a machine without Landlock (a Mac, a
# container on a kernel without it). A run made with it is no certificate: nothing prevents
# the solution from writing to the files of the challenge. `run_comparator.sh` never uses it.
#
# Adapted from `scripts/fake-landrun.sh` of https://github.com/leanprover/comparator
# (Apache-2.0), at the commit FAKE_LANDRUN_REV of `comparator/PINS.env`.

set -euo pipefail

# The flags of landrun that are followed by a value.
flags_with_value=(
  --ro --rox --rw --rwx
  --bind-tcp --connect-tcp
  --log-level
  --env
)

is_value_flag() {
  local flag="$1"
  local known
  for known in "${flags_with_value[@]}"; do
    [[ "$flag" == "$known" ]] && return 0
  done
  return 1
}

case "${1:-}" in
  -h|--help)
    cat <<'EOF'
fake_landrun.sh: a stand-in for landrun that runs the command without any sandbox

Usage: landrun [flags] <command> [args...]

All flags are accepted and ignored.
EOF
    exit 0
    ;;
  -V|--version)
    echo "fake_landrun.sh: this is not landrun; nothing is sandboxed" >&2
    exit 0
    ;;
esac

# Drop the flags of landrun up to `--` or up to the first word that is not a flag.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --) shift; break ;;
    -*)
      if is_value_flag "$1"; then shift; fi
      shift
      ;;
    *) break ;;
  esac
done

if [[ $# -eq 0 ]]; then
  echo "fake_landrun.sh: no command given" >&2
  exit 2
fi

echo "fake_landrun.sh: NO SANDBOX, running: $*" >&2
exec "$@"
