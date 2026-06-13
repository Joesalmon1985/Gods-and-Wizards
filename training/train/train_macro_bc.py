"""Behavioural cloning trainer for macro_training_v2 CSV."""

from __future__ import annotations

import argparse
from pathlib import Path

import torch

import checkpoint_metadata
from etl.macro_v2_loader import LAYOUT_VERSION, load_macro_v2_csv
from models.masked_policy import export_godot_weights
from train.common import TrainConfig, build_model, evaluate_bc, set_seed, train_bc


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Train macro BC policy from macro_training_v2 CSV")
    parser.add_argument("--csv", required=True, help="Path to macro_training_v2 CSV export")
    parser.add_argument("--output-weights", required=True, help="Path for Godot-compatible weights JSON")
    parser.add_argument("--run-id", default="macro_bc_run", help="Checkpoint run identifier")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--hidden-size", type=int, default=8)
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--learning-rate", type=float, default=1e-3)
    parser.add_argument("--output-size", type=int, default=64, help="Compact macro action head size (fixed at 64)")
    parser.add_argument("--git-commit", default="", help="Optional provenance stamp")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    set_seed(args.seed)

    dataset = load_macro_v2_csv(args.csv, output_size=args.output_size)
    feature_dim = int(dataset.metadata["feature_dim"])
    output_size = int(dataset.metadata["output_size"])

    model = build_model(feature_dim, output_size, args.hidden_size, args.seed)
    metrics = train_bc(
        model,
        dataset.features,
        dataset.targets,
        dataset.masks,
        epochs=args.epochs,
        batch_size=args.batch_size,
        learning_rate=args.learning_rate,
    )
    eval_metrics = evaluate_bc(model, dataset.features, dataset.targets, dataset.masks)

    weights_path = export_godot_weights(model, args.output_weights)
    pt_path = Path(args.output_weights).with_suffix(".pt")
    torch.save(
        {
            "state_dict": model.state_dict(),
            "feature_dim": feature_dim,
            "output_size": output_size,
            "hidden_size": args.hidden_size,
        },
        pt_path,
    )
    training_cmd = " ".join(["python", "-m", "train.train_macro_bc", f"--csv={args.csv}", f"--output-weights={args.output_weights}"])
    eval_cmd = f"python -m eval.evaluate_macro_policy --checkpoint {weights_path} --episodes 5 --seed 900 --output logs/eval_macro_run_k.csv"
    metadata = checkpoint_metadata.new_metadata(
        run_id=args.run_id,
        policy_kind="macro_bc",
        schema_version="macro_training_v2",
        rules_version=str(dataset.metadata.get("rules_version", "run_g_v2")),
        training_seed=args.seed,
        source_csv=str(Path(args.csv).resolve()),
        feature_dim=feature_dim,
        output_size=output_size,
        hidden_size=args.hidden_size,
        epochs=args.epochs,
        learning_rate=args.learning_rate,
        batch_size=args.batch_size,
        final_loss=metrics["final_loss"],
        final_accuracy=metrics["final_accuracy"],
        weights_json_path=str(weights_path.resolve()),
        featurizer_version=str(dataset.metadata["featurizer_version"]),
        framework_version=torch.__version__,
        git_commit=args.git_commit,
        action_space_layout_key=str(dataset.metadata.get("action_space_layout_key", "")),
        sample_count=int(dataset.metadata["sample_count"]),
        eval_metrics=eval_metrics,
    )
    metadata.extra["training_command"] = training_cmd
    metadata.extra["eval_command"] = eval_cmd
    metadata.extra["observation_schema_version"] = "macro_training_v2"
    metadata.extra["legal_mask_layout_version"] = str(dataset.metadata.get("legal_mask_layout_version", LAYOUT_VERSION))
    checkpoint_metadata.save_metadata(metadata, weights_path)

    print(
        f"macro BC complete: loss={metrics['final_loss']:.4f} "
        f"acc={metrics['final_accuracy']:.4f} weights={weights_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
