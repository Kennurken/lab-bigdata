"""Render R console output (output.txt) as RStudio-style console screenshots."""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

def _load(size, bold=False):
    """Monospace font with Cyrillic support: macOS Menlo, Windows Consolas, Linux DejaVu Sans Mono."""
    candidates = [
        ("/System/Library/Fonts/Menlo.ttc", 1 if bold else 0),
        ("C:/Windows/Fonts/consolab.ttf" if bold else "C:/Windows/Fonts/consola.ttf", 0),
        ("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf" if bold
         else "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 0),
    ]
    for path, index in candidates:
        try:
            return ImageFont.truetype(path, size, index=index)
        except OSError:
            continue
    return ImageFont.load_default()


FONT = _load(15)
FONT_BOLD = _load(15, bold=True)
TITLE_FONT = _load(14)

BG = "#FFFFFF"
BAR = "#E8ECEF"
CODE = "#1F4E8C"
OUT = "#1C2430"
COMMENT = "#4A7A3A"
WARN = "#B4372B"
LINES_PER_PAGE = 46
WIDTH = 1180
LINE_H = 21
PAD = 18
BAR_H = 34
MAX_CHARS = 112


def wrap(line: str) -> list[str]:
    if len(line) <= MAX_CHARS:
        return [line]
    return [line[i:i + MAX_CHARS] for i in range(0, len(line), MAX_CHARS)]


def colour(line: str) -> tuple[str, ImageFont.FreeTypeFont]:
    if line.startswith(("> #", "# ")):
        return COMMENT, FONT
    if line.startswith(("> ", "+ ")):
        return CODE, FONT_BOLD
    if line.startswith(("Warning", "Error")):
        return WARN, FONT
    return OUT, FONT


def render(lines: list[str], title: str, out: Path) -> None:
    h = BAR_H + PAD * 2 + LINE_H * len(lines)
    img = Image.new("RGB", (WIDTH, h), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, WIDTH, BAR_H], fill=BAR)
    for i, c in enumerate(["#FF5F57", "#FEBC2E", "#28C840"]):
        d.ellipse([14 + i * 22, 11, 26 + i * 22, 23], fill=c)
    d.text((90, 9), title, font=TITLE_FONT, fill="#4B5563")
    y = BAR_H + PAD
    for line in lines:
        col, font = colour(line)
        d.text((PAD, y), line, font=font, fill=col)
        y += LINE_H
    img.save(out)


def main(lab_dir: str) -> None:
    lab = Path(lab_dir)
    raw = (lab / "output.txt").read_text(encoding="utf-8").splitlines()
    lines: list[str] = []
    for ln in raw:
        lines.extend(wrap(ln.replace("\t", "    ")))
    shots = lab / "screenshots"
    shots.mkdir(exist_ok=True)
    for old in shots.glob("console_*.png"):
        old.unlink()
    pages = [lines[i:i + LINES_PER_PAGE] for i in range(0, len(lines), LINES_PER_PAGE)]
    script = next(lab.glob("lab*.R")).name
    for n, page in enumerate(pages, 1):
        title = f"RStudio — Console ~/lab-bigdata/{lab.name}/  ({script}, {n}/{len(pages)})"
        render(page, title, shots / f"console_{n:02d}.png")
    print(f"{lab.name}: {len(pages)} console screenshots")


if __name__ == "__main__":
    for arg in sys.argv[1:]:
        main(arg)
