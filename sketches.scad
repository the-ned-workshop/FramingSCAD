// sketches.scad — 2D profiles shared by the framing library.
//
// Under NeoSCAD with `--enable sketch`, every profile is a fully constrained sketch. Anywhere
// else (OpenSCAD, or NeoSCAD without the extension) the same profiles are plain polygon() /
// circle() geometry. The switch is automatic: $neoscad_features lists the extensions that are
// on and is unbound in OpenSCAD. Override it after the include, or with -D FS_SKETCH=false.

// fs_feature("sketch"|"query"|"part"): whether a NeoSCAD extension is on (false in OpenSCAD).
function fs_feature(name) = !is_undef($neoscad_features) && [for (f = $neoscad_features) if (f == name) f] != [];

FS_SKETCH = fs_feature("sketch");

// profile(name, P): a closed polygon through the points P. As a sketch, polyline() with
// constrain = "fixed" pins the first point and gives every edge but the closing one its
// direction and length, so strict = true holds and changing a dimension in P moves exactly
// what it should.
module profile(name, P) if (!FS_SKETCH) polygon(P); else sketch(name = name, strict = true) {
    e = polyline(P, constrain = "fixed");
}

// rect_profile(name, w, h): a w × h rectangle with its lower-left corner at the origin.
module rect_profile(name, w, h) profile(name, [[0, 0], [w, 0], [w, h], [0, h]]);

// strap_profile(name, w, l, hole_d, pitch): a flat strap w wide and l long with a row of
// fastener holes pitch apart down its centreline, as one sketch (circles are holes).
module strap_profile(name, w, l, hole_d = 0.17, pitch = 1) if (!FS_SKETCH)
    difference() { square([l, w]); for (x = [pitch / 2 : pitch : l - pitch / 2]) translate([x, w / 2]) circle(d = hole_d, $fn = 12); }
else sketch(name = name, strict = true) {
    e = polyline([[0, 0], [l, 0], [l, w], [0, w]], constrain = "fixed");
    for (x = [pitch / 2 : pitch : l - pitch / 2]) {
        h = circle([x, w / 2], d = hole_d);
        fix(h.center);
    }
}

// pin_profile(name, r, len, head_r, head_t, tip): half-profile of a round fastener in the
// x–y plane (x = radius, y = axis, tip at y = 0) for rotate_extrude. No head when head_r ≤ r.
module pin_profile(name, r, len, head_r, head_t, tip) profile(name,
    head_r > r ? [[0, 0], [r, tip], [r, len - head_t], [head_r, len - head_t], [head_r, len], [0, len]]
               : [[0, 0], [r, tip], [r, len], [0, len]]);
