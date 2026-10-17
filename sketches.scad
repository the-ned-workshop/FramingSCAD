// sketches.scad — constrained NeoSCAD sketches shared by the framing library.
// Requires `--enable sketch`.

// profile(name, P): a closed polygon through the points P as a fully constrained sketch.
// The first point is fixed; every edge but the closing one gets its direction and length
// (horizontal/vertical + length, or dx/dy distances), so strict = true holds and changing
// a dimension in P moves exactly what it should.
module profile(name, P) sketch(name = name, strict = true) {
    n = len(P);
    q = [for (p = P) point(p)];
    e = [for (i = [0 : n - 1]) line(q[i], q[(i + 1) % n])];
    fix(q[0]);
    for (i = [0 : n - 2]) let (d = P[i + 1] - P[i]) {
        if (d[1] == 0) { horizontal(e[i]); length(e[i], abs(d[0])); }
        else if (d[0] == 0) { vertical(e[i]); length(e[i], abs(d[1])); }
        else { distance(q[i], q[i + 1], d[0], along = "x"); distance(q[i], q[i + 1], d[1], along = "y"); }
    }
}

// rect_profile(name, w, h): a w × h rectangle with its lower-left corner at the origin.
module rect_profile(name, w, h) profile(name, [[0, 0], [w, 0], [w, h], [0, h]]);

// strap_profile(name, w, l, hole_d, pitch): a flat strap w wide and l long with a row of
// fastener holes pitch apart down its centreline, as one sketch (circles are holes).
module strap_profile(name, w, l, hole_d = 0.17, pitch = 1) sketch(name = name, strict = true) {
    c = [point([0, 0]), point([l, 0]), point([l, w]), point([0, w])];
    e = [for (i = [0 : 3]) line(c[i], c[(i + 1) % 4])];
    fix(c[0]); horizontal(e[0]); length(e[0], l); vertical(e[1]); length(e[1], w); horizontal(e[2]); vertical(e[3]);
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
