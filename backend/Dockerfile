FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install system dependencies (curl needed for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

# Expose the API port
EXPOSE 8000

# Run uvicorn on container start
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
