#!/bin/sh
# A sandboxed run of comparator on `comparator/config.json`. Linux only.
#
# Usage: run_comparator.sh [PROJECT_DIR [CONFIG]]
# Without arguments the project is this repository and the configuration is
# `comparator/config.json`. The arguments exist for the controls of
# `verification/control/` (see run_comparator_controls.sh).
#
# The tools must be on PATH: `landrun`, `lean4export`, `nanoda_bin`, `lake`, `systemd-run`,
# and `comparator` (or give its path in COMPARATOR_BIN). `comparator/README.md` says how to
# build them at the revisions of `comparator/PINS.env`.
#
# Run this in a fresh checkout, after `lake exe cache get` and before anything else has been
# built: comparator assumes that the solution has not been compiled on the machine before.
#
# The run is wrapped in `systemd-run --property=RestrictAddressFamilies=~AF_UNIX`, as the
# README of the current revision of comparator asks: this closes a way out of the landrun
# sandbox (see "The sandbox" in `comparator/README.md`). With `--wait`, systemd-run returns
# the exit status of comparator and prints the statistics of the run after its output.

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
comparator_bin=${COMPARATOR_BIN:-comparator}
project=$(CDPATH= cd -- "${1:-$root}" && pwd)
config=${2:-comparator/config.json}
case "$config" in
  /*) ;;
  *) config="$project/$config" ;;
esac

if [ ! -f "$config" ]; then
  echo "run_comparator.sh: no such file: $config" >&2
  exit 2
fi

if [ "$(uname -s)" != Linux ]; then
  echo "run_comparator.sh: the sandbox needs Linux; on other systems only" >&2
  echo "scripts/run_comparator_unsandboxed.sh runs, and it certifies nothing" >&2
  exit 2
fi

if [ "$(id -u)" -eq 0 ]; then
  echo "run_comparator.sh: comparator must not be run by a privileged user" >&2
  exit 2
fi

for tool in systemd-run landrun lean4export nanoda_bin lake; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "run_comparator.sh: missing tool: $tool" >&2
    exit 2
  fi
done

if comparator_path=$(command -v "$comparator_bin" 2>/dev/null); then
  :
else
  echo "run_comparator.sh: comparator not found: $comparator_bin" >&2
  exit 2
fi
case "$comparator_path" in
  /*) ;;
  *) comparator_path="$(pwd)/$comparator_path" ;;
esac

# Comparator would not notice a sandbox that confines nothing; see check_sandbox.sh.
"$root/scripts/check_sandbox.sh"

exec systemd-run \
  --property=RestrictAddressFamilies=~AF_UNIX \
  --user \
  --wait \
  --pty \
  --pipe \
  -E PATH="$PATH" \
  --working-directory "$project" \
  -- bash -c 'lake env "$1" "$2"' comparator-run "$comparator_path" "$config"
