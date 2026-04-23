"""
orchestrator.py — PolicyIQ Simulation Orchestrator

Coordinates the full simulation pipeline:
  1. Policy Gatekeeper validation (fast Gemini 1.5 Flash check)
  2. Dynamic Decomposition → PolicyDecomposition (Contract B)
  3. Tick loop: Observation Generation → Parallel Agent Execution → Aggregation
  4. Anomaly detection and final AI policy recommendation

This module is the bridge between the FastAPI layer and the AI engine
sub-modules (physics.py, rag_client.py, and the Genkit workflow).

Team AI owns the implementation of the methods marked with TODO below.
Team Backend owns the cloud deployment and environment configuration.
"""

from __future__ import annotations

import json
import logging
import os
from pathlib import Path
from typing import AsyncGenerator, Optional

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig

from ai_engine.physics import GlobalStateEngine
from ai_engine.rag_client import RAGClient

logger = logging.getLogger("policyiq.ai_engine.orchestrator")

# ─── Path helpers ─────────────────────────────────────────────────────────────
_ENGINE_DIR = Path(__file__).parent
PROMPTS_DIR = _ENGINE_DIR / "prompts"
AGENT_DNA_FILE = _ENGINE_DIR / "agent_dna" / "agents_master.json"


class Orchestrator:
    """
    Central coordinator for the PolicyIQ simulation.

    Lifecycle (per request)::

        orchestrator = Orchestrator()                          # main.py init
        result = await orchestrator.validate_policy(req)      # Gatekeeper
        async for tick in orchestrator.run_simulation(req):   # SSE ticks
            yield tick
        final = await orchestrator.get_final_result()         # Contract E

    State is reset between simulate() calls via _reset().
    """

    def __init__(self) -> None:
        self._physics = GlobalStateEngine()
        self._rag = RAGClient()
        self._decomposition: Optional[dict] = None
        self._tick_results: list[dict] = []
        self._agents: list[dict] = []
        self._gemini_model: str = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

        # ── Vertex AI SDK initialisation ──────────────────────────────────────
        _project  = os.getenv("GOOGLE_CLOUD_PROJECT", "")
        _location = os.getenv("VERTEX_AI_LOCATION", "asia-southeast1")
        if _project:
            vertexai.init(project=_project, location=_location)
            logger.info(
                "Vertex AI initialised │ project=%s │ location=%s", _project, _location
            )
        else:
            logger.warning(
                "GOOGLE_CLOUD_PROJECT is not set — Vertex AI calls will fail at runtime."
            )

    # ─── Prompt Loaders ───────────────────────────────────────────────────────

    def _load_prompt(self, name: str) -> str:
        """Load a prompt template from the prompts/ directory."""
        path = PROMPTS_DIR / name
        if path.exists() and path.stat().st_size > 0:
            return path.read_text(encoding="utf-8")
        logger.warning("Prompt template '%s' is empty or missing — using placeholder.", name)
        return f"[PLACEHOLDER: {name} — Team AI must populate this prompt template]"

    def _load_agents(self) -> list[dict]:
        """Load Agent DNA profiles from agents_master.json."""
        if AGENT_DNA_FILE.exists() and AGENT_DNA_FILE.stat().st_size > 5:
            with AGENT_DNA_FILE.open("r", encoding="utf-8") as f:
                return json.load(f)
        logger.warning("agents_master.json is empty — using synthetic placeholder agents.")
        return self._synthetic_agents(count=5)

    @staticmethod
    def _synthetic_agents(count: int) -> list[dict]:
        """
        Generate realistic synthetic Economic Entity agents for local dev/testing.

        Each agent is seeded with tier-appropriate economic metadata so the LLM
        can make financially grounded decisions.  Ranges are calibrated against
        2023 DOSM household income data:

        Tier     | monthly_income_rm | liquid_savings_rm | digital_readiness_score
        ---------+-------------------+-------------------+------------------------
        B40      | 2,000 – 4,850     | 200  – 2,000      | 0.15 – 0.50
        M40      | 4,850 – 10,959    | 2,000 – 15,000    | 0.45 – 0.78
        T20      | 10,960 +          | 15,000 – 80,000   | 0.72 – 0.98

        Team AI: replace with real 50-agent DNA from agents_master.json.
        """
        import random  # noqa: PLC0415

        tiers = ["B40", "M40", "T20"]
        occupations = ["Gig Worker", "Salaried Corporate", "SME Owner", "Civil Servant", "Unemployed"]
        locations = ["Urban KL", "Suburban Selangor", "Rural Sabah"]

        # ── Per-tier economic parameter ranges ─────────────────────────────────
        tier_config: dict[str, dict] = {
            "B40": {
                "income_range":        (2000.0,  4849.0),
                "savings_range":       (200.0,   2000.0),
                "dti_range":           (0.35,    0.65),   # high debt burden
                "dependents_range":    (2, 5),
                "readiness_range":     (0.15,    0.50),   # limited digital access
                "subsidy_flags": {
                    "brim": True,
                    "petrol_quota": True,
                    "padu_registered": False,   # friction barrier
                    "oku_allowance": False,
                },
            },
            "M40": {
                "income_range":        (4850.0,  10959.0),
                "savings_range":       (2000.0,  15000.0),
                "dti_range":           (0.20,    0.45),
                "dependents_range":    (1, 3),
                "readiness_range":     (0.45,    0.78),
                "subsidy_flags": {
                    "brim": False,
                    "petrol_quota": False,
                    "padu_registered": True,
                    "oku_allowance": False,
                },
            },
            "T20": {
                "income_range":        (10960.0, 30000.0),
                "savings_range":       (15000.0, 80000.0),
                "dti_range":           (0.05,    0.25),   # low relative debt
                "dependents_range":    (0, 2),
                "readiness_range":     (0.72,    0.98),   # high digital fluency
                "subsidy_flags": {
                    "brim": False,
                    "petrol_quota": False,
                    "padu_registered": True,
                    "oku_allowance": False,
                },
            },
        }

        agents = []
        for i in range(count):
            tier = tiers[i % len(tiers)]
            cfg  = tier_config[tier]

            income   = round(random.uniform(*cfg["income_range"]), 2)
            savings  = round(random.uniform(*cfg["savings_range"]), 2)
            dti      = round(random.uniform(*cfg["dti_range"]), 4)
            deps     = random.randint(*cfg["dependents_range"])
            readiness = round(random.uniform(*cfg["readiness_range"]), 4)

            # Disposable buffer = income after debt service and a rough 40 % fixed-cost estimate
            fixed_costs = round(income * 0.40, 2)
            debt_payments = round(income * dti, 2)
            disposable_buffer = round(income - fixed_costs - debt_payments, 2)

            agents.append({
                "agent_id":   f"AGT-{i+1:03d}",
                "demographic": tier,
                "occupation":  occupations[i % len(occupations)],
                "location":    locations[i % len(locations)],
                "financial_health": savings,  # seed financial_health from liquid savings

                # ── Economic Entity Fields ──────────────────────────────────
                "monthly_income_rm":     income,
                "disposable_buffer_rm":  disposable_buffer,
                "liquid_savings_rm":     savings,
                "debt_to_income_ratio":  dti,
                "dependents_count":      deps,
                "digital_readiness_score": readiness,
                "subsidy_flags":         dict(cfg["subsidy_flags"]),  # copy, not reference

                # ── Sensitivity Matrix ──────────────────────────────────────
                "sensitivity_matrix": {
                    # B40 agents feel disposable income changes most acutely
                    "disposable_income_delta": round(
                        0.9 if tier == "B40" else (0.6 if tier == "M40" else 0.3), 1
                    ),
                    "operational_expense_index": round(
                        0.8 if tier == "B40" else (0.5 if tier == "M40" else 0.3), 1
                    ),
                    "capital_access_pressure": round(
                        0.7 if tier == "B40" else (0.5 if tier == "M40" else 0.2), 1
                    ),
                    # High systemic_friction hits low-readiness agents hardest
                    "systemic_friction": round(
                        max(0.1, 1.0 - readiness), 2
                    ),
                    "social_equity_weight": round(
                        0.8 if tier == "B40" else (0.5 if tier == "M40" else 0.2), 1
                    ),
                    "systemic_trust_baseline": round(
                        0.4 if tier == "B40" else (0.6 if tier == "M40" else 0.8), 1
                    ),
                    "future_mobility_index": round(
                        0.3 if tier == "B40" else (0.5 if tier == "M40" else 0.9), 1
                    ),
                    "ecological_pressure": 0.2,
                },
            })
        return agents

    # ─── Gatekeeper ───────────────────────────────────────────────────────────

    async def validate_policy(self, request) -> object:
        """
        Contract Pre-A → Pre-B  —  The AI Gatekeeper.

        Sends the raw policy text to Gemini 1.5 Flash using the
        gatekeeper.txt prompt template and parses the strict JSON response
        into a ValidatePolicyResponse.

        Robustness:
          - Falls back to a safe "Invalid" response if the Gemini call fails
            or the model returns malformed JSON.
        """
        # ── Import here to avoid circular deps at module load ─────────────────
        from schemas import ValidatePolicyResponse  # noqa: PLC0415

        text = request.raw_policy_text.strip()
        gatekeeper_prompt = self._load_prompt("gatekeeper.txt")
        logger.info("Gatekeeper prompt loaded (%d chars). Calling Gemini…", len(gatekeeper_prompt))

        # ── Build the final prompt by injecting the policy text ───────────────
        final_prompt = gatekeeper_prompt.replace("{{policy_text}}", text)

        try:
            # ── Gemini 1.5 Flash call ─────────────────────────────────────────
            model = GenerativeModel(self._gemini_model)
            response = model.generate_content(
                final_prompt,
                generation_config=GenerationConfig(
                    response_mime_type="application/json",
                    temperature=0.1,   # near-deterministic for a validation gate
                    max_output_tokens=512,
                ),
            )

            raw_text = response.text.strip()
            logger.info("Gatekeeper raw response: %s", raw_text[:300])

            # ── Parse and validate the JSON against our Pydantic schema ───────
            payload = json.loads(raw_text)

            # Normalise: ensure refined_options is always a list
            if not isinstance(payload.get("refined_options"), list):
                payload["refined_options"] = []

            # Enforce exactly 3 refined_options when is_valid is False
            if not payload.get("is_valid", True) and len(payload["refined_options"]) != 3:
                logger.warning(
                    "Gatekeeper returned %d refined_options (expected 3); "
                    "truncating/padding to 3.",
                    len(payload["refined_options"]),
                )
                # Pad if fewer than 3
                while len(payload["refined_options"]) < 3:
                    payload["refined_options"].append(
                        "Please resubmit the policy with a specific RM amount and target demographic."
                    )
                # Truncate if more than 3
                payload["refined_options"] = payload["refined_options"][:3]

            return ValidatePolicyResponse(**payload)

        except Exception as exc:  # noqa: BLE001
            logger.exception("Gatekeeper Gemini call failed: %s", exc)
            # ── Safe fallback — never crash the endpoint ───────────────────────
            return ValidatePolicyResponse(
                is_valid=False,
                rejection_reason=(
                    "The policy validation service is temporarily unavailable. "
                    "Please try again in a moment."
                ),
                refined_options=[
                    "Please try submitting your policy again.",
                    "Ensure your policy contains a specific RM amount or percentage.",
                    "Make sure your policy targets a specific demographic (e.g. B40, M40, Rural).",
                ],
            )

    # ─── Dynamic Decomposition ────────────────────────────────────────────────

    async def _decompose_policy(self, policy_text: str) -> dict:
        """
        Contract B: Translate policy text into GlobalState + 3–5 sub-layers.

        TODO (Team AI): Replace the stub below with a real Gemini call using
        the decomposition.txt prompt template.  The response MUST be validated
        against the PolicyDecomposition schema (schemas.py).
        """
        decomposition_prompt = self._load_prompt("decomposition.txt")
        logger.info("Decomposition prompt loaded (%d chars). Calling Gemini…", len(decomposition_prompt))

        # ── STUB: Hardcoded decomposition for dev ─────────────────────────────
        return {
            "policy_summary": policy_text[:120],
            "global_state": {
                "disposable_income_delta": 0.3,
                "operational_expense_index": 0.0,
                "capital_access_pressure": 0.0,
                "systemic_friction": -0.2,
                "social_equity_weight": 0.5,
                "systemic_trust_baseline": 0.4,
                "future_mobility_index": 0.0,
                "ecological_pressure": 0.0,
            },
            "dynamic_sub_layers": [
                {
                    "parent_knob": "disposable_income_delta",
                    "sub_layer_name": "Direct Cash Injection",
                    "target_demographic": ["B40"],
                    "impact_multiplier": 0.80,
                    "description": "Immediate increase in monthly liquidity for essential goods.",
                },
                {
                    "parent_knob": "systemic_friction",
                    "sub_layer_name": "PADU Registration Burden",
                    "target_demographic": ["Rural", "Elderly"],
                    "impact_multiplier": -0.40,
                    "description": "Time spent navigating digital registration to claim funds.",
                },
                {
                    "parent_knob": "social_equity_weight",
                    "sub_layer_name": "Perceived Fairness Boost",
                    "target_demographic": ["B40", "M40"],
                    "impact_multiplier": 0.50,
                    "description": "Improved public trust in government redistribution.",
                },
            ],
        }

    # ─── Agent Observation Generation ────────────────────────────────────────

    async def _build_agent_prompt(
        self, agent: dict, tick: int, world_update: str
    ) -> dict:
        """
        Contract C: Build the prompt payload for a single agent.

        Retrieves RAG context then constructs the observation dict.
        """
        rag_context = await self._rag.retrieve(
            query=f"Economic conditions for {agent['demographic']} {agent['occupation']}",
            demographic=agent["demographic"],
            location=agent["location"],
        )
        return {
            "tick_number": tick,
            "agent_profile": agent,
            "rag_context": rag_context,
            "world_update": world_update,
        }

    # ─── Agent Decision (Gemini call) ─────────────────────────────────────────

    async def _execute_agent(self, prompt_payload: dict) -> dict:
        """
        Contract D: Fire the agent prompt at Gemini and parse the strict JSON
        response.

        TODO (Team AI): Replace the stub below with a real Firebase Genkit
        parallel execution using the observation.txt prompt template.
        """
        observation_prompt = self._load_prompt("observation.txt")
        agent = prompt_payload["agent_profile"]

        # ── STUB: Synthetic decision for dev ──────────────────────────────────
        import random  # noqa: PLC0415
        sentiment = round(random.uniform(-0.5, 0.8), 2)
        financial_change = round(random.uniform(-50.0, 150.0), 2)
        is_bp = agent.get("financial_health", 1000.0) + financial_change < 0 or sentiment <= -1.0

        return {
            "agent_id": agent["agent_id"],
            "action": "pay_essential_bills",
            "sentiment_score": sentiment,
            "financial_health_change": financial_change,
            "internal_monologue": (
                f"[STUB — Tick {prompt_payload['tick_number']}] "
                f"As a {agent['demographic']} {agent['occupation']} in {agent['location']}, "
                f"I am adjusting my spending based on the policy change."
            ),
            "is_breaking_point": is_bp,
            "exploiting_loophole": False,
        }

    # ─── Main Simulation Loop ─────────────────────────────────────────────────

    async def run_simulation(
        self, request
    ) -> AsyncGenerator[dict, None]:
        """
        The Tick Loop (SYSTEM_SPEC §7).

        For each tick:
          1. State Broadcast (GlobalStateEngine.advance_tick)
          2. Observation Generation (build prompts for each agent)
          3. Parallel Execution (fire agent prompts — stub for now)
          4. Aggregation (collect decisions, update financial health)

        Yields a dict per tick for the SSE stream.
        """
        self._reset()
        self._agents = self._load_agents()[: request.agent_count]

        # Decompose policy → seed physics engine
        self._decomposition = await self._decompose_policy(request.policy_text)
        self._physics.initialize_from_decomposition(self._decomposition)
        self._physics.apply_overrides(
            request.knob_overrides.model_dump(exclude_none=True)
        )

        for tick_num in range(1, request.simulation_ticks + 1):
            knob_state = self._physics.advance_tick()
            world_update = (
                f"Month {tick_num}: The global economy shifts — "
                f"disposable income delta is now {knob_state.disposable_income_delta:.2f}."
            )

            # Build prompts & execute agents (parallelisable — Team AI: use asyncio.gather)
            decisions: list[dict] = []
            for agent in self._agents:
                prompt_payload = await self._build_agent_prompt(agent, tick_num, world_update)
                decision = await self._execute_agent(prompt_payload)
                # Update running financial health on the agent record
                agent["financial_health"] = (
                    agent.get("financial_health", 1000.0) + decision["financial_health_change"]
                )
                decisions.append(decision)

            avg_sentiment = (
                sum(d["sentiment_score"] for d in decisions) / len(decisions)
                if decisions else 0.0
            )

            tick_payload = {
                "tick_id": tick_num,
                "average_sentiment": round(avg_sentiment, 4),
                "agent_actions": decisions,
                "knob_state": knob_state.to_dict(),
            }
            self._tick_results.append(tick_payload)
            yield tick_payload

    # ─── Final Result Assembly ────────────────────────────────────────────────

    async def get_final_result(self) -> object:
        """
        Assemble and return the full Contract E SimulateResponse after all
        ticks have completed.

        TODO (Team AI): Wire the real AI policy recommendation from Gemini.
        """
        from schemas import (  # noqa: PLC0415
            SimulateResponse, SimulationMetadata, MacroSummary,
            TickSummary, TickAgentAction, Anomaly,
        )

        all_sentiments = [
            d["sentiment_score"]
            for tick in self._tick_results
            for d in tick["agent_actions"]
        ]
        overall_shift = round(
            (sum(all_sentiments) / len(all_sentiments)) if all_sentiments else 0.0, 4
        )

        timeline = [
            TickSummary(
                tick_id=t["tick_id"],
                average_sentiment=t["average_sentiment"],
                agent_actions=[
                    TickAgentAction(**{k: v for k, v in a.items() if k != "exploiting_loophole"})
                    for a in t["agent_actions"]
                ],
            )
            for t in self._tick_results
        ]

        anomalies = [
            Anomaly(
                type="breaking_point",
                agent_id=d["agent_id"],
                demographic=next(
                    (a["demographic"] for a in self._agents if a["agent_id"] == d["agent_id"]),
                    "Unknown",
                ),
                reason="Agent's financial health dropped to a critical level.",
            )
            for tick in self._tick_results
            for d in tick["agent_actions"]
            if d.get("is_breaking_point")
        ]

        return SimulateResponse(
            simulation_metadata=SimulationMetadata(
                policy=self._decomposition.get("policy_summary", "") if self._decomposition else "",
                total_ticks=len(self._tick_results),
            ),
            macro_summary=MacroSummary(
                overall_sentiment_shift=overall_shift,
                inequality_delta=round(overall_shift * -0.3, 4),  # placeholder formula
            ),
            timeline=timeline,
            anomalies=anomalies,
            ai_policy_recommendation=(
                "[TODO — Team AI: Call Gemini post-simulation to generate a 1-paragraph "
                "policy mitigation recommendation based on the full timeline.]"
            ),
        )

    # ─── Internal ─────────────────────────────────────────────────────────────

    def _reset(self) -> None:
        """Reset all per-request state."""
        self._physics.reset()
        self._decomposition = None
        self._tick_results = []
        self._agents = []
