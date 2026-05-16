#!/usr/bin/env python3
"""Generate docs/assets/hackify-demo.gif — the README hero animation.

requires Pillow (pip install Pillow>=10).

Usage: python3 scripts/gen-demo-gif.py [output_path]
Default output_path: docs/assets/hackify-demo.gif (relative to repo root cwd).
"""

import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

CANVAS_SIZE = (1200, 675)
BG_NAVY = "#0F1419"
PANEL_BG = "#1A2128"
PANEL_BORDER = "#2A3540"
TEXT_BRIGHT = "#E0E6ED"
TEXT_DIM = "#7A8A99"
TEXT_MUTED = "#5A6A79"
TILE_ACTIVE = "#2C3E55"
TILE_BORDER_ACTIVE = "#4A6FB5"
FRAME_COUNT = 7
FRAME_DURATION_MS = 600
PHASES = [
    (1, "Clarify", "batched wizard"),
    (2, "Plan", "hard gate"),
    (3, "Implement", "parallel waves"),
    (4, "Verify", "fresh evidence"),
    (5, "Review", "multi-reviewer"),
    (6, "Finish", "summary table"),
]

FONT_PATHS = [
    "/System/Library/Fonts/SFNSDisplay.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/Library/Fonts/Arial.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
]


def load_font(size: int) -> ImageFont.ImageFont:
    """Try common system fonts at the given size; fall back to default."""
    for path in FONT_PATHS:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


def _text_width(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> int:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def draw_header(draw: ImageDraw.ImageDraw) -> None:
    """Top region (y 0-170): title, subtitle, top-right badge."""
    draw.rounded_rectangle((30, 30, 1170, 170), radius=14, fill=PANEL_BG, outline=PANEL_BORDER, width=2)
    draw.text((50, 40), "Hackify", font=load_font(60), fill=TEXT_BRIGHT)
    subtitle = "One end-to-end dev workflow for every task in Claude Code"
    draw.text((50, 115), subtitle, font=load_font(22), fill=TEXT_DIM)
    badge_font = load_font(18)
    badge = "MIT  |  github.com/nadyshalaby/hackify"
    bw = _text_width(draw, badge, badge_font)
    draw.rounded_rectangle((1150 - bw - 20, 70, 1150, 105), radius=8, fill=BG_NAVY, outline=PANEL_BORDER, width=1)
    draw.text((1150 - bw - 10, 78), badge, font=badge_font, fill=TEXT_MUTED)


def _draw_tile(draw: ImageDraw.ImageDraw, x: int, active: bool) -> None:
    bg = TILE_ACTIVE if active else PANEL_BG
    border = TILE_BORDER_ACTIVE if active else PANEL_BORDER
    width = 2 if active else 1
    draw.rounded_rectangle((x, 200, x + 165, 390), radius=12, fill=bg, outline=border, width=width)


def _draw_tile_text(draw: ImageDraw.ImageDraw, x: int, phase: tuple) -> None:
    number_font = load_font(38)
    name_font = load_font(22)
    tag_font = load_font(14)
    num = str(phase[0])
    nw = _text_width(draw, num, number_font)
    draw.text((x + (165 - nw) // 2, 220), num, font=number_font, fill=TEXT_BRIGHT)
    name = phase[1]
    nmw = _text_width(draw, name, name_font)
    draw.text((x + (165 - nmw) // 2, 280), name, font=name_font, fill=TEXT_BRIGHT)
    tag = phase[2]
    tw = _text_width(draw, tag, tag_font)
    draw.text((x + (165 - tw) // 2, 325), tag, font=tag_font, fill=TEXT_DIM)


def draw_phase_tiles(draw: ImageDraw.ImageDraw, active_phase_index: int) -> None:
    """6 phase tiles in a row with arrow connectors; highlight active index."""
    arrow_font = load_font(20)
    for i, phase in enumerate(PHASES):
        x = 60 + i * (165 + 25)
        _draw_tile(draw, x, i == active_phase_index)
        _draw_tile_text(draw, x, phase)
        if i < 5:
            draw.text((x + 165 + 5, 285), ">", font=arrow_font, fill=TEXT_MUTED)


def draw_pipeline_and_caption(draw: ImageDraw.ImageDraw) -> None:
    """Pipeline text (y 440-470) and caption (y 480-510), both centered."""
    pipeline = "Clarify  >  Plan  >  Implement  >  Verify  >  Review  >  Finish"
    pipe_font = load_font(28)
    pw = _text_width(draw, pipeline, pipe_font)
    draw.text(((CANVAS_SIZE[0] - pw) // 2, 440), pipeline, font=pipe_font, fill=TEXT_BRIGHT)
    caption = "anchored to a single per-task markdown work-doc"
    cap_font = load_font(18)
    cw = _text_width(draw, caption, cap_font)
    draw.text(((CANVAS_SIZE[0] - cw) // 2, 485), caption, font=cap_font, fill=TEXT_DIM)


def draw_footer_panel(draw: ImageDraw.ImageDraw) -> None:
    """Footer panel (y 550-650) with install hint."""
    draw.rounded_rectangle((30, 550, 1170, 650), radius=14, fill=BG_NAVY, outline=PANEL_BORDER, width=2)
    draw.text((70, 585), "Install via Claude Code plugin marketplace", font=load_font(18), fill=TEXT_DIM)


def render_frame(active_phase_index: int) -> Image.Image:
    """Render one full 1200x675 frame; -1 means all tiles dimmed (settle)."""
    image = Image.new("RGB", CANVAS_SIZE, BG_NAVY)
    draw = ImageDraw.Draw(image)
    draw_header(draw)
    draw_phase_tiles(draw, active_phase_index)
    draw_pipeline_and_caption(draw)
    draw_footer_panel(draw)
    return image


def main(output_path: str = "docs/assets/hackify-demo.gif") -> None:
    """Build 7 frames (6 phase highlights + 1 settle) and save as animated GIF."""
    frames = [render_frame(i) for i in range(6)] + [render_frame(-1)]
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_DURATION_MS,
        loop=0,
        optimize=False,
    )
    print(
        f"Wrote {output_path}: {CANVAS_SIZE[0]}x{CANVAS_SIZE[1]}, "
        f"{FRAME_COUNT} frames @ {FRAME_DURATION_MS}ms, loop=infinite"
    )


if __name__ == "__main__":
    # Dev-only tool. The output path is trusted developer input — not a
    # CI entry point and never invoked on untrusted argv.
    output = sys.argv[1] if len(sys.argv) > 1 else "docs/assets/hackify-demo.gif"
    Path(output).parent.mkdir(parents=True, exist_ok=True)
    main(output)
