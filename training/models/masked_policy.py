"""Single-hidden-layer MLP with masked softmax for discrete BC policies."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import torch
import torch.nn as nn
import torch.nn.functional as F


class MaskedPolicy(nn.Module):
    """ReLU MLP policy head compatible with Godot TinyNeuralNetwork weight layout."""

    def __init__(self, input_size: int, output_size: int, hidden_size: int = 8) -> None:
        super().__init__()
        self.input_size = input_size
        self.hidden_size = hidden_size
        self.output_size = output_size
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.fc2 = nn.Linear(hidden_size, output_size)

    def forward(self, features: torch.Tensor) -> torch.Tensor:
        hidden = F.relu(self.fc1(features))
        return self.fc2(hidden)

    def masked_softmax(self, logits: torch.Tensor, legal_mask: torch.Tensor) -> torch.Tensor:
        if legal_mask.dtype != torch.bool:
            legal_mask = legal_mask > 0.0
        masked_logits = logits.masked_fill(~legal_mask, float("-inf"))
        return F.softmax(masked_logits, dim=-1)

    def choose_action(self, logits: torch.Tensor, legal_mask: torch.Tensor) -> torch.Tensor:
        if legal_mask.dtype != torch.bool:
            legal_mask = legal_mask > 0.0
        masked_logits = logits.masked_fill(~legal_mask, float("-inf"))
        return masked_logits.argmax(dim=-1)

    def masked_cross_entropy(
        self,
        logits: torch.Tensor,
        targets: torch.Tensor,
        legal_mask: torch.Tensor,
    ) -> torch.Tensor:
        log_probs = torch.log(self.masked_softmax(logits, legal_mask) + 1e-12)
        return F.nll_loss(log_probs, targets)

    def to_godot_dict(self) -> dict[str, Any]:
        w1 = self.fc1.weight.detach().cpu().numpy()
        b1 = self.fc1.bias.detach().cpu().numpy()
        w2 = self.fc2.weight.detach().cpu().numpy()
        b2 = self.fc2.bias.detach().cpu().numpy()

        weights_ih: list[float] = []
        for i in range(self.input_size):
            for h in range(self.hidden_size):
                weights_ih.append(float(w1[h, i]))

        weights_ho: list[float] = []
        for h in range(self.hidden_size):
            for o in range(self.output_size):
                weights_ho.append(float(w2[o, h]))

        return {
            "input_size": self.input_size,
            "hidden_size": self.hidden_size,
            "output_size": self.output_size,
            "weights_ih": weights_ih,
            "bias_h": [float(x) for x in b1],
            "weights_ho": weights_ho,
            "bias_o": [float(x) for x in b2],
        }

    @classmethod
    def from_godot_dict(cls, data: dict[str, Any]) -> "MaskedPolicy":
        model = cls(
            int(data["input_size"]),
            int(data["output_size"]),
            int(data.get("hidden_size", 8)),
        )
        w1 = torch.zeros(model.hidden_size, model.input_size)
        for i in range(model.input_size):
            for h in range(model.hidden_size):
                w1[h, i] = float(data["weights_ih"][i * model.hidden_size + h])
        b1 = torch.tensor(data["bias_h"], dtype=torch.float32)
        w2 = torch.zeros(model.output_size, model.hidden_size)
        for h in range(model.hidden_size):
            for o in range(model.output_size):
                w2[o, h] = float(data["weights_ho"][h * model.output_size + o])
        b2 = torch.tensor(data["bias_o"], dtype=torch.float32)
        with torch.no_grad():
            model.fc1.weight.copy_(w1)
            model.fc1.bias.copy_(b1)
            model.fc2.weight.copy_(w2)
            model.fc2.bias.copy_(b2)
        return model


def export_godot_weights(model: MaskedPolicy, output_path: str | Path) -> Path:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(model.to_godot_dict(), indent=2) + "\n", encoding="utf-8")
    return path


def load_godot_weights(weights_path: str | Path) -> MaskedPolicy:
    data = json.loads(Path(weights_path).read_text(encoding="utf-8"))
    return MaskedPolicy.from_godot_dict(data)
