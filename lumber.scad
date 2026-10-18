// lumber.scad — framing members that report themselves.
//
// Units are inches. Every member echoes two lines that tools/ turn into documents:
//   CUT|tag|nominal|length                      → tools/cutlist.py (cut list, stock order)
//   GEO|box|tag|nominal|[min xyz]|[max xyz]      → tools/drawings (orthographic views)
//   GEO|poly|tag|nominal|[[x,y,z]…]|[thickness vector]
// plus SHEET|tag|kind|sq ft and ITEM|tag|what|count for sheet goods and bought items.
//
// World positions: under NeoSCAD with `--enable query`, members read their own transform
// (to_world()), so plain translate()/rotate()/mirror() around them report correctly. Without
// it (OpenSCAD), wrap placements in xf(matrix) (or along_y(), mirror_about_x()) instead,
// which thread the matrix through $M; those work everywhere.
// Parts: with `--enable part`, every member is a part() named "<tag> <world corner>", so an
// SVG or DXF export (through projection()) keeps one outline per member.

include <sketches.scad>

FS_WORLD = fs_feature("query");
FS_PART = fs_feature("part");

C_FRAME   = [0.89, 0.76, 0.55];
C_TREATED = [0.56, 0.64, 0.46];
C_TIMBER  = [0.70, 0.50, 0.30];
C_SHEET   = [0.80, 0.68, 0.48];
C_METAL   = [0.33, 0.36, 0.38];
C_STEEL   = [0.45, 0.45, 0.48];
C_ZMAX    = [0.62, 0.64, 0.66];

// Dressed (actual) size [thickness, width] by nominal size; grade or treatment may follow
// after a space ("6x6 UC4B", "2x6 UC4A").
DRESSED = [
    ["1x3", [0.75, 2.5]], ["1x4", [0.75, 3.5]], ["1x6", [0.75, 5.5]], ["1x8", [0.75, 7.25]], ["1x10", [0.75, 9.25]],
    ["2x4", [1.5, 3.5]], ["2x6", [1.5, 5.5]], ["2x8", [1.5, 7.25]], ["2x10", [1.5, 9.25]], ["2x12", [1.5, 11.25]],
    ["4x4", [3.5, 3.5]], ["4x6", [3.5, 5.5]], ["4x8", [3.5, 7.25]],
    ["6x6", [5.5, 5.5]], ["6x8", [5.5, 7.25]], ["6x10", [5.5, 9.25]],
    ["1-3/4x9-1/4", [1.75, 9.25]], ["1-3/4x11-7/8", [1.75, 11.875]],
];
function _prefix(s, p) = len(s) >= len(p) && [for (i = [0 : len(p) - 1]) s[i]] == [for (i = [0 : len(p) - 1]) p[i]]
                         && (len(s) == len(p) || s[len(p)] == " ");
function dressed(nom) = let (m = [for (e = DRESSED) if (_prefix(nom, e[0])) e[1]]) len(m) ? m[0] : undef;

// ---------- filters (collision checks and per-member renders) ----------
// Set $noms = ["4x4", …] or $tags = ["girt", …] to draw only those members.
function _in(x, list) = len([for (n = list) if (n == x) 1]) > 0;
function _on(nom, tag) = (is_undef($noms) || _in(nom, $noms)) && (is_undef($tags) || _in(tag, $tags));
function _all() = is_undef($noms) && is_undef($tags);

// ---------- placement transforms members can report ----------
I4 = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]];
function _M() = is_undef($M) ? I4 : $M;
function T(v) = [[1, 0, 0, v[0]], [0, 1, 0, v[1]], [0, 0, 1, v[2]], [0, 0, 0, 1]];
function _pt(p) = FS_WORLD ? to_world(p) : let (m = _M(), q = m * [p[0], p[1], p[2], 1]) [q[0], q[1], q[2]];
module xf(m) { $M = _M() * m; multmatrix(m) children(); }
// a part() per member when the extension is on; a plain group otherwise
module _part(name) if (FS_PART) part(name) children(); else children();
// lay a wall drawn along +x down along +y (swap x and y)
module along_y() xf([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]) children();
// mirror about the plane x = cx when on
module mirror_about_x(cx, on = true) xf(on ? [[-1, 0, 0, 2 * cx], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]] : I4) children();

// ---------- members ----------

// stick(tag, nom, p, s): an axis-aligned member at corner p with size s; length = longest side.
module stick(tag, nom, p, s, c = C_FRAME) if (_on(nom, tag)) {
    echo(str("CUT|", tag, "|", nom, "|", max(s)));
    a = _pt(p); b = _pt(p + s);
    lo = [min(a[0], b[0]), min(a[1], b[1]), min(a[2], b[2])];
    echo(str("GEO|box|", tag, "|", nom, "|", lo, "|", [max(a[0], b[0]), max(a[1], b[1]), max(a[2], b[2])]));
    _part(str(tag, " ", lo)) color(c) translate(p) cube(s);
}

// slab_xz(tag, nom, len, pts, y0, t): a member whose profile pts lies in the x–z plane
// (rafters, braces), t thick along +y from y0. The profile is a constrained sketch.
module slab_xz(tag, nom, len, pts, y0, t = 1.5, c = C_FRAME) if (_on(nom, tag)) {
    echo(str("CUT|", tag, "|", nom, "|", len));
    echo(str("GEO|poly|", tag, "|", nom, "|", [for (q = pts) _pt([q[0], y0, q[1]])], "|", _pt([0, y0 + t, 0]) - _pt([0, y0, 0])));
    _part(str(tag, " ", _pt([pts[0][0], y0, pts[0][1]]))) color(c) translate([0, y0 + t, 0]) rotate([90, 0, 0]) linear_extrude(t) profile(tag, pts);
}

// slab_yz(tag, nom, len, pts, x0, t): profile in the y–z plane (u → y, v → z), t thick along +x.
module slab_yz(tag, nom, len, pts, x0, t = 1.5, c = C_FRAME) if (_on(nom, tag)) {
    echo(str("CUT|", tag, "|", nom, "|", len));
    echo(str("GEO|poly|", tag, "|", nom, "|", [for (q = pts) _pt([x0, q[0], q[1]])], "|", _pt([x0 + t, 0, 0]) - _pt([x0, 0, 0])));
    _part(str(tag, " ", _pt([x0, pts[0][0], pts[0][1]]))) color(c) translate([x0, 0, 0]) rotate([90, 0, 90]) linear_extrude(t) profile(tag, pts);
}

// rafter_profile(pitch, x_tail, x_seat_out, x_seat_in, x_top, z_seat, depth):
// points (x–z) of a common rafter with a plumb-cut tail at x_tail, a birdsmouth whose seat
// runs from the outside of the wall (x_seat_out) to x_seat_in at height z_seat, and a plumb
// cut at x_top. depth is the plumb depth (member depth × sqrt(1 + pitch²)).
function rafter_profile(pitch, x_tail, x_seat_out, x_seat_in, x_top, z_seat, depth) =
    let (zb = function(x) z_seat + (x - x_seat_in) * pitch)
    [[x_tail, zb(x_tail)], [x_seat_out, zb(x_seat_out)], [x_seat_out, z_seat], [x_seat_in, z_seat],
     [x_top, zb(x_top)], [x_top, zb(x_top) + depth], [x_tail, zb(x_tail) + depth]];

// Sheet goods; area in sq ft for the order.
module sheet(tag, kind, area_sf) echo(str("SHEET|", tag, "|", kind, "|", area_sf));

// Things bought by count (hardware, anchors, doors…).
module item(tag, what, n = 1) echo(str("ITEM|", tag, "|", what, "|", n));
