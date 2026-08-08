#!/usr/bin/env python3
"""Split the 3E79-7116 container into meaningful sub-assets.

The container holds several distinct resources whose section starts are
structurally confirmed by code references:
  $3E79-$3F00  padding (FF)
  $3F00-$4E20  compressed sprite/tile set   -> VRAM $6000
  $4E20-$5903  compressed tile patterns     -> VRAM $4000
  $5903-$63C1  compressed background tiles  -> RAM $C700
  $63C1-$670D  compressed title graphics    -> VRAM $6C00
  $670D-$6D55  course data (ptr table + layouts)
  $6D55-$7055  background scroll tilemap
  $7055-$7116  road tilemap

The exact END of each compressed stream within its section is pending the
custom decompression format (DecompressTiles $078D) — the sections are the
confirmed stream STARTS, so a section may include trailing bytes of the
previous stream. See docs/ASSET_RENAME_PLAN.md.

After splitting, updates src/hangon_europe.asm (replace the single .incbin
with one .incbin per sub-asset) and docs/assets.csv, then re-verifies build.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = ROOT / "assets"
ASM = ROOT / "src" / "hangon_europe.asm"
CSV = ROOT / "docs" / "assets.csv"

# (offset_from_container_start, name) - contiguous slices of the container
SECTIONS = [
    (0x3E79, 0x3F00, "container_padding"),
    (0x3F00, 0x4E20, "sprite_tiles_compressed"),
    (0x4E20, 0x5903, "tile_patterns_compressed"),
    (0x5903, 0x63C1, "background_tiles_compressed"),
    (0x63C1, 0x670D, "title_graphics_compressed"),
    (0x670D, 0x6D55, "course_data"),
    (0x6D55, 0x7055, "background_scroll_tilemap"),
    (0x7055, 0x7117, "road_tilemap_second"),
]


def main() -> int:
    container = (ASSETS_DIR / "rom_data_3e79_7116.bin").read_bytes()
    # Remove the old container
    (ASSETS_DIR / "rom_data_3e79_7116.bin").unlink()

    written = []
    for start, end, name in SECTIONS:
        data = container[start - 0x3E79: end - 0x3E79]
        (ASSETS_DIR / f"{name}.bin").write_bytes(data)
        written.append((start, end, name, len(data)))

    # Update asm: replace the single incbin with 8 sequential incbins
    asm_text = ASM.read_text()
    old_incbin = '.incbin "../assets/rom_data_3e79_7116.bin"'
    assert old_incbin in asm_text, "old container incbin not found"
    new_incbins = "\n".join(
        f'    .incbin "../assets/{name}.bin"' for _, _, name, _ in written)
    asm_text = asm_text.replace(old_incbin, new_incbins)
    ASM.write_text(asm_text)

    # Update csv: replace the single container row with the section rows
    csv_text = CSV.read_text()
    csv_text = csv_text.replace("3E79,7116,12958,rom_data_3e79_7116.bin", "")
    new_rows = "\n".join(
        f"{start:04X},{end:04X},{size},{name}.bin"
        for start, end, name, size in written)
    # insert before the 7383 row
    csv_text = csv_text.replace("7383,748A,264,engine_tone_tables.bin",
                                f"{new_rows}\n7383,748A,264,engine_tone_tables.bin")
    CSV.write_text(csv_text)

    for start, end, name, size in written:
        print(f"{name:30s} {start:04X}-{end:04X} ({size:5d} B)")

    # Rebuild
    print("\nRebuilding...")
    result = subprocess.run(
        [sys.executable, str(ROOT / "build.py")], cwd=ROOT,
        capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
