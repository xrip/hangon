# Основные восстановленные функции

Полный список из 500 ROM labels, RAM symbols и I/O ports находится в `symbols.csv`. Ниже — навигационная выборка.

## Startup, interrupts, main flow

| Адрес | Символ |
|---:|---|
| `$0000` | `Reset` |
| `$0008` | `WaitForVBlankAndClearPauseFlag` |
| `$001E` | `WriteDataToVDP` |
| `$0030` | `WaitForVBlank` |
| `$0038` | `InterruptHandler` |
| `$0042` | `MutePSG` |
| `$0053` | `PauseLoop` |
| `$0066` | `NMIHandler` |
| `$00A7` | `ColdStart` |
| `$01C8` | `VBlankHandler` |
| `$02CF` | `InitializeGameplay` |
| `$03B3` | `LineInterruptHandlerROM` |
| `$03DD` | `SplashAndTitleScreen` |

## VDP/data helpers

| Адрес | Символ |
|---:|---|
| `$05F1` | `MultiplyHLByB` |
| `$05FD` | `DrawNullTerminatedTilemap` |
| `$060F` | `SetVDPRegisterCToB` |
| `$0616` | `WriteAToVDPAtHL` |
| `$0620` | `ReadAFromVDPAtHL` |
| `$0628` | `CopyRAMToVRAM` |
| `$0638` | `CopyVRAMToRAM` |
| `$0647` | `CopyVRAMToVRAM` |
| `$0657` | `BlankTilemapPalette1` |
| `$0674` | `BlankTilemapPalette2` |
| `$0691` | `MoveAllSpritesOffscreen` |
| `$0699` | `FillVRAM` |
| `$06AA` | `TurnScreenOff` |
| `$06B5` | `TurnScreenOn` |
| `$06C0` | `SetVDPRegisters` |
| `$078D` | `DecompressTiles` |
| `$07C4` | `ReverseFlipAndEmitTiles` |

## Gameplay/rendering

| Адрес | Символ |
|---:|---|
| `$0959` | `DrawRoad` |
| `$126A` | `UpdateRoadCurve` |
| `$12AB` | `DrawSpeed` |
| `$1331` | `UpdateGameState` |
| `$23D3` | `UpdateSpeedDisplay` |
| `$2402` | `UpdateTimeLeft` |
| `$2496` | `UpdateObjects` |
| `$3088` | `PatchRoadTilemap` |
| `$3406` | `UpdatePlayer` |
| `$3577` | `UpdateHighScore` |
| `$3590` | `DrawScore` |
| `$35E5` | `DrawStartLights` |
| `$3612` | `UpdateStartLights` |
| `$36CC` | `UpdateGearDisplay` |
| `$370B` | `UpdateLeftDistanceDisplay` |
| `$3838` | `UpdateDistance` |
| `$3945` | `LoadStagePalette` |
| `$3DAB` | `DemoControls` |

## Sound engine

| Адрес | Символ |
|---:|---|
| `$711A` | `SoundUpdate` |
| `$7153` | `SoundFunctionOvertakeHigh` |
| `$716D` | `SoundFunctionOvertakeLow` |
| `$717B` | `SoundFunctionBump` |
| `$7195` | `SoundFunctionSkid` |
| `$71AF` | `SoundFunctionGoSign` |
| `$71DC` | `SoundFunctionEngine` |
| `$71FC` | `InitializeLowVoices` |
| `$7207` | `UpdateSFXVoice` |
| `$729C` | `UpdateSharedSFXMusicVoice` |
| `$7304` | `UpdateEngineSounds` |
| `$748B` | `CheckForNewSoundTrigger` |
| `$7534` | `UpdateSoundLoop` |
| `$7545` | `UpdateVoice` |
| `$756C` | `ApplyEnvelope` |
| `$75A1` | `GetNextSoundDataByte` |
| `$75FD` | `DispatchSoundCommand` |

## Нейтрально названные handlers

Некоторые functions можно надёжно привязать к state/object type, но не к окончательному игровому смыслу без runtime tracing. Поэтому они названы `StateHandler...` и `ObjectHandler...`, а не получили спекулятивные имена. Адреса и control flow при этом полностью восстановлены.
