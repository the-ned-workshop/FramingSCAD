// connectors.scad — schematic light-gauge framing connectors (Simpson Strong-Tie style).
//
// Shapes and sizes are close enough for details, clash checks and counts; they are not
// catalogue drawings. Check the manufacturer's current catalogue for exact dimensions,
// fastener schedules and allowable loads. Each connector echoes an ITEM line when
// count = true, so placing it in a model also orders it.
//
// Orientation conventions are given per module; the origin is the connector's reference
// corner on the framing it attaches to.

include <lumber.scad>

GA18 = 0.0478;   // 18 gauge steel
GA16 = 0.0598;   // 16 gauge
GA14 = 0.0747;   // 14 gauge

// a flat plate w (x) × l (y) × t (z) from the origin, as a sketch
module _plate(name, w, l, t) linear_extrude(t) rect_profile(name, w, l);

// angle_clip(name, a, b, l, t): an L-angle with legs a (along +x) and b (along +z), l long
// along +y, inside corner on the origin.
module angle_clip(name, a, b, l, t = GA18) {
    rotate([90, 0, 0]) mirror([0, 0, 1]) linear_extrude(l)
        profile(name, [[0, 0], [a, 0], [a, -t], [-t, -t], [-t, b], [0, b]]);
}

// a35(): framing angle; legs 1-7/16" × 1-7/16", 4-1/2" long (along +y).
module a35(count = false) {
    color(C_ZMAX) angle_clip("A35", 1.4375, 1.4375, 4.5);
    if (count) item("connector", "Simpson A35 framing angle");
}

// h2_5a(): hurricane tie on a rafter seated on a top plate. The rafter runs along +x with
// its side face on y = 0 (the tie is on the −y side); the plate runs along y with its top at
// z = 0 and its outside face on x = 0. One leg nails to the rafter, the other twists down
// onto the plate's outside face.
module h2_5a(count = false) {
    color(C_ZMAX) {
        // leg on the rafter face (x–z plane) …
        translate([0, 0, 0]) rotate([90, 0, 0]) _plate("H2.5A rafter leg", 1.25, 2.75, GA18);
        // … twisting to a leg down the outside face of the plate (y–z plane at x = 0)
        translate([0, -1.4, -2.4]) rotate([0, -90, 0]) _plate("H2.5A plate leg", 2.4, 1.4, GA18);
    }
    if (count) item("connector", "Simpson H2.5A hurricane tie");
}

// h10a(): heavier hurricane tie, same placement as h2_5a().
module h10a(count = false) {
    color(C_ZMAX) {
        rotate([90, 0, 0]) _plate("H10A rafter leg", 1.75, 4.5, GA18);
        translate([0, -1.9, -3.5]) rotate([0, -90, 0]) _plate("H10A plate leg", 3.5, 1.9, GA18);
    }
    if (count) item("connector", "Simpson H10A hurricane tie");
}

// strap(name, l, w, t): flat punched strap l long along +x, w wide along +y, on z = 0.
module strap(name, l, w = 1.25, t = GA18) linear_extrude(t) strap_profile(name, w, l);

// msta(l): Simpson MSTA strap (l = 36 for MSTA36), ZMAX.
module msta(l = 36, count = false) {
    color(C_ZMAX) strap(str("MSTA", l), l);
    if (count) item("connector", str("Simpson MSTA", l, "Z strap (ZMAX)"));
}

// cs16(l): coil strap cut to length l.
module cs16(l = 24, count = false) {
    color(C_ZMAX) strap("CS16", l, 1.25, GA16);
    if (count) item("connector", str("Simpson CS16 coil strap (ZMAX), ", l, "\" piece"));
}

// lsu26(): sloped/skewable U-hanger for a 2x6, seat at z = 0, the carried member's end
// at y = 0 running toward +y, header face at y = 0 (flanges on y = 0, −y side behind).
module lsu26(count = false) {
    color(C_ZMAX) {
        w = 1.5 + 2 * GA18;
        // U: seat + two sides, 2" deep along +y
        translate([-w / 2, 0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1]) linear_extrude(2)
            profile("LSU26 U", [[0, 0], [w, 0], [w, 5], [w - GA18, 5], [w - GA18, GA18], [GA18, GA18], [GA18, 5], [0, 5]]);
        // flanges on the header face
        for (s = [-1, 1]) translate([s > 0 ? w / 2 : -w / 2 - 1.25, 0, 0.5]) rotate([90, 0, 0])
            _plate("LSU26 flange", 1.25, 4.5, GA18);
    }
    if (count) item("connector", "Simpson LSU26 skewable rafter hanger");
}

// face_hanger(name, w, h, d): generic face-mount hanger for a member w wide and h deep,
// seat d long; same placement as lsu26().
module face_hanger(name, w, h, d = 2, t = GA16, count = false) {
    color(C_ZMAX) {
        ww = w + 2 * t;
        translate([-ww / 2, 0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1]) linear_extrude(d)
            profile(str(name, " U"), [[0, 0], [ww, 0], [ww, h], [ww - t, h], [ww - t, t], [t, t], [t, h], [0, h]]);
        for (s = [-1, 1]) translate([s > 0 ? ww / 2 : -ww / 2 - 1.25, 0, 0]) rotate([90, 0, 0])
            _plate(str(name, " flange"), 1.25, h, t);
    }
    if (count) item("connector", str("Simpson ", name, " face-mount hanger"));
}

// post_cap(name, post_w, beam_w): U-shaped cap for a beam on a post; post top at z = 0,
// centred on x = y = 0, beam running along y.
module post_cap(name, post_w = 3.5, beam_w = 3.5, t = GA16, count = false) {
    color(C_ZMAX) {
        translate([-beam_w / 2 - t, -post_w / 2, 0]) _plate(str(name, " seat"), beam_w + 2 * t, post_w, t);
        for (s = [-1, 1]) translate([s > 0 ? beam_w / 2 + t : -beam_w / 2, -post_w / 2, -4]) rotate([0, -90, 0])
            _plate(str(name, " side"), 8, post_w, t);
    }
    if (count) item("connector", str("Simpson ", name, " post cap"));
}
