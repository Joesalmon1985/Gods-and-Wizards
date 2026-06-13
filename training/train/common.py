"""Shared BC training helpers."""

from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Callable

import torch
import torch.nn as nn

from models.masked_policy import MaskedPolicy


@dataclass
class TrainConfig:
    seed: int = 42
    hidden_size: int = 8
    epochs: int = 50
    batch_size: int = 32
    learning_rate: float = 1e-3
    output_size: int | None = None


def set_seed(seed: int) -> None:
    random.seed(seed)
    torch.manual_seed(seed)


def train_bc(
    model: MaskedPolicy,
    features: torch.Tensor,
    targets: torch.Tensor,
    masks: torch.Tensor,
    *,
    epochs: int,
    batch_size: int,
    learning_rate: float,
) -> dict[str, float]:
    optimizer = torch.optim.Adam(model.parameters(), lr=learning_rate)
    dataset_size = features.shape[0]
    last_loss = 0.0
    last_accuracy = 0.0

    for _ in range(epochs):
        permutation = torch.randperm(dataset_size)
        epoch_loss = 0.0
        epoch_correct = 0
        epoch_count = 0

        for start in range(0, dataset_size, batch_size):
            indices = permutation[start : start + batch_size]
            batch_x = features[indices]
            batch_y = targets[indices]
            batch_mask = masks[indices]

            logits = model(batch_x)
            loss = model.masked_cross_entropy(logits, batch_y, batch_mask)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            preds = model.choose_action(logits, batch_mask)
            epoch_correct += int((preds == batch_y).sum().item())
            epoch_count += batch_y.shape[0]
            epoch_loss += float(loss.item()) * batch_y.shape[0]

        last_loss = epoch_loss / max(epoch_count, 1)
        last_accuracy = epoch_correct / max(epoch_count, 1)

    return {"final_loss": last_loss, "final_accuracy": last_accuracy}


def evaluate_bc(
    model: MaskedPolicy,
    features: torch.Tensor,
    targets: torch.Tensor,
    masks: torch.Tensor,
) -> dict[str, float]:
    model.eval()
    with torch.no_grad():
        logits = model(features)
        preds = model.choose_action(logits, masks)
        accuracy = float((preds == targets).float().mean().item())
        illegal = 0
        for i in range(masks.shape[0]):
            action = int(preds[i].item())
            if masks[i, action] <= 0.0:
                illegal += 1
        loss = float(model.masked_cross_entropy(logits, targets, masks).item())
    model.train()
    return {
        "accuracy": accuracy,
        "loss": loss,
        "illegal_actions": float(illegal),
        "sample_count": float(features.shape[0]),
    }


def build_model(
    feature_dim: int,
    output_size: int,
    hidden_size: int,
    seed: int,
) -> MaskedPolicy:
    set_seed(seed)
    return MaskedPolicy(feature_dim, output_size, hidden_size)
