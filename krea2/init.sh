#!/usr/bin/env bash
# Worker entrypoint: point ComfyUI at THIS stack's models on the shared network volume, then hand
# over to the stock start.sh.
#
# History: an earlier version created a symlink farm at /runpod-volume/models/<type> -> the stack's
# folders. That lived on the volume, so the links created by the Krea2 worker persisted and the H3
# worker silently inherited Krea2's models ("value_not_in_list"). Two stacks sharing one volume also
# cannot share a mutable path. This version writes a per-container extra_model_paths.yaml instead:
# nothing is written to the volume, and each endpoint resolves its own stack.
set -u

VOL_STACK="${VOL_STACK:-ComfyUI-krea2}"
SRC="/runpod-volume/${VOL_STACK}/models"

echo "init: stack=${VOL_STACK} src=${SRC}"

# The volume's own symlinks (character LoRAs live as links into /workspace/output/...) assume the
# volume is mounted at /workspace, which is how pods see it. Give /workspace back or they dangle.
if [ ! -e /workspace ] && [ -d /runpod-volume ]; then
  ln -s /runpod-volume /workspace && echo "init: linked /workspace -> /runpod-volume"
fi

if [ -d "$SRC" ]; then
  cat > /comfyui/extra_model_paths.yaml <<EOF
# generated at container start by init.sh — per container, never on the volume
runpod_worker_comfy:
  base_path: ${SRC}
  checkpoints: checkpoints
  loras: loras
  vae: vae
  vae_approx: vae_approx
  text_encoders: text_encoders
  clip: text_encoders
  diffusion_models: diffusion_models
  unet: diffusion_models
  upscale_models: upscale_models
  controlnet: controlnet
  clip_vision: clip_vision
EOF
  echo "init: wrote /comfyui/extra_model_paths.yaml -> ${SRC}"
  echo "init: visible: $(ls -1 "$SRC" 2>/dev/null | tr '\n' ' ')"
  echo "init: loras: $(ls -1 "$SRC/loras" 2>/dev/null | head -8 | tr '\n' ' ')"
else
  echo "init: WARNING ${SRC} not found — check the volume mount and VOL_STACK"
  echo "init: /runpod-volume contains: $(ls -1 /runpod-volume 2>/dev/null | head -10 | tr '\n' ' ')"
fi

exec /start.sh
