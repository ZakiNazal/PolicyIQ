"""
main.py — PolicyIQ FastAPI Application Entrypoint.

Endpoints:
  POST /validate-policy  → Gatekeeper validation (Contract Pre-A → Pre-B)
  POST /simulate         → Full simulation as an SSE stream (Contract A → E)
  GET  /health           → Docker/GCP healthcheck probe
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import AsyncGenerator

from dotenv import load_dotenv

# Load .env from the project root (one level up from backend/)
_env_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(_env_path)


from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sse_starlette.sse import EventSourceResponse

from schemas import (
    ValidatePolicyRequest,
    ValidatePolicyResponse,
    SimulateRequest,
    SimulateResponse,
)
from ai_engine.orchestrator import Orchestrator

# ─── Logging ─────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO, format="%(levelname)s │ %(name)s │ %(message)s")
logger = logging.getLogger("policyiq.main")

# ─── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="PolicyIQ API",
    description=(
        "Multi-agent AI simulation engine for stress-testing Malaysian government policies. "
        "Translates raw policy text into an 8-Knob state matrix and simulates 50 Digital "
        "Malaysians across configurable time steps."
    ),
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ─── CORS ─────────────────────────────────────────────────────────────────────
# Allow the Flutter web app (and local dev tooling) to call the API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten for production; fine for hackathon
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Shared orchestrator instance ────────────────────────────────────────────
orchestrator = Orchestrator()


# ─── Health ──────────────────────────────────────────────────────────────────
@app.get("/health", tags=["ops"], summary="Liveness probe")
async def health() -> dict:
    """Simple liveness probe used by Docker healthcheck and Cloud Run."""
    return {"status": "ok", "service": "policyiq-backend"}


# ─── Contract Pre-A → Pre-B ──────────────────────────────────────────────────
@app.post(
    "/validate-policy",
    response_model=ValidatePolicyResponse,
    tags=["gatekeeper"],
    summary="Validate raw policy text before simulation",
)
async def validate_policy(request: ValidatePolicyRequest) -> ValidatePolicyResponse:
    """
    **The Gatekeeper.**

    Runs a fast Gemini 1.5 Flash check on the submitted policy text.
    Returns a validation verdict (Contract Pre-B).

    - If `is_valid` is `false`, the response includes a `rejection_reason` and
      up to 3 specific `refined_options` the user can adopt instead.
    - If `is_valid` is `true`, the frontend should proceed to `POST /simulate`.
    """
    logger.info("Gatekeeper received policy: %.80s…", request.raw_policy_text)
    try:
        result: ValidatePolicyResponse = await orchestrator.validate_policy(request)
        return result
    except Exception as exc:
        logger.exception("Gatekeeper error")
        raise HTTPException(status_code=500, detail=str(exc)) from exc


# ─── Contract A → E (SSE) ────────────────────────────────────────────────────
@app.post(
    "/simulate",
    tags=["simulation"],
    summary="Run the full multi-agent policy simulation (SSE stream)",
)
async def simulate(request: SimulateRequest) -> EventSourceResponse:
    """
    **The Simulation Engine.**

    Accepts a validated policy and optional Knob overrides (Contract A).
    Returns a Server-Sent Events stream where each event is either:

    - **`tick`** — JSON payload for a completed simulation tick (partial Contract E).
    - **`complete`** — Final `SimulateResponse` payload (full Contract E).
    - **`error`** — Error details if the simulation fails mid-run.

    Flutter client should listen with an SSE-capable HTTP client.
    """
    logger.info(
        "Simulation request │ ticks=%d agents=%d",
        request.simulation_ticks,
        request.agent_count,
    )

    async def event_generator() -> AsyncGenerator[dict, None]:
        try:
            async for tick_payload in orchestrator.run_simulation(request):
                yield {
                    "event": "tick",
                    "data": json.dumps(tick_payload),
                }
            # Final aggregated result
            final: SimulateResponse = await orchestrator.get_final_result()
            yield {
                "event": "complete",
                "data": final.model_dump_json(),
            }
        except Exception as exc:
            logger.exception("Simulation error during SSE stream")
            yield {
                "event": "error",
                "data": json.dumps({"detail": str(exc)}),
            }

    return EventSourceResponse(event_generator())
