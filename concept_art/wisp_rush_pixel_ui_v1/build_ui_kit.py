"""Build a source-only pixel-art UI kit for Wisp Rush. No Godot files are touched."""
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
COMPONENTS = ROOT / "components"
PREVIEWS = ROOT / "previews"
GRID = 4
COMPONENTS.mkdir(parents=True, exist_ok=True)
PREVIEWS.mkdir(parents=True, exist_ok=True)

COLORS = {
    "void": "#0B1116", "shadow": "#070B0E", "panel": "#151E24",
    "panel_alt": "#1C272D", "stone_dark": "#263238", "stone": "#35434A",
    "stone_light": "#536064", "stone_edge": "#697473",
    "stitch_dark": "#604D40", "stitch": "#A78768",
    "ivory": "#E8CAA0", "ivory_light": "#FAE5C1",
    "amber_dark": "#8E552D", "amber": "#ECA255", "amber_light": "#FFD391",
    "cyan_dark": "#246B78", "cyan": "#63D7DF",
    "magenta_dark": "#6B397F", "magenta": "#B963CB",
    "muted": "#697273", "disabled": "#414B4F",
}
META = []


def color(name: str, alpha: int = 255):
    h = COLORS.get(name, name).lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def canvas(width: int, height: int):
    assert width % GRID == height % GRID == 0
    im = Image.new("RGBA", (width // GRID, height // GRID), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def polygon_box(draw, x0, y0, x1, y1, cut, fill):
    draw.polygon([(x0 + cut, y0), (x1 - cut, y0), (x1, y0 + cut),
                  (x1, y1 - cut), (x1 - cut, y1), (x0 + cut, y1),
                  (x0, y1 - cut), (x0, y0 + cut)], fill=fill)


def stitches(draw, x, y, tone="stitch"):
    ink = color(tone)
    draw.line((x, y, x + 4, y + 4), fill=ink, width=1)
    draw.line((x + 2, y - 1, x - 1, y + 2), fill=ink, width=1)
    draw.line((x + 5, y + 2, x + 2, y + 5), fill=ink, width=1)


def diamond(draw, cx, cy, radius, fill, shade=None):
    draw.polygon([(cx, cy - radius), (cx + radius, cy), (cx, cy + radius),
                  (cx - radius, cy)], fill=color(fill))
    if shade:
        draw.line((cx, cy - radius + 1, cx + radius - 1, cy), fill=color(shade), width=1)


def save(name, im, role, margins=None, content=None):
    big = im.resize((im.width * GRID, im.height * GRID), Image.Resampling.NEAREST)
    big.save(COMPONENTS / f"{name}.png", optimize=True)
    row = {"file": f"components/{name}.png", "role": role,
           "size_px": [big.width, big.height]}
    if margins:
        row["nine_slice_px"] = [n * GRID for n in margins]
    if content:
        row["content_inset_px"] = [n * GRID for n in content]
    META.append(row)


def button(name, width, height, tier, state):
    im, d = canvas(width, height)
    w, h = im.size
    pushed = 1 if state == "pressed" else 0
    disabled = state == "disabled"
    focus = state == "focus"
    hover = state == "hover"
    accent = ("muted" if disabled else "magenta" if tier == "selected"
              else "amber" if tier in ("primary", "danger") else "stitch")
    if focus:
        polygon_box(d, 1, 1, w - 2, h - 2, 5, color("cyan_dark"))
        polygon_box(d, 2, 2, w - 3, h - 3, 5, color("cyan"))
    y0 = 2 + pushed
    y1 = h - 3 + pushed
    polygon_box(d, 2, y0 + 2, w - 3, y1 + 1, 5, color("shadow"))
    polygon_box(d, 2, y0, w - 3, y1, 5, color("stone_dark" if not disabled else "disabled"))
    polygon_box(d, 3, y0 + 1, w - 4, y1 - 1, 4, color("stone_light" if hover else "stone" if not disabled else "muted"))
    polygon_box(d, 4, y0 + 2, w - 5, y1 - 2, 4, color("stitch_dark" if tier in ("primary", "danger") and not disabled else "stone_dark"))
    polygon_box(d, 5, y0 + 3, w - 6, y1 - 3, 3, color("panel_alt" if not pushed else "panel" , 245))
    d.line((8, y0 + 3, w - 9, y0 + 3), fill=color(accent), width=1)
    d.line((8, y1 - 3, w - 9, y1 - 3), fill=color("stitch_dark" if not disabled else "muted"), width=1)
    d.line((5, y0 + 7, 5, y1 - 7), fill=color("stone_edge" if not disabled else "muted"), width=1)
    d.line((w - 6, y0 + 7, w - 6, y1 - 7), fill=color("stone_edge" if not disabled else "muted"), width=1)
    diamond(d, 6, h // 2 + pushed, 2, accent, "ivory_light" if tier == "primary" and not disabled else None)
    diamond(d, w - 7, h // 2 + pushed, 2, accent, "ivory_light" if tier == "primary" and not disabled else None)
    if tier == "danger" and not disabled:
        d.point((7, y0 + 5), fill=color("amber_light"))
        d.point((w - 8, y0 + 5), fill=color("amber_light"))
    margins = (10, 9, 10, 9) if tier == "primary" else (9, 8, 9, 8)
    save(name, im, f"{tier} button {state}", margins, (10, 7, 10, 7))


def panel(name, width, height, mode):
    im, d = canvas(width, height)
    w, h = im.size
    selected = mode == "selected"
    locked = mode == "locked"
    crest = mode == "crest"
    accent = "magenta" if selected else "muted" if locked else "stitch"
    polygon_box(d, 1, 2, w - 2, h - 2, 4, color("shadow"))
    polygon_box(d, 1, 1, w - 2, h - 3, 4, color("stone_dark"))
    polygon_box(d, 2, 2, w - 3, h - 4, 3, color("stone_light" if selected else "stone"))
    polygon_box(d, 3, 3, w - 4, h - 5, 3, color("stitch_dark" if selected else "stone_dark"))
    polygon_box(d, 4, 4, w - 5, h - 6, 2, color("panel", 238))
    d.line((7, 3, w - 8, 3), fill=color(accent), width=1)
    d.line((7, h - 6, w - 8, h - 6), fill=color("stone_edge"), width=1)
    d.line((3, 8, 3, h - 10), fill=color("stone_edge"), width=1)
    d.line((w - 4, 8, w - 4, h - 10), fill=color("stitch_dark"), width=1)
    stitches(d, 6, 6, "stitch" if not locked else "muted")
    stitches(d, w - 12, h - 14, "stitch" if not locked else "muted")
    if crest:
        d.line((6, 13, 6, h - 16), fill=color("cyan_dark"), width=1)
        d.line((w - 7, 13, w - 7, h - 16), fill=color("cyan_dark"), width=1)
        diamond(d, 6, h // 2, 2, "cyan")
        diamond(d, w - 7, h // 2, 2, "cyan")
    if selected:
        diamond(d, 7, h // 2, 2, "magenta")
        diamond(d, w - 8, h // 2, 2, "magenta")
    save(name, im, f"{mode} panel", (8, 8, 8, 8), (8, 8, 8, 8))


def plate(name, width, height, accent="stitch", role="small value plate"):
    im, d = canvas(width, height)
    w, h = im.size
    polygon_box(d, 1, 2, w - 2, h - 2, 3, color("shadow"))
    polygon_box(d, 1, 1, w - 2, h - 3, 3, color("stone_dark"))
    polygon_box(d, 2, 2, w - 3, h - 4, 2, color("stone_edge"))
    polygon_box(d, 3, 3, w - 4, h - 5, 2, color("panel", 245))
    d.line((6, 2, w - 7, 2), fill=color(accent), width=1)
    d.line((6, h - 5, w - 7, h - 5), fill=color("stitch_dark"), width=1)
    diamond(d, 4, h // 2, 1, accent)
    diamond(d, w - 5, h // 2, 1, accent)
    vertical_margin = 3 if h <= 10 else 5
    save(name, im, role, (7, vertical_margin, 7, vertical_margin),
         (8, vertical_margin, 8, vertical_margin))


def slot(name, width, height, state):
    im, d = canvas(width, height)
    w, h = im.size
    accent = "magenta" if state == "selected" else "muted" if state == "disabled" else "stitch"
    polygon_box(d, 1, 2, w - 2, h - 2, 3, color("shadow"))
    polygon_box(d, 1, 1, w - 2, h - 3, 3, color("stone_dark"))
    polygon_box(d, 2, 2, w - 3, h - 4, 2, color("stone_light" if state == "selected" else "stone"))
    polygon_box(d, 4, 4, w - 5, h - 6, 1, color("panel", 240))
    d.line((5, 5, 9, 5), fill=color(accent), width=1)
    d.line((w - 10, 5, w - 6, 5), fill=color(accent), width=1)
    d.line((5, h - 8, 9, h - 8), fill=color(accent), width=1)
    d.line((w - 10, h - 8, w - 6, h - 8), fill=color(accent), width=1)
    save(name, im, f"{state} slot", (7, 7, 7, 7), (7, 7, 7, 7))


def tab(name, state):
    im, d = canvas(136, 64)
    w, h = im.size
    active = state == "active"
    accent = "amber" if active else "stitch_dark"
    polygon_box(d, 1, 2, w - 2, h - 2, 3, color("shadow"))
    polygon_box(d, 1, 1, w - 2, h - 3, 3, color("stone_dark"))
    polygon_box(d, 2, 2, w - 3, h - 4, 2, color("stone"))
    polygon_box(d, 3, 3, w - 4, h - 5, 2, color("panel_alt" if active else "panel", 245))
    d.line((8, 3, w - 9, 3), fill=color(accent), width=1)
    if active:
        d.line((8, h - 5, w - 9, h - 5), fill=color("amber_light"), width=1)
        diamond(d, 5, h // 2, 1, "cyan")
    save(name, im, f"tab {state}", (8, 5, 8, 5), (8, 4, 8, 4))


def caption_tile(name, state):
    im, d = canvas(140, 164)
    w, h = im.size
    disabled = state == "disabled"
    accent = "muted" if disabled else "cyan" if state == "focus" else "stitch"
    polygon_box(d, 1, 2, w - 2, h - 2, 4, color("shadow"))
    polygon_box(d, 1, 1, w - 2, h - 3, 4, color("stone_dark"))
    polygon_box(d, 2, 2, w - 3, h - 4, 3, color("stone_light" if state == "focus" else "stone"))
    polygon_box(d, 3, 3, w - 4, h - 5, 3, color("panel", 245))
    d.line((6, 4, w - 7, 4), fill=color(accent), width=1)
    d.line((6, 29, w - 7, 29), fill=color("stitch_dark" if not disabled else "muted"), width=1)
    d.line((6, 30, w - 7, 30), fill=color("stone_edge" if not disabled else "muted"), width=1)
    diamond(d, w // 2, 30, 2, accent)
    save(name, im, f"captioned Home tile {state}; icon above separator, text below", None, (4, 4, 4, 4))


def portrait_ring(name, selected):
    im, d = canvas(280, 280)
    w, h = im.size
    accent = "magenta" if selected else "stitch"
    polygon_box(d, 2, 3, w - 3, h - 3, 14, color("shadow"))
    polygon_box(d, 2, 2, w - 3, h - 4, 14, color("stone_dark"))
    polygon_box(d, 4, 4, w - 5, h - 6, 13, color("stone_light"))
    polygon_box(d, 6, 6, w - 7, h - 8, 12, color("stone_dark"))
    polygon_box(d, 8, 8, w - 9, h - 10, 11, (0, 0, 0, 0))
    for x,y in [(w//2,5),(w//2,h-7),(5,h//2),(w-6,h//2)]:
        diamond(d,x,y,3,accent)
        diamond(d,x,y,1,"ivory_light" if selected else "stitch")
    save(name, im, "transparent portrait ring" + (" selected" if selected else ""))


def bar(name, width, height, kind, tone):
    im, d = canvas(width, height)
    w, h = im.size
    slim = h <= 6
    cut = 1 if slim else 2
    if kind == "track":
        polygon_box(d, 1, 1, w - 2, h - 2, cut, color("shadow"))
        if slim:
            # Five logical pixels tall: reserve one complete interior row.
            d.rectangle((2, 2, w - 3, 2), fill=color("stone_edge"))
            d.line((4, 2, w - 5, 2), fill=color("void"), width=1)
        else:
            polygon_box(d, 2, 2, w - 3, h - 3, cut - 1, color("stone_edge"))
            polygon_box(d, 3, 3, w - 4, h - 4, 0, color("void"))
            d.line((5, 2, w - 6, 2), fill=color("stitch"), width=1)
    else:
        polygon_box(d, 1, 1, w - 2, h - 2, cut, color(tone))
        d.line((4, 2, w - 5, 2), fill=color("ivory_light" if tone == "ivory" else "amber_light" if tone == "amber" else tone), width=1)
    margins = (4, 2, 4, 2) if slim else (5, 3, 5, 3)
    save(name, im, f"{tone} {kind} bar", margins)


def misc():
    im,d=canvas(128,16); d.line((1,2,30,2),fill=color("stitch_dark"),width=1); d.line((1,3,30,3),fill=color("stone_edge"),width=1); diamond(d,16,2,1,"stitch"); save("divider",im,"stone seam divider",(4,1,4,1))
    for state,tone in [("idle","stitch"),("active","amber"),("locked","muted")]:
        im,d=canvas(24,24);diamond(d,3,3,2,"stone_dark");diamond(d,3,3,1,tone);save("page_diamond_"+state,im,"carousel page diamond "+state)
    for state,tone in [("idle","stitch"),("active","amber"),("disabled","muted")]:
        im,d=canvas(60,60);diamond(d,7,7,7,"shadow");diamond(d,7,7,6,"stone");diamond(d,7,7,4,tone);diamond(d,7,7,2,"ivory_light" if state=="active" else "panel");save("slider_grabber_"+state,im,"slider grabber "+state)
    im,d=canvas(48,48);diamond(d,6,6,5,"shadow");diamond(d,6,6,4,"stone");diamond(d,6,6,3,"panel");save("hud_health_socket",im,"Soul Fragment socket")
    im,d=canvas(48,48);diamond(d,6,6,5,"shadow");diamond(d,6,6,4,"stitch_dark");diamond(d,6,6,3,"amber");diamond(d,6,5,1,"ivory_light");save("hud_health_full",im,"filled Soul Fragment")
    for state,tone in [("warm","amber"),("cyan","cyan")]:
        im,d=canvas(48,48);diamond(d,6,6,5,"shadow");diamond(d,6,6,4,"stone");diamond(d,6,6,2,tone);diamond(d,6,5,1,"ivory_light");save("ornament_diamond_"+state,im,"separate edge ornament "+state)
    im,d=canvas(48,48);stitches(d,3,3);stitches(d,7,7,"stitch_dark");save("ornament_stitches",im,"separate stitched repair ornament")


def glyph(name, design, tone="ivory"):
    im,d=canvas(64,64)
    c=color(tone); hi=color("ivory_light"); dark=color("stitch_dark")
    # Distinct, label-free silhouettes sized for a 64 px icon box.
    if design=="play": d.polygon([(5,3),(13,8),(5,13)],fill=c);d.line((5,3,5,13),fill=dark,width=1)
    elif design=="pause": d.rectangle((4,3,6,13),fill=c);d.rectangle((10,3,12,13),fill=c)
    elif design=="back": d.polygon([(3,8),(9,2),(9,5),(13,5),(13,11),(9,11),(9,14)],fill=c);d.rectangle((7,7,13,9),fill=c)
    elif design=="home": d.polygon([(2,7),(8,2),(14,7),(12,7),(12,14),(4,14),(4,7)],fill=c);d.rectangle((7,9,9,14),fill=color("void"))
    elif design=="lock": d.rectangle((4,7,12,14),fill=c);d.line((5,7,5,4,7,2,9,2,11,4,11,7),fill=c,width=2);d.point((8,10),fill=color("void"))
    elif design=="settings":
        d.polygon([(7,1),(9,1),(10,4),(13,3),(15,6),(12,8),(15,10),(13,13),(10,12),(9,15),(7,15),(6,12),(3,13),(1,10),(4,8),(1,6),(3,3),(6,4)],fill=c);d.ellipse((6,6,10,10),fill=color("void"))
    elif design=="shop": d.rectangle((3,6,13,14),fill=c);d.line((5,6,5,3,11,3,11,6),fill=c,width=2);d.rectangle((5,8,11,12),fill=color("panel"))
    elif design=="trials": d.polygon([(8,1),(10,6),(15,6),(11,9),(13,15),(8,12),(3,15),(5,9),(1,6),(6,6)],fill=c)
    elif design=="daily": d.ellipse((5,5,11,11),fill=c);d.line((8,0,8,3),fill=c,width=1);d.line((8,13,8,15),fill=c,width=1);d.line((0,8,3,8),fill=c,width=1);d.line((13,8,15,8),fill=c,width=1)
    elif design=="stats": d.line((2,14,14,14),fill=c,width=1);d.rectangle((3,9,5,13),fill=c);d.rectangle((7,6,9,13),fill=c);d.rectangle((11,3,13,13),fill=c)
    elif design=="rift": d.ellipse((2,2,14,14),outline=c,width=2);d.polygon([(8,4),(11,8),(8,12),(5,8)],fill=color("cyan"));d.point((8,8),fill=hi)
    elif design=="currency": diamond(d,8,8,7,"stitch_dark");diamond(d,8,8,5,tone);diamond(d,8,7,2,"ivory_light")
    elif design=="health": d.polygon([(8,14),(2,8),(2,4),(5,2),(8,5),(11,2),(14,4),(14,8)],fill=c);d.point((5,5),fill=hi)
    elif design=="audio": d.polygon([(2,6),(5,6),(9,3),(9,13),(5,10),(2,10)],fill=c);d.arc((7,3,14,13),290,70,fill=c,width=2)
    elif design=="mute": d.polygon([(2,6),(5,6),(9,3),(9,13),(5,10),(2,10)],fill=c);d.line((11,5,15,11),fill=color("amber"),width=2)
    elif design=="close": d.line((3,3,13,13),fill=c,width=3);d.line((13,3,3,13),fill=c,width=3)
    save("icon_"+name,im,"text-free "+name+" glyph")


def build():
    for tier,wh in [("primary",(120,112)),("secondary",(112,96))]:
        for state in ("normal","hover","focus","pressed","disabled"):
            button(f"button_{tier}_{state}",*wh,tier,state)
    for state in ("normal","pressed"):
        button(f"button_danger_{state}",112,96,"danger",state)
    for state in ("normal","focus","disabled"):
        button(f"icon_tile_{state}",112,112,"secondary",state)
    for name,w,h,mode in [("panel_default",128,128,"default"),("panel_card",188,252,"card"),
                          ("panel_card_selected",188,252,"selected"),("panel_card_locked",188,252,"locked"),
                          ("panel_crest",196,308,"crest"),("panel_banner",144,96,"banner")]:
        panel(name,w,h,mode)
    plate("plate_small",128,64)
    plate("hud_counter_plate",160,64,"stitch","score, currency, or wave plate")
    plate("hud_alert_plate",160,64,"amber","warning or landmark plate")
    slot("slot_normal",116,120,"normal");slot("slot_selected",116,120,"selected")
    slot("slot_disabled",116,120,"disabled");slot("slot_small",60,60,"normal")
    tab("tab_normal","normal");tab("tab_active","active")
    for state in ("normal", "focus", "disabled"):
        caption_tile("caption_tile_"+state, state)
    portrait_ring("portrait_ring", False)
    portrait_ring("portrait_ring_selected", True)
    panel("nav_dock", 480, 88, "navigation dock")
    plate("badge_plate_warm",96,40,"amber","text-free reward or NEW badge frame")
    plate("badge_plate_muted",96,40,"muted","text-free locked badge frame")
    for name,w,h,kind,tone in [("progress_track",96,40,"track","stone"),
                                ("progress_fill_xp",96,40,"fill","cyan"),
                                ("progress_fill_boss",96,40,"fill","magenta"),
                                ("progress_fill_reward",96,40,"fill","amber"),
                                ("hud_slim_track",96,20,"track","stone"),
                                ("hud_slim_fill_xp",96,20,"fill","cyan"),
                                ("hud_slim_fill_rush",96,20,"fill","ivory"),
                                ("hud_slim_fill_boss",96,20,"fill","magenta")]:
        bar(name,w,h,kind,tone)
    misc()
    for name,tone in [("play","ivory_light"),("pause","ivory"),("back","ivory"),
                      ("home","ivory"),("lock","stitch"),("settings","ivory"),
                      ("shop","ivory"),("trials","ivory"),("daily","amber"),
                      ("stats","ivory"),("rift","cyan"),("currency","amber"),
                      ("health","amber"),("audio","ivory"),("mute","muted"),
                      ("close","ivory")]:
        glyph(name,name,tone)
    manifest={"status":"source_only_not_integrated","grid_px":GRID,
              "palette":COLORS,"components":META,
              "nine_slice_order":"left,top,right,bottom"}
    (ROOT/"components.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print(f"generated {len(META)} text-free components")


if __name__ == "__main__":
    build()
