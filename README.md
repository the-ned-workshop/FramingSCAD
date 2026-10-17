# FramingSCAD

A NeoSCAD library for light wood-frame buildings: lumber that reports itself, schematic framing
connectors and fasteners, and tools that turn a model into a cut list, a lumber order, a clash check
and construction drawings. It grew out of designing a 10' × 12' timber shed.

![Catalog](docs/catalog.png)

**Requires [NeoSCAD](https://neoscad.org) with `--enable sketch`.** Every profile in the library (rafters,
braces, connector shapes, fastener shanks) is a fully constrained NeoSCAD sketch (`strict = true`), so
changing a dimension moves exactly what it should and an under- or over-constrained profile is an error.
Units are inches.

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
| `lumber.scad` | `stick()`, `slab_xz()`, `slab_yz()` members; `rafter_profile()`; `dressed()` sizes; `sheet()`, `item()` order lines; `xf()`, `T()`, `along_y()`, `mirror_about_x()` placement transforms; `$noms`/`$tags` member filters |
| `sketches.scad` | `profile(name, points)`: a closed polygon as a fully constrained sketch; `rect_profile()`, `strap_profile()` (strap with fastener holes), `pin_profile()` (revolved fastener half-profile) |
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

World coordinates work because placements go through `xf(matrix)`, which multiplies `$M`. Plain
`translate()`/`mirror()` still draw correctly, but the members inside them report local coordinates.

## Tools

```sh
NEOSCAD=/Applications/NeoSCAD.app/Contents/Helpers/neoscad
$NEOSCAD --enable sketch -o model.echo model.scad        # don't pass -q: it suppresses ECHO
python3 tools/cutlist.py model.echo > order.md
python3 tools/collide.py model.scad "frame()" "roof()"   # module calls that build the framing
```

`collide.py` needs the model's top-level calls wrapped in `if (is_undef(model_only)) { … }` so it can
include the file and call the framing modules itself.

## Conventions

- Inches, z up. Tag members by what they are ("rafter", "loft joist"); the tag is the cut-list
  "member" column and the clash-check unit.
- Nominal strings start with a size from `DRESSED` and can carry a grade or treatment after a space:
  `"2x6"`, `"6x6 UC4B"`, `"4x6 DF#2"`, `"1-3/4x9-1/4 LVL"`.
- Hardware takes `count = true` to echo an `ITEM` line when it's placed.

## License

MIT — see [LICENSE](LICENSE).
