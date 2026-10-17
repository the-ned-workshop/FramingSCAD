#!/usr/bin/env python3
"""Turn a shed model's echo output into a cut list and a lumber-yard order.

    neoscad --enable sketch -o model.echo model.scad      # no -q: it suppresses ECHO
    python3 tools/cutlist.py model.echo > order.md

Each framing member echoes CUT|tag|nominal|length_in; sheet goods echo
SHEET|tag|kind|sq_ft; bought items echo ITEM|tag|what|count.
Pieces are packed first-fit-decreasing into the shortest stock length that
holds them, with a 1/4" kerf and 1" end trim per piece.
"""
import math
import re
import sys
from collections import Counter, defaultdict

STOCK = {  # available lengths, feet
    "default": [8, 10, 12, 14, 16],
    "6x6": [8, 10, 12, 14, 16],
    "6x8": [8, 10, 12, 14, 16],
}
KERF, TRIM = 0.25, 1.0
WASTE = 1.10
SHEET_SF = 32.0


def stock_for(nom):
    key = nom.split()[0]
    return STOCK.get(key, STOCK["default"])


def pack(pieces, stock_ft):
    """First-fit decreasing; each new board is the shortest stock that fits the piece.
    pieces: [(length_in, use)]. Returns {stock_ft: (count, {uses})}."""
    boards = []  # [stock_in, remaining_in, uses]
    for L, use in sorted(pieces, reverse=True):
        need = L + KERF + TRIM
        for b in boards:
            if b[1] >= need:
                b[1] -= need
                b[2].add(use)
                break
        else:
            fits = [s * 12 for s in stock_ft if s * 12 >= need - TRIM]
            if not fits:
                raise SystemExit(f"piece {L:.1f}\" longer than any stock")
            boards.append([fits[0], fits[0] - need, {use}])
    out = defaultdict(lambda: [0, set()])
    for b in boards:
        o = out[int(b[0] // 12)]
        o[0] += 1
        o[1] |= b[2]
    return out


def fmt_in(x):
    ft, inch = divmod(round(x * 8) / 8, 12)
    whole = int(inch)
    frac = inch - whole
    f = {0: "", 0.125: " 1/8", 0.25: " 1/4", 0.375: " 3/8", 0.5: " 1/2",
         0.625: " 5/8", 0.75: " 3/4", 0.875: " 7/8"}[frac]
    return f"{int(ft)}'-{whole}{f}\""


def main(path):
    cuts = defaultdict(list)     # nominal -> lengths
    by_tag = Counter()           # (tag, nominal, length) -> n
    sheets = defaultdict(float)
    items = Counter()
    heights = []
    for line in open(path):
        m = re.search(r'ECHO: "(.*)"', line)
        if not m:
            continue
        f = m.group(1).replace('\\"', '"').split("|")
        if f[0] == "CUT":
            tag, nom, L = f[1], f[2], float(f[3])
            cuts[nom].append((L, re.sub(r"^(left|right|front|back) wall ", "", tag)))
            by_tag[(nom, tag, round(L, 2))] += 1
        elif f[0] == "SHEET":
            sheets[f[2]] += float(f[3])
        elif f[0] == "ITEM":
            items[(f[1], f[2])] += int(f[3])
        elif f[0] == "HEIGHT":
            heights.append((f[1], float(f[2])))

    out = []
    if heights:
        out.append("| Check | Value |\n|---|---|")
        out += [f"| {k} | {fmt_in(v)} |" for k, v in heights]
        out.append("")

    out.append("### Lumber order\n")
    out.append("| Qty | Size | Length | Use |\n|---:|---|---|---|")
    for nom in sorted(cuts):
        for ft, (n, uses) in sorted(pack(cuts[nom], stock_for(nom)).items()):
            out.append(f"| {n} | {nom} | {ft}' | {', '.join(sorted(uses))} |")
    out.append("")

    out.append("### Sheet goods & finishes\n")
    out.append("| Qty | Material | Basis |\n|---:|---|---|")
    for kind, sf in sorted(sheets.items()):
        if "plywood" in kind or "panel" in kind:
            out.append(f"| {math.ceil(sf * WASTE / SHEET_SF)} sheets | {kind}, 4x8 | {sf:.0f} sq ft + 10% |")
        elif "board & batten" in kind:
            boards = math.ceil(sf * 12 / 10 / 12 * WASTE)   # 1x10 @ 10" coverage, 12' boards (gables run 11'+)
            out.append(f"| {boards} + {boards} | 1x10 boards + 1x3 battens, 12' | {sf:.0f} sq ft wall + 10% |")
        else:
            out.append(f"| {sf * WASTE:.0f} sq ft | {kind.replace(' (sq ft)', '')} | {sf:.0f} sq ft + 10% |")
    out.append("")

    out.append("### Hardware & bought items\n")
    out.append("| Qty | Item |\n|---:|---|")
    for (tag, what), n in sorted(items.items()):
        out.append(f"| {n} | {what} |")
    out.append("")

    out.append("<details><summary>Cut list (every piece)</summary>\n")
    out.append("| Qty | Size | Cut length | Member |\n|---:|---|---|---|")
    for (nom, tag, L), n in sorted(by_tag.items()):
        out.append(f"| {n} | {nom} | {fmt_in(L)} | {tag} |")
    out.append("\n</details>")
    print("\n".join(out))


if __name__ == "__main__":
    main(sys.argv[1])
