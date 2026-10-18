# FramingSCAD

An OpenSCAD-compatible library for light wood-frame buildings, built for [NeoSCAD](https://neoscad.org): lumber that reports itself, schematic framing
connectors and fasteners, and tools that turn a model into a cut list, a lumber order, a clash check
and construction drawings. It grew out of designing a 10' × 12' timber shed.

![Catalog](docs/catalog.png)

## Install

`include <FramingSCAD/framing.scad>` is a path that must resolve next to your file or in a library
search folder. Pick one of these.

**A. As a project dependency (NeoSCAD 0.7 and later, recommended).** One command records the library
and its exact commit in `scad.toml` / `scad.lock`, checks it out once per machine into a shared store
and links it into `<project>/.scad/libraries`:

```sh
neoscad add FramingSCAD --git https://github.com/the-ned-workshop/FramingSCAD --tag v0.1.0
```
```scad
include <FramingSCAD/framing.scad>
```
A fresh clone of the project needs only `neoscad fetch`. Stock OpenSCAD renders the same files after
`export $(neoscad vendor)` or with `OPENSCADPATH=$(neoscad fetch --print-path)`; see NeoSCAD's
[dependencies guide](https://github.com/neoscad/neoscad/blob/main/docs/dependencies.md). The same
`scad-deps` command line is available on its own (`cargo install scad-deps --features cli`).

**B. As a git submodule.** Pinned and portable, included by relative path.

```sh
git submodule add https://github.com/the-ned-workshop/FramingSCAD.git lib/FramingSCAD
```
```scad
include <lib/FramingSCAD/framing.scad>   // relative to the including file
```

**C. Once per machine.** Clone into the user library folder, or into any folder on `OPENSCADPATH`,
and every model on the machine can `include <FramingSCAD/framing.scad>`. It's simpler, but unpinned:
every project sees whatever version is checked out.

```sh
# macOS (Linux: ~/.local/share/OpenSCAD/libraries; Windows: Documents\OpenSCAD\libraries)
git clone https://github.com/the-ned-workshop/FramingSCAD.git ~/Documents/OpenSCAD/libraries/FramingSCAD
```

`neoscad --info` (or OpenSCAD's Help → Library Info) lists the folders searched.

## NeoSCAD and OpenSCAD

The library runs in both and adapts itself: `$neoscad_features` (unbound in OpenSCAD) says which
NeoSCAD extensions are on, and `fs_feature("sketch")` and friends read it.

| NeoSCAD extension | On (`neoscad --enable …`) | Off, or OpenSCAD (2021.01 and later) |
|---|---|---|
| `sketch` | every profile is a fully constrained sketch (`polyline(…, constrain = "fixed")`, `strict = true`): change a dimension and exactly the right thing moves; an under- or over-constrained profile is an error | the same shapes as plain `polygon()` / `circle()` |
| `query` | members report world coordinates through `to_world()`, whatever `translate()` / `rotate()` / `mirror()` is around them | members report world coordinates only inside `xf()` / `along_y()` / `mirror_about_x()` placements |
| `part` | every member is a `part()` named `"<tag> <world corner>"`, so an SVG or DXF export through `projection()` keeps one outline per member | members are plain groups; 2D exports union touching members |

Run NeoSCAD with `--enable sketch --enable query --enable part` for all three (one flag each). To force
the plain geometry anyway, `-D FS_SKETCH=false` or `FS_SKETCH = false;` after the `include`. Units
are inches.

```scad
include <FramingSCAD/framing.scad>

stick("stud", "2x6", [0, 0, 7], [1.5, 5.5, 86]);          // an axis-aligned member
slab_xz("rafter", "2x6", 90, rafter_profile(3/12, -12, 0, 3.5, 58, 117.5, 5.67), 23.25);
xf(T([120, 0, 0])) along_y() stick("plate", "2x6", [0, 0, 0], [144, 5.5, 1.5]);   // placed members report world coordinates
translate([0, 30, 0]) h2_5a(count = true);               // hardware; count = true also orders it
```

## What's in it

| File | Contents |
|---|---|
| `lumber.scad` | `stick()`, `slab_xz()`, `slab_yz()` members (each a `part()` under `--enable part`); `rafter_profile()`; `dressed()` sizes; `sheet()`, `item()` order lines; `xf()`, `T()`, `along_y()`, `mirror_about_x()` placement transforms; `$noms`/`$tags` member filters |
| `sketches.scad` | `fs_feature(name)` and the `FS_SKETCH` switch; `profile(name, points)`: a closed polygon as a fully constrained sketch (or a polygon); `rect_profile()`, `strap_profile()` (strap with fastener holes), `pin_profile()` (revolved fastener half-profile) |
| `connectors.scad` | Simpson Strong-Tie-style schematic connectors: `a35()`, `h2_5a()`, `h10a()`, `lsu26()`, `face_hanger()`, `msta(l)`, `cs16(l)`, `post_cap()`, `angle_clip()`, `strap()` |
| `fasteners.scad` | `nail("6d"|"8d"|"10d"|"16d"|"N10")`, `sdws(len)`, `lag(d, len)`, `carriage_bolt(d, len)`, `earth_anchor(len)`, `rock_anchor(len, d)` |
| `framing.scad` | includes everything |
| `tools/cutlist.py` | ECHO → cut list and stock-length lumber order (first-fit-decreasing packing), sheet goods, hardware |
| `tools/collide.py` | finds members that overlap (not just touch), member type against member type |
| `examples/catalog.scad` | every component, laid out (renders `docs/catalog.png`) |

Connector and fastener shapes are close enough for details, clash checks and counts. They are **not**
catalogue drawings: check the manufacturer's current catalogue for exact dimensions, fastener schedules
and allowable loads.

## The ECHO contract

Members and parts echo machine-readable lines that the tools consume:

```
CUT|tag|nominal|length                          one per member      → cut list, lumber order
GEO|box|tag|nominal|[min x,y,z]|[max x,y,z]     axis-aligned member  → drawings (world coordinates)
GEO|poly|tag|nominal|[[x,y,z]…]|[dx,dy,dz]      profile + thickness  → drawings
SHEET|tag|kind|square feet                       sheet goods          → order
ITEM|tag|what|count                              bought items         → order
```

Under NeoSCAD with `--enable query`, members read their own transform (`to_world()`), so any
placement reports world coordinates. Elsewhere they work because placements go through `xf(matrix)`,
which multiplies `$M`: plain `translate()`/`mirror()` still draw correctly, but the members inside
them report local coordinates.

## Tools

```sh
NEOSCAD=/Applications/NeoSCAD.app/Contents/Helpers/neoscad
$NEOSCAD --enable sketch --enable query -o model.echo model.scad   # don't pass -q: it suppresses ECHO
# OpenSCAD: openscad -o model.echo model.scad
python3 tools/cutlist.py model.echo > order.md
python3 tools/collide.py model.scad "frame()" "roof()"   # module calls that build the framing
# one outline per member, for drawings:
$NEOSCAD --enable sketch --enable query --enable part -o front.svg front_view.scad   # projection() of the model
```

`collide.py` needs the model's top-level calls wrapped in `if (is_undef(model_only)) { … }` so it can
include the file and call the framing modules itself; its scratch files go beside the model so they
share its project. The tools are also at `.scad/libraries/FramingSCAD/tools/` in a project that
depends on the library.

## Conventions

- Inches, z up. Tag members by what they are ("rafter", "loft joist"); the tag is the cut-list
  "member" column and the clash-check unit.
- Nominal strings start with a size from `DRESSED` and can carry a grade or treatment after a space:
  `"2x6"`, `"6x6 UC4B"`, `"4x6 DF#2"`, `"1-3/4x9-1/4 LVL"`.
- Hardware takes `count = true` to echo an `ITEM` line when it's placed.

## License

MIT — see [LICENSE](LICENSE).
