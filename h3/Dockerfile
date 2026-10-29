# MiniMax H3 (ref_vidswap) as a RunPod Serverless worker.
#
# Mirrors the pod stack from minimax-h3/install/MINIMAX_H3_ULTRA-AUTO_INSTALL-RUNPOD.sh:
#   ComfyUI-Manager, rgthree-comfy, ComfyUI-KJNodes, ComfyUI-VideoHelperSuite, ComfyUI-Spectrum-MiniMax-H3
# Models stay on the network volume (/runpod-volume/ComfyUI-minimax/models); init.sh links them into
# the paths worker-comfyui expects, including /workspace -> /runpod-volume so the volume's own
# symlinks (character LoRAs) resolve.
#
# sageattention is deliberately NOT installed: it compiles CUDA kernels at build time and the captured
# graph only uses PathchSageAttentionKJ, which passes through when set to "disabled". If a later graph
# needs it, add `RUN pip install sageattention triton` and expect a long build.
FROM runpod/worker-comfyui:5.10.0-base

ENV PIP_NO_CACHE_DIR=1 \
    PIP_PREFER_BINARY=1 \
    NETWORK_VOLUME_DEBUG=true \
    VOL_STACK=ComfyUI-minimax

RUN set -eux; \
    cd /comfyui/custom_nodes; \
    for repo in \
        https://github.com/ltdrdata/ComfyUI-Manager.git \
        https://github.com/rgthree/rgthree-comfy.git \
        https://github.com/kijai/ComfyUI-KJNodes.git \
        https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
        https://github.com/xmarre/ComfyUI-Spectrum-MiniMax-H3.git \
    ; do \
        name="$(basename "$repo" .git)"; \
        if ! git clone --depth 1 "$repo" "$name"; then echo "WARN: clone failed for $repo (skipping)"; continue; fi; \
        sed -i 's/^matrix-client==0\.4\.0/# matrix-client disabled for headless worker/' \
            "$name/requirements.txt" 2>/dev/null || true; \
        if [ -f "$name/requirements.txt" ]; then \
            grep -viE '^(rembg|transparent-background|pixeloe|numba|colour-science)' \
                "$name/requirements.txt" > "$name/req.filtered" || true; \
            pip install --only-binary=:all: -r "$name/req.filtered" \
                || pip install -r "$name/req.filtered" \
                || echo "WARN: deps for $name failed (continuing)"; \
        fi; \
    done

COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
