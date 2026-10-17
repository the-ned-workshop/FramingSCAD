#!/usr/bin/env python3
"""Find framing members that overlap each other (not just touch).

    python3 tools/collide.py model.scad ["frame()" "roof()" ...]

Draws each member type (CUT tag) against all the others with lumber.scad's $tags
filter, then narrows any hit down to the pair of tags. Needs the model's top-level
calls wrapped in `if (is_undef(model_only))` and the module calls that build the
framing passed as arguments (default: frame()/walls() and roof()).
"""
import os
import re
import subprocess
import sys
import tempfile

NEOSCAD = "/Applications/NeoSCAD.app/Contents/Helpers/neoscad"
MIN_VOL = 0.5   # cu in; smaller is a sliver from faces that merely touch


def run(path, body, out):
    src = f'include <{os.path.abspath(path)}>\nmodel_only = true;\n{body}\n'
    scad = out.replace(".stl", ".scad")
    open(scad, "w").write(src)
    if os.path.exists(out):
        os.remove(out)
    r = subprocess.run([NEOSCAD, "--enable", "sketch", "--backend=manifold", "-o", out, scad], capture_output=True, text=True)
    return r.stderr


def volume(stl):
    if not os.path.exists(stl):
        return 0.0
    v, tri = 0.0, []
    for line in open(stl):
        t = line.split()
        if t and t[0] == "vertex":
            tri.append(tuple(map(float, t[1:4])))
            if len(tri) == 3:
                a, b, c = tri
                tri = []
                v += (a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
                      + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6
    return abs(v)


def main(path, mods):
    tmp = tempfile.mkdtemp()
    out = f"{tmp}/x.stl"
    calls = " ".join(f"{m};" for m in mods)
    echo = run(path, f"union() {{ {calls} }}", f"{tmp}/all.echo".replace(".echo", ".stl"))
    tags = sorted(set(re.findall(r'ECHO: "CUT\|([^|]+)\|', echo)))
    q = lambda ts: "[" + ", ".join(f'"{t}"' for t in ts) + "]"
    hits = []
    for t in tags:
        others = [o for o in tags if o != t]
        run(path, f"intersection() {{ let($tags={q([t])}) {{ {calls} }} let($tags={q(others)}) {{ {calls} }} }}", out)
        if volume(out) > MIN_VOL:
            for o in others:
                if (o, t) in [(h[0], h[1]) for h in hits]:
                    continue
                run(path, f"intersection() {{ let($tags={q([t])}) {{ {calls} }} let($tags={q([o])}) {{ {calls} }} }}", out)
                v = volume(out)
                if v > MIN_VOL:
                    hits.append((t, o, round(v, 1)))
    print(f"{path}: {len(tags)} member types checked")
    for t, o, v in hits:
        print(f"  OVERLAP  {t}  ×  {o}: {v} cu in")
    if not hits:
        print("  no overlaps")
    return 1 if hits else 0


if __name__ == "__main__":
    body = "frame()" if "module frame" in open(sys.argv[1]).read() else "walls()"
    mods = sys.argv[2:] or ["foundation(DOOR[0], DOOR[1])", body, "roof()"]
    sys.exit(main(sys.argv[1], mods))
