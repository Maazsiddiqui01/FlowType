from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from PySide6.QtCore import QByteArray, QRectF
from PySide6.QtGui import QColor, QImage, QPainter
from PySide6.QtSvg import QSvgRenderer


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PACKAGE_BRANDING_DIR = PROJECT_ROOT / "src" / "flowtype" / "assets" / "branding"
BUILD_BRANDING_DIR = PROJECT_ROOT / "build" / "branding"
SOURCE_BRANDING_DIR = PROJECT_ROOT / "assets" / "branding"

CANVAS = 1024
BACKGROUND_TOP = "#21245C"
BACKGROUND_BOTTOM = "#342E8C"
BAR_FILL = "#F8FBFF"

BAR_SPECS = (
    (166, 188, 110, 654),
    (356, 272, 110, 492),
    (546, 412, 110, 208),
    (736, 330, 110, 372),
    (926, 188, 110, 654),
)

STATUS_COLORS = {
    "ready": "#29C3A9",
    "recording": "#F05A67",
    "processing": "#F7B955",
    "error": "#FB7185",
}


def main() -> int:
    logo_source = _resolve_logo_source()
    if logo_source is None:
        raise SystemExit("Missing branding source asset at assets/branding/logo-mark.svg or assets/branding/logo-mark.png")

    PACKAGE_BRANDING_DIR.mkdir(parents=True, exist_ok=True)
    BUILD_BRANDING_DIR.mkdir(parents=True, exist_ok=True)

    base_logo = _build_logo_image(CANVAS, logo_source)
    logo_mark_path = PACKAGE_BRANDING_DIR / "logo-mark.png"
    base_logo.save(logo_mark_path)
    base_logo.save(BUILD_BRANDING_DIR / "logo-mark.png")

    icon_master = _build_windows_icon_master(CANVAS)

    _build_icon(icon_master, PACKAGE_BRANDING_DIR / "app-icon.ico")
    _build_icon(icon_master, BUILD_BRANDING_DIR / "app-icon.ico")
    _build_wordmark(base_logo)
    _build_tray_icons(icon_master)
    _build_installer_art(base_logo)
    _build_release_preview(base_logo)
    return 0


def _build_logo_image(size: int, logo_source: Path) -> Image.Image:
    rendered = _render_logo_source(logo_source, size)
    if rendered is not None:
        return rendered
    return _build_logo_fallback_image(size)


def _build_logo_fallback_image(size: int) -> Image.Image:
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    background = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(background)
    _draw_vertical_gradient(bg_draw, size, size, BACKGROUND_TOP, BACKGROUND_BOTTOM)
    bg_draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.08), outline=(255, 255, 255, 20), width=2)
    base.alpha_composite(background)

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_radial_glow(glow, size, (int(size * 0.34), int(size * 0.48)), int(size * 0.24), "#8FD9FF", 90)
    _draw_radial_glow(glow, size, (int(size * 0.68), int(size * 0.54)), int(size * 0.28), "#BC7DFF", 90)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(size * 0.05)))
    base.alpha_composite(glow)

    bars_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bar_draw = ImageDraw.Draw(bars_layer)
    shadow_draw = ImageDraw.Draw(shadow)

    scale = size / CANVAS
    for x, y, width, height in BAR_SPECS:
        rect = (
            int(x * scale),
            int(y * scale),
            int((x + width) * scale),
            int((y + height) * scale),
        )
        radius = int((width * scale) / 2)
        shadow_draw.rounded_rectangle(rect, radius=radius, fill=(255, 255, 255, 90))
        bar_draw.rounded_rectangle(rect, radius=radius, fill=BAR_FILL)

    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(10, int(size * 0.018))))
    base.alpha_composite(shadow)
    base.alpha_composite(bars_layer)
    return base


def _resolve_logo_source() -> Path | None:
    svg_path = SOURCE_BRANDING_DIR / "logo-mark.svg"
    if svg_path.exists():
        return svg_path

    png_path = SOURCE_BRANDING_DIR / "logo-mark.png"
    if png_path.exists():
        return png_path
    return None


def _render_logo_source(logo_source: Path, size: int) -> Image.Image | None:
    suffix = logo_source.suffix.lower()
    if suffix == ".png":
        image = Image.open(logo_source).convert("RGBA")
        if image.size != (size, size):
            image = image.resize((size, size), Image.Resampling.LANCZOS)
        return image

    if suffix != ".svg":
        return None

    svg_data = logo_source.read_text(encoding="utf-8")
    renderer = QSvgRenderer(QByteArray(svg_data.encode("utf-8")))
    if not renderer.isValid():
        return None

    canvas = QImage(size, size, QImage.Format.Format_ARGB32)
    canvas.fill(QColor(0, 0, 0, 0))
    painter = QPainter(canvas)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
    painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform, True)
    renderer.render(painter, QRectF(0, 0, size, size))
    painter.end()

    return Image.frombuffer("RGBA", (size, size), bytes(canvas.bits()), "raw", "BGRA", 0, 1).copy()


def _build_icon(base_logo: Image.Image, destination: Path) -> None:
    sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    destination.parent.mkdir(parents=True, exist_ok=True)
    base_logo.save(destination, sizes=sizes)


def _build_windows_icon_master(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tile_margin = int(size * 0.115)
    tile_radius = int(size * 0.185)
    tile_rect = (tile_margin, tile_margin, size - tile_margin, size - tile_margin)

    tile_gradient = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gradient_draw = ImageDraw.Draw(tile_gradient)
    _draw_vertical_gradient(gradient_draw, size, size, "#15173F", "#2E2773")

    tile_mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(tile_mask)
    mask_draw.rounded_rectangle(tile_rect, radius=tile_radius, fill=255)
    canvas.paste(tile_gradient, (0, 0), tile_mask)

    ambient_glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    _draw_radial_glow(ambient_glow, size, (int(size * 0.34), int(size * 0.38)), int(size * 0.18), "#73C8FF", 52)
    _draw_radial_glow(ambient_glow, size, (int(size * 0.70), int(size * 0.64)), int(size * 0.21), "#A769FF", 64)
    ambient_glow = ambient_glow.filter(ImageFilter.GaussianBlur(radius=max(6, int(size * 0.02))))
    canvas.paste(ambient_glow, (0, 0), tile_mask)

    tile_details = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    details_draw = ImageDraw.Draw(tile_details)
    details_draw.rounded_rectangle(tile_rect, radius=tile_radius, outline=(255, 255, 255, 28), width=max(2, size // 160))
    details_draw.rounded_rectangle(
        (tile_rect[0] + 2, tile_rect[1] + 2, tile_rect[2] - 2, tile_rect[3] - 2),
        radius=max(0, tile_radius - 2),
        outline=(255, 255, 255, 10),
        width=max(1, size // 256),
    )
    canvas.alpha_composite(tile_details)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse(
        (
            int(size * 0.18),
            int(size * 0.12),
            int(size * 0.58),
            int(size * 0.44),
        ),
        fill=(255, 255, 255, 18),
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(radius=max(8, int(size * 0.03))))
    canvas.paste(highlight, (0, 0), tile_mask)

    usable_left = tile_rect[0] + int(size * 0.10)
    usable_top = tile_rect[1] + int(size * 0.14)
    usable_width = (tile_rect[2] - tile_rect[0]) - int(size * 0.20)
    usable_height = (tile_rect[3] - tile_rect[1]) - int(size * 0.28)

    bar_specs = (
        (0.00, 0.00, 0.13, 1.00),
        (0.22, 0.12, 0.13, 0.76),
        (0.44, 0.34, 0.13, 0.32),
        (0.66, 0.22, 0.13, 0.56),
        (0.87, 0.00, 0.13, 1.00),
    )

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    bars = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bars_draw = ImageDraw.Draw(bars)

    for left_ratio, top_ratio, width_ratio, height_ratio in bar_specs:
        left = int(usable_left + usable_width * left_ratio)
        top = int(usable_top + usable_height * top_ratio)
        width = int(usable_width * width_ratio)
        height = int(usable_height * height_ratio)
        rect = (left, top, left + width, top + height)
        radius = max(3, width // 2)
        shadow_draw.rounded_rectangle(rect, radius=radius, fill=(255, 255, 255, 78))
        bars_draw.rounded_rectangle(rect, radius=radius, fill=(249, 252, 255, 255))

    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(6, int(size * 0.018))))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(bars)
    return canvas


def _build_wordmark(base_logo: Image.Image) -> None:
    width = 1200
    height = 320
    image = Image.new("RGBA", (width, height), "#F6F9FC")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((0, 0, width - 1, height - 1), radius=52, fill="#F6F9FC", outline="#D9E6F1", width=2)

    mark = base_logo.resize((224, 224), Image.Resampling.LANCZOS)
    image.alpha_composite(mark, (24, 48))

    display_font = _load_font(102, bold=True)
    body_font = _load_font(34, bold=False)
    draw.text((292, 92), "FlowType", fill="#1E275F", font=display_font)
    draw.text((298, 210), "Local dictation for Windows", fill="#657A8D", font=body_font)

    image.save(PACKAGE_BRANDING_DIR / "wordmark.png")
    image.save(BUILD_BRANDING_DIR / "wordmark.png")


def _build_tray_icons(base_logo: Image.Image) -> None:
    for status, accent in STATUS_COLORS.items():
        tray = base_logo.resize((64, 64), Image.Resampling.LANCZOS)
        overlay = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        draw.ellipse((42, 42, 58, 58), fill=accent)
        draw.ellipse((39, 39, 61, 61), outline=(255, 255, 255, 180), width=2)
        tray.alpha_composite(overlay)
        tray.save(PACKAGE_BRANDING_DIR / f"tray-{status}.png")


def _build_installer_art(base_logo: Image.Image) -> None:
    small = Image.new("RGB", (164, 314), "#EEF4FF")
    small_draw = ImageDraw.Draw(small)
    small_draw.rounded_rectangle((0, 0, 163, 313), radius=18, fill="#EEF4FF")
    accent_band = Image.new("RGBA", (164, 314), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent_band)
    _draw_vertical_gradient(accent_draw, 164, 314, "#1E255F", "#4E46E5")
    accent_band = accent_band.filter(ImageFilter.GaussianBlur(radius=14))
    small.paste(accent_band.convert("RGB"), mask=accent_band.split()[-1])
    small_mark = base_logo.resize((108, 108), Image.Resampling.LANCZOS)
    small.paste(small_mark.convert("RGB"), (28, 28), small_mark)
    small_text = ImageDraw.Draw(small)
    small_text.text((26, 160), "FlowType", fill="#FFFFFF", font=_load_font(28, bold=True))
    small_text.text((26, 198), "Dictate locally.\nPaste instantly.", fill="#DEE7FF", font=_load_font(16))
    small.save(BUILD_BRANDING_DIR / "installer-small.bmp")

    wide = Image.new("RGB", (640, 314), "#F6F9FC")
    wide_draw = ImageDraw.Draw(wide)
    wide_draw.rounded_rectangle((0, 0, 639, 313), radius=20, fill="#F6F9FC")
    glow_panel = Image.new("RGBA", (640, 314), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_panel)
    _draw_vertical_gradient(glow_draw, 640, 314, "#21245C", "#4E46E5")
    glow_panel = glow_panel.filter(ImageFilter.GaussianBlur(radius=10))
    wide.paste(glow_panel.convert("RGB"), mask=glow_panel.split()[-1])
    wide_mark = base_logo.resize((184, 184), Image.Resampling.LANCZOS)
    wide.paste(wide_mark.convert("RGB"), (36, 64), wide_mark)
    wide_draw = ImageDraw.Draw(wide)
    wide_draw.text((246, 96), "FlowType", fill="#FFFFFF", font=_load_font(50, bold=True))
    wide_draw.text((248, 160), "Local dictation for Windows", fill="#DCE7FF", font=_load_font(24))
    wide_draw.text((248, 206), "Faster-Whisper locally. Cleanup with your own key. Paste anywhere.", fill="#ECF2FF", font=_load_font(18))
    wide.save(BUILD_BRANDING_DIR / "installer-wide.bmp")


def _build_release_preview(base_logo: Image.Image) -> None:
    preview = Image.new("RGBA", (1600, 900), "#F3F7FC")
    draw = ImageDraw.Draw(preview)
    draw.rounded_rectangle((32, 32, 1568, 868), radius=48, fill="#FFFFFF", outline="#DAE6F1", width=2)

    left_panel = Image.new("RGBA", (420, 900), (0, 0, 0, 0))
    left_draw = ImageDraw.Draw(left_panel)
    _draw_vertical_gradient(left_draw, 420, 900, "#20245B", "#4C45E3")
    left_panel = left_panel.filter(ImageFilter.GaussianBlur(radius=18))
    preview.alpha_composite(left_panel, (0, 0))
    preview.alpha_composite(base_logo.resize((180, 180), Image.Resampling.LANCZOS), (120, 102))

    draw = ImageDraw.Draw(preview)
    draw.text((490, 136), "FlowType Windows Beta", fill="#14253D", font=_load_font(56, bold=True))
    draw.text((492, 220), "Fast local dictation with optional cleanup and native paste.", fill="#5F7386", font=_load_font(24))
    draw.rounded_rectangle((488, 308, 1470, 726), radius=36, fill="#F8FBFF", outline="#D9E7F2", width=2)
    draw.text((540, 380), "Polished shell", fill="#14253D", font=_load_font(30, bold=True))
    draw.text((540, 430), "Runs as a tray-first Windows utility with branded icons,\nsingle-instance restore, startup-at-login, and first-run onboarding.", fill="#5F7386", font=_load_font(22))
    draw.text((540, 560), "Dictation loop", fill="#14253D", font=_load_font(30, bold=True))
    draw.text((540, 610), "Record -> transcribe locally -> optional cleanup -> paste.\nFalls back cleanly to raw transcript if cleanup fails.", fill="#5F7386", font=_load_font(22))
    preview.save(BUILD_BRANDING_DIR / "release-preview.png")


def _draw_vertical_gradient(draw: ImageDraw.ImageDraw, width: int, height: int, top_hex: str, bottom_hex: str) -> None:
    top = _hex_to_rgb(top_hex)
    bottom = _hex_to_rgb(bottom_hex)
    for y in range(height):
        mix = y / max(height - 1, 1)
        color = tuple(int(top[channel] + (bottom[channel] - top[channel]) * mix) for channel in range(3))
        draw.line((0, y, width, y), fill=color)


def _draw_radial_glow(base: Image.Image, canvas_size: int, center: tuple[int, int], radius: int, color_hex: str, alpha: int) -> None:
    glow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    red, green, blue = _hex_to_rgb(color_hex)
    glow_draw.ellipse(
        (center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius),
        fill=(red, green, blue, alpha),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=radius // 2))
    base.alpha_composite(glow)


def _hex_to_rgb(value: str) -> tuple[int, int, int]:
    normalized = value.lstrip("#")
    return tuple(int(normalized[index:index + 2], 16) for index in (0, 2, 4))


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


if __name__ == "__main__":
    raise SystemExit(main())
