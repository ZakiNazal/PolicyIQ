"""
schemas.py — Pydantic models for all API Contracts (Pre-A through E).
Mirrors the JSON schemas defined in CLAUDE.md exactly.
"""

from __future__ import annotations

from typing import Optional
from pydantic import BaseModel, Field


# ─────────────────────────────────────────────────────────────────────────────
# Contract Pre-A  │  Frontend ➡ Backend  │  POST /validate-policy
# ─────────────────────────────────────────────────────────────────────────────

class ValidatePolicyRequest(BaseModel):
    """Contract Pre-A: Raw policy text submitted for Gatekeeper validation."""
    raw_policy_text: str = Field(
        ...,
        min_length=10,
        description="The raw, unstructured policy text entered by the user.",
        example="Make petrol cheaper for poor people.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Contract Pre-B  │  Backend ➡ Frontend  │  Validation Result
# ─────────────────────────────────────────────────────────────────────────────

class ValidatePolicyResponse(BaseModel):
    """Contract Pre-B: Gatekeeper verdict — valid or rejected with refinements."""
    is_valid: bool = Field(..., description="True if the policy passes Gatekeeper checks.")
    rejection_reason: Optional[str] = Field(
        None,
        description="Human-readable explanation of why the policy was rejected.",
        example="The policy lacks specific pricing mechanisms and defines 'poor people' too vaguely.",
    )
    refined_options: list[str] = Field(
        default_factory=list,
        description="Up to 3 specific, mathematically viable alternative policy wordings.",
        example=[
            "Implement a targeted RM100 monthly cash transfer to the B40 demographic via PADU.",
            "Introduce a tiered quota system where B40 citizens receive 50 liters of subsidized RON95 per month.",
        ],
    )


# ─────────────────────────────────────────────────────────────────────────────
# Contract A  │  Frontend ➡ Backend  │  POST /simulate
# ─────────────────────────────────────────────────────────────────────────────

class KnobOverrides(BaseModel):
    """Partial manual overrides for the 8 Universal Knobs. Null = AI-determined."""
    disposable_income_delta: Optional[float] = Field(None, ge=-1.0, le=1.0)
    operational_expense_index: Optional[float] = Field(None, ge=-1.0, le=1.0)
    capital_access_pressure: Optional[float] = Field(None, ge=-1.0, le=1.0)
    systemic_friction: Optional[float] = Field(None, ge=-1.0, le=1.0)
    social_equity_weight: Optional[float] = Field(None, ge=-1.0, le=1.0)
    systemic_trust_baseline: Optional[float] = Field(None, ge=-1.0, le=1.0)
    future_mobility_index: Optional[float] = Field(None, ge=-1.0, le=1.0)
    ecological_pressure: Optional[float] = Field(None, ge=-1.0, le=1.0)


class SimulateRequest(BaseModel):
    """Contract A: Full simulation request from the Frontend."""
    policy_text: str = Field(
        ...,
        min_length=10,
        description="The validated policy text to simulate.",
        example="Implement a targeted RM100 monthly cash transfer to the B40 demographic.",
    )
    simulation_ticks: int = Field(
        4, ge=1, le=12,
        description="Number of time steps to simulate (keep at 4 for dev).",
    )
    agent_count: int = Field(
        5, ge=1, le=50,
        description="Number of Digital Malaysian agents to instantiate (5 for dev, 50 for pitch).",
    )
    knob_overrides: KnobOverrides = Field(
        default_factory=KnobOverrides,
        description="Optional manual Knob overrides; unset fields are AI-determined.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Contract B  │  AI Engine Internal State  │  8 Knobs + Sub-Layers
# ─────────────────────────────────────────────────────────────────────────────

class GlobalState(BaseModel):
    """The 8 Universal Knobs. All values clamped to [-1.0, 1.0]."""
    disposable_income_delta: float = Field(..., ge=-1.0, le=1.0)
    operational_expense_index: float = Field(..., ge=-1.0, le=1.0)
    capital_access_pressure: float = Field(..., ge=-1.0, le=1.0)
    systemic_friction: float = Field(..., ge=-1.0, le=1.0)
    social_equity_weight: float = Field(..., ge=-1.0, le=1.0)
    systemic_trust_baseline: float = Field(..., ge=-1.0, le=1.0)
    future_mobility_index: float = Field(..., ge=-1.0, le=1.0)
    ecological_pressure: float = Field(..., ge=-1.0, le=1.0)


class DynamicSubLayer(BaseModel):
    """A single concrete sub-layer produced by Dynamic Decomposition (3–5 required)."""
    parent_knob: str = Field(..., description="Which of the 8 Knobs this sub-layer modifies.")
    sub_layer_name: str = Field(..., description="Human-readable name for the sub-layer.")
    target_demographic: list[str] = Field(
        ...,
        description="Demographic groups this sub-layer targets (e.g. ['B40', 'Rural']).",
    )
    impact_multiplier: float = Field(
        ..., ge=-1.0, le=1.0,
        description="Scales the parent knob's effect on the targeted demographic.",
    )
    description: str = Field(..., description="Plain-English explanation of this sub-layer.")


class PolicyDecomposition(BaseModel):
    """Contract B: Full AI Engine internal state after Dynamic Decomposition."""
    policy_summary: str
    global_state: GlobalState
    dynamic_sub_layers: list[DynamicSubLayer] = Field(
        ...,
        min_length=3,
        max_length=5,
        description="Exactly 3–5 sub-layers as enforced by SYSTEM_SPEC §4.",
    )


# ─────────────────────────────────────────────────────────────────────────────
# Contract C  │  AI Engine ➡ LLM  │  Agent Prompt Injection
# ─────────────────────────────────────────────────────────────────────────────

class SensitivityMatrix(BaseModel):
    """Per-agent weights (0–1) for each knob, derived from Agent DNA."""
    disposable_income_delta: Optional[float] = Field(None, ge=0.0, le=1.0)
    operational_expense_index: Optional[float] = Field(None, ge=0.0, le=1.0)
    capital_access_pressure: Optional[float] = Field(None, ge=0.0, le=1.0)
    systemic_friction: Optional[float] = Field(None, ge=0.0, le=1.0)
    social_equity_weight: Optional[float] = Field(None, ge=0.0, le=1.0)
    systemic_trust_baseline: Optional[float] = Field(None, ge=0.0, le=1.0)
    future_mobility_index: Optional[float] = Field(None, ge=0.0, le=1.0)
    ecological_pressure: Optional[float] = Field(None, ge=0.0, le=1.0)


class AgentProfile(BaseModel):
    """Static Agent DNA profile for a single Digital Malaysian."""
    agent_id: str = Field(..., example="AGT-012")
    demographic: str = Field(..., example="B40")
    occupation: str = Field(..., example="Gig Worker")
    location: str = Field(..., example="Urban KL")
    sensitivity_matrix: SensitivityMatrix


class AgentPromptPayload(BaseModel):
    """Contract C: Full prompt context injected into the LLM per tick per agent."""
    tick_number: int
    agent_profile: AgentProfile
    rag_context: str = Field(..., description="Factual DOSM/OpenDOSM data retrieved via RAG.")
    world_update: str = Field(..., description="Narrative description of the tick's world events.")


# ─────────────────────────────────────────────────────────────────────────────
# Contract D  │  LLM ➡ AI Engine  │  The Agent Decision
# ─────────────────────────────────────────────────────────────────────────────

class AgentDecision(BaseModel):
    """Contract D: Strict JSON output guaranteed from Gemini for each agent per tick."""
    agent_id: str
    action: str = Field(..., description="Verb phrase describing the agent's chosen action.")
    sentiment_score: float = Field(..., ge=-1.0, le=1.0)
    financial_health_change: float = Field(..., description="Change in RM (positive = gain).")
    internal_monologue: str = Field(..., description="First-person reasoning from the agent's POV.")
    is_breaking_point: bool = Field(..., description="True if financial_health < 0 or sentiment == -1.0.")
    exploiting_loophole: bool = Field(..., description="True if the agent is gaming a policy gap.")


# ─────────────────────────────────────────────────────────────────────────────
# Contract E  │  Backend ➡ Frontend  │  Final Dashboard Payload
# ─────────────────────────────────────────────────────────────────────────────

class SimulationMetadata(BaseModel):
    policy: str
    total_ticks: int


class MacroSummary(BaseModel):
    overall_sentiment_shift: float
    inequality_delta: float


class TickAgentAction(BaseModel):
    """Condensed agent output included in the timeline tick summary."""
    agent_id: str
    action: str
    sentiment_score: float
    financial_health_change: float
    internal_monologue: str
    is_breaking_point: bool


class TickSummary(BaseModel):
    tick_id: int
    average_sentiment: float
    agent_actions: list[TickAgentAction]


class Anomaly(BaseModel):
    type: str = Field(..., example="friction_warning")
    agent_id: str
    demographic: str
    reason: str


class SimulateResponse(BaseModel):
    """Contract E: Full dashboard payload streamed back to the Frontend."""
    simulation_metadata: SimulationMetadata
    macro_summary: MacroSummary
    timeline: list[TickSummary]
    anomalies: list[Anomaly]
    ai_policy_recommendation: str
