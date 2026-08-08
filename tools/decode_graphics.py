#!/usr/bin/env python3
"""Decode Hang-On (Europe) SMS compressed graphics streams and render contact sheets.

Replicates DecompressTiles / DecompressBitplane (ROM $078D/$079A):

Format (verified by byte-exact rebuild):
  DecompressTiles runs the bitplane decoder 4 times, advancing the destination
  base by +1 between passes; each pass writes at stride +4. Result:
    dest[4*r + p] = plane p, row r   (standard SMS 4bpp tile interleave)
  A tile is 32 bytes (8 rows x 4 planes).

  DecompressBitplane:
    while True:
        C = src[pos++]
        if C == 0: break              # end of this bitplane
        B = C & 0x7F
        if C & 0x80:                  # LITERAL run: B distinct source bytes
            emit src[pos..pos+B-1]; pos += B
        else:                         # RLE run: one source byte repeated B times
            emit src[pos] repeated B times; pos += 1

Call sites (source ROM -> destination):
  $3F00 -> VRAM $6000  (sprite/tile set, 200 tiles)
  $4E20 -> VRAM $4000  (tile patterns, 136 tiles)
  $5903 -> RAM $C700   (background tiles, 134 tiles)
  $63C1 -> VRAM $6C00  (title graphics, 85 tiles)

Usage: python tools/decode_graphics.py
Outputs PNGs + a JSON boundary report into build/graphics_decoded/.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ROM_PATH = ROOT / "build" / "hangon-europe.sms"
OUT_DIR = ROOT / "build" / "graphics_decoded"


def sms_color(byte: int) -> tuple[int, int, int]:
    """SMS colour byte -> RGB (bits: B0 G0 R0 B1 G1 R1)."""
    def comp(bits: int) -> int:
        return round(255 * (bits / 3))
    r = comp(((byte >> 2) & 1) | (((byte >> 5) & 1) << 1))
    g = comp(((byte >> 1) & 1) | (((byte >> 4) & 1) << 1))
    b = comp((byte & 1) | (((byte >> 3) & 1) << 1))
    return (r, g, b)


def decompress_stream(data: bytes, start: int) -> tuple[bytes, int]:
    """Decode a full DecompressTiles stream. Returns (output bytes, next pos)."""
    planes: list[list[int]] = []
    pos = start
    for _ in range(4):
        values: list[int] = []
        while True:
            c = data[pos]
            pos += 1
            if c == 0:
                break
            length = c & 0x7F
            if c & 0x80:
                # literal run
                values.extend(data[pos:pos + length])
                pos += length
            else:
                # RLE run: one byte repeated
                b = data[pos]
                pos += 1
                values.extend([b] * length)
        planes.append(values)
    n = max((len(p) for p in planes), default=0)
    out = bytearray(n * 4)
    for p, vals in enumerate(planes):
        for i, v in enumerate(vals):
            out[p + 4 * i] = v
    return bytes(out), pos


def render_tiles(data: bytes, path: Path, label: str,
                 tiles_per_row: int = 16, scale: int = 4,
                 palette: list[tuple[int, int, int]] | None = None) -> int:
    """Render 8x8 SMS 4bpp tiles (32 bytes each, plane-interleaved layout)."""
    if palette is None:
        palette = [sms_color(i) for i in range(16)]
    tile_bytes = 32
    ntiles = len(data) // tile_bytes
    if ntiles == 0:
        return 0
    cols = min(tiles_per_row, ntiles)
    rows = (ntiles + cols - 1) // cols
    cell = 8 * scale
    img = Image.new("RGB", (cols * cell, rows * cell), (0, 0, 0))
    dr = ImageDraw.Draw(img)
    for t in range(ntiles):
        tile = data[t * tile_bytes:(t + 1) * tile_bytes]
        x0 = (t % cols) * cell
        y0 = (t // cols) * cell
        for r in range(8):
            base = 4 * r
            row_planes = [tile[base + p] for p in range(4)]
            for c in range(8):
                mask = 1 << (7 - c)
                color = 0
                for p in range(4):
                    if row_planes[p] & mask:
                        color |= (1 << p)
                px = palette[color] if color < len(palette) else (255, 0, 255)
                dr.rectangle([x0 + c * scale, y0 + r * scale,
                              x0 + (c + 1) * scale - 1, y0 + (r + 1) * scale - 1],
                             fill=px)
    img.save(path)
    return ntiles


def decode_rom_palette(data: bytes) -> list[tuple[int, int, int]]:
    """Read the first stage palette bytes from $39B6 (10 CRAM colours)."""
    return [sms_color(b) for b in data[0x39b6:0x39c6]]


def main() -> int:
    rom = ROM_PATH.read_bytes()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    palette = decode_rom_palette(rom)

    streams = {
        "sprite_tiles_6000": 0x3F00,     # -> VRAM $6000  LoadInitialGraphics
        "tile_patterns_4000": 0x4E20,    # -> VRAM $4000  InitializeDisplay
        "background_tiles_ramtiles": 0x5903,  # -> RAMTiles $C700
        "title_graphics_6C00": 0x63C1,   # -> VRAM $6C00  SplashAndTitleScreen
    }
    report = {}
    for name, start in streams.items():
        out, end = decompress_stream(rom, start)
        ntiles = render_tiles(out, OUT_DIR / f"{name}.png", name,
                              palette=palette)
        report[name] = {
            "start": hex(start),
            "end_exclusive": hex(end),
            "size": len(out),
            "tiles": ntiles,
        }
        print(f"{name}: start={start:04X} end={end:04X} "
              f"decompressed={len(out)}B tiles={ntiles}")

    (OUT_DIR / "boundaries.json").write_text(json.dumps(report, indent=2))
    print(f"\nPalette(CRAM): {palette}")
    print(f"Wrote to {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
