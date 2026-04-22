"""
rag_client.py — Vertex AI Search / Discovery Engine RAG Client

Provides factual, DOSM-grounded context to be injected into each agent's
prompt as ``rag_context`` (Contract C).

Dependencies:
  google-cloud-discoveryengine  (installed via requirements.txt)

Environment variables required:
  GOOGLE_CLOUD_PROJECT         – GCP project ID
  VERTEX_AI_LOCATION           – e.g. "us-central1"
  VERTEX_SEARCH_DATA_STORE_ID  – Vertex AI Search datastore containing
                                  cleaned OpenDOSM / Data.gov.my datasets
"""

from __future__ import annotations

import logging
import os
from typing import Optional

logger = logging.getLogger("policyiq.ai_engine.rag_client")


class RAGClient:
    """
    Thin wrapper around the Vertex AI Discovery Engine search API.

    Usage::

        client = RAGClient()
        context = await client.retrieve(
            query="Average B40 household income in Kuala Lumpur",
            demographic="B40",
            location="Urban KL",
        )
    """

    def __init__(self) -> None:
        self._project = os.getenv("GOOGLE_CLOUD_PROJECT", "")
        self._location = os.getenv("VERTEX_AI_LOCATION", "us-central1")
        self._data_store_id = os.getenv("VERTEX_SEARCH_DATA_STORE_ID", "")
        self._client = None  # Lazy initialisation to avoid cold-start overhead

    def _get_client(self):  # type: ignore[return]
        """Lazily initialise the Discovery Engine search client."""
        if self._client is None:
            try:
                from google.cloud import discoveryengine_v1 as discoveryengine  # noqa: PLC0415
                self._client = discoveryengine.SearchServiceClient()
                logger.info("DiscoveryEngine SearchServiceClient initialised.")
            except Exception as exc:
                logger.warning("Could not initialise DiscoveryEngine client: %s", exc)
        return self._client

    async def retrieve(
        self,
        query: str,
        demographic: Optional[str] = None,
        location: Optional[str] = None,
        max_results: int = 3,
    ) -> str:
        """
        Query Vertex AI Search for grounding context.

        Args:
            query:       Natural-language query (e.g. "Average B40 transport spend in Selangor").
            demographic: Optional demographic label to enrich the query.
            location:    Optional location label to enrich the query.
            max_results: Number of search results to incorporate.

        Returns:
            A plain-text string summarising the retrieved DOSM data,
            ready to be injected as ``rag_context`` in Contract C.
            Falls back to a placeholder string if the client is unavailable.
        """
        enriched_query = query
        if demographic:
            enriched_query = f"[{demographic}] {enriched_query}"
        if location:
            enriched_query = f"{enriched_query} in {location}"

        client = self._get_client()
        if client is None or not self._data_store_id:
            # Graceful fallback for local dev without GCP credentials
            logger.warning("RAGClient: using placeholder context (no GCP config).")
            return self._placeholder_context(demographic, location)

        try:
            from google.cloud import discoveryengine_v1 as discoveryengine  # noqa: PLC0415

            serving_config = (
                f"projects/{self._project}/locations/{self._location}"
                f"/collections/default_collection"
                f"/dataStores/{self._data_store_id}"
                f"/servingConfigs/default_config"
            )

            request = discoveryengine.SearchRequest(
                serving_config=serving_config,
                query=enriched_query,
                page_size=max_results,
            )
            response = client.search(request)

            snippets: list[str] = []
            for result in response.results:
                doc = result.document
                if doc.derived_struct_data:
                    snippet = doc.derived_struct_data.get("snippets", [{}])
                    if snippet:
                        snippets.append(snippet[0].get("snippet", ""))

            if snippets:
                return " | ".join(snippets)

        except Exception as exc:
            logger.error("DiscoveryEngine search error: %s", exc)

        return self._placeholder_context(demographic, location)

    # ─── Dev Fallback ─────────────────────────────────────────────────────────

    @staticmethod
    def _placeholder_context(
        demographic: Optional[str], location: Optional[str]
    ) -> str:
        """
        Hardcoded DOSM-inspired placeholder used when Vertex AI Search is
        unavailable (local dev / CI).
        Team Backend: replace with real Vertex AI Search once the datastore is
        populated with OpenDOSM and Data.gov.my datasets.
        """
        income_map = {
            "B40": "RM 3,000",
            "M40": "RM 6,500",
            "T20": "RM 15,000",
        }
        income = income_map.get(demographic or "", "RM 4,800")
        loc_str = location or "Malaysia"
        return (
            f"[PLACEHOLDER — connect Vertex AI Search] "
            f"According to DOSM, average {demographic or 'household'} monthly income "
            f"in {loc_str} is approximately {income}. "
            f"Source: OpenDOSM Household Income & Expenditure Survey 2022."
        )
