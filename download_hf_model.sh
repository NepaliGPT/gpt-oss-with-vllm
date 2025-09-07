#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./download_hf_model.sh "Qwen/Qwen3-0.6B" "/home/$USER/models/qwen3-0.6b"
#   ./download_hf_model.sh "openai/gpt-oss-20b" "/home/$USER/models/gpt-oss-20b"
#
# Notes:
# - Requires internet access from the machine where you run it.
# - If your HF repo is gated/private, run `huggingface-cli login` first.
# - Works on login node; then point vLLM to the local_dir in offline mode.

MODEL_ID="${1:-Qwen/Qwen3-0.6B}"
DEST_DIR="${2:-/home/$USER/models/qwen3-0.6b}"

echo "[*] Model: ${MODEL_ID}"
echo "[*] Dest : ${DEST_DIR}"
mkdir -p "${DEST_DIR}"

# Prefer the official CLI; fall back to Python if CLI is missing.
if ! command -v huggingface-cli >/dev/null 2>&1; then
  echo "[*] Installing huggingface_hub (user scope)…"
  python3 -m pip install --user "huggingface_hub>=0.23"
fi

if command -v huggingface-cli >/dev/null 2>&1; then
  echo "[*] Using huggingface-cli download…"
  # --local-dir-use-symlinks False is important for NFS/HPC stability.
  huggingface-cli download "${MODEL_ID}" \
    --local-dir "${DEST_DIR}" \
    --local-dir-use-symlinks False \
    --resume-download
else
  echo "[*] CLI unavailable; using Python fallback…"
  python3 - <<PY
from huggingface_hub import snapshot_download
snapshot_download(
    repo_id="${MODEL_ID}",
    local_dir="${DEST_DIR}",
    local_dir_use_symlinks=False,
    resume_download=True
)
PY
fi

echo "[✓] Done. Files in: ${DEST_DIR}"

