"""Give video outputs a path through worker-comfyui's image collection.

worker-comfyui's handler only appends node outputs found under "images". Our only output node is
VHS_VideoCombine, which reports its mp4 under "gifs" — so a successful render comes back as
"success_no_images" with the file dropped on the floor. This rewrites that one branch so gifs are
treated as outputs. Fails the build loudly if the handler layout changes.
"""
p = "/handler.py"
s = open(p).read()

OLD = (
    '        for node_id, node_output in outputs.items():\n'
    '            if "images" in node_output:'
)
NEW = (
    '        for node_id, node_output in outputs.items():\n'
    '            if "gifs" in node_output and "images" not in node_output:\n'
    '                node_output["images"] = node_output["gifs"]\n'
    '            if "images" in node_output:'
)

if OLD not in s:
    raise SystemExit("handler layout changed - re-check the worker-comfyui version")

open(p, "w").write(s.replace(OLD, NEW, 1))
print("handler patched: VHS 'gifs' -> 'images'")
