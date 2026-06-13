# Run K — External PyTorch Training Package

Headless behavioural cloning (BC) for Gods and Wizards telemetry exported from Godot.

## Overview

| Track | Godot schema | Feature dim | Default head |
|---|---|---:|---:|
| Macro board game | `macro_training_v2` | 16 | inferred from `legal_mask_json` |
| Micro spell combat | `micro_combat_v2` | 10 | inferred from `legal_mask_json` |

Featurizers mirror Godot:

- `MacroFeatureFeaturizer` → `etl/featurizers.py`
- `MicroCombatFeatureFeaturizer` → `etl/featurizers.py`

Trained weights export as JSON compatible with Godot `TinyNeuralNetwork.from_dict()`.

## Setup

```bash
cd training
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pytest
```

## Godot export (data generation)

From the Godot project root:

```bash
# Macro telemetry CSV
godot4 --headless --path godot_game --script res://run_modes/run_macro_training_export.gd

# Micro combat telemetry CSV
godot4 --headless --path godot_game --script res://run_modes/run_micro_combat_export.gd
```

## Train (BC)

```bash
python -m train.train_macro_bc \
  --csv /path/to/macro_training_v2.csv \
  --output-weights artifacts/macro_policy.json \
  --seed 42 --epochs 50

python -m train.train_micro_bc \
  --csv /path/to/micro_combat_v2.csv \
  --output-weights artifacts/micro_policy.json \
  --seed 42 --epochs 50
```

Each run writes:

- `artifacts/macro_policy.json` — Godot weight layout
- `artifacts/macro_policy.json.meta.json` — checkpoint sidecar (`checkpoint_metadata.py`)

## Evaluate

Python-side held-out eval (mask accuracy + illegal action count):

```bash
python -m eval.evaluate_macro_policy \
  --csv tests/fixtures/macro_training_v2_tiny.csv \
  --weights artifacts/macro_policy.json \
  --metrics-csv artifacts/macro_eval.csv

python -m eval.evaluate_micro_policy \
  --csv tests/fixtures/micro_combat_v2_tiny.csv \
  --weights artifacts/micro_policy.json
```

Optional Godot subprocess eval (pass your local Godot command):

```bash
python -m eval.evaluate_macro_policy \
  --csv data/macro_holdout.csv \
  --weights artifacts/macro_policy.json \
  --godot-eval-cmd 'godot4 --headless --path ../godot_game --script res://run_modes/run_macro_baseline_eval.gd'
```

## Godot deployment

Load exported JSON in GDScript:

```gdscript
var net := TinyNeuralNetwork.from_dict(JSON.parse_string(FileAccess.get_file_as_string(path)))
var logits := net.forward(features)
var action_index := net.choose_action_index(logits, legal_mask)
```

## Layout

```
training/
  checkpoint_metadata.py
  etl/macro_v2_loader.py
  etl/micro_v2_loader.py
  models/masked_policy.py
  train/train_macro_bc.py
  train/train_micro_bc.py
  eval/evaluate_macro_policy.py
  eval/evaluate_micro_policy.py
  tests/fixtures/
  scripts/export_and_train.sh
```

## Related docs

- `docs/MACRO_TRAINING_ENV_CONTRACT.md`
- `docs/MICRO_SPELL_COMBAT_TRAINING_ENV_CONTRACT.md`
- `godot_game/core/export/macro_training_telemetry_schema.gd`
- `godot_game/core/export/micro_combat_telemetry_schema.gd`
