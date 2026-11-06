#!/usr/bin/env bash
# Prints the statements and the axiom dependencies of the final theorems and of the theorems on
# which they rest. The project must have been built (`lake build`) before.
set -euo pipefail
cd "$(dirname "$0")/.."
lake env lean AaronsonAmbainis/AxiomReport.lean
