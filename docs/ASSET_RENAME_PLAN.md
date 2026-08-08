# Asset rename plan — Hang-On (Europe)

Byte-exact source reconstruction. Each `.bin` in `assets/` is a slice of the 32 KiB ROM.
This document records the mapping from the original generic names
(`rom_data_START_END.bin`) to meaningful names derived from code analysis.

## Status

**All 26 original assets renamed and the container split into 8 named
sub-assets. Build re-verified byte-exact** (all hashes match the reference ROM).

## Renamed assets (in `assets/`)

| ROM range | Meaningful name | Content / code evidence |
|---|---|---|
| `$080D-$0958` | `road_tilemap_hud_labels.bin` | `DrawRoad` tilemaps + "SCORE/SPEED/LEFT/COURSE" |
| `$0F8F-$1269` | `player_physics_tables.bin` | `ObjectHandlerType01` accel/RPM/collision tables |
| `$1304-$1330` | `bcd_digit_patterns.bin` | `DrawSpeed` BCD digit tables |
| `$15CB-$23D2` | `road_curvature_tables.bin` | course curve data → `RoadCurvature` $C600 |
| `$2469-$247C` | `time_digit_patterns.bin` | `UpdateTimeLeft` digit patterns |
| `$2553-$2A5C` | `object_layout_tables.bin` | object handler layout/sprite lists |
| `$2CC5-$2EF2` | `course_physics_tables.bin` | hitbox/speed-curve/sprite-frame tables |
| `$2FDD-$3087` | `bike_animation_tables.bin` | speed→frame + sprite-order tables |
| `$3136-$3405` | `road_patch_tilemap_table.bin` | `PatchRoadTilemap` VRAM addr/row table |
| `$3489-$34BE` | `course_segment_offsets.bin` | per-segment offset deltas |
| `$34D1-$3552` | `road_tilemap_initialize.bin` | `InitializeRoad` tilemap (attr 09) |
| `$35D0-$35E4` | `score_bcd_increment_table.bin` | `UpdateScore` +1..+5 BCD |
| `$3669-$3693` | `start_light_tilemaps.bin` | `DrawStartLights` RED/YELLOW lights |
| `$3976-$39FB` | `stage_palettes_and_init_state.bin` | stage palettes + initial RAM state |
| `$3A80-$3B0A` | `message_strings.bin` | "GAME OVER", "CONGRATULATIONS:" etc. |
| `$3C1D-$3C3C` | `course_collision_table.bin` | segment collision thresholds |
| `$7383-$748A` | `engine_tone_tables.bin` | PSG engine frequency tables |
| `$770B-$795B` | `psg_note_tables_and_sfx.bin` | note freq + SFX voice streams |
| `$795C-$79A5` | `track86_race_start.bin` | music stream (trigger $86) |
| `$79A6-$79BB` | `track87_time_countdown.bin` | music stream (trigger $87) |
| `$79BC-$7A41` | `track88_congratulations.bin` | music stream (trigger $88) |
| `$7A42-$7B72` | `track89_game_over.bin` | music stream (trigger $89) |
| `$7B73-$7D37` | `track8a_easter_egg_theme.bin` | music stream (trigger $8A) |
| `$7D38-$7D63` | `track8b_explosion.bin` | SFX stream (trigger $8B) |
| `$7D83-$7DBE` | `track8f_title_screen.bin` | music stream (trigger $8F) |

## Container split (`$3E79-$7116`)

The former `rom_data_3e79_7116.bin` was a multi-resource container, split into 8
named sub-assets. The compressed-graphics format was reverse-engineered
(`DecompressTiles` $078D: bit7 SET = literal run, bit7 CLEAR = RLE run of one
byte; 4 bitplane passes with destination stride 4 → standard SMS 4bpp tiles).
Every stream terminates exactly at the next section's start.

| ROM range | Name | Content / destination |
|---|---|---|
| `$3E79-$3F00` | `container_padding.bin` | padding (FF) |
| `$3F00-$4E20` | `sprite_tiles_compressed.bin` | compressed sprite/tile set → VRAM `$6000` (200 tiles) |
| `$4E20-$5903` | `tile_patterns_compressed.bin` | compressed tile patterns → VRAM `$4000` (136 tiles) |
| `$5903-$63C1` | `background_tiles_compressed.bin` | compressed bg tiles → RAM `$C700` (134 tiles) |
| `$63C1-$670D` | `title_graphics_compressed.bin` | compressed title graphics → VRAM `$6C00` (85 tiles) |
| `$670D-$6D55` | `course_data.bin` | course pointer table + layouts |
| `$6D55-$7055` | `background_scroll_tilemap.bin` | background scroll tilemap |
| `$7055-$7116` | `road_tilemap_second.bin` | road tilemap (attr 09, ends `$00`) |

The compressed streams are decoded by `tools/decode_graphics.py`; contact sheets
are rendered to `build/graphics_decoded/`.
