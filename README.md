# 🧠 PolicyIQ — AI-Powered Policy Stress-Testing Engine

PolicyIQ is a multi-agent simulation platform that translates raw Malaysian government policy text into an 8-Knob economic state matrix and stress-tests it against 50 demographically diverse "Digital Malaysian" AI citizens across simulated time steps. It surfaces macro sentiment shifts, inequality deltas, anomaly flags, and an AI-generated policy mitigation recommendation — giving decision-makers a data-grounded view of real-world impact *before* deployment.

---

## 🗂️ Project Structure

```
PolicyIQ/
├── backend/            # FastAPI + AI Engine (Python 3.10)
│   ├── ai_engine/      # Physics engine, orchestrator, RAG client
│   ├── main.py         # API entrypoint
│   ├── schemas.py      # Pydantic contract models (Pre-A → E)
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/           # Flutter dashboard
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   └── pubspec.yaml
├── docker-compose.yml
├── Makefile
└── .env                # (not committed — see .env.example)
```

---

## 🚀 How to Run

### Prerequisites
- Docker Desktop ≥ 24
- Flutter SDK ≥ 3.19 (for frontend dev)
- A `.env` file in the project root (copy `.env.example` and fill in secrets)

### Option A — Docker (Backend only, recommended for hackathon)

```bash
# 1. Build the backend image
make build-docker

# 2. Start all services
make up
```

The API will be available at **http://localhost:8000**.  
Interactive docs: **http://localhost:8000/docs**

### Option B — Local Python (Backend)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
make run-backend
```

### Option C — Flutter Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome   # or your target device
```

Set `API_BASE_URL` in `frontend/lib/services/api_client.dart` to `http://localhost:8000`.

---

## 🔑 Environment Variables

| Variable | Description |
|---|---|
| `GOOGLE_CLOUD_PROJECT` | GCP project ID |
| `VERTEX_AI_LOCATION` | e.g. `us-central1` |
| `VERTEX_SEARCH_DATA_STORE_ID` | Vertex AI Search datastore ID |
| `GEMINI_MODEL` | e.g. `gemini-1.5-flash` |

---

## 🏗️ API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/validate-policy` | Gatekeeper — validates raw policy text |
| `POST` | `/simulate` | SSE stream — runs the full simulation loop |

---

## 🤝 Team Streams

| Stream | Focus |
|---|---|
| **Team AI** | Physics engine, agent DNA, Genkit orchestration |
| **Team Backend** | FastAPI gateway, Cloud Run deployment, RAG pipeline |
| **Team Frontend** | Flutter dashboard, heatmaps, anomaly hunter |
