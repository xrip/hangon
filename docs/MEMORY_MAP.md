# Карта памяти и аппаратные интерфейсы

## CPU address map

| Диапазон | Назначение |
|---|---|
| `$0000-$7FFF` | 32 КиБ ROM, без bank switching |
| `$8000-$BFFF` | cartridge address space; этой игре дополнительный ROM/RAM mapper не требуется |
| `$C000-$DFFF` | 8 КиБ Work RAM |
| `$E000-$FFFF` | зеркало Work RAM |

Начальный stack pointer устанавливается в `$DFFE`.

## Векторы

| Адрес | Символ | Назначение |
|---:|---|---|
| `$0000` | `Reset` | reset/startup |
| `$0038` | `InterruptHandler` | IM 1 IRQ |
| `$0066` | `NMIHandler` | Pause/NMI |

## I/O ports

| Port | Символ | Использование |
|---:|---|---|
| `$7E` | `VCounterPort` | vertical counter |
| `$7F` | `PSGPort` | SN76489-compatible PSG write |
| `$BE` | `VDPDataPort` | VDP data |
| `$BF` | `VDPControlPort` | VDP control/status |
| `$DC` | `ControllerPort1` | controller input |
| `$DD` | `ControllerPort2` | controller/input status |
| `$DE` | `IOControlPort1` | I/O control/PPI-compatible path |
| `$DF` | `IOControlPort2` | I/O control/PPI-compatible path |

## Основные Work RAM symbols

Полный список находится в `include/ram.inc` и `docs/symbols.csv`.

| Адрес | Символ | Назначение |
|---:|---|---|
| `$C000` | `GameState` | главное состояние игры |
| `$C001` | `Buttons` | текущий input |
| `$C002` | `VBlankComplete` | синхронизация main loop/VBlank |
| `$C004` | `ScoreBCD` | BCD score |
| `$C00D` | `TimeLeft` | оставшееся время |
| `$C02D` | `PauseFlag` | NMI pause flag |
| `$C049` | `StartLightPhase` | состояние стартовых огней |
| `$C051` | `BackgroundXScroll` | background scroll |
| `$C060` | `LeftDistanceBCD` | оставшаяся дистанция |
| `$C100` | `SoundTrigger` | запрос звука/музыки |
| `$C101` | `SoundFunctionPointer` | runtime sound function pointer |
| `$C110` | `SoundVoices` | voice structures |
| `$C2F0` | `CurrentCourseSegment` | структура текущего сегмента трассы |
| `$C300` | `PlayerObject` | object/player structure |
| `$C318` | `Gear` | передача |
| `$C319-$C31B` | `SpeedLow/Middle/High` | fixed-point/многобайтовая скорость |
| `$C4D0` | `LineInterruptHandlerRAM` | скопированный line IRQ handler |
| `$C500` | `HorizontalScrollValues` | per-line horizontal scroll table |
| `$C600` | `RoadCurvature` | данные кривизны дороги |
| `$C680` | `TileFlipBuffer` | временный tile transform buffer |
| `$C700` | `RAMTiles` | tile workspace |
| `$D7E0` | `GoSignTiles` | динамические tiles таблички GO |
| `$D8A0` | `BikeSpriteTiles` | динамические motorcycle sprites |

## VDP-oriented flow

Main loop ждёт `VBlankComplete`, который устанавливается IRQ path. VBlank handler обновляет VRAM/CRAM state, game logic, sprites и sound. Line interrupt handler меняет VDP horizontal scroll/register state по vertical counter, обеспечивая отдельное поведение дорожной части экрана.
