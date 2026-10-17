// fasteners.scad — nails, screws, bolts and ground anchors.
//
// Every fastener lies along +z with its tip at z = 0 and its head at z = length: place the
// tip on the far side of the joint and rotate to the drive direction. Profiles are
// constrained sketches revolved about the axis.

include <lumber.scad>

C_BRIGHT = [0.72, 0.72, 0.74];
C_HDG    = [0.58, 0.60, 0.60];

// [name, shank diameter, length, head diameter] — common nails and connector nails.
NAILS = [
    ["6d",  0.113, 2.0, 0.266],
    ["8d",  0.131, 2.5, 0.281],
    ["10d", 0.148, 3.0, 0.312],
    ["16d", 0.162, 3.5, 0.344],
    ["N10", 0.148, 1.5, 0.312],
];
function nail_spec(size) = let (m = [for (n = NAILS) if (n[0] == size) n]) len(m) ? m[0] : undef;

// nail(size, hdg): a common nail ("8d", "16d", "N10" …).
module nail(size = "8d", hdg = false) {
    n = nail_spec(size);
    assert(!is_undef(n), str("unknown nail size ", size));
    color(hdg ? C_HDG : C_BRIGHT) rotate_extrude($fn = 16)
        pin_profile(str("nail ", size), n[1] / 2, n[2], n[3] / 2, 0.06, n[1] * 1.2);
}

// sdws(len): Simpson Strong-Drive SDWS ¼" timber screw with a washer head.
module sdws(len = 4) {
    color(C_HDG) rotate_extrude($fn = 16) pin_profile(str("SDWS ", len), 0.11, len, 0.375, 0.12, 0.3);
}

// lag(d, len): hex-head lag screw (head drawn round) with a flat washer under it.
module lag(d = 0.5, len = 10) {
    color(C_HDG) {
        rotate_extrude($fn = 20) pin_profile(str("lag ", d, "x", len), d / 2, len, d * 0.75, d * 0.65, d);
        translate([0, 0, len - d * 0.65 - 0.1]) linear_extrude(0.1) sketch(name = "washer", strict = true) {
            o = circle([0, 0], d = d * 2.6); i = circle([0, 0], d = d * 1.1); fix(o.center); fix(i.center);
        }
    }
}

// carriage_bolt(d, len): domed-head bolt (dome drawn as a low cylinder), nut at the tip.
module carriage_bolt(d = 0.25, len = 3) {
    color(C_HDG) {
        rotate_extrude($fn = 20) pin_profile(str("carriage bolt ", d), d / 2, len, d * 1.1, d * 0.55, 0.03);
        translate([0, 0, 0.1]) cylinder(d = d * 1.8, h = d * 0.9, $fn = 6);
    }
}

// earth_anchor(len, helix_d): helical earth anchor — 3/4" shaft, one helix plate near the
// tip (drawn flat), drop-forged eye at the top (z = len).
module earth_anchor(len = 48, helix_d = 4, count = false) {
    color(C_HDG) {
        rotate_extrude($fn = 16) pin_profile("anchor shaft", 0.375, len, 0.375, 0.01, 1.5);
        translate([0, 0, 3]) linear_extrude(0.25) sketch(name = "helix", strict = true) {
            c = circle([0, 0], d = helix_d); fix(c.center);
        }
        translate([0, 0, len + 0.9]) rotate([90, 0, 0]) rotate_extrude($fn = 24) translate([0.9, 0]) circle(0.2, $fn = 10);
    }
    if (count) item("foundation", str(len, "\" helical earth anchor"));
}

// rock_anchor(len, d): epoxied threaded rod / rebar anchor; z = 0 is the bottom of the hole.
module rock_anchor(len = 18, d = 0.625, count = false) {
    color(C_STEEL) cylinder(d = d, h = len, $fn = 16);
    color([0.55, 0.52, 0.45], 0.6) cylinder(d = d + 0.25, h = len * 0.6, $fn = 16);   // epoxy
    if (count) item("foundation", str(d, "\" epoxied rock anchor, ", len, "\""));
}
