"""Generate launcher icons from vector spec (mirrors assets/icon/*.svg)."""
from PIL import Image, ImageDraw

SIZE = 1024
P, C, G, SW = 164, 200, 48, 24
XS = [P, P + C + G, P + 2 * (C + G)]  # [164, 412, 660]
YS = XS
CHECK_SMALL = [(460, 515), (505, 560), (570, 470)]
CHECK_LARGE = [(350, 540), (480, 670), (700, 390)]

BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
# Fully transparent ink: punches holes (used for the knocked-out check in
# the monochrome themed icon).
CLEAR = (0, 0, 0, 0)

def sc(v, s):
    return round(v * s / 1024)

def draw_grid(draw, s, stroke_color, fill_default, fill_center):
    sw = max(1, round(SW * s / 1024))
    half = sw / 2
    for r, y in enumerate(YS):
        for c, x in enumerate(XS):
            is_center = (r == 1 and c == 1)
            fill = fill_center if is_center else fill_default
            x0, y0 = sc(x, s), sc(y, s)
            x1, y1 = sc(x + C, s), sc(y + C, s)
            # simulate centered stroke: outer stroke-color rect, inner fill rect
            ox0 = round(x0 - half); oy0 = round(y0 - half)
            ox1 = round(x1 + half); oy1 = round(y1 + half)
            draw.rectangle([ox0, oy0, ox1, oy1], fill=stroke_color)
            draw.rectangle([x0, y0, x1, y1], fill=fill)

def draw_check(draw, s, points, width, color):
    w = max(1, round(width * s / 1024))
    pts = [(sc(x, s), sc(y, s)) for x, y in points]
    draw.line(pts, fill=color, width=w, joint="curve")
    # Fill elbow to avoid miter notch on sharp check angle (Pillow vs SVG miter)
    if len(pts) == 3:
        ex, ey = pts[1]
        r = w / 2
        draw.ellipse([ex - r, ey - r, ex + r, ey + r], fill=color)

def make_primary(s, bg=True):
    img = Image.new("RGBA", (s, s), BLACK if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    if bg:
        pass  # already black
    draw_grid(d, s, WHITE, BLACK, WHITE)
    draw_check(d, s, CHECK_SMALL, 32, BLACK)
    return img.convert("RGB") if bg else img

def make_inverted(s, bg=True):
    img = Image.new("RGBA", (s, s), WHITE if bg else (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_grid(d, s, BLACK, WHITE, BLACK)
    draw_check(d, s, CHECK_SMALL, 32, WHITE)
    return img.convert("RGB") if bg else img

def make_simplified(s):
    img = Image.new("RGBA", (s, s), WHITE)
    d = ImageDraw.Draw(img)
    d.rectangle([sc(64, s), sc(64, s), sc(960, s), sc(960, s)], fill=BLACK)
    d.rectangle([sc(184, s), sc(184, s), sc(840, s), sc(840, s)], fill=WHITE)
    draw_check(d, s, CHECK_LARGE, 110, BLACK)
    return img.convert("RGB")

def _knock_out_check(img, points, width):
    """Punch a transparent check out of `img` via a mask.

    Direct transparent-ink drawing is backend-dependent (Pillow may blend
    instead of replacing), so render the check shape to an L mask and clear
    those pixels explicitly. The elbow dot mirrors draw_check's joint fill.
    """
    s = img.width
    w = max(1, round(width * s / 1024))
    mask = Image.new("L", (s, s), 0)
    md = ImageDraw.Draw(mask)
    pts = [(sc(x, s), sc(y, s)) for x, y in points]
    md.line(pts, fill=255, width=w, joint="curve")
    ex, ey = pts[1]
    r = w / 2
    md.ellipse([ex - r, ey - r, ex + r, ey + r], fill=255)
    # alpha = alpha AND NOT mask
    alpha = img.getchannel("A")
    cleared = Image.composite(
        Image.new("L", (s, s), 0), alpha, mask,
    )
    img.putalpha(cleared)

def save(img, path):
    img.save(path, "PNG")
    print(f"wrote {path} {img.size}")

if __name__ == "__main__":
    import os
    root = os.path.dirname(os.path.abspath(__file__))
    save(make_primary(1024), os.path.join(root, "app_icon_primary-1024.png"))
    save(make_inverted(1024), os.path.join(root, "app_icon_inverted-1024.png"))
    save(make_simplified(1024), os.path.join(root, "app_icon_simplified-1024.png"))
    # Adaptive foregrounds (transparent, 432)
    save(make_primary(432, bg=False), os.path.join(root, "android_foreground-432.png"))
    save(make_inverted(432, bg=False), os.path.join(root, "android_foreground_inverted-432.png"))
    # Adaptive backgrounds (solid, 432)
    save(Image.new("RGB", (432, 432), (0, 0, 0)), os.path.join(root, "android_background-432.png"))
    save(Image.new("RGB", (432, 432), (255, 255, 255)), os.path.join(root, "android_background_inverted-432.png"))
    # Monochrome themed icon: single-color silhouette. Opaque = glyph (tinted
    # by the system), transparent = system background. The center cell stays
    # solid with the check knocked out as transparent so the mark survives
    # theming instead of vanishing into a solid box.
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    d = ImageDraw.Draw(mono)
    draw_grid(d, 432, BLACK, (0, 0, 0, 0), BLACK)
    _knock_out_check(mono, CHECK_SMALL, 32)
    save(mono, os.path.join(root, "android_monochrome-432.png"))
    # Favicons from simplified
    for sz in (16, 32, 48):
        save(make_simplified(sz), os.path.join(root, f"favicon-{sz}.png"))
