#!/usr/bin/env bash
# Worker entrypoint: map the media network volume onto the paths worker-comfyui expects, then hand
# over to the stock start.sh.
#
# worker-comfyui looks for models at /runpod-volume/models/<type>/ (checkpoints, loras, vae,
# clip, unet, upscale_models). Our volume keeps a full ComfyUI install per stack, e.g.
# /runpod-volume/ComfyUI-krea2/models/{diffusion_models,text_encoders,vae,loras,...}.
# Symlinking the second onto the first means no extra_model_paths.yaml override and no renaming.
set -u

VOL_STACK="${VOL_STACK:-ComfyUI-krea2}"
SRC="/runpod-volume/${VOL_STACK}/models"
DST="/runpod-volume/models"

echo "init: volume stack = ${VOL_STACK}"
if [ -d /runpod-volume ]; then
  echo "init: /runpod-volume mounted; top level: $(ls -1 /runpod-volume 2>/dev/null | head -20 | tr '\n' ' ')"
else
  echo "init: WARNING /runpod-volume is NOT mounted - models will be missing"
fi

# The volume's own symlinks (character LoRAs live as links into /workspace/output/...) assume the
# volume is mounted at /workspace, which is how pods see it. Serverless mounts it at /runpod-volume,
# so give /workspace back or every such link dangles and ComfyUI silently hides the file.
if [ ! -e /workspace ] && [ -d /runpod-volume ]; then
  ln -s /runpod-volume /workspace && echo "init: linked /workspace -> /runpod-volume"
fi

if [ -d "$SRC" ]; then
  mkdir -p "$DST"
  # worker type  :  our ComfyUI folder
  for pair in \
      unet:diffusion_models \
      clip:text_encoders \
      vae:vae \
      loras:loras \
      upscale_models:upscale_models \
      checkpoints:checkpoints \
      clip_vision:clip_vision \
      controlnet:controlnet \
  ; do
    want="${pair%%:*}"; have="${pair##*:}"
    if [ -d "$SRC/$have" ] && [ ! -e "$DST/$want" ]; then
      ln -s "$SRC/$have" "$DST/$want" && echo "init: linked models/$want -> $SRC/$have"
    fi
  done
  echo "init: model dirs visible: $(ls -1 "$DST" 2>/dev/null | tr '\n' ' ')"
  echo "init: loras visible: $(ls -1 "$SRC/loras" 2>/dev/null | head -12 | tr '\n' ' ')"
else
  echo "init: WARNING $SRC not found - check the volume mount and VOL_STACK"
fi

exec /start.sh
