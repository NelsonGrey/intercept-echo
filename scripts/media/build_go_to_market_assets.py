#!/usr/bin/env python3
"""Build upload-ready Intercept Echo App Store and social launch artwork."""

from __future__ import annotations

import csv
import hashlib
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
CAPTURES = ROOT / "packages/mobile/output/gameplay-capture-2026-09-30/curated-screenshots"
SITE_ASSETS = Path("/Users/marknelson/Circus/Repositories/nelson-grey/games/intercept-echo/assets")
OUTPUT = ROOT / "packages/mobile/output/go-to-market-2026-10-02"
STORE = ROOT / "packages/mobile/ios/fastlane/screenshots/en-US"

NAVY = "#071322"
NAVY_DARK = "#040b14"
PANEL = "#0c1b2e"
CREAM = "#f8f3e8"
BLUE = "#9dacbf"
LINE = "#233a55"
AMBER = "#ffb44d"
AMBER_SOFT = "#ffd089"

FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_MONO = "/System/Library/Fonts/SFNSMono.ttf"


def font(size: int, *, bold: bool = False, mono: bool = False) -> ImageFont.FreeTypeFont:
    path = FONT_MONO if mono else (FONT_BOLD if bold else FONT_REGULAR)
    return ImageFont.truetype(path, size)


def fit_inside(image: Image.Image, box: tuple[int, int]) -> Image.Image:
    image = image.copy()
    image.thumbnail(box, Image.Resampling.LANCZOS)
    return image


def crop_fill(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_ratio = size[0] / size[1]
    ratio = image.width / image.height
    if ratio > target_ratio:
        width = round(image.height * target_ratio)
        left = (image.width - width) // 2
        image = image.crop((left, 0, left + width, image.height))
    else:
        height = round(image.width / target_ratio)
        top = (image.height - height) // 2
        image = image.crop((0, top, image.width, top + height))
    return image.resize(size, Image.Resampling.LANCZOS)


def radar_background(size: tuple[int, int], focus: tuple[float, float] = (0.72, 0.42)) -> Image.Image:
    w, h = size
    base = Image.new("RGB", size, NAVY)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    spacing = max(44, min(w, h) // 16)
    for x in range(0, w + 1, spacing):
        draw.line((x, 0, x, h), fill=(157, 172, 191, 13), width=1)
    for y in range(0, h + 1, spacing):
        draw.line((0, y, w, y), fill=(157, 172, 191, 13), width=1)
    cx, cy = int(w * focus[0]), int(h * focus[1])
    for radius in range(spacing * 2, max(w, h), spacing * 2):
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), outline=(75, 105, 140, 48), width=2)
    draw.line((0, cy, w, cy), fill=(255, 180, 77, 52), width=2)
    for x in range(spacing, w, spacing * 2):
        draw.ellipse((x - 3, cy - 3, x + 3, cy + 3), fill=(255, 180, 77, 96))
    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    r = int(min(w, h) * 0.42)
    gd.ellipse((cx-r, cy-r, cx+r, cy+r), fill=(45, 99, 150, 54))
    glow = glow.filter(ImageFilter.GaussianBlur(max(40, r // 2)))
    composed = Image.alpha_composite(base.convert("RGBA"), glow)
    composed = Image.alpha_composite(composed, overlay)
    return composed.convert("RGB")


def draw_tracking(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt: ImageFont.FreeTypeFont,
                  fill: str, tracking: int = 5, anchor: str = "la") -> None:
    widths = [draw.textlength(ch, font=fnt) for ch in text]
    total = sum(widths) + tracking * max(0, len(text) - 1)
    x, y = xy
    if anchor.startswith("m"):
        x -= total / 2
    elif anchor.startswith("r"):
        x -= total
    for ch, width in zip(text, widths):
        draw.text((round(x), y), ch, font=fnt, fill=fill, anchor="la")
        x += width + tracking


def draw_label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int) -> None:
    x, y = xy
    draw.line((x, y + size // 2, x + size * 2, y + size // 2), fill=AMBER, width=max(2, size // 14))
    draw_tracking(draw, (x + size * 3, y), text.upper(), font(size, bold=True), AMBER, max(2, size // 5))


def draw_multiline(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, fnt: ImageFont.FreeTypeFont,
                   fill: str, max_width: int, spacing: int = 12, anchor: str = "la") -> tuple[int, int, int, int]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if current and draw.textlength(candidate, font=fnt) > max_width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    rendered = "\n".join(lines)
    draw.multiline_text(xy, rendered, font=fnt, fill=fill, spacing=spacing, anchor=anchor)
    return draw.multiline_textbbox(xy, rendered, font=fnt, spacing=spacing, anchor=anchor)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def paste_phone(canvas: Image.Image, screen: Image.Image, box: tuple[int, int, int, int], *, angle: float = 0,
                shadow: bool = True) -> None:
    x, y, w, h = box
    screen = crop_fill(screen, (w, h))
    radius = max(26, w // 12)
    bezel = max(7, w // 55)
    device = Image.new("RGBA", (w + bezel * 2, h + bezel * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(device)
    d.rounded_rectangle((0, 0, device.width - 1, device.height - 1), radius=radius + bezel,
                        fill="#02070d", outline="#526a86", width=max(2, bezel // 2))
    mask = rounded_mask((w, h), radius)
    device.paste(screen.convert("RGBA"), (bezel, bezel), mask)
    if angle:
        device = device.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
    px = x - (device.width - w) // 2
    py = y - (device.height - h) // 2
    if shadow:
        sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        sd.rounded_rectangle((px + 20, py + 30, px + device.width + 20, py + device.height + 30),
                             radius=radius, fill=(0, 0, 0, 165))
        sh = sh.filter(ImageFilter.GaussianBlur(max(18, w // 18)))
        canvas.alpha_composite(sh)
    canvas.alpha_composite(device, (px, py))


def load_capture(name: str) -> Image.Image:
    return Image.open(CAPTURES / name).convert("RGB")


def save_rgb(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(path, "PNG", optimize=True)


def build_store_screens() -> list[Path]:
    # App Store Connect requests the 6.5-inch screenshot class for this
    # listing. The authentic iPhone captures remain at their native 1206x2622
    # under app-store/raw-native-iphone; promotional panels are composed at
    # the accepted 1242x2688 portrait size shown by App Store Connect.
    store_size = (1242, 2688)
    specs = [
        ("01-crack-the-transmission.png", "CRACK THE TRANSMISSION", "Every bit is a clue.", "02-transmission-board.png"),
        ("02-master-eight-bits.png", "MASTER EIGHT BITS", "Turn visible bits into exact values.", "03-crack-the-letter.png"),
        ("03-solve-efficiently.png", "SOLVE EFFICIENTLY", "Find the shortest route through the noise.", "04-letter-cracked.png"),
        ("04-read-the-signal.png", "READ THE SIGNAL", "Each solved puzzle reveals a letter.", "05-guess-the-message.png"),
        ("05-take-the-risk.png", "TAKE THE RISK", "Guess early for a bigger score.", "06-message-decoded.png"),
        ("06-chase-the-next-echo.png", "CHASE THE NEXT ECHO", "Twelve transmissions. Three difficulties.", "07-transmission-results.png"),
    ]
    built: list[Path] = []
    for filename, label, headline, capture in specs:
        canvas = radar_background(store_size, (0.5, 0.68)).convert("RGBA")
        draw = ImageDraw.Draw(canvas)
        draw_label(draw, (87, 98), label, 25)
        draw_multiline(draw, (87, 212), headline, font(83, bold=True), CREAM, 1068, spacing=14)
        draw.text((89, 450), "COUNT  •  SHIFT  •  ROTATE", font=font(23, bold=True, mono=True), fill=BLUE)
        paste_phone(canvas, load_capture(capture), (222, 600, 798, 1735), shadow=True)
        draw.rounded_rectangle((87, 2484, 1062, 2488), radius=2, fill=LINE)
        draw_tracking(draw, (87, 2535), "INTERCEPT ECHO", font(30, bold=True), CREAM, 9)
        draw.text((1153, 2531), "iOS", font=font(27, bold=True), fill=AMBER, anchor="ra")
        fastlane_path = STORE / filename
        package_path = OUTPUT / "app-store" / "6.5-inch-1242x2688" / filename
        save_rgb(canvas, fastlane_path)
        save_rgb(canvas, package_path)
        built.extend((fastlane_path, package_path))
    return built


CAMPAIGNS = [
    ("every-bit", "SIGNAL ACQUIRED", "Every bit is a clue.", "Count. Shift. Rotate.", "03-crack-the-letter.png"),
    ("crack-message", "INTERCEPT CAMPAIGN", "Crack the transmission.", "Solve each letter. Read the signal.", "02-transmission-board.png"),
    ("guess-early", "RISK / REWARD", "Think you know it?", "Guess early. Score bigger.", "06-message-decoded.png"),
    ("exact-logic", "NO RANDOM OUTCOMES", "Compact rules. Real mastery.", "Every move is visible. Every solution is yours.", "07-transmission-results.png"),
]


def social_card(size: tuple[int, int], campaign: tuple[str, str, str, str, str]) -> Image.Image:
    _, label, headline, subhead, capture_name = campaign
    w, h = size
    landscape = w / h > 1.25
    squareish = 0.85 <= w / h <= 1.25
    canvas = radar_background(size, (0.74 if landscape else 0.5, 0.52)).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    margin = max(48, int(min(w, h) * 0.065))
    label_size = max(18, int(min(w, h) * 0.024))
    head_size = max(52, int(min(w, h) * (0.072 if landscape else 0.066)))
    body_size = max(24, int(min(w, h) * 0.028))
    draw_label(draw, (margin, margin), label, label_size)
    screen = load_capture(capture_name)
    if landscape:
        copy_w = int(w * 0.50)
        headline_box = draw_multiline(draw, (margin, int(h * 0.26)), headline, font(head_size, bold=True), CREAM,
                                      copy_w, spacing=8)
        subhead_y = max(int(h * 0.61), headline_box[3] + body_size)
        draw_multiline(draw, (margin, subhead_y), subhead, font(body_size), BLUE, copy_w, spacing=8)
        pw = int(h * 0.44)
        ph = int(pw * 2.174)
        paste_phone(canvas, screen, (int(w * 0.70), int(h * 0.05), pw, ph), angle=2)
    else:
        copy_width = w - margin * 2
        headline_box = draw_multiline(draw, (margin, int(h * 0.12)), headline, font(head_size, bold=True), CREAM,
                                      copy_width, spacing=8)
        subhead_y = max(int(h * 0.25), headline_box[3] + body_size)
        draw_multiline(draw, (margin, subhead_y), subhead, font(body_size), BLUE, copy_width, spacing=8)
        pw = int(w * (0.48 if squareish else 0.58))
        ph = int(pw * 2.174)
        phone_y = int(h * (0.40 if squareish else 0.36))
        paste_phone(canvas, screen, ((w - pw) // 2, phone_y, pw, ph), angle=1.5)
    footer_top = h - margin - int(body_size * 1.8)
    draw.rectangle((0, footer_top, w, h), fill=NAVY_DARK)
    draw.line((0, footer_top, w, footer_top), fill=LINE, width=max(1, body_size // 12))
    draw_tracking(draw, (margin, h - margin - body_size), "INTERCEPT ECHO", font(body_size, bold=True), CREAM,
                  max(3, body_size // 4))
    return canvas


def build_social_campaigns() -> list[Path]:
    formats = {
        "square-1080x1080": (1080, 1080),
        "portrait-1080x1350": (1080, 1350),
        "story-1080x1920": (1080, 1920),
        "landscape-1200x675": (1200, 675),
    }
    built: list[Path] = []
    for campaign in CAMPAIGNS:
        slug = campaign[0]
        for fmt, size in formats.items():
            path = OUTPUT / "social" / "campaigns" / slug / f"intercept-echo-{slug}-{fmt}.png"
            save_rgb(social_card(size, campaign), path)
            built.append(path)
    return built


def banner(size: tuple[int, int], headline: str, subhead: str, *, safe_width: int | None = None) -> Image.Image:
    w, h = size
    canvas = radar_background(size, (0.78, 0.5)).convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    safe_width = safe_width or w
    left = (w - safe_width) // 2
    margin = max(32, int(h * 0.10))
    label_size = max(15, int(h * 0.046))
    headline_size = max(36, int(h * 0.15))
    body_size = max(19, int(h * 0.061))
    draw_label(draw, (left + margin, margin), "SIGNAL ACQUIRED / iOS", label_size)
    copy_width = int(safe_width * 0.56)
    draw_multiline(draw, (left + margin, int(h * 0.31)), headline, font(headline_size, bold=True), CREAM,
                   copy_width, spacing=6)
    draw_multiline(draw, (left + margin, int(h * 0.72)), subhead, font(body_size), BLUE, copy_width, spacing=5)
    screen = load_capture("03-crack-the-letter.png")
    phone_h = int(h * 1.38)
    phone_w = int(phone_h / 2.174)
    paste_phone(canvas, screen, (left + int(safe_width * 0.74), -int(h * 0.18), phone_w, phone_h), angle=2)
    return canvas


def build_headers() -> list[Path]:
    specs = [
        ("general/intercept-echo-launch-banner-2400x1200.png", (2400, 1200), None),
        ("x/intercept-echo-x-header-1500x500.png", (1500, 500), None),
        ("facebook/intercept-echo-facebook-cover-1640x624.png", (1640, 624), None),
        ("linkedin/intercept-echo-linkedin-cover-1128x191.png", (1128, 191), None),
        ("bluesky/intercept-echo-bluesky-header-1500x500.png", (1500, 500), None),
        ("youtube/intercept-echo-youtube-banner-2560x1440.png", (2560, 1440), 1546),
    ]
    built: list[Path] = []
    for relative, size, safe in specs:
        path = OUTPUT / "social" / "headers" / relative
        save_rgb(banner(size, "Every bit is a clue.", "Count. Shift. Rotate. Crack the transmission.", safe_width=safe), path)
        built.append(path)
    return built


def build_profile_assets() -> list[Path]:
    icon = Image.open(SITE_ASSETS / "app-icon-512.png").convert("RGB")
    mark = Image.open(SITE_ASSETS / "mark.png").convert("RGBA")
    built: list[Path] = []
    for filename, source in [("intercept-echo-profile-icon-1024.png", icon), ("intercept-echo-mark-transparent-1024.png", mark)]:
        path = OUTPUT / "social" / "profile" / filename
        resized = source.resize((1024, 1024), Image.Resampling.LANCZOS)
        path.parent.mkdir(parents=True, exist_ok=True)
        resized.save(path, "PNG", optimize=True)
        built.append(path)
    return built


def build_iap_promotional_image() -> list[Path]:
    """Build the App Store promotional image for the Remove Ads IAP."""
    size = (1024, 1024)
    canvas = radar_background(size, (0.5, 0.47)).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # Product signal: an uninterrupted amber waveform inside a crisp frame.
    frame = (222, 214, 802, 672)
    draw.rectangle(frame, fill=PANEL, outline="#526a86", width=4)
    draw.line((272, 443, 752, 443), fill=(255, 180, 77, 90), width=2)
    bar_width = 52
    gap = 34
    heights = [118, 190, 270, 350, 270, 190]
    total = len(heights) * bar_width + (len(heights) - 1) * gap
    x = (1024 - total) // 2
    baseline = 596
    for height in heights:
        draw.rounded_rectangle((x, baseline - height, x + bar_width, baseline), radius=18, fill=AMBER)
        x += bar_width + gap

    # A small confirmation badge communicates that interruptions are removed.
    draw.ellipse((719, 190, 815, 286), fill="#63d6ad", outline=NAVY_DARK, width=8)
    draw.line((744, 239, 762, 257), fill=NAVY_DARK, width=10)
    draw.line((761, 257, 792, 220), fill=NAVY_DARK, width=10)

    draw_tracking(draw, (512, 760), "REMOVE ADS", font(60, bold=True), CREAM, 12, anchor="ma")
    draw_tracking(draw, (512, 846), "CLEAR SIGNAL", font(28, bold=True), AMBER, 9, anchor="ma")
    draw.text((512, 914), "ONE-TIME UPGRADE", font=font(24, bold=True), fill=BLUE, anchor="ma")

    path = OUTPUT / "app-store" / "in-app-purchase" / "remove-ads-1024x1024.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(path, "PNG", optimize=True, dpi=(72, 72))
    return [path]


def build_raw_store_sources() -> list[Path]:
    built: list[Path] = []
    for source in sorted(CAPTURES.glob("*.png")):
        path = OUTPUT / "app-store" / "raw-native-iphone" / source.name
        save_rgb(Image.open(source), path)
        built.append(path)
    return built


def write_manifest(paths: list[Path]) -> None:
    manifest = OUTPUT / "ASSET_MANIFEST.csv"
    manifest.parent.mkdir(parents=True, exist_ok=True)
    with manifest.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["path", "width", "height", "mode", "bytes", "sha256"])
        for path in sorted(paths):
            with Image.open(path) as image:
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                try:
                    relative = path.relative_to(ROOT)
                except ValueError:
                    relative = path
                writer.writerow([relative, image.width, image.height, image.mode, path.stat().st_size, digest])


def main() -> None:
    paths: list[Path] = []
    paths.extend(build_store_screens())
    paths.extend(build_raw_store_sources())
    paths.extend(build_social_campaigns())
    paths.extend(build_headers())
    paths.extend(build_profile_assets())
    paths.extend(build_iap_promotional_image())
    for existing in OUTPUT.rglob("*.png"):
        if existing not in paths:
            paths.append(existing)
    write_manifest(paths)
    print(f"Built {len(paths)} PNG assets")
    print(f"Store screenshots: {STORE}")
    print(f"Launch and social package: {OUTPUT}")


if __name__ == "__main__":
    main()
