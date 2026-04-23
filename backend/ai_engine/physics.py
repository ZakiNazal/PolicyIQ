"""
physics.py — GlobalStateEngine

Manages the 8 Universal Knobs and the mathematical state of the simulated
Malaysian economy across simulation ticks.

The 8 Knobs (all values clamped to [0.0, 1.0]):
  1. disposable_income_delta      – Direct cash flow changes
  2. operational_expense_index    – Cost of existing (inflation, subsidy cuts)
  3. capital_access_pressure      – Debt/borrowing stress (OPR)
  4. systemic_friction            – Time poverty and administrative red tape
  5. social_equity_weight         – Perception of fairness (Gini impact)
  6. systemic_trust_baseline      – Strength of the social contract
  7. future_mobility_index        – Upskilling / class mobility opportunities
  8. ecological_pressure          – Sustainability and resource metrics

Physics Engine — Step 4:
  • Delta Application  : decomposition global_state values drive each tick change.
  • Systemic Friction  : avg digital_readiness of agents dampens policy impact.
  • Sensitivity Matrix : cross-knob ripple (e.g. rising costs erode trust).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from typing import Optional

logger = logging.getLogger("policyiq.ai_engine.physics")

# ─── Sensitivity / Ripple-Effect Matrix ──────────────────────────────────────
# Maps knob_name → list of (target_knob, coefficient) pairs.
# When a knob changes by Δ, each downstream knob is nudged by coefficient * Δ.
# Keep coefficients small (0.05–0.20) so the ripple is subtle.
_RIPPLE_MATRIX: dict[str, list[tuple[str, float]]] = {
    # Higher taxes (op expense) → friction rises, trust erodes
    "operational_expense_index": [
        ("systemic_friction",        0.12),
        ("systemic_trust_baseline", -0.08),
        ("social_equity_weight",    -0.06),
    ],
    # Rising capital pressure → disposable income squeezed, trust falls
    "capital_access_pressure": [
        ("disposable_income_delta", -0.10),
        ("systemic_trust_baseline", -0.06),
        ("future_mobility_index",   -0.05),
    ],
    # Better disposable income → boosts trust and mobility
    "disposable_income_delta": [
        ("systemic_trust_baseline",  0.07),
        ("future_mobility_index",    0.05),
        ("social_equity_weight",     0.04),
    ],
    # Rising systemic friction → erodes equity perception
    "systemic_friction": [
        ("social_equity_weight",    -0.08),
        ("future_mobility_index",   -0.06),
    ],
    # Ecological pressure → raises op expense and friction
    "ecological_pressure": [
        ("operational_expense_index", 0.06),
        ("systemic_friction",         0.04),
    ],
}


@dataclass
class KnobState:
    """Snapshot of all 8 Universal Knobs at a given tick.

    Values are clamped to [0.0, 1.0] per the Step 4 spec.
    """
    disposable_income_delta: float = 0.0
    operational_expense_index: float = 0.0
    capital_access_pressure: float = 0.0
    systemic_friction: float = 0.0
    social_equity_weight: float = 0.0
    systemic_trust_baseline: float = 0.0
    future_mobility_index: float = 0.0
    ecological_pressure: float = 0.0

    def clamp(self) -> "KnobState":
        """Ensure all values stay strictly within [0.0, 1.0]."""
        for knob in self.__dataclass_fields__:  # type: ignore[attr-defined]
            val = getattr(self, knob)
            setattr(self, knob, max(0.0, min(1.0, val)))
        return self

    def to_dict(self) -> dict[str, float]:
        return {k: getattr(self, k) for k in self.__dataclass_fields__}  # type: ignore[attr-defined]


class GlobalStateEngine:
    """
    Manages time progression (Ticks) and the mathematical state of the
    8 Universal Knobs.

    Step 4 physics loop per tick
    ─────────────────────────────
    1. Compute *systemic_friction_factor* from agents' avg digital readiness:
       ``friction_factor = avg(digital_readiness_score)``
       (High readiness → factor near 1.0 → policy lands at full strength.)
       (Low  readiness → factor near 0.0 → policy is dampened.)

    2. Apply policy *deltas* from the decomposition, scaled by friction_factor:
       ``new_val = current_val + (delta * friction_factor)``

    3. Apply *Ripple Effect* from the sensitivity/cross-knob matrix:
       For each knob that changed, nudge its downstream neighbours.

    4. Clamp all knobs to [0.0, 1.0].

    Usage::

        engine = GlobalStateEngine()
        engine.initialize_from_decomposition(policy_decomposition)
        for tick in range(simulation_ticks):
            state = engine.advance_tick(decomposition=decomp, agents=agents)
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
        # global_state may arrive as a nested dict (from Pydantic .model_dump())
        if isinstance(gs, dict):
            # Filter only known knob keys; ignore extra fields
            knob_fields = set(KnobState.__dataclass_fields__)  # type: ignore[attr-defined]
            filtered = {k: v for k, v in gs.items() if k in knob_fields}
            self.knob_state = KnobState(**filtered).clamp()
        else:
            self.knob_state = KnobState().clamp()

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

    def advance_tick(
        self,
        decomposition: Optional[dict] = None,
        agents: Optional[list[dict]] = None,
    ) -> KnobState:
        """
        Advance the simulation by one tick using active state evolution.

        Args:
            decomposition: PolicyDecomposition dict (Contract B).  The
                ``global_state`` sub-dict supplies the *intended* delta for
                each knob this tick.  If None the engine falls back to a
                mild 5 % momentum decay toward the current midpoint.
            agents: List of agent dicts (each must carry a
                ``digital_readiness_score`` float in [0, 1]).  Used to
                compute the ``systemic_friction_factor`` that dampens or
                amplifies the policy delta.  If None, friction factor
                defaults to 1.0 (full policy impact).

        Returns:
            The updated KnobState for this tick.
        """
        self.current_tick += 1
        # Snapshot current state *before* mutation (history = completed ticks)
        import copy
        self._history.append(copy.deepcopy(self.knob_state))

        # ── 1. Compute systemic friction factor ───────────────────────────────
        friction_factor = self._compute_friction_factor(agents)
        logger.debug(
            "Tick %d │ systemic_friction_factor=%.4f (agents=%d)",
            self.current_tick,
            friction_factor,
            len(agents) if agents else 0,
        )

        # ── 2. Apply decomposition deltas (scaled by friction) ────────────────
        raw_deltas: dict[str, float] = {}
        if decomposition is not None:
            gs = decomposition.get("global_state", {})
            # gs may be a nested Pydantic-like dict or a flat dict
            if hasattr(gs, "model_dump"):
                gs = gs.model_dump()
            knob_fields = set(KnobState.__dataclass_fields__)  # type: ignore[attr-defined]
            for knob in knob_fields:
                intended_delta = float(gs.get(knob, 0.0))
                # Scale the intended change by the friction factor:
                # Low digital readiness → small fraction of policy lands
                effective_delta = intended_delta * friction_factor
                raw_deltas[knob] = effective_delta
                current_val = getattr(self.knob_state, knob)
                setattr(self.knob_state, knob, current_val + effective_delta)
        else:
            # Fallback: gentle 5 % momentum drift toward 0.5 equilibrium
            equilibrium = 0.5
            drift_factor = 0.05
            for knob in self.knob_state.__dataclass_fields__:  # type: ignore[attr-defined]
                current_val = getattr(self.knob_state, knob)
                drift = (equilibrium - current_val) * drift_factor
                raw_deltas[knob] = drift
                setattr(self.knob_state, knob, current_val + drift)

        # ── 3. Apply ripple / sensitivity matrix ──────────────────────────────
        self._apply_ripple(raw_deltas)

        # ── 4. Clamp all knobs to [0.0, 1.0] ─────────────────────────────────
        self.knob_state.clamp()
        logger.debug("Tick %d │ knobs=%s", self.current_tick, self.knob_state.to_dict())
        return self.knob_state

    # ─── Physics Helpers ─────────────────────────────────────────────────────

    def _compute_friction_factor(self, agents: Optional[list[dict]]) -> float:
        """
        Derive systemic friction factor from agents' average digital readiness.

        Rule: friction_factor = avg(digital_readiness_score) across all agents.
            - readiness = 1.0 → factor = 1.0 → policy lands at 100 % strength
            - readiness = 0.3 → factor = 0.3 → only 30 % of intended delta lands
            - readiness = 0.0 → factor = 0.05 (floor) — never fully blocks policy

        The computed factor is also reflected back into the ``systemic_friction``
        knob so the frontend trajectory shows the real-world barrier.
        """
        if not agents:
            return 1.0

        readiness_scores = [
            float(a.get("digital_readiness_score", 0.5))
            for a in agents
        ]
        avg_readiness = sum(readiness_scores) / len(readiness_scores)

        # Friction factor has a minimum floor (policy never totally blocked)
        friction_factor = max(0.05, avg_readiness)

        # Reflect the population's friction into the systemic_friction knob:
        # systemic_friction = 1 − avg_readiness  (higher friction when less ready)
        systemic_friction_knob_value = 1.0 - avg_readiness
        current_sf = self.knob_state.systemic_friction
        # Blend 30 % toward the population-derived friction (smooth, not abrupt)
        blended = current_sf + 0.30 * (systemic_friction_knob_value - current_sf)
        self.knob_state.systemic_friction = max(0.0, min(1.0, blended))

        logger.debug(
            "Friction │ avg_readiness=%.3f → factor=%.3f │ systemic_friction_knob=%.3f",
            avg_readiness,
            friction_factor,
            self.knob_state.systemic_friction,
        )
        return friction_factor

    def _apply_ripple(self, deltas: dict[str, float]) -> None:
        """
        Apply cross-knob ripple effects defined in _RIPPLE_MATRIX.

        For each knob that had a non-trivial delta, nudge its downstream
        neighbours proportionally. The ripple is additive and applied *once*
        after the primary delta pass to avoid compound feedback within a tick.
        """
        ripple_accumulator: dict[str, float] = {}

        for source_knob, delta in deltas.items():
            if abs(delta) < 1e-6:
                continue  # skip negligible deltas to avoid noise
            for target_knob, coefficient in _RIPPLE_MATRIX.get(source_knob, []):
                nudge = coefficient * delta
                ripple_accumulator[target_knob] = (
                    ripple_accumulator.get(target_knob, 0.0) + nudge
                )

        for target_knob, total_nudge in ripple_accumulator.items():
            if hasattr(self.knob_state, target_knob):
                current_val = getattr(self.knob_state, target_knob)
                setattr(self.knob_state, target_knob, current_val + total_nudge)
                logger.debug(
                    "Ripple │ %s nudged by %.4f → %.4f",
                    target_knob,
                    total_nudge,
                    getattr(self.knob_state, target_knob),
                )

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
            effective[knob] = max(0.0, min(1.0, base_value * sensitivity * multiplier))

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
