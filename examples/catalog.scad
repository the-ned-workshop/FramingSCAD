// catalog.scad — every component in the library, magnified to fill a 6" cell, with labels.
// neoscad --enable sketch --enable query --enable part -o docs/catalog.png --imgsize=1600,900 \
//         --camera=0,0,0,55,0,20,0 --viewall --autocenter --projection=o examples/catalog.scad
include <../framing.scad>

ITEMS = ["A35", "H2.5A", "H10A", "LSU26", "MSTA36", "CS16", "8d nail",
         "16d nail", "N10 nail", "SDWS 4\"", "lag 1/2 x 10", "carriage bolt", "earth anchor", "rock anchor"];

module part_n(i) {
    if (i == 0) a35();
    if (i == 1) h2_5a();
    if (i == 2) h10a();
    if (i == 3) lsu26();
    if (i == 4) msta(36);
    if (i == 5) cs16(24);
    if (i == 6) nail("8d");
    if (i == 7) nail("16d");
    if (i == 8) nail("N10");
    if (i == 9) sdws(4);
    if (i == 10) lag(0.5, 10);
    if (i == 11) carriage_bolt(0.25, 3);
    if (i == 12) earth_anchor(48);
    if (i == 13) rock_anchor(18);
}

// per-item magnification so every part fills its 6" cell (nails ×2, anchors ×0.1 …)
SCALE = [2.2, 1.4, 1.1, 1.0, 0.17, 0.25, 1.8, 1.4, 2.6, 1.2, 0.5, 1.5, 0.11, 0.28];

for (i = [0 : len(ITEMS) - 1]) translate([(i % 7) * 9, -floor(i / 7) * 10, 0]) {
    scale(SCALE[i]) part_n(i);
    color([0.2, 0.2, 0.2]) translate([2, -2.5, 0]) linear_extrude(0.02) text(ITEMS[i], size = 0.7, halign = "center");
}
