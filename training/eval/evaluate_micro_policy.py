"""Live micro policy evaluation via Godot headless learned-policy runner (Route B)."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Evaluate micro BC with live Godot rollout")
    parser.add_argument("--checkpoint", required=True, help="Godot-compatible weights JSON path")
    parser.add_argument("--episodes", type=int, default=10)
    parser.add_argument("--seed", type=int, default=901)
    parser.add_argument("--output", required=True, help="Evaluation CSV output path")
    parser.add_argument("--godot-root", default="..", help="Repo root containing godot_game/")
    parser.add_argument("--loadout-a", default="hero_patrol")
    parser.add_argument("--loadout-b", default="demon_breach")
    parser.add_argument("--max-steps", type=int, default=200)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    root = Path(args.godot_root).resolve()
    script = root / "scripts" / "invoke-godot-headless.sh"
    weights = Path(args.checkpoint).resolve()
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    rows: list[dict] = []
    for episode in range(args.episodes):
        eval_seed = args.seed + episode
        episode_out = out_path.parent / f"eval_micro_seed_{eval_seed}.csv"
        cmd = [
            str(script),
            "--headless",
            "--path",
            "godot_game",
            "-s",
            "res://run_modes/run_micro_learned_eval.gd",
            "--",
            "--weights",
            str(weights),
            "--seed",
            str(eval_seed),
            "--loadout-a",
            args.loadout_a,
            "--loadout-b",
            args.loadout_b,
            "--max-steps",
            str(args.max_steps),
            "--output",
            str(episode_out),
        ]
        completed = subprocess.run(cmd, cwd=root, check=False, capture_output=True, text=True)
        report_line = completed.stdout.strip().split("\n")[-1] if completed.stdout else ""
        try:
            report = json.loads(report_line)
        except json.JSONDecodeError:
            report = {"seed": eval_seed, "error": completed.stderr or report_line}
        report["godot_exit_code"] = completed.returncode
        rows.append(report)

    with out_path.open("w", encoding="utf-8") as handle:
        if rows:
            headers = list(rows[0].keys())
            handle.write(",".join(headers) + "\n")
            for row in rows:
                handle.write(",".join(str(row.get(h, "")) for h in headers) + "\n")

    print(json.dumps({"output": str(out_path), "episodes": rows}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
