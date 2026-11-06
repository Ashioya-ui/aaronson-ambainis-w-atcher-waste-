#!/bin/sh
# Comparator on `comparator/config.json` WITHOUT its sandbox.
#
# Usage: run_comparator_unsandboxed.sh [PROJECT_DIR [CONFIG]]
# Without arguments the project is this repository and the configuration is
# `comparator/config.json`. The arguments exist for the controls of
# `verification/control/` (see run_comparator_controls.sh).
#
# `landrun` is replaced by `scripts/fake_landrun.sh`, which runs every step unconfined. All
# other parts are the real ones: both modules are built, both are exported with `lean4export`,
# the statements are compared, the axioms are checked, and the solution is replayed by nanoda
# and by the Lean kernel. The run shows that the setup works and that these checks pass. It is
# no certificate: without the sandbox nothing prevents the solution from tampering with the
# challenge. The certificate is a run of `scripts/run_comparator.sh`.
#
# The tools `lean4export`, `nanoda_bin`, `lake` must be on PATH, and `comparator` too (or give
# its path in COMPARATOR_BIN).

set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
comparator_bin=${COMPARATOR_BIN:-comparator}
shim="$root/scripts/fake_landrun.sh"
project=$(CDPATH= cd -- "${1:-$root}" && pwd)
config=${2:-comparator/config.json}
case "$config" in
  /*) ;;
  *) config="$project/$config" ;;
esac

if [ ! -f "$config" ]; then
  echo "run_comparator_unsandboxed.sh: no such file: $config" >&2
  exit 2
fi

for tool in lean4export nanoda_bin lake; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "run_comparator_unsandboxed.sh: missing tool: $tool" >&2
    exit 2
  fi
done

if comparator_path=$(command -v "$comparator_bin" 2>/dev/null); then
  :
else
  echo "run_comparator_unsandboxed.sh: comparator not found: $comparator_bin" >&2
  exit 2
fi
case "$comparator_path" in
  /*) ;;
  *) comparator_path="$(pwd)/$comparator_path" ;;
esac

if [ ! -x "$shim" ]; then
  echo "run_comparator_unsandboxed.sh: not executable: $shim" >&2
  exit 2
fi

echo "run_comparator_unsandboxed.sh: NO SANDBOX. This run tests the setup and certifies nothing." >&2

shim_dir=$(mktemp -d)
trap 'rm -rf -- "$shim_dir"' EXIT HUP INT TERM
ln -s "$shim" "$shim_dir/landrun"

cd "$project"
PATH="$shim_dir:$PATH" lake env "$comparator_path" "$config"
