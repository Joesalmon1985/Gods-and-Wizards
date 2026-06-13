#!/usr/bin/env bash
# Run K skeleton: export telemetry from Godot, train BC in Python, evaluate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "${ROOT}/.." && pwd)"
GODOT_PROJECT="${GODOT_PROJECT:-${REPO_ROOT}/godot_game}"
GODOT_BIN="${GODOT_BIN:-godot4}"
ARTIFACTS="${ARTIFACTS:-${ROOT}/artifacts}"
SEED="${SEED:-42}"
MAX_STEPS="${MAX_STEPS:-64}"

mkdir -p "${ARTIFACTS}"

echo "==> Export macro_training_v2 (seed=${SEED})"
"${GODOT_BIN}" --headless --path "${GODOT_PROJECT}" \
  --script res://run_modes/run_macro_training_export.gd \
  -- --seed "${SEED}" --max-steps "${MAX_STEPS}" \
  --output "user://macro_training_seed_${SEED}.csv"

echo "==> Export micro_combat_v2 (seed=${SEED})"
"${GODOT_BIN}" --headless --path "${GODOT_PROJECT}" \
  --script res://run_modes/run_micro_combat_export.gd \
  -- --seed "${SEED}" --max-steps "${MAX_STEPS}" \
  --output "user://micro_combat_seed_${SEED}.csv"

MACRO_CSV="${MACRO_CSV:-${ARTIFACTS}/macro_training_seed_${SEED}.csv}"
MICRO_CSV="${MICRO_CSV:-${ARTIFACTS}/micro_combat_seed_${SEED}.csv}"

echo "==> Train macro BC"
python -m train.train_macro_bc \
  --csv "${MACRO_CSV}" \
  --output-weights "${ARTIFACTS}/macro_policy.json" \
  --seed "${SEED}"

echo "==> Train micro BC"
python -m train.train_micro_bc \
  --csv "${MICRO_CSV}" \
  --output-weights "${ARTIFACTS}/micro_policy.json" \
  --seed "${SEED}"

echo "==> Evaluate (Python hold-out on same CSV for smoke test)"
python -m eval.evaluate_macro_policy \
  --csv "${MACRO_CSV}" \
  --weights "${ARTIFACTS}/macro_policy.json" \
  --metrics-csv "${ARTIFACTS}/macro_eval.csv"

python -m eval.evaluate_micro_policy \
  --csv "${MICRO_CSV}" \
  --weights "${ARTIFACTS}/micro_policy.json" \
  --metrics-csv "${ARTIFACTS}/micro_eval.csv"

echo "Done. Weights in ${ARTIFACTS}"
