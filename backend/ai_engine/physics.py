"""
physics.py — GlobalStateEngine

Manages the 8 Universal Knobs and the mathematical state of the simulated
Malaysian economy across simulation ticks.

The 8 Knobs (all values clamped to [-1.0, 1.0]):
  1. disposable_income_delta      – Direct cash flow changes
  2. operational_expense_index    – Cost of existing (inflation, subsidy cuts)
  3. capital_access_pressure      – Debt/borrowing stress (OPR)
  4. systemic_friction            – Time poverty and administrative red tape
  5. social_equity_weight         – Perception of fairness (Gini impact)
  6. systemic_trust_baseline      – Strength of the social contract
  7. future_mobility_index        – Upskilling / class mobility opportunities
  8. ecological_pressure          – Sustainability and resource metrics
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger("policyiq.ai_engine.physics")


@dataclass
class KnobState:
    """Snapshot of all 8 Universal Knobs at a given tick."""
    disposable_income_delta: float = 0.0
    operational_expense_index: float = 0.0
    capital_access_pressure: float = 0.0
    systemic_friction: float = 0.0
    social_equity_weight: float = 0.0
    systemic_trust_baseline: float = 0.0
    future_mobility_index: float = 0.0
    ecological_pressure: float = 0.0

    def clamp(self) -> "KnobState":
        """Ensure all values stay within [-1.0, 1.0]."""
        for knob in self.__dataclass_fields__:  # type: ignore[attr-defined]
            val = getattr(self, knob)
            setattr(self, knob, max(-1.0, min(1.0, val)))
        return self

    def to_dict(self) -> dict[str, float]:
        return {k: getattr(self, k) for k in self.__dataclass_fields__}  # type: ignore[attr-defined]


class GlobalStateEngine:
    """
    Manages time progression (Ticks) and the mathematical state of the
    8 Universal Knobs.

    Usage::

        engine = GlobalStateEngine()
        engine.initialize_from_decomposition(policy_decomposition)
        for tick in range(simulation_ticks):
            state = engine.advance_tick()
            # ... run agents against state ...
    """

    def __init__(self) -> None:
        self.current_tick: int = 0
        self.knob_state: KnobState = KnobState()
        self._sub_layers: list[dict] = []
        self._history: list[KnobState] = []

    # ─── Initialisation ──────────────────────────────────────────────────────

    def initialize_from_decomposition(self, decomposition: dict) -> None:
        """
        Seed the engine from the PolicyDecomposition produced by the
        Orchestrator (Contract B).

        Args:
            decomposition: dict with keys ``global_state`` and
                           ``dynamic_sub_layers``.
        """
        gs = decomposition.get("global_state", {})
        self.knob_state = KnobState(**gs).clamp()
        self._sub_layers = decomposition.get("dynamic_sub_layers", [])
        logger.info("GlobalStateEngine initialised │ knobs=%s", self.knob_state.to_dict())

    def apply_overrides(self, overrides: dict) -> None:
        """
        Apply manual Knob overrides from the frontend (Contract A).
        Only non-null override values are applied.
        """
        for knob, value in overrides.items():
            if value is not None and hasattr(self.knob_state, knob):
                setattr(self.knob_state, knob, value)
        self.knob_state.clamp()
        logger.info("Knob overrides applied │ knobs=%s", self.knob_state.to_dict())

    # ─── Tick Progression ────────────────────────────────────────────────────

    def advance_tick(self) -> KnobState:
        """
        Advance the simulation by one tick.

        Applies natural decay/momentum to each knob so that the global state
        evolves organically over time (placeholder logic — Team AI should
        replace with physics equations).

        Returns:
            The updated KnobState for this tick.
        """
        self.current_tick += 1
        self._history.append(self.knob_state)

        # ── Placeholder momentum decay ─────────────────────────────────────
        # Each knob drifts 10 % toward equilibrium (0.0) per tick.
        # Team AI: replace with policy-specific physics equations.
        decay_factor = 0.10
        for knob in self.knob_state.__dataclass_fields__:  # type: ignore[attr-defined]
            current_val = getattr(self.knob_state, knob)
            setattr(self.knob_state, knob, current_val * (1.0 - decay_factor))

        self.knob_state.clamp()
        logger.debug("Tick %d │ knobs=%s", self.current_tick, self.knob_state.to_dict())
        return self.knob_state

    # ─── Agent-Level Calculations ────────────────────────────────────────────

    def calculate_effective_impact(
        self,
        agent_sensitivity: dict[str, float],
        agent_demographic: str,
    ) -> dict[str, float]:
        """
        Calculate the effective knob impact for a specific agent, factoring in
        their sensitivity matrix and any applicable sub-layer multipliers.

        Args:
            agent_sensitivity: {knob_name: weight} from Agent DNA.
            agent_demographic: e.g. "B40", "Rural", "Urban".

        Returns:
            {knob_name: effective_value} dict.
        """
        effective: dict[str, float] = {}
        knob_dict = self.knob_state.to_dict()

        for knob, base_value in knob_dict.items():
            sensitivity = agent_sensitivity.get(knob, 0.5)
            multiplier = self._get_sub_layer_multiplier(knob, agent_demographic)
            effective[knob] = max(-1.0, min(1.0, base_value * sensitivity * multiplier))

        return effective

    def _get_sub_layer_multiplier(self, knob: str, demographic: str) -> float:
        """
        Find the most specific impact multiplier from dynamic sub-layers
        for a given knob and demographic.
        """
        relevant = [
            sl for sl in self._sub_layers
            if sl.get("parent_knob") == knob
            and demographic in sl.get("target_demographic", [])
        ]
        if not relevant:
            return 1.0
        # Use the sub-layer with the highest absolute impact
        best = max(relevant, key=lambda sl: abs(sl.get("impact_multiplier", 0.0)))
        return best.get("impact_multiplier", 1.0)

    # ─── Diagnostics ─────────────────────────────────────────────────────────

    @property
    def history(self) -> list[dict[str, float]]:
        """Ordered list of knob snapshots, one per completed tick."""
        return [ks.to_dict() for ks in self._history]

    def reset(self) -> None:
        """Reset the engine to its initial zero state."""
        self.current_tick = 0
        self.knob_state = KnobState()
        self._sub_layers = []
        self._history = []
        logger.info("GlobalStateEngine reset.")
