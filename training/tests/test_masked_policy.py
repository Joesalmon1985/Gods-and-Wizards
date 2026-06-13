from __future__ import annotations

import json

import torch

from models.masked_policy import MaskedPolicy, export_godot_weights, load_godot_weights


def test_masked_softmax_zeroes_illegal_actions() -> None:
    model = MaskedPolicy(input_size=4, output_size=3, hidden_size=4)
    logits = torch.tensor([[1.0, 2.0, 3.0]])
    mask = torch.tensor([[1.0, 0.0, 1.0]])
    probs = model.masked_softmax(logits, mask)
    assert probs[0, 1].item() == 0.0
    assert abs(probs.sum(dim=-1).item() - 1.0) < 1e-5


def test_godot_weight_roundtrip(tmp_path) -> None:
    model = MaskedPolicy(input_size=16, output_size=8, hidden_size=8)
    path = export_godot_weights(model, tmp_path / "weights.json")
    restored = load_godot_weights(path)
    x = torch.randn(2, 16)
    assert torch.allclose(model(x), restored(x), atol=1e-6)


def test_godot_dict_matches_tiny_neural_layout() -> None:
    model = MaskedPolicy(input_size=16, output_size=8, hidden_size=8)
    data = model.to_godot_dict()
    assert data["input_size"] == 16
    assert data["hidden_size"] == 8
    assert data["output_size"] == 8
    assert len(data["weights_ih"]) == 16 * 8
    assert len(data["weights_ho"]) == 8 * 8
    assert len(data["bias_h"]) == 8
    assert len(data["bias_o"]) == 8
