# ── Stage 1: build dependencies ───────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# System deps for OpenCV and PyTorch
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ libgl1 libglib2.0-0 libsm6 libxrender1 libxext6 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install CPU-only torch (smaller image for Cloud Run)
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
      torch==2.3.0+cpu torchvision==0.18.0+cpu \
      --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir -r requirements.txt

# ── Stage 2: runtime image ─────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Runtime system libs only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages \
                    /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application source
COPY app/        ./app/
COPY wsgi.py     .

# Model directory — models are mounted via Cloud Run volume or
# baked in at build time (see cloudbuild.yaml for GCS copy step)
RUN mkdir -p /app/models

# Non-root user for security
RUN useradd --create-home appuser
USER appuser

ENV PORT=8080
ENV MODEL_DIR=/app/models
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8080

# Gunicorn: 1 worker per vCPU, 120s timeout for heavy ML inference
CMD exec gunicorn \
      --bind "0.0.0.0:$PORT" \
      --workers 1 \
      --threads 8 \
      --timeout 120 \
      --worker-class gthread \
      --log-level info \
      wsgi:app
