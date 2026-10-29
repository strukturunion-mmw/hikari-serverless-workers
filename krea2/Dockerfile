# Krea2 ULTRA as a RunPod Serverless worker.
#
# Base: the official worker-comfyui image (ComfyUI 0.34.0, CUDA 12.8, venv at /opt/venv).
# Adds: the exact custom-node set our pod stack uses (krea2/install/KREA2_ULTRA-AUTO_INSTALL-RUNPOD-V2.sh).
# Models stay on the network volume; init.sh maps our volume layout onto the paths the worker expects.
#
# Build (from this directory):
#   docker buildx build --platform linux/amd64 -t docker.io/<user>/hikari-comfyui-krea2:2026-10-28 --load .
FROM runpod/worker-comfyui:5.10.0-base

ENV PIP_NO_CACHE_DIR=1 \
    PIP_PREFER_BINARY=1 \
    NETWORK_VOLUME_DEBUG=true

# Custom nodes, cloned public and pinned by depth-1 at build time.
# ComfyUI-Manager's matrix-client pin is disabled exactly as the pod installer does; it is
# unnecessary for a headless worker and is the one dependency that breaks offline installs.
RUN set -eux; \
    cd /comfyui/custom_nodes; \
    for repo in \
        https://github.com/ltdrdata/ComfyUI-Manager.git \
        https://github.com/rgthree/rgthree-comfy.git \
        https://github.com/kijai/ComfyUI-KJNodes.git \
        https://github.com/cubiq/ComfyUI_essentials.git \
        https://github.com/RamonGuthrie/ComfyUI-RBG-SmartSeedVariance.git \
        https://github.com/aitrepreneur/ComfyUI-KreaImageAspectPreserve \
        https://github.com/aitrepreneur/ComfyUI-KreaAspectPreserveOutpaint \
        https://github.com/aitrepreneur/ComfyUI-DefaultGreenMaskColor \
    ; do \
        name="$(basename "$repo" .git)"; \
        if ! git clone --depth 1 "$repo" "$name"; then echo "WARN: clone failed for $repo (skipping)"; continue; fi; \
        sed -i 's/^matrix-client==0\.4\.0/# matrix-client disabled for headless worker/' \
            "$name/requirements.txt" 2>/dev/null || true; \
        if [ -f "$name/requirements.txt" ]; then \
            pip install -r "$name/requirements.txt" || echo "WARN: deps for $name failed (continuing)"; \
        fi; \
    done; \
    git -C ComfyUI-Manager rev-parse --short HEAD || true

COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
