# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (production-ready)
# ═══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# Stage 1: builder — cài dependencies (có compiler)
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Build tools chỉ cần ở stage này
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements trước để tận dụng Docker layer cache
COPY requirements.txt .

# Cài vào venv riêng để dễ copy sang runtime
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir -r requirements.txt


# ─────────────────────────────────────────────────────────────
# Stage 2: runtime — image gọn, non-root
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8000

WORKDIR /app

# Copy venv đã build sẵn từ stage builder
COPY --from=builder /opt/venv /opt/venv

# Copy source SAU CÙNG — sửa code không phá cache dependencies
COPY app/ ./app/
COPY utils/ ./utils/

# Tạo user thường, không chạy root
RUN useradd --create-home --shell /bin/bash appuser \
    && chown -R appuser:appuser /app
USER appuser

EXPOSE 8000

# Healthcheck gọi /health — dùng Python vì slim không có curl/wget
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os,urllib.request,sys; \
        sys.exit(0) if urllib.request.urlopen(f'http://127.0.0.1:{os.getenv(\"PORT\",\"8000\")}/health', timeout=3).status==200 else sys.exit(1)"

# Bind 0.0.0.0, đọc PORT từ env (cloud tự gán)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
