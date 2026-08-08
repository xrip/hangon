#!/usr/bin/env python3
"""Rename the generic rom_data_*.bin assets to meaningful names and update all references.

Mapping is defined in the RENAME dict (old stem -> new stem). The script:
1. Renames files in assets/.
2. Updates .incbin paths in src/hangon_europe.asm.
3. Updates the representation column in docs/assets.csv.
4. Rebuilds and verifies byte-exact output.

The 3E79-7116 container is renamed as a whole; a later step may split it
once the compressed-stream boundaries are resolved.
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

# old stem (rom_data_XXXX_YYYY) -> new stem (meaningful name)
RENAME = {
    "rom_data_080d_0958": "road_tilemap_hud_labels",
    "rom_data_0f8f_1269": "player_physics_tables",
    "rom_data_1304_1330": "bcd_digit_patterns",
    "rom_data_15cb_23d2": "road_curvature_tables",
    "rom_data_2469_247c": "time_digit_patterns",
    "rom_data_2553_2a5c": "object_layout_tables",
    "rom_data_2cc5_2ef2": "course_physics_tables",
    "rom_data_2fdd_3087": "bike_animation_tables",
    "rom_data_3136_3405": "road_patch_tilemap_table",
    "rom_data_3489_34be": "course_segment_offsets",
    "rom_data_34d1_3552": "road_tilemap_initialize",
    "rom_data_35d0_35e4": "score_bcd_increment_table",
    "rom_data_3669_3693": "start_light_tilemaps",
    "rom_data_3976_39fb": "stage_palettes_and_init_state",
    "rom_data_3a80_3b0a": "message_strings",
    "rom_data_3c1d_3c3c": "course_collision_table",
    # 3E79-7116 is a multi-resource container; split once compressed-stream
    # boundaries are resolved (see docs/ASSET_RENAME_PLAN.md). Kept generic for now.
    "rom_data_7383_748a": "engine_tone_tables",
    "rom_data_770b_795b": "psg_note_tables_and_sfx",
    "rom_data_795c_79a5": "track86_race_start",
    "rom_data_79a6_79bb": "track87_time_countdown",
    "rom_data_79bc_7a41": "track88_congratulations",
    "rom_data_7a42_7b72": "track89_game_over",
    "rom_data_7b73_7d37": "track8a_easter_egg_theme",
    "rom_data_7d38_7d63": "track8b_explosion",
    "rom_data_7d83_7dbe": "track8f_title_screen",
}


def main() -> int:
    # 1. Rename files
    renamed = []
    for old_stem, new_stem in RENAME.items():
        old = ASSETS_DIR / f"{old_stem}.bin"
        new = ASSETS_DIR / f"{new_stem}.bin"
        if old.exists():
            old.rename(new)
            renamed.append((old_stem, new_stem))
        elif new.exists():
            print(f"  already renamed: {new.name}")
        else:
            print(f"  WARNING: {old.name} not found")
            return 1

    # 2. Update asm
    asm_text = ASM.read_text()
    for old_stem, new_stem in renamed:
        asm_text = asm_text.replace(
            f"../assets/{old_stem}.bin", f"../assets/{new_stem}.bin")
    ASM.write_text(asm_text)

    # 3. Update csv
    csv_text = CSV.read_text()
    for old_stem, new_stem in renamed:
        csv_text = csv_text.replace(old_stem, new_stem)
    CSV.write_text(csv_text)

    print(f"Renamed {len(renamed)} assets and updated references.")

    # 4. Rebuild
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
