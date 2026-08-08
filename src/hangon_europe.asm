; Hang-On (Europe) for Sega Master System
; Byte-exact Z80 source reconstruction of the 32 KiB ROM.
;
; Code is emitted as Z80 mnemonics. Opaque graphics, maps, music streams,
; and compressed resources are retained as range-named binary assets.
; Every instruction comment records the original address and bytes but the
; bundled assembler generates bytes from the mnemonic, not from the comment.

.include "../include/hardware.inc"
.include "../include/ram.inc"

.org $0000

; ============================================================================
; Code $0000
; ============================================================================
; Reset vector and hardware initialization entry.
Reset:
    di                                      ; 0000: F3
    im 1                                    ; 0001: ED 56
    ld sp, $dffe                            ; 0003: 31 FE DF
    jr loc_0071                             ; 0006: 18 69
WaitForVBlankAndClearPauseFlag:
    ei                                      ; 0008: FB
    ld hl, VBlankComplete                   ; 0009: 21 02 C0
loc_000C:
    ld a, (hl)                              ; 000C: 7E
    or a                                    ; 000D: B7
    jr z, loc_000C                          ; 000E: 28 FC
    xor a                                   ; 0010: AF
    ld (hl), a                              ; 0011: 77
    ld (PauseFlag), a                       ; 0012: 32 2D C0
    ret                                     ; 0015: C9
WriteAAndHToVDPControl:
    ld a, l                                 ; 0016: 7D
    out (VDPControlPort), a                 ; 0017: D3 BF
    ld a, h                                 ; 0019: 7C
    out (VDPControlPort), a                 ; 001A: D3 BF
    ret                                     ; 001C: C9

; ----------------------------------------------------------------------------
; ROM data $001D-$001D (1 bytes)
; ----------------------------------------------------------------------------
RomData_001D:
    .db $ff                                 ; 001D: FF

; ============================================================================
; Code $001E
; ============================================================================
WriteDataToVDP:
    ex de, hl                               ; 001E: EB
    call WriteAAndHToVDPControl             ; 001F: CD 16 00
    ex (sp), hl                             ; 0022: E3
    ex (sp), hl                             ; 0023: E3
    ex de, hl                               ; 0024: EB
    ld c, $be                               ; 0025: 0E BE
loc_0027:
    outi                                    ; 0027: ED A3
    jr nz, loc_0027                         ; 0029: 20 FC
    ret                                     ; 002B: C9

; ----------------------------------------------------------------------------
; ROM data $002C-$002F (4 bytes)
; ----------------------------------------------------------------------------
RomData_002C:
    .db $21, $42, $25, $5e                  ; 002C: 21 42 25 5E

; ============================================================================
; Code $0030
; ============================================================================
WaitForVBlank:
    ei                                      ; 0030: FB
    ld hl, VBlankComplete                   ; 0031: 21 02 C0
loc_0034:
    ld a, (hl)                              ; 0034: 7E
    or a                                    ; 0035: B7
    jr loc_005F                             ; 0036: 18 27
; IM 1 interrupt vector. Dispatches line IRQs to the handler copied into RAM.
InterruptHandler:
    push af                                 ; 0038: F5
    in a, (VDPControlPort)                  ; 0039: DB BF
    or a                                    ; 003B: B7
    jp p, LineInterruptHandlerRAM           ; 003C: F2 D0 C4
    jp VBlankHandler                        ; 003F: C3 C8 01
MutePSG:
    ld a, $9f                               ; 0042: 3E 9F
    out (PSGPort), a                        ; 0044: D3 7F
    ld a, $bf                               ; 0046: 3E BF
    out (PSGPort), a                        ; 0048: D3 7F
    ld a, $df                               ; 004A: 3E DF
    out (PSGPort), a                        ; 004C: D3 7F
    ld a, $ff                               ; 004E: 3E FF
    out (PSGPort), a                        ; 0050: D3 7F
    ret                                     ; 0052: C9
PauseLoop:
    call MutePSG                            ; 0053: CD 42 00
    ld a, (PauseFlag)                       ; 0056: 3A 2D C0
    or a                                    ; 0059: B7
    jr nz, PauseLoop                        ; 005A: 20 F7
    jp loc_0187                             ; 005C: C3 87 01
loc_005F:
    jp z, loc_0034                          ; 005F: CA 34 00
    ld (hl), $00                            ; 0062: 36 00
    ret                                     ; 0064: C9

; ----------------------------------------------------------------------------
; ROM data $0065-$0065 (1 bytes)
; ----------------------------------------------------------------------------
RomData_0065:
    .db $ff                                 ; 0065: FF

; ============================================================================
; Code $0066
; ============================================================================
; NMI pause handler.
NMIHandler:
    push af                                 ; 0066: F5
    ld a, (PauseFlag)                       ; 0067: 3A 2D C0
    cpl                                     ; 006A: 2F
    ld (PauseFlag), a                       ; 006B: 32 2D C0
    pop af                                  ; 006E: F1
    retn                                    ; 006F: ED 45
loc_0071:
    call MutePSG                            ; 0071: CD 42 00
    ld de, WarmBootSignatureROM             ; 0074: 11 A2 00
    ld hl, WarmBootSignatureRAM             ; 0077: 21 CB C4
    ld bc, $0005                            ; 007A: 01 05 00
loc_007D:
    ld a, (de)                              ; 007D: 1A
    inc de                                  ; 007E: 13
    cpi                                     ; 007F: ED A1
    jr nz, ColdStart                        ; 0081: 20 24
    ld a, b                                 ; 0083: 78
    or c                                    ; 0084: B1
    jr nz, loc_007D                         ; 0085: 20 F6
    ld hl, GameState                        ; 0087: 21 00 C0
    ld de, Buttons                          ; 008A: 11 01 C0
    ld bc, $04c0                            ; 008D: 01 C0 04
    ld (hl), l                              ; 0090: 75
    ldir                                    ; 0091: ED B0
    ld hl, $c4c4                            ; 0093: 21 C4 C4
    ld de, $c4c5                            ; 0096: 11 C5 C4
    ld bc, $1b2e                            ; 0099: 01 2E 1B
    ld (hl), $00                            ; 009C: 36 00
    ldir                                    ; 009E: ED B0
    jr loc_00B3                             ; 00A0: 18 11

; Warm-boot signature checked against RAM during reset.
WarmBootSignatureROM:
    .db "NAOMI"                         ; 00A2: 4E 41 4F 4D 49

; ============================================================================
; Code $00A7
; ============================================================================
ColdStart:
    ld hl, GameState                        ; 00A7: 21 00 C0
    ld de, Buttons                          ; 00AA: 11 01 C0
    ld bc, $1ffc                            ; 00AD: 01 FC 1F
    ld (hl), l                              ; 00B0: 75
    ldir                                    ; 00B1: ED B0
loc_00B3:
    ld hl, LineInterruptHandlerROM          ; 00B3: 21 B3 03
    ld de, LineInterruptHandlerRAM          ; 00B6: 11 D0 C4
    ld bc, $002a                            ; 00B9: 01 2A 00
    ldir                                    ; 00BC: ED B0
    ld hl, WarmBootSignatureROM             ; 00BE: 21 A2 00
    ld de, WarmBootSignatureRAM             ; 00C1: 11 CB C4
    ld bc, $0005                            ; 00C4: 01 05 00
    ldir                                    ; 00C7: ED B0
    call InitializeDisplay                  ; 00C9: CD D1 06
    ld a, $04                               ; 00CC: 3E 04
    ld (GameState), a                       ; 00CE: 32 00 C0
    ld a, $ff                               ; 00D1: 3E FF
    ld (HaveDoneColdStart), a               ; 00D3: 32 15 C0
    ld a, $00                               ; 00D6: 3E 00
    ld (Level), a                           ; 00D8: 32 C0 C4
    ld a, $01                               ; 00DB: 3E 01
    ld ($c4c7), a                           ; 00DD: 32 C7 C4
loc_00E0:
    call TurnScreenOff                      ; 00E0: CD AA 06
    call MutePSG                            ; 00E3: CD 42 00
    ld a, (HaveDoneColdStart)               ; 00E6: 3A 15 C0
    push af                                 ; 00E9: F5
    ld hl, (ScoreBCD)                       ; 00EA: 2A 04 C0
    push hl                                 ; 00ED: E5
    ld a, ($c006)                           ; 00EE: 3A 06 C0
    ld hl, Buttons                          ; 00F1: 21 01 C0
    ld de, VBlankComplete                   ; 00F4: 11 02 C0
    ld bc, $04be                            ; 00F7: 01 BE 04
    ld (hl), $00                            ; 00FA: 36 00
    ldir                                    ; 00FC: ED B0
    ld hl, HorizontalScrollValues           ; 00FE: 21 00 C5
    ld de, $c501                            ; 0101: 11 01 C5
    ld bc, $01ff                            ; 0104: 01 FF 01
    ld (hl), l                              ; 0107: 75
    ldir                                    ; 0108: ED B0
    pop hl                                  ; 010A: E1
    ld (ScoreBCD), hl                       ; 010B: 22 04 C0
    ld ($c006), a                           ; 010E: 32 06 C0
    pop af                                  ; 0111: F1
    ld (HaveDoneColdStart), a               ; 0112: 32 15 C0
    call InitializeLowVoices                ; 0115: CD FC 71
    call SplashAndTitleScreen               ; 0118: CD DD 03
    call InitializeGameplay                 ; 011B: CD CF 02
    di                                      ; 011E: F3
    call TurnScreenOff                      ; 011F: CD AA 06
    call BlankTilemapPalette1               ; 0122: CD 57 06
    call DrawRoad                           ; 0125: CD 59 09
    call InitializeRoad                     ; 0128: CD BF 34
    xor a                                   ; 012B: AF
    call LoadStagePalettes                  ; 012C: CD 51 39
loc_012F:
    ld a, (Course)                          ; 012F: 3A 10 C0
    add a, $31                              ; 0132: C6 31
    ld de, $783a                            ; 0134: 11 3A 78
    call WriteAToVRAMDE                     ; 0137: CD 89 24
    ld hl, $0004                            ; 013A: 21 04 00
    ld (LeftDistanceBCD), hl                ; 013D: 22 60 C0
    ld hl, $0000                            ; 0140: 21 00 00
    ld (SpeedMiddle), hl                    ; 0143: 22 1A C3
    xor a                                   ; 0146: AF
    ld ($c301), a                           ; 0147: 32 01 C3
    ld (CourseDataIndex), a                 ; 014A: 32 11 C0
    ld ($c2f2), a                           ; 014D: 32 F2 C2
    ld bc, $7680                            ; 0150: 01 80 76
    call SetVDPRegisterCToB                 ; 0153: CD 0F 06
    ld a, (GameState)                       ; 0156: 3A 00 C0
    and $04                                 ; 0159: E6 04
    jr nz, loc_0179                         ; 015B: 20 1C
    call DrawStartLights                    ; 015D: CD E5 35
    call TurnScreenOn                       ; 0160: CD B5 06
    call WaitForVBlankAndClearPauseFlag     ; 0163: CD 08 00
    call UpdateObjects                      ; 0166: CD 96 24
loc_0169:
    call WaitForVBlankAndClearPauseFlag     ; 0169: CD 08 00
    ld a, (HaveDoneColdStart)               ; 016C: 3A 15 C0
    or a                                    ; 016F: B7
    jp nz, loc_00E0                         ; 0170: C2 E0 00
    ld a, (StartLightPhase)                 ; 0173: 3A 49 C0
    or a                                    ; 0176: B7
    jr nz, loc_0169                         ; 0177: 20 F0
loc_0179:
    call TurnScreenOn                       ; 0179: CD B5 06
    ld hl, $71dc                            ; 017C: 21 DC 71
    ld (SoundFunctionPointer), hl           ; 017F: 22 01 C1
    ld a, $81                               ; 0182: 3E 81
    ld (SoundTrigger), a                    ; 0184: 32 00 C1
loc_0187:
    call WaitForVBlank                      ; 0187: CD 30 00
    ld a, (GameState)                       ; 018A: 3A 00 C0
    and $04                                 ; 018D: E6 04
    jr z, loc_019F                          ; 018F: 28 0E
    ld a, (TimeLeft)                        ; 0191: 3A 0D C0
    cp $13                                  ; 0194: FE 13
    jr nc, loc_01A6                         ; 0196: 30 0E
    ld a, $ff                               ; 0198: 3E FF
    ld (HaveDoneColdStart), a               ; 019A: 32 15 C0
    jr loc_01A6                             ; 019D: 18 07
loc_019F:
    ld a, (PauseFlag)                       ; 019F: 3A 2D C0
    or a                                    ; 01A2: B7
    jp nz, PauseLoop                        ; 01A3: C2 53 00
loc_01A6:
    ld a, (HaveDoneColdStart)               ; 01A6: 3A 15 C0
    or a                                    ; 01A9: B7
    jp nz, loc_00E0                         ; 01AA: C2 E0 00
    call UpdateGameState                    ; 01AD: CD 31 13
    call UpdateObjects                      ; 01B0: CD 96 24
    call UpdateBikeAnimation                ; 01B3: CD F3 2E
    call UpdatePlayer                       ; 01B6: CD 06 34
    ld a, (GameState)                       ; 01B9: 3A 00 C0
    bit 6, a                                ; 01BC: CB 77
    jp nz, UpdateStageMessage               ; 01BE: C2 FC 39
    bit 5, a                                ; 01C1: CB 6F
    jp nz, UpdateRoadsideScenery            ; 01C3: C2 0B 3B
    jr loc_0187                             ; 01C6: 18 BF
; Per-VBlank update path: input, video state, gameplay, sprites, and sound.
VBlankHandler:
    push bc                                 ; 01C8: C5
    push de                                 ; 01C9: D5
    push hl                                 ; 01CA: E5
    push ix                                 ; 01CB: DD E5
    push iy                                 ; 01CD: FD E5
    exx                                     ; 01CF: D9
    ex af, af'                              ; 01D0: 08
    push af                                 ; 01D1: F5
    push bc                                 ; 01D2: C5
    push de                                 ; 01D3: D5
    push hl                                 ; 01D4: E5
    in a, (ControllerPort2)                 ; 01D5: DB DD
    bit 4, a                                ; 01D7: CB 67
    jp z, Reset                             ; 01D9: CA 00 00
    call MaybeLoadSceneryTiles              ; 01DC: CD 8C 37
    call MaybeReloadBikeSpritesB            ; 01DF: CD 06 38
    call MaybeReloadBikeSpritesA            ; 01E2: CD D9 37
    call UpdateSpriteTable                  ; 01E5: CD 9E 02
    ld a, ($c05b)                           ; 01E8: 3A 5B C0
    neg                                     ; 01EB: ED 44
    ld b, a                                 ; 01ED: 47
    ld c, $88                               ; 01EE: 0E 88
    call SetVDPRegisterCToB                 ; 01F0: CD 0F 06
    ld bc, $2f8a                            ; 01F3: 01 8A 2F
    call SetVDPRegisterCToB                 ; 01F6: CD 0F 06
    ld a, (GameState)                       ; 01F9: 3A 00 C0
    or a                                    ; 01FC: B7
    jp p, RunFrameTail                      ; 01FD: F2 66 02
    and $04                                 ; 0200: E6 04
    jr nz, loc_020B                         ; 0202: 20 07
    ld a, (PauseFlag)                       ; 0204: 3A 2D C0
    or a                                    ; 0207: B7
    jp nz, loc_027F                         ; 0208: C2 7F 02
loc_020B:
    call UpdateDistance                     ; 020B: CD 38 38
    call UpdateSpeedDisplay                 ; 020E: CD D3 23
    call UpdateTimeLeft                     ; 0211: CD 02 24
    call UpdateStartLights                  ; 0214: CD 12 36
    call UpdateGearDisplay                  ; 0217: CD CC 36
    ld hl, MessageFlashFrameTimer           ; 021A: 21 78 C0
    ld a, (hl)                              ; 021D: 7E
    or a                                    ; 021E: B7
    jp z, loc_024E                          ; 021F: CA 4E 02
    cp $14                                  ; 0222: FE 14
    jr nz, loc_0235                         ; 0224: 20 0F
    ld a, (StageNumber)                     ; 0226: 3A 07 C0
    add a, $05                              ; 0229: C6 05
    ld (TextTrigger), a                     ; 022B: 32 64 C0
    ld de, $71af                            ; 022E: 11 AF 71
    ld (SoundFunctionPointer), de           ; 0231: ED 53 01 C1
loc_0235:
    dec (hl)                                ; 0235: 35
    jr nz, loc_024E                         ; 0236: 20 16
    ld a, $0a                               ; 0238: 3E 0A
    ld (TextTrigger), a                     ; 023A: 32 64 C0
    ld hl, $71af                            ; 023D: 21 AF 71
    ld (SoundFunctionPointer), hl           ; 0240: 22 01 C1
    ld hl, MessageFlashCounter              ; 0243: 21 79 C0
    dec (hl)                                ; 0246: 35
    jr z, loc_024E                          ; 0247: 28 05
    ld a, $28                               ; 0249: 3E 28
    ld (MessageFlashFrameTimer), a          ; 024B: 32 78 C0
loc_024E:
    call MaybeDrawText                      ; 024E: CD 33 3A
    call DrawScore                          ; 0251: CD 90 35
    call UpdateLeftDistanceDisplay          ; 0254: CD 0B 37
    call DrawSpeed                          ; 0257: CD AB 12
    call LoadStagePalette                   ; 025A: CD 45 39
    call UpdateRoadCurve                    ; 025D: CD 6A 12
    call PatchRoadTilemap                   ; 0260: CD 88 30
    jp loc_0276                             ; 0263: C3 76 02
RunFrameTail:
    or a                                    ; 0266: B7
    jr nz, loc_0276                         ; 0267: 20 0D
    ld hl, $7c24                            ; 0269: 21 24 7C
    call WriteAAndHToVDPControl             ; 026C: CD 16 00
    ld a, (Level)                           ; 026F: 3A C0 C4
    add a, $31                              ; 0272: C6 31
    out (VDPDataPort), a                    ; 0274: D3 BE
loc_0276:
    call ReadControls                       ; 0276: CD 64 07
    ld (Buttons), a                         ; 0279: 32 01 C0
    call SoundUpdate                        ; 027C: CD 1A 71
loc_027F:
    ld a, $01                               ; 027F: 3E 01
    ld (VBlankComplete), a                  ; 0281: 32 02 C0
    ld bc, $2f8a                            ; 0284: 01 8A 2F
    call SetVDPRegisterCToB                 ; 0287: CD 0F 06
    ld hl, VBlankCounter                    ; 028A: 21 73 C0
    inc (hl)                                ; 028D: 34
    pop hl                                  ; 028E: E1
    pop de                                  ; 028F: D1
    pop bc                                  ; 0290: C1
    pop af                                  ; 0291: F1
    ex af, af'                              ; 0292: 08
    exx                                     ; 0293: D9
    pop iy                                  ; 0294: FD E1
    pop ix                                  ; 0296: DD E1
    pop hl                                  ; 0298: E1
    pop de                                  ; 0299: D1
    pop bc                                  ; 029A: C1
    pop af                                  ; 029B: F1
    ei                                      ; 029C: FB
    ret                                     ; 029D: C9
UpdateSpriteTable:
    ld hl, $c045                            ; 029E: 21 45 C0
    ld a, (hl)                              ; 02A1: 7E
    or a                                    ; 02A2: B7
    ret z                                   ; 02A3: C8
    ld (hl), $00                            ; 02A4: 36 00
    ld hl, $7f15                            ; 02A6: 21 15 7F
    call WriteAAndHToVDPControl             ; 02A9: CD 16 00
    ld hl, SpriteYs                         ; 02AC: 21 3F C4
    ld bc, $2bbe                            ; 02AF: 01 BE 2B
loc_02B2:
    outi                                    ; 02B2: ED A3
    inc hl                                  ; 02B4: 23
    inc hl                                  ; 02B5: 23
    jp nz, loc_02B2                         ; 02B6: C2 B2 02
    ld hl, $7faa                            ; 02B9: 21 AA 7F
    call WriteAAndHToVDPControl             ; 02BC: CD 16 00
    ld hl, SpriteXNs                        ; 02BF: 21 40 C4
    ld b, $56                               ; 02C2: 06 56
loc_02C4:
    outi                                    ; 02C4: ED A3
    nop                                     ; 02C6: 00
    nop                                     ; 02C7: 00
    outi                                    ; 02C8: ED A3
    inc hl                                  ; 02CA: 23
    jp nz, loc_02C4                         ; 02CB: C2 C4 02
    ret                                     ; 02CE: C9
InitializeGameplay:
    ld ix, GameState                        ; 02CF: DD 21 00 C0
    ld (ix+31), $10                         ; 02D3: DD 36 1F 10
    ld (ix+24), $01                         ; 02D7: DD 36 18 01
    ld (ix+32), $01                         ; 02DB: DD 36 20 01
    ld (ix+12), $3c                         ; 02DF: DD 36 0C 3C
    ld (ix+13), $3c                         ; 02E3: DD 36 0D 3C
    ld (ix+116), $3c                        ; 02E7: DD 36 74 3C
    ld (ix+42), $80                         ; 02EB: DD 36 2A 80
    ld (ix+19), $54                         ; 02EF: DD 36 13 54
    ld (ix+71), $04                         ; 02F3: DD 36 47 04
    ld (ix+38), $01                         ; 02F7: DD 36 26 01
    ld a, $01                               ; 02FB: 3E 01
    ld (PlayerObject), a                    ; 02FD: 32 00 C3
    ld hl, $6d55                            ; 0300: 21 55 6D
    ld (BackgroundDataPointer), hl          ; 0303: 22 4D C0
    ld hl, $0020                            ; 0306: 21 20 00
    ld ($c05c), hl                          ; 0309: 22 5C C0
    ld a, $14                               ; 030C: 3E 14
    ld ($c044), a                           ; 030E: 32 44 C0
    ld a, $ff                               ; 0311: 3E FF
    ld ($c071), a                           ; 0313: 32 71 C0
    ld ($c067), a                           ; 0316: 32 67 C0
    ld d, $02                               ; 0319: 16 02
    ld c, $f8                               ; 031B: 0E F8
    ld hl, $c400                            ; 031D: 21 00 C4
loc_0320:
    ld a, $6f                               ; 0320: 3E 6F
    ld b, $05                               ; 0322: 06 05
loc_0324:
    ld (hl), a                              ; 0324: 77
    inc hl                                  ; 0325: 23
    ld (hl), c                              ; 0326: 71
    inc hl                                  ; 0327: 23
    ld (hl), $00                            ; 0328: 36 00
    inc hl                                  ; 032A: 23
    add a, $10                              ; 032B: C6 10
    djnz loc_0324                           ; 032D: 10 F5
    ld c, $08                               ; 032F: 0E 08
    dec d                                   ; 0331: 15
    jr nz, loc_0320                         ; 0332: 20 EC
    call LoadInitialGraphics                ; 0334: CD 1F 07
    ld hl, $3976                            ; 0337: 21 76 39
    ld de, GameState                        ; 033A: 11 00 C0
    ld bc, $0020                            ; 033D: 01 20 00
    call CopyRAMToVRAM                      ; 0340: CD 28 06
    ld hl, $7f00                            ; 0343: 21 00 7F
    call WriteAAndHToVDPControl             ; 0346: CD 16 00
    ld hl, $c400                            ; 0349: 21 00 C4
    ld bc, $16be                            ; 034C: 01 BE 16
loc_034F:
    outi                                    ; 034F: ED A3
    inc hl                                  ; 0351: 23
    inc hl                                  ; 0352: 23
    jp nz, loc_034F                         ; 0353: C2 4F 03
    ld hl, $7f80                            ; 0356: 21 80 7F
    call WriteAAndHToVDPControl             ; 0359: CD 16 00
    ld hl, $c401                            ; 035C: 21 01 C4
    ld b, $2c                               ; 035F: 06 2C
loc_0361:
    outi                                    ; 0361: ED A3
    push af                                 ; 0363: F5
    pop af                                  ; 0364: F1
    outi                                    ; 0365: ED A3
    inc hl                                  ; 0367: 23
    jp nz, loc_0361                         ; 0368: C2 61 03
    ld a, (GameState)                       ; 036B: 3A 00 C0
    and $04                                 ; 036E: E6 04
    jp nz, loc_037F                         ; 0370: C2 7F 03
    xor a                                   ; 0373: AF
    ld hl, ScoreBCD                         ; 0374: 21 04 C0
    ld (hl), a                              ; 0377: 77
    inc hl                                  ; 0378: 23
    ld (hl), a                              ; 0379: 77
    inc hl                                  ; 037A: 23
    ld (hl), a                              ; 037B: 77
    jp TurnScreenOn                         ; 037C: C3 B5 06
loc_037F:
    ld a, r                                 ; 037F: ED 5F
    and $07                                 ; 0381: E6 07
    ld (Course), a                          ; 0383: 32 10 C0
    ld a, ($c4c6)                           ; 0386: 3A C6 C4
    ld (StageNumber), a                     ; 0389: 32 07 C0
    ld (BackgroundIndex), a                 ; 038C: 32 4B C0
    ld e, a                                 ; 038F: 5F
    ld d, $00                               ; 0390: 16 00
    ld hl, $3939                            ; 0392: 21 39 39
    add hl, de                              ; 0395: 19
    add hl, de                              ; 0396: 19
    ld e, (hl)                              ; 0397: 5E
    inc hl                                  ; 0398: 23
    ld d, (hl)                              ; 0399: 56
    ex de, hl                               ; 039A: EB
    ld (BackgroundDataPointer), hl          ; 039B: 22 4D C0
    inc a                                   ; 039E: 3C
    cp $04                                  ; 039F: FE 04
    jr c, loc_03A4                          ; 03A1: 38 01
    xor a                                   ; 03A3: AF
loc_03A4:
    ld ($c4c6), a                           ; 03A4: 32 C6 C4
    call TurnScreenOn                       ; 03A7: CD B5 06
    ld a, $0b                               ; 03AA: 3E 0B
    ld (RoadsideSceneryLoadIndex), a        ; 03AC: 32 68 C0
    ld ($c072), a                           ; 03AF: 32 72 C0
    ret                                     ; 03B2: C9
; Position-independent line interrupt routine copied to $C4D0 during boot.
LineInterruptHandlerROM:
    in a, (VCounterPort)                    ; 03B3: DB 7E
    cp $5f                                  ; 03B5: FE 5F
    jr c, loc_03C8                          ; 03B7: 38 0F
    ld ($c4da), a                           ; 03B9: 32 DA C4
    ld a, (HorizontalScrollValues)          ; 03BC: 3A 00 C5
    out (VDPControlPort), a                 ; 03BF: D3 BF
    ld a, $88                               ; 03C1: 3E 88
    out (VDPControlPort), a                 ; 03C3: D3 BF
    pop af                                  ; 03C5: F1
    ei                                      ; 03C6: FB
    ret                                     ; 03C7: C9
loc_03C8:
    ld a, (BackgroundXScroll)               ; 03C8: 3A 51 C0
    neg                                     ; 03CB: ED 44
    out (VDPControlPort), a                 ; 03CD: D3 BF
    ld a, $88                               ; 03CF: 3E 88
    out (VDPControlPort), a                 ; 03D1: D3 BF
    xor a                                   ; 03D3: AF
    out (VDPControlPort), a                 ; 03D4: D3 BF
    ld a, $8a                               ; 03D6: 3E 8A
    out (VDPControlPort), a                 ; 03D8: D3 BF
    pop af                                  ; 03DA: F1
    ei                                      ; 03DB: FB
    ret                                     ; 03DC: C9
SplashAndTitleScreen:
    di                                      ; 03DD: F3
    ld de, GameState                        ; 03DE: 11 00 C0
    ld hl, $3996                            ; 03E1: 21 96 39
    ld b, $20                               ; 03E4: 06 20
    call WriteDataToVDP                     ; 03E6: CD 1E 00
    call MoveAllSpritesOffscreen            ; 03E9: CD 91 06
    ld hl, $6c00                            ; 03EC: 21 00 6C
    ld de, $63c1                            ; 03EF: 11 C1 63
    ld a, $00                               ; 03F2: 3E 00
    ex af, af'                              ; 03F4: 08
    call DecompressTiles                    ; 03F5: CD 8D 07
    ld hl, GameState                        ; 03F8: 21 00 C0
    ld a, (hl)                              ; 03FB: 7E
    bit 2, a                                ; 03FC: CB 57
    jr z, loc_040F                          ; 03FE: 28 0F
    ld a, (HaveDoneColdStart)               ; 0400: 3A 15 C0
    or a                                    ; 0403: B7
    jp p, loc_040F                          ; 0404: F2 0F 04
    ld a, ($c4c5)                           ; 0407: 3A C5 C4
    or a                                    ; 040A: B7
    jr nz, loc_040F                         ; 040B: 20 02
    ld (hl), $01                            ; 040D: 36 01
loc_040F:
    ld hl, GameState                        ; 040F: 21 00 C0
    xor a                                   ; 0412: AF
    ld (hl), a                              ; 0413: 77
    ld (HaveDoneColdStart), a               ; 0414: 32 15 C0
    call TurnScreenOff                      ; 0417: CD AA 06
    di                                      ; 041A: F3
    call BlankTilemapPalette2               ; 041B: CD 74 06
    ld hl, TitleScreenTextTable             ; 041E: 21 FC 04
    ld b, $07                               ; 0421: 06 07
loc_0423:
    ld e, (hl)                              ; 0423: 5E
    inc hl                                  ; 0424: 23
    ld d, (hl)                              ; 0425: 56
    inc hl                                  ; 0426: 23
    ld a, (hl)                              ; 0427: 7E
    inc hl                                  ; 0428: 23
    ld c, (hl)                              ; 0429: 4E
    inc hl                                  ; 042A: 23
    push hl                                 ; 042B: E5
    ld l, a                                 ; 042C: 6F
    ld h, c                                 ; 042D: 61
    call DrawNullTerminatedTilemap          ; 042E: CD FD 05
    pop hl                                  ; 0431: E1
    djnz loc_0423                           ; 0432: 10 EF
    ld hl, $78ca                            ; 0434: 21 CA 78
    ld de, HangOnLogoTilemap                ; 0437: 11 51 05
    ld bc, $1408                            ; 043A: 01 08 14
    call EmitTilemapRectangle               ; 043D: CD 94 36
    ld hl, $7ca2                            ; 0440: 21 A2 7C
    call WriteAAndHToVDPControl             ; 0443: CD 16 00
    ld hl, HighScoreBCD                     ; 0446: 21 C1 C4
    call DrawBCDThreeBytes                  ; 0449: CD A1 35
    xor a                                   ; 044C: AF
    ld (BackgroundXScroll), a               ; 044D: 32 51 C0
    ld ($c05a), a                           ; 0450: 32 5A C0
    call TurnScreenOn                       ; 0453: CD B5 06
    ei                                      ; 0456: FB
loc_0457:
    call WaitForVBlankAndClearPauseFlag     ; 0457: CD 08 00
    ld a, (Buttons)                         ; 045A: 3A 01 C0
    cpl                                     ; 045D: 2F
    and $30                                 ; 045E: E6 30
    jr nz, loc_0457                         ; 0460: 20 F5
    ld de, $00b4                            ; 0462: 11 B4 00
    ld hl, $c4c5                            ; 0465: 21 C5 C4
    dec (hl)                                ; 0468: 35
    jp p, loc_0484                          ; 0469: F2 84 04
    ld (hl), $00                            ; 046C: 36 00
    ld de, $01b8                            ; 046E: 11 B8 01
    ld a, ($c4c7)                           ; 0471: 3A C7 C4
    dec a                                   ; 0474: 3D
    ld ($c4c7), a                           ; 0475: 32 C7 C4
    jr nz, loc_0484                         ; 0478: 20 0A
    ld a, $03                               ; 047A: 3E 03
    ld ($c4c7), a                           ; 047C: 32 C7 C4
    ld a, $8f                               ; 047F: 3E 8F
    ld (SoundTrigger), a                    ; 0481: 32 00 C1
loc_0484:
    ld (TitleScreenTimeout), de             ; 0484: ED 53 23 C0
loc_0488:
    ld a, $1e                               ; 0488: 3E 1E
    ld (TitleScreenRepeatCounter), a        ; 048A: 32 22 C0
    ld hl, (TitleScreenTimeout)             ; 048D: 2A 23 C0
    ld de, $00f0                            ; 0490: 11 F0 00
    or a                                    ; 0493: B7
    sbc hl, de                              ; 0494: ED 52
    jr nc, loc_049C                         ; 0496: 30 04
    ld (TitleScreenTimeout), de             ; 0498: ED 53 23 C0
loc_049C:
    call WaitForVBlankAndClearPauseFlag     ; 049C: CD 08 00
    ld hl, Level                            ; 049F: 21 C0 C4
    ld a, (Buttons)                         ; 04A2: 3A 01 C0
    cpl                                     ; 04A5: 2F
    and $33                                 ; 04A6: E6 33
    jr nz, loc_04B9                         ; 04A8: 20 0F
    ld hl, (TitleScreenTimeout)             ; 04AA: 2A 23 C0
    dec hl                                  ; 04AD: 2B
    ld (TitleScreenTimeout), hl             ; 04AE: 22 23 C0
    ld a, h                                 ; 04B1: 7C
    or l                                    ; 04B2: B5
    jr nz, loc_049C                         ; 04B3: 20 E7
    ld a, $84                               ; 04B5: 3E 84
    jr loc_04EC                             ; 04B7: 18 33
loc_04B9:
    ld c, a                                 ; 04B9: 4F
    and $30                                 ; 04BA: E6 30
    jr nz, loc_04EA                         ; 04BC: 20 2C
    ld a, (ButtonsPrevious)                 ; 04BE: 3A 1A C0
    cpl                                     ; 04C1: 2F
    and $03                                 ; 04C2: E6 03
    cp c                                    ; 04C4: B9
    jr nz, loc_04D0                         ; 04C5: 20 09
    ld a, (TitleScreenRepeatCounter)        ; 04C7: 3A 22 C0
    dec a                                   ; 04CA: 3D
    ld (TitleScreenRepeatCounter), a        ; 04CB: 32 22 C0
    jr nz, loc_049C                         ; 04CE: 20 CC
loc_04D0:
    bit 0, c                                ; 04D0: CB 41
    jr nz, loc_04E2                         ; 04D2: 20 0E
    bit 1, c                                ; 04D4: CB 49
    jr z, loc_0488                          ; 04D6: 28 B0
    inc (hl)                                ; 04D8: 34
    ld a, (hl)                              ; 04D9: 7E
    cp $03                                  ; 04DA: FE 03
    jr nz, loc_0488                         ; 04DC: 20 AA
    ld (hl), $00                            ; 04DE: 36 00
    jr loc_0488                             ; 04E0: 18 A6
loc_04E2:
    dec (hl)                                ; 04E2: 35
    jp p, loc_0488                          ; 04E3: F2 88 04
    ld (hl), $02                            ; 04E6: 36 02
    jr loc_0488                             ; 04E8: 18 9E
loc_04EA:
    ld a, $80                               ; 04EA: 3E 80
loc_04EC:
    ld b, a                                 ; 04EC: 47
    xor a                                   ; 04ED: AF
    ld (SoundTrigger), a                    ; 04EE: 32 00 C1
    ld (HaveDoneColdStart), a               ; 04F1: 32 15 C0
    call WaitForVBlankAndClearPauseFlag     ; 04F4: CD 08 00
    ld a, b                                 ; 04F7: 78
    ld (GameState), a                       ; 04F8: 32 00 C0
    ret                                     ; 04FB: C9

; Title-screen text pointer/VRAM-address pairs.
TitleScreenTextTable:
    .dw TitlePushStart, $7b8e          ; 04FC: 26 05 8E 7B  ; PUSH START BUTTON
    .dw TitleLevelText, $7c18          ; 0500: 39 05 18 7C  ; LEVEL
    .dw TitleHighScoreText, $7c90      ; 0504: 40 05 90 7C  ; HI-SCORE
    .dw TitleTrademarkGlyphs, $78f2    ; 0508: 4A 05 F2 78  ; trademark glyphs
    .dw TitleHighScoreTrailingZero, $7cae ; 050C: 4E 05 AE 7C  ; high-score trailing zero
    .dw TitleCopyrightGlyphs, $7d94    ; 0510: 18 05 94 7D  ; copyright glyphs
    .dw TitleYear1985, $7da2           ; 0514: 20 05 A2 7D  ; year

TitleCopyrightGlyphs:
    .db $09, $ae, $20, $af, $b0, $b1, $b2, $00 ; 0518: 09 AE 20 AF B0 B1 B2 00
TitleYear1985:
    .db $01, "1985", $00                 ; 0520: 01 31 39 38 35 00
TitlePushStart:
    .db $09, "PUSH START BUTTON", $00    ; 0526: 09 50 55 53 48 20 53 54 41 52 54 20 42 55 54 54 4F 4E 00
TitleLevelText:
    .db $09, "LEVEL", $00                ; 0539: 09 4C 45 56 45 4C 00
TitleHighScoreText:
    .db $09, "HI;SCORE", $00             ; 0540: 09 48 49 3B 53 43 4F 52 45 00
TitleTrademarkGlyphs:
    .db $01, $b3, $b4, $00               ; 054A: 01 B3 B4 00
TitleHighScoreTrailingZero:
    .db $09, "0", $00                    ; 054E: 09 30 00

; 8 rows x 20 tile indices for the HANG-ON logo.
HangOnLogoTilemap:
    .db $20, $60, $61, $20, $62, $61, $20, $60, $61, $20, $62, $61, $20, $20, $20, $62, $61, $20, $60, $61 ; 0551: 20 60 61 20 62 61 20 60 61 20 62 61 20 20 20 62 61 20 60 61  ; row 0
    .db $63, $64, $65, $62, $66, $67, $68, $69, $65, $62, $66, $6a, $20, $20, $62, $66, $67, $68, $69, $65 ; 0565: 63 64 65 62 66 67 68 69 65 62 66 6A 20 20 62 66 67 68 69 65  ; row 1
    .db $6b, $6c, $6d, $6b, $6e, $6f, $6b, $70, $6d, $6b, $71, $72, $20, $20, $6b, $73, $6f, $6b, $70, $6d ; 0579: 6B 6C 6D 6B 6E 6F 6B 70 6D 6B 71 72 20 20 6B 73 6F 6B 70 6D  ; row 2
    .db $74, $75, $76, $74, $77, $78, $74, $79, $6d, $74, $7a, $7b, $62, $61, $74, $7c, $6d, $74, $79, $6d ; 058D: 74 75 76 74 77 78 74 79 6D 74 7A 7B 62 61 74 7C 6D 74 79 6D  ; row 3
    .db $74, $7d, $7e, $74, $7f, $6f, $74, $80, $81, $74, $82, $83, $6b, $6a, $74, $84, $6d, $74, $80, $81 ; 05A1: 74 7D 7E 74 7F 6F 74 80 81 74 82 83 6B 6A 74 84 6D 74 80 81  ; row 4
    .db $74, $84, $6d, $74, $7c, $6d, $74, $85, $81, $74, $86, $87, $88, $89, $74, $8a, $87, $74, $85, $81 ; 05B5: 74 84 6D 74 7C 6D 74 85 81 74 86 87 88 89 74 8A 87 74 85 81  ; row 5
    .db $74, $8b, $8c, $74, $8b, $8c, $74, $8d, $8e, $74, $8f, $8e, $20, $20, $74, $8f, $8e, $74, $8d, $8e ; 05C9: 74 8B 8C 74 8B 8C 74 8D 8E 74 8F 8E 20 20 74 8F 8E 74 8D 8E  ; row 6
    .db $90, $91, $20, $90, $91, $20, $90, $91, $20, $90, $8e, $20, $20, $20, $90, $8e, $20, $90, $91, $20 ; 05DD: 90 91 20 90 91 20 90 91 20 90 8E 20 20 20 90 8E 20 90 91 20  ; row 7

; ============================================================================
; Code $05F1
; ============================================================================
MultiplyHLByB:
    ld d, $00                               ; 05F1: 16 00
    ld l, d                                 ; 05F3: 6A
    ld b, $08                               ; 05F4: 06 08
loc_05F6:
    add hl, hl                              ; 05F6: 29
    jr nc, loc_05FA                         ; 05F7: 30 01
    add hl, de                              ; 05F9: 19
loc_05FA:
    djnz loc_05F6                           ; 05FA: 10 FA
    ret                                     ; 05FC: C9
DrawNullTerminatedTilemap:
    call WriteAAndHToVDPControl             ; 05FD: CD 16 00
    ld a, (de)                              ; 0600: 1A
    ld c, a                                 ; 0601: 4F
loc_0602:
    inc de                                  ; 0602: 13
    ld a, (de)                              ; 0603: 1A
    or a                                    ; 0604: B7
    ret z                                   ; 0605: C8
    out (VDPDataPort), a                    ; 0606: D3 BE
    ld a, c                                 ; 0608: 79
    ex (sp), hl                             ; 0609: E3
    ex (sp), hl                             ; 060A: E3
    out (VDPDataPort), a                    ; 060B: D3 BE
    jr loc_0602                             ; 060D: 18 F3
SetVDPRegisterCToB:
    ld a, b                                 ; 060F: 78
    out (VDPControlPort), a                 ; 0610: D3 BF
    ld a, c                                 ; 0612: 79
    out (VDPControlPort), a                 ; 0613: D3 BF
    ret                                     ; 0615: C9
WriteAToVDPAtHL:
    push af                                 ; 0616: F5
    call WriteAAndHToVDPControl             ; 0617: CD 16 00
    ex (sp), hl                             ; 061A: E3
    ex (sp), hl                             ; 061B: E3
    pop af                                  ; 061C: F1
    out (VDPDataPort), a                    ; 061D: D3 BE
    ret                                     ; 061F: C9
ReadAFromVDPAtHL:
    call WriteAAndHToVDPControl             ; 0620: CD 16 00
    ex (sp), hl                             ; 0623: E3
    ex (sp), hl                             ; 0624: E3
    in a, (VDPDataPort)                     ; 0625: DB BE
    ret                                     ; 0627: C9
CopyRAMToVRAM:
    ex de, hl                               ; 0628: EB
    call WriteAAndHToVDPControl             ; 0629: CD 16 00
    ex (sp), hl                             ; 062C: E3
    ex (sp), hl                             ; 062D: E3
loc_062E:
    ld a, (de)                              ; 062E: 1A
    out (VDPDataPort), a                    ; 062F: D3 BE
    inc de                                  ; 0631: 13
    dec bc                                  ; 0632: 0B
    ld a, b                                 ; 0633: 78
    or c                                    ; 0634: B1
    jr nz, loc_062E                         ; 0635: 20 F7
    ret                                     ; 0637: C9
CopyVRAMToRAM:
    call WriteAAndHToVDPControl             ; 0638: CD 16 00
    ex (sp), hl                             ; 063B: E3
    ex (sp), hl                             ; 063C: E3
loc_063D:
    in a, (VDPDataPort)                     ; 063D: DB BE
    ld (de), a                              ; 063F: 12
    inc de                                  ; 0640: 13
    dec bc                                  ; 0641: 0B
    ld a, b                                 ; 0642: 78
    or c                                    ; 0643: B1
    jr nz, loc_063D                         ; 0644: 20 F7
    ret                                     ; 0646: C9
CopyVRAMToVRAM:
    call ReadAFromVDPAtHL                   ; 0647: CD 20 06
    ex de, hl                               ; 064A: EB
    call WriteAToVDPAtHL                    ; 064B: CD 16 06
    ex de, hl                               ; 064E: EB
    inc hl                                  ; 064F: 23
    inc de                                  ; 0650: 13
    dec bc                                  ; 0651: 0B
    ld a, b                                 ; 0652: 78
    or c                                    ; 0653: B1
    jr nz, CopyVRAMToVRAM                   ; 0654: 20 F1
    ret                                     ; 0656: C9
BlankTilemapPalette1:
    ld hl, $7800                            ; 0657: 21 00 78
    ld bc, $0300                            ; 065A: 01 00 03
    push de                                 ; 065D: D5
    call WriteAAndHToVDPControl             ; 065E: CD 16 00
loc_0661:
    ex (sp), hl                             ; 0661: E3
    ex (sp), hl                             ; 0662: E3
    ld a, $20                               ; 0663: 3E 20
    out (VDPDataPort), a                    ; 0665: D3 BE
    ex (sp), hl                             ; 0667: E3
    ex (sp), hl                             ; 0668: E3
    ld a, $01                               ; 0669: 3E 01
    out (VDPDataPort), a                    ; 066B: D3 BE
    dec bc                                  ; 066D: 0B
    ld a, b                                 ; 066E: 78
    or c                                    ; 066F: B1
    jr nz, loc_0661                         ; 0670: 20 EF
    pop de                                  ; 0672: D1
    ret                                     ; 0673: C9
BlankTilemapPalette2:
    ld hl, $7800                            ; 0674: 21 00 78
    ld bc, $0300                            ; 0677: 01 00 03
    push de                                 ; 067A: D5
    call WriteAAndHToVDPControl             ; 067B: CD 16 00
loc_067E:
    ex (sp), hl                             ; 067E: E3
    ex (sp), hl                             ; 067F: E3
    ld a, $20                               ; 0680: 3E 20
    out (VDPDataPort), a                    ; 0682: D3 BE
    ex (sp), hl                             ; 0684: E3
    ex (sp), hl                             ; 0685: E3
    ld a, $09                               ; 0686: 3E 09
    out (VDPDataPort), a                    ; 0688: D3 BE
    dec bc                                  ; 068A: 0B
    ld a, b                                 ; 068B: 78
    or c                                    ; 068C: B1
    jr nz, loc_067E                         ; 068D: 20 EF
    pop de                                  ; 068F: D1
    ret                                     ; 0690: C9
MoveAllSpritesOffscreen:
    ld hl, $7f00                            ; 0691: 21 00 7F
    ld bc, $0040                            ; 0694: 01 40 00
    ld a, $ef                               ; 0697: 3E EF
FillVRAM:
    push de                                 ; 0699: D5
    ld d, a                                 ; 069A: 57
    call WriteAAndHToVDPControl             ; 069B: CD 16 00
    ex (sp), hl                             ; 069E: E3
    ex (sp), hl                             ; 069F: E3
loc_06A0:
    ld a, d                                 ; 06A0: 7A
    out (VDPDataPort), a                    ; 06A1: D3 BE
    dec bc                                  ; 06A3: 0B
    ld a, b                                 ; 06A4: 78
    or c                                    ; 06A5: B1
    jr nz, loc_06A0                         ; 06A6: 20 F8
    pop de                                  ; 06A8: D1
    ret                                     ; 06A9: C9
TurnScreenOff:
    push af                                 ; 06AA: F5
    ld a, $82                               ; 06AB: 3E 82
    out (VDPControlPort), a                 ; 06AD: D3 BF
    ld a, $81                               ; 06AF: 3E 81
    out (VDPControlPort), a                 ; 06B1: D3 BF
    pop af                                  ; 06B3: F1
    ret                                     ; 06B4: C9
TurnScreenOn:
    push af                                 ; 06B5: F5
    ld a, $e2                               ; 06B6: 3E E2
    out (VDPControlPort), a                 ; 06B8: D3 BF
    ld a, $81                               ; 06BA: 3E 81
    out (VDPControlPort), a                 ; 06BC: D3 BF
    pop af                                  ; 06BE: F1
    ret                                     ; 06BF: C9
SetVDPRegisters:
    ld hl, $0759                            ; 06C0: 21 59 07
    ld c, $80                               ; 06C3: 0E 80
    ld e, $0b                               ; 06C5: 1E 0B
loc_06C7:
    ld b, (hl)                              ; 06C7: 46
    call SetVDPRegisterCToB                 ; 06C8: CD 0F 06
    inc hl                                  ; 06CB: 23
    inc c                                   ; 06CC: 0C
    dec e                                   ; 06CD: 1D
    jr nz, loc_06C7                         ; 06CE: 20 F7
    ret                                     ; 06D0: C9
InitializeDisplay:
    di                                      ; 06D1: F3
    in a, (VDPControlPort)                  ; 06D2: DB BF
    call SetVDPRegisters                    ; 06D4: CD C0 06
    ld hl, $3996                            ; 06D7: 21 96 39
    ld de, GameState                        ; 06DA: 11 00 C0
    ld b, $20                               ; 06DD: 06 20
    call WriteDataToVDP                     ; 06DF: CD 1E 00
    ld hl, $7f00                            ; 06E2: 21 00 7F
    ld bc, $0100                            ; 06E5: 01 00 01
    xor a                                   ; 06E8: AF
    call FillVRAM                           ; 06E9: CD 99 06
    ld de, $4e20                            ; 06EC: 11 20 4E
    ld hl, $4000                            ; 06EF: 21 00 40
    ld a, $00                               ; 06F2: 3E 00
    ex af, af'                              ; 06F4: 08
    call DecompressTiles                    ; 06F5: CD 8D 07
    ld de, $5903                            ; 06F8: 11 03 59
    ld hl, RAMTiles                         ; 06FB: 21 00 C7
    ld a, $ff                               ; 06FE: 3E FF
    ex af, af'                              ; 0700: 08
    call DecompressTiles                    ; 0701: CD 8D 07
    call ReverseFlipAndEmitTiles            ; 0704: CD C4 07
    ld hl, $0400                            ; 0707: 21 00 04
    ld de, GoSignTiles                      ; 070A: 11 E0 D7
    ld bc, $00c0                            ; 070D: 01 C0 00
    call CopyVRAMToRAM                      ; 0710: CD 38 06
    ld hl, $0cc0                            ; 0713: 21 C0 0C
    ld de, BikeSpriteTiles                  ; 0716: 11 A0 D8
    ld bc, $0700                            ; 0719: 01 00 07
    call CopyVRAMToRAM                      ; 071C: CD 38 06
LoadInitialGraphics:
    di                                      ; 071F: F3
    call TurnScreenOff                      ; 0720: CD AA 06
    ld hl, $6000                            ; 0723: 21 00 60
    ld de, $3f00                            ; 0726: 11 00 3F
    ld a, $00                               ; 0729: 3E 00
    ex af, af'                              ; 072B: 08
    call DecompressTiles                    ; 072C: CD 8D 07
    ld hl, $3800                            ; 072F: 21 00 38
    ld de, $7e00                            ; 0732: 11 00 7E
    ld bc, $0100                            ; 0735: 01 00 01
    call CopyVRAMToVRAM                     ; 0738: CD 47 06
    ld hl, RAMTiles                         ; 073B: 21 00 C7
    ld de, $5d40                            ; 073E: 11 40 5D
    ld bc, $02c0                            ; 0741: 01 C0 02
    call CopyRAMToVRAM                      ; 0744: CD 28 06
    ld hl, BikeSpriteTiles                  ; 0747: 21 A0 D8
    ld de, $4cc0                            ; 074A: 11 C0 4C
    ld bc, $0700                            ; 074D: 01 00 07
    call CopyRAMToVRAM                      ; 0750: CD 28 06
    call BlankTilemapPalette1               ; 0753: CD 57 06
    jp MoveAllSpritesOffscreen              ; 0756: C3 91 06

; ----------------------------------------------------------------------------
; ROM data $0759-$0763 (11 bytes)
; ----------------------------------------------------------------------------
RomData_0759:
    .db $66, $82, $ff, $ff, $ff, $ff, $fb, $00, $00, $00, $ff ; 0759: 66 82 FF FF FF FF FB 00 00 00 FF

; ============================================================================
; Code $0764
; ============================================================================
ReadControls:
    ld a, (Buttons)                         ; 0764: 3A 01 C0
    ld (ButtonsPrevious), a                 ; 0767: 32 1A C0
    in a, (ControllerPort1)                 ; 076A: DB DC
    ld hl, GameState                        ; 076C: 21 00 C0
    bit 2, (hl)                             ; 076F: CB 56
    ret z                                   ; 0771: C8
    cpl                                     ; 0772: 2F
    and $30                                 ; 0773: E6 30
    jp z, DemoControls                      ; 0775: CA AB 3D
    ld hl, HaveDoneColdStart                ; 0778: 21 15 C0
    ld (hl), $01                            ; 077B: 36 01
    ld a, $ff                               ; 077D: 3E FF
    ret                                     ; 077F: C9
Delay:
    ld b, $03                               ; 0780: 06 03
loc_0782:
    ld de, $0000                            ; 0782: 11 00 00
loc_0785:
    dec de                                  ; 0785: 1B
    ld a, d                                 ; 0786: 7A
    or e                                    ; 0787: B3
    jr nz, loc_0785                         ; 0788: 20 FB
    djnz loc_0782                           ; 078A: 10 F6
    ret                                     ; 078C: C9
; Custom compressed graphics decoder.
DecompressTiles:
    ld b, $04                               ; 078D: 06 04
loc_078F:
    push bc                                 ; 078F: C5
    push hl                                 ; 0790: E5
    call DecompressBitplane                 ; 0791: CD 9A 07
    pop hl                                  ; 0794: E1
    inc hl                                  ; 0795: 23
    pop bc                                  ; 0796: C1
    djnz loc_078F                           ; 0797: 10 F6
    ret                                     ; 0799: C9
DecompressBitplane:
    ld a, (de)                              ; 079A: 1A
    inc de                                  ; 079B: 13
    or a                                    ; 079C: B7
    ret z                                   ; 079D: C8
    ld c, a                                 ; 079E: 4F
    and $7f                                 ; 079F: E6 7F
    ld b, a                                 ; 07A1: 47
loc_07A2:
    ld a, (de)                              ; 07A2: 1A
    ex af, af'                              ; 07A3: 08
    or a                                    ; 07A4: B7
    jr nz, loc_07AD                         ; 07A5: 20 06
    ex af, af'                              ; 07A7: 08
    call WriteAToVDPAtHL                    ; 07A8: CD 16 06
    jr loc_07AF                             ; 07AB: 18 02
loc_07AD:
    ex af, af'                              ; 07AD: 08
    ld (hl), a                              ; 07AE: 77
loc_07AF:
    bit 7, c                                ; 07AF: CB 79
    jr z, loc_07B4                          ; 07B1: 28 01
    inc de                                  ; 07B3: 13
loc_07B4:
    inc hl                                  ; 07B4: 23
    inc hl                                  ; 07B5: 23
    inc hl                                  ; 07B6: 23
    inc hl                                  ; 07B7: 23
    djnz loc_07A2                           ; 07B8: 10 E8
    bit 7, c                                ; 07BA: CB 79
    jr nz, DecompressBitplane               ; 07BC: 20 DC
    inc de                                  ; 07BE: 13
    jr DecompressBitplane                   ; 07BF: 18 D9

; ----------------------------------------------------------------------------
; ROM data $07C1-$07C3 (3 bytes)
; ----------------------------------------------------------------------------
RomData_07C1:
    .db $52, $45, $56                       ; 07C1: 52 45 56

; ============================================================================
; Code $07C4
; ============================================================================
ReverseFlipAndEmitTiles:
    ld hl, $04c0                            ; 07C4: 21 C0 04
    ld de, $5d00                            ; 07C7: 11 00 5D
    ld b, $31                               ; 07CA: 06 31
loc_07CC:
    push bc                                 ; 07CC: C5
    push hl                                 ; 07CD: E5
    push de                                 ; 07CE: D5
    ld de, TileFlipBuffer                   ; 07CF: 11 80 C6
    ld bc, $0040                            ; 07D2: 01 40 00
    call CopyVRAMToRAM                      ; 07D5: CD 38 06
    call loc_07F5                           ; 07D8: CD F5 07
    pop de                                  ; 07DB: D1
    push de                                 ; 07DC: D5
    ld hl, TileFlipBuffer                   ; 07DD: 21 80 C6
    ld bc, $0040                            ; 07E0: 01 40 00
    call CopyRAMToVRAM                      ; 07E3: CD 28 06
    pop de                                  ; 07E6: D1
    ld hl, $ffc0                            ; 07E7: 21 C0 FF
    add hl, de                              ; 07EA: 19
    ex de, hl                               ; 07EB: EB
    pop hl                                  ; 07EC: E1
    ld bc, $0040                            ; 07ED: 01 40 00
    add hl, bc                              ; 07F0: 09
    pop bc                                  ; 07F1: C1
    djnz loc_07CC                           ; 07F2: 10 D8
    ret                                     ; 07F4: C9
loc_07F5:
    push bc                                 ; 07F5: C5
    push hl                                 ; 07F6: E5
    ld b, $40                               ; 07F7: 06 40
    ld hl, TileFlipBuffer                   ; 07F9: 21 80 C6
loc_07FC:
    push bc                                 ; 07FC: C5
    ld a, (hl)                              ; 07FD: 7E
    ld b, $08                               ; 07FE: 06 08
loc_0800:
    rrca                                    ; 0800: 0F
    rl c                                    ; 0801: CB 11
    djnz loc_0800                           ; 0803: 10 FB
    ld (hl), c                              ; 0805: 71
    pop bc                                  ; 0806: C1
    inc hl                                  ; 0807: 23
    djnz loc_07FC                           ; 0808: 10 F2
    pop hl                                  ; 080A: E1
    pop bc                                  ; 080B: C1
    ret                                     ; 080C: C9

; ----------------------------------------------------------------------------
; ROM data $080D-$0958 (332 bytes)
; ----------------------------------------------------------------------------
RoadTilemapHudLabels:
    .incbin "../assets/road_tilemap_hud_labels.bin"

; ============================================================================
; Code $0959
; ============================================================================
; Road renderer and scanline scroll-table generator.
DrawRoad:
    ld hl, $7b00                            ; 0959: 21 00 7B
    ld de, $080d                            ; 095C: 11 0D 08
    ld c, $0c                               ; 095F: 0E 0C
loc_0961:
    call WriteAAndHToVDPControl             ; 0961: CD 16 00
    ld b, $10                               ; 0964: 06 10
loc_0966:
    ld a, (de)                              ; 0966: 1A
    out (VDPDataPort), a                    ; 0967: D3 BE
    ex (sp), hl                             ; 0969: E3
    ex (sp), hl                             ; 096A: E3
    ld a, $01                               ; 096B: 3E 01
    out (VDPDataPort), a                    ; 096D: D3 BE
    ex (sp), hl                             ; 096F: E3
    ex (sp), hl                             ; 0970: E3
    inc de                                  ; 0971: 13
    djnz loc_0966                           ; 0972: 10 F2
    inc de                                  ; 0974: 13
    push de                                 ; 0975: D5
    ld de, $0040                            ; 0976: 11 40 00
    add hl, de                              ; 0979: 19
    pop de                                  ; 097A: D1
    dec c                                   ; 097B: 0D
    jr nz, loc_0961                         ; 097C: 20 E3
    ld hl, $7de0                            ; 097E: 21 E0 7D
    ld de, $08d8                            ; 0981: 11 D8 08
    ld c, $0c                               ; 0984: 0E 0C
loc_0986:
    call WriteAAndHToVDPControl             ; 0986: CD 16 00
    ld b, $10                               ; 0989: 06 10
loc_098B:
    ld a, (de)                              ; 098B: 1A
    out (VDPDataPort), a                    ; 098C: D3 BE
    ex (sp), hl                             ; 098E: E3
    ex (sp), hl                             ; 098F: E3
    ld a, $03                               ; 0990: 3E 03
    out (VDPDataPort), a                    ; 0992: D3 BE
    ex (sp), hl                             ; 0994: E3
    ex (sp), hl                             ; 0995: E3
    dec de                                  ; 0996: 1B
    djnz loc_098B                           ; 0997: 10 F2
    dec de                                  ; 0999: 1B
    push de                                 ; 099A: D5
    ld de, $ffc0                            ; 099B: 11 C0 FF
    add hl, de                              ; 099E: 19
    pop de                                  ; 099F: D1
    dec c                                   ; 09A0: 0D
    jr nz, loc_0986                         ; 09A1: 20 E3
    ld hl, $08d9                            ; 09A3: 21 D9 08
    ld de, $7802                            ; 09A6: 11 02 78
    ld b, $7e                               ; 09A9: 06 7E
    call WriteDataToVDP                     ; 09AB: CD 1E 00
    ret                                     ; 09AE: C9
ObjectHandlerType01:
    ld a, ($c301)                           ; 09AF: 3A 01 C3
    bit 7, a                                ; 09B2: CB 7F
    jr nz, loc_09C7                         ; 09B4: 20 11
    bit 6, a                                ; 09B6: CB 77
    jp nz, loc_0EA1                         ; 09B8: C2 A1 0E
    ld de, $c301                            ; 09BB: 11 01 C3
    ld hl, $0f9d                            ; 09BE: 21 9D 0F
    ld bc, $001f                            ; 09C1: 01 1F 00
    ldir                                    ; 09C4: ED B0
    ret                                     ; 09C6: C9
loc_09C7:
    ld a, (Buttons)                         ; 09C7: 3A 01 C0
    ld (PlayerControls), a                  ; 09CA: 32 16 C3
    ld a, (GameState)                       ; 09CD: 3A 00 C0
    bit 5, a                                ; 09D0: CB 6F
    jp nz, loc_0EDE                         ; 09D2: C2 DE 0E
    bit 6, a                                ; 09D5: CB 77
    jr z, loc_09E2                          ; 09D7: 28 09
    ld (ix+1), $80                          ; 09D9: DD 36 01 80
    ld (ix+10), $03                         ; 09DD: DD 36 0A 03
    ret                                     ; 09E1: C9
loc_09E2:
    ld a, (TimeLeft)                        ; 09E2: 3A 0D C0
    or a                                    ; 09E5: B7
    jr nz, loc_09F0                         ; 09E6: 20 08
    set 5, (ix+22)                          ; 09E8: DD CB 16 EE
    res 4, (ix+22)                          ; 09EC: DD CB 16 A6
loc_09F0:
    ld (ix+1), $80                          ; 09F0: DD 36 01 80
    ld a, ($c309)                           ; 09F4: 3A 09 C3
    or a                                    ; 09F7: B7
    jr z, loc_0A02                          ; 09F8: 28 08
    ld (ix+31), $ff                         ; 09FA: DD 36 1F FF
    ld (ix+9), $00                          ; 09FE: DD 36 09 00
loc_0A02:
    ld a, (Gear)                            ; 0A02: 3A 18 C3
    sub $01                                 ; 0A05: D6 01
    jr c, loc_0A1B                          ; 0A07: 38 12
    jr z, loc_0A13                          ; 0A09: 28 08
    ld de, $0fbc                            ; 0A0B: 11 BC 0F
    ld bc, $fed3                            ; 0A0E: 01 D3 FE
    jr loc_0A21                             ; 0A11: 18 0E
loc_0A13:
    ld de, $1016                            ; 0A13: 11 16 10
    ld bc, $ff32                            ; 0A16: 01 32 FF
    jr loc_0A21                             ; 0A19: 18 06
loc_0A1B:
    ld de, $1070                            ; 0A1B: 11 70 10
    ld bc, $ff8c                            ; 0A1E: 01 8C FF
loc_0A21:
    ld hl, (SpeedMiddle)                    ; 0A21: 2A 1A C3
    add hl, bc                              ; 0A24: 09
    ld bc, $ff00                            ; 0A25: 01 00 FF
    jr c, loc_0A4C                          ; 0A28: 38 22
    ld a, (PlayerControls)                  ; 0A2A: 3A 16 C3
    bit 5, a                                ; 0A2D: CB 6F
    ld bc, $ffb4                            ; 0A2F: 01 B4 FF
    jr nz, loc_0A4C                         ; 0A32: 20 18
    ld hl, (SpeedMiddle)                    ; 0A34: 2A 1A C3
    add hl, de                              ; 0A37: 19
    ld e, (hl)                              ; 0A38: 5E
    ld d, $00                               ; 0A39: 16 00
    ld hl, (SpeedLow)                       ; 0A3B: 2A 19 C3
    add hl, de                              ; 0A3E: 19
    ld (SpeedLow), hl                       ; 0A3F: 22 19 C3
    ld a, (SpeedHigh)                       ; 0A42: 3A 1B C3
    adc a, $00                              ; 0A45: CE 00
    ld (SpeedHigh), a                       ; 0A47: 32 1B C3
    jr loc_0A6B                             ; 0A4A: 18 1F
loc_0A4C:
    ld hl, (SpeedLow)                       ; 0A4C: 2A 19 C3
    add hl, bc                              ; 0A4F: 09
    ld (SpeedLow), hl                       ; 0A50: 22 19 C3
    ld a, (SpeedHigh)                       ; 0A53: 3A 1B C3
    adc a, $ff                              ; 0A56: CE FF
    ld (SpeedHigh), a                       ; 0A58: 32 1B C3
    jr c, loc_0A6B                          ; 0A5B: 38 0E
    ld hl, $0000                            ; 0A5D: 21 00 00
    ld (SpeedMiddle), hl                    ; 0A60: 22 1A C3
    ld (SpeedLow), hl                       ; 0A63: 22 19 C3
    ld ($c31c), hl                          ; 0A66: 22 1C C3
    jr loc_0AC2                             ; 0A69: 18 57
loc_0A6B:
    ld a, (PlayerControls)                  ; 0A6B: 3A 16 C3
    bit 4, a                                ; 0A6E: CB 67
    jr nz, loc_0A94                         ; 0A70: 20 22
    ld de, $ff34                            ; 0A72: 11 34 FF
    ld hl, (SpeedLow)                       ; 0A75: 2A 19 C3
    add hl, de                              ; 0A78: 19
    ld (SpeedLow), hl                       ; 0A79: 22 19 C3
    ld a, (SpeedHigh)                       ; 0A7C: 3A 1B C3
    adc a, $ff                              ; 0A7F: CE FF
    ld (SpeedHigh), a                       ; 0A81: 32 1B C3
    jr c, loc_0A94                          ; 0A84: 38 0E
    ld hl, $0000                            ; 0A86: 21 00 00
    ld (SpeedMiddle), hl                    ; 0A89: 22 1A C3
    ld (SpeedLow), hl                       ; 0A8C: 22 19 C3
    ld ($c31c), hl                          ; 0A8F: 22 1C C3
    jr loc_0AC2                             ; 0A92: 18 2E
loc_0A94:
    ld hl, (SpeedMiddle)                    ; 0A94: 2A 1A C3
    srl h                                   ; 0A97: CB 3C
    rr l                                    ; 0A99: CB 1D
    ld a, (Gear)                            ; 0A9B: 3A 18 C3
    sub $01                                 ; 0A9E: D6 01
    jr c, loc_0AA9                          ; 0AA0: 38 07
    jr z, loc_0AB0                          ; 0AA2: 28 0C
    ld de, $11d3                            ; 0AA4: 11 D3 11
    jr loc_0ABD                             ; 0AA7: 18 14
loc_0AA9:
    ld b, $60                               ; 0AA9: 06 60
    ld de, $10e8                            ; 0AAB: 11 E8 10
    jr loc_0AB5                             ; 0AAE: 18 05
loc_0AB0:
    ld b, $8e                               ; 0AB0: 06 8E
    ld de, $1147                            ; 0AB2: 11 47 11
loc_0AB5:
    ld a, l                                 ; 0AB5: 7D
    cp b                                    ; 0AB6: B8
    jr c, loc_0ABD                          ; 0AB7: 38 04
    ld a, $3f                               ; 0AB9: 3E 3F
    jr loc_0ABF                             ; 0ABB: 18 02
loc_0ABD:
    add hl, de                              ; 0ABD: 19
    ld a, (hl)                              ; 0ABE: 7E
loc_0ABF:
    ld (BikeRPM), a                         ; 0ABF: 32 1D C3
loc_0AC2:
    ld a, (PlayerControls)                  ; 0AC2: 3A 16 C3
    cpl                                     ; 0AC5: 2F
    and $03                                 ; 0AC6: E6 03
    jr z, loc_0AEF                          ; 0AC8: 28 25
    ld b, a                                 ; 0ACA: 47
    ld a, ($c317)                           ; 0ACB: 3A 17 C3
    cpl                                     ; 0ACE: 2F
    and $03                                 ; 0ACF: E6 03
    cp b                                    ; 0AD1: B8
    jr z, loc_0AEF                          ; 0AD2: 28 1B
    dec b                                   ; 0AD4: 05
    jr nz, loc_0AE0                         ; 0AD5: 20 09
    ld a, (Gear)                            ; 0AD7: 3A 18 C3
    or a                                    ; 0ADA: B7
    jr z, loc_0AEF                          ; 0ADB: 28 12
    dec a                                   ; 0ADD: 3D
    jr loc_0AE8                             ; 0ADE: 18 08
loc_0AE0:
    ld a, (Gear)                            ; 0AE0: 3A 18 C3
    cp $02                                  ; 0AE3: FE 02
    jr z, loc_0AEF                          ; 0AE5: 28 08
    inc a                                   ; 0AE7: 3C
loc_0AE8:
    ld (Gear), a                            ; 0AE8: 32 18 C3
    ld (ix+9), $ff                          ; 0AEB: DD 36 09 FF
loc_0AEF:
    ld hl, ($c2f5)                          ; 0AEF: 2A F5 C2
    ld d, h                                 ; 0AF2: 54
    ld e, l                                 ; 0AF3: 5D
    bit 7, h                                ; 0AF4: CB 7C
    jr nz, loc_0B1A                         ; 0AF6: 20 22
    ld bc, $fe40                            ; 0AF8: 01 40 FE
    add hl, bc                              ; 0AFB: 09
    ld b, $06                               ; 0AFC: 06 06
    jp c, loc_0B37                          ; 0AFE: DA 37 0B
    ld h, d                                 ; 0B01: 62
    ld l, e                                 ; 0B02: 6B
    ld bc, $ff00                            ; 0B03: 01 00 FF
    add hl, bc                              ; 0B06: 09
    ld b, $05                               ; 0B07: 06 05
    jp c, loc_0B37                          ; 0B09: DA 37 0B
    ex de, hl                               ; 0B0C: EB
    ld bc, $ffc0                            ; 0B0D: 01 C0 FF
    add hl, bc                              ; 0B10: 09
    ld b, $04                               ; 0B11: 06 04
    jp c, loc_0B37                          ; 0B13: DA 37 0B
    ld b, $00                               ; 0B16: 06 00
    jr loc_0B37                             ; 0B18: 18 1D
loc_0B1A:
    ld bc, $01c0                            ; 0B1A: 01 C0 01
    add hl, bc                              ; 0B1D: 09
    ld b, $01                               ; 0B1E: 06 01
    jr nc, loc_0B37                         ; 0B20: 30 15
    ld h, d                                 ; 0B22: 62
    ld l, e                                 ; 0B23: 6B
    ld bc, $0100                            ; 0B24: 01 00 01
    add hl, bc                              ; 0B27: 09
    ld b, $02                               ; 0B28: 06 02
    jr nc, loc_0B37                         ; 0B2A: 30 0B
    ex de, hl                               ; 0B2C: EB
    ld bc, $0040                            ; 0B2D: 01 40 00
    add hl, bc                              ; 0B30: 09
    ld b, $03                               ; 0B31: 06 03
    jr nc, loc_0B37                         ; 0B33: 30 02
    ld b, $00                               ; 0B35: 06 00
loc_0B37:
    ld (ix+12), b                           ; 0B37: DD 70 0C
    ld a, ($c315)                           ; 0B3A: 3A 15 C3
    or a                                    ; 0B3D: B7
    jp nz, loc_0F0B                         ; 0B3E: C2 0B 0F
    ld a, (PlayerControls)                  ; 0B41: 3A 16 C3
    bit 2, a                                ; 0B44: CB 57
    jp z, loc_0D70                          ; 0B46: CA 70 0D
    bit 3, a                                ; 0B49: CB 5F
    jp z, loc_0E04                          ; 0B4B: CA 04 0E
    ld hl, $0000                            ; 0B4E: 21 00 00
    ld ($c30e), hl                          ; 0B51: 22 0E C3
    ld b, $00                               ; 0B54: 06 00
    ld a, ($c30c)                           ; 0B56: 3A 0C C3
    or a                                    ; 0B59: B7
    jr z, loc_0B78                          ; 0B5A: 28 1C
    cp $03                                  ; 0B5C: FE 03
    jr z, loc_0B78                          ; 0B5E: 28 18
    cp $04                                  ; 0B60: FE 04
    jr z, loc_0B78                          ; 0B62: 28 14
    jr c, loc_0B70                          ; 0B64: 38 0A
    ld a, (PlayerAnimationFrame)            ; 0B66: 3A 0A C3
    bit 2, a                                ; 0B69: CB 57
    jr z, loc_0B78                          ; 0B6B: 28 0B
    dec b                                   ; 0B6D: 05
    jr loc_0B78                             ; 0B6E: 18 08
loc_0B70:
    ld a, (PlayerAnimationFrame)            ; 0B70: 3A 0A C3
    cp $03                                  ; 0B73: FE 03
    jr nc, loc_0B78                         ; 0B75: 30 01
    dec b                                   ; 0B77: 05
loc_0B78:
    ld a, b                                 ; 0B78: 78
    ld ($c308), a                           ; 0B79: 32 08 C3
    ld hl, (SpeedMiddle)                    ; 0B7C: 2A 1A C3
    ld de, $fff6                            ; 0B7F: 11 F6 FF
    add hl, de                              ; 0B82: 19
    jr nc, loc_0BAE                         ; 0B83: 30 29
    ld a, ($c30c)                           ; 0B85: 3A 0C C3
    or a                                    ; 0B88: B7
    jr z, loc_0BAE                          ; 0B89: 28 23
    cp $03                                  ; 0B8B: FE 03
    jr z, loc_0BAE                          ; 0B8D: 28 1F
    cp $04                                  ; 0B8F: FE 04
    jr z, loc_0BAE                          ; 0B91: 28 1B
    ld a, ($c30d)                           ; 0B93: 3A 0D C3
    jr nc, loc_0B9E                         ; 0B96: 30 06
    cp $02                                  ; 0B98: FE 02
    jr z, loc_0BAE                          ; 0B9A: 28 12
    jr loc_0BA1                             ; 0B9C: 18 03
loc_0B9E:
    dec a                                   ; 0B9E: 3D
    jr z, loc_0BAE                          ; 0B9F: 28 0D
loc_0BA1:
    ld a, (PlayerAnimationFrame)            ; 0BA1: 3A 0A C3
    bit 0, a                                ; 0BA4: CB 47
    jr nz, loc_0BE0                         ; 0BA6: 20 38
    ld (ix+11), $00                         ; 0BA8: DD 36 0B 00
    jr loc_0BE0                             ; 0BAC: 18 32
loc_0BAE:
    ld a, (PlayerControls)                  ; 0BAE: 3A 16 C3
    cpl                                     ; 0BB1: 2F
    and $0c                                 ; 0BB2: E6 0C
    jr nz, loc_0BC5                         ; 0BB4: 20 0F
    ld a, ($c304)                           ; 0BB6: 3A 04 C3
    inc a                                   ; 0BB9: 3C
    ld ($c304), a                           ; 0BBA: 32 04 C3
    cp $07                                  ; 0BBD: FE 07
    jr c, loc_0BE0                          ; 0BBF: 38 1F
    xor a                                   ; 0BC1: AF
    ld ($c304), a                           ; 0BC2: 32 04 C3
loc_0BC5:
    ld a, (PlayerAnimationFrame)            ; 0BC5: 3A 0A C3
    cp $03                                  ; 0BC8: FE 03
    inc a                                   ; 0BCA: 3C
    jr c, loc_0BDD                          ; 0BCB: 38 10
    cp $05                                  ; 0BCD: FE 05
    dec a                                   ; 0BCF: 3D
    dec a                                   ; 0BD0: 3D
    jr nc, loc_0BDD                         ; 0BD1: 30 0A
    ld (ix+13), $00                         ; 0BD3: DD 36 0D 00
    ld (ix+11), $00                         ; 0BD7: DD 36 0B 00
    ld a, $03                               ; 0BDB: 3E 03
loc_0BDD:
    ld (PlayerAnimationFrame), a            ; 0BDD: 32 0A C3
loc_0BE0:
    ld a, ($c30c)                           ; 0BE0: 3A 0C C3
    cp $04                                  ; 0BE3: FE 04
    jr c, loc_0C0D                          ; 0BE5: 38 26
    jr z, loc_0C3B                          ; 0BE7: 28 52
    ld hl, (SpeedMiddle)                    ; 0BE9: 2A 1A C3
    ex de, hl                               ; 0BEC: EB
    cp $06                                  ; 0BED: FE 06
    jr nz, loc_0BFA                         ; 0BEF: 20 09
    ld l, e                                 ; 0BF1: 6B
    ld h, d                                 ; 0BF2: 62
    add hl, hl                              ; 0BF3: 29
    add hl, de                              ; 0BF4: 19
    srl h                                   ; 0BF5: CB 3C
    rr l                                    ; 0BF7: CB 1D
    ex de, hl                               ; 0BF9: EB
loc_0BFA:
    ld a, ($c308)                           ; 0BFA: 3A 08 C3
    or a                                    ; 0BFD: B7
    jr z, loc_0C04                          ; 0BFE: 28 04
    srl d                                   ; 0C00: CB 3A
    rr e                                    ; 0C02: CB 1B
loc_0C04:
    ld hl, ($c30e)                          ; 0C04: 2A 0E C3
    add hl, de                              ; 0C07: 19
    ld ($c30e), hl                          ; 0C08: 22 0E C3
    jr loc_0C3B                             ; 0C0B: 18 2E
loc_0C0D:
    or a                                    ; 0C0D: B7
    jr z, loc_0C3B                          ; 0C0E: 28 2B
    cp $03                                  ; 0C10: FE 03
    jr z, loc_0C3B                          ; 0C12: 28 27
    ld hl, (SpeedMiddle)                    ; 0C14: 2A 1A C3
    dec a                                   ; 0C17: 3D
    jr nz, loc_0C22                         ; 0C18: 20 08
    ld e, l                                 ; 0C1A: 5D
    ld d, h                                 ; 0C1B: 54
    add hl, hl                              ; 0C1C: 29
    add hl, de                              ; 0C1D: 19
    srl h                                   ; 0C1E: CB 3C
    rr l                                    ; 0C20: CB 1D
loc_0C22:
    ld a, ($c308)                           ; 0C22: 3A 08 C3
    or a                                    ; 0C25: B7
    jr z, loc_0C2C                          ; 0C26: 28 04
    srl h                                   ; 0C28: CB 3C
    rr l                                    ; 0C2A: CB 1D
loc_0C2C:
    ld a, l                                 ; 0C2C: 7D
    cpl                                     ; 0C2D: 2F
    ld l, a                                 ; 0C2E: 6F
    ld a, h                                 ; 0C2F: 7C
    cpl                                     ; 0C30: 2F
    ld h, a                                 ; 0C31: 67
    inc hl                                  ; 0C32: 23
    ex de, hl                               ; 0C33: EB
    ld hl, ($c30e)                          ; 0C34: 2A 0E C3
    add hl, de                              ; 0C37: 19
    ld ($c30e), hl                          ; 0C38: 22 0E C3
loc_0C3B:
    ld hl, ($c30e)                          ; 0C3B: 2A 0E C3
    ex de, hl                               ; 0C3E: EB
    ld l, (ix+30)                           ; 0C3F: DD 6E 1E
    ld a, ($c013)                           ; 0C42: 3A 13 C0
    ld h, a                                 ; 0C45: 67
    add hl, de                              ; 0C46: 19
    ld a, h                                 ; 0C47: 7C
    cp $c0                                  ; 0C48: FE C0
    jr nc, loc_0C55                         ; 0C4A: 30 09
    cp $a9                                  ; 0C4C: FE A9
    jr c, loc_0C58                          ; 0C4E: 38 08
    ld hl, $a800                            ; 0C50: 21 00 A8
    jr loc_0C58                             ; 0C53: 18 03
loc_0C55:
    ld hl, $0000                            ; 0C55: 21 00 00
loc_0C58:
    ld (ix+30), l                           ; 0C58: DD 75 1E
    ld a, h                                 ; 0C5B: 7C
    ld ($c013), a                           ; 0C5C: 32 13 C0
    ld a, $01                               ; 0C5F: 3E 01
    ld ($c033), a                           ; 0C61: 32 33 C0
loc_0C64:
    ld (ix+2), $b6                          ; 0C64: DD 36 02 B6
    ld a, ($c013)                           ; 0C68: 3A 13 C0
    cp $12                                  ; 0C6B: FE 12
    jr c, loc_0C73                          ; 0C6D: 38 04
    cp $97                                  ; 0C6F: FE 97
    jr c, loc_0CE6                          ; 0C71: 38 73
loc_0C73:
    ld de, $ffb4                            ; 0C73: 11 B4 FF
    ld a, (Gear)                            ; 0C76: 3A 18 C3
    or a                                    ; 0C79: B7
    jr z, loc_0C87                          ; 0C7A: 28 0B
    sla e                                   ; 0C7C: CB 23
    rl d                                    ; 0C7E: CB 12
    dec a                                   ; 0C80: 3D
    jr z, loc_0C87                          ; 0C81: 28 04
    sla e                                   ; 0C83: CB 23
    rl d                                    ; 0C85: CB 12
loc_0C87:
    ld hl, (SpeedLow)                       ; 0C87: 2A 19 C3
    add hl, de                              ; 0C8A: 19
    ld (SpeedLow), hl                       ; 0C8B: 22 19 C3
    ld a, (SpeedHigh)                       ; 0C8E: 3A 1B C3
    adc a, $ff                              ; 0C91: CE FF
    ld (SpeedHigh), a                       ; 0C93: 32 1B C3
    jr c, loc_0CA6                          ; 0C96: 38 0E
    ld hl, $0000                            ; 0C98: 21 00 00
    ld (SpeedLow), hl                       ; 0C9B: 22 19 C3
    ld (SpeedMiddle), hl                    ; 0C9E: 22 1A C3
    ld ($c31c), hl                          ; 0CA1: 22 1C C3
    jr loc_0CE6                             ; 0CA4: 18 40
loc_0CA6:
    ld a, ($c313)                           ; 0CA6: 3A 13 C3
    or a                                    ; 0CA9: B7
    jr nz, loc_0CC0                         ; 0CAA: 20 14
    ld a, ($c302)                           ; 0CAC: 3A 02 C3
    sub $02                                 ; 0CAF: D6 02
    ld ($c302), a                           ; 0CB1: 32 02 C3
    ld a, $81                               ; 0CB4: 3E 81
    ld (SoundTrigger), a                    ; 0CB6: 32 00 C1
    ld hl, $717b                            ; 0CB9: 21 7B 71
    ld (SoundFunctionPointer), hl           ; 0CBC: 22 01 C1
    xor a                                   ; 0CBF: AF
loc_0CC0:
    ld b, a                                 ; 0CC0: 47
    ld d, $07                               ; 0CC1: 16 07
    ld hl, (SpeedMiddle)                    ; 0CC3: 2A 1A C3
    ld a, h                                 ; 0CC6: 7C
    or a                                    ; 0CC7: B7
    jr nz, loc_0CDD                         ; 0CC8: 20 13
    ld a, l                                 ; 0CCA: 7D
    cp $3c                                  ; 0CCB: FE 3C
    jr nc, loc_0CDD                         ; 0CCD: 30 0E
    ld d, $0a                               ; 0CCF: 16 0A
    cp $1e                                  ; 0CD1: FE 1E
    jr nc, loc_0CDD                         ; 0CD3: 30 08
    ld d, $0f                               ; 0CD5: 16 0F
    cp $0d                                  ; 0CD7: FE 0D
    jr nc, loc_0CDD                         ; 0CD9: 30 02
    ld d, $17                               ; 0CDB: 16 17
loc_0CDD:
    ld a, b                                 ; 0CDD: 78
    inc a                                   ; 0CDE: 3C
    cp d                                    ; 0CDF: BA
    jr c, loc_0CE3                          ; 0CE0: 38 01
    xor a                                   ; 0CE2: AF
loc_0CE3:
    ld ($c313), a                           ; 0CE3: 32 13 C3
loc_0CE6:
    ld a, (ix+21)                           ; 0CE6: DD 7E 15
    or a                                    ; 0CE9: B7
    jr nz, loc_0D39                         ; 0CEA: 20 4D
    ld a, ($c30c)                           ; 0CEC: 3A 0C C3
    or a                                    ; 0CEF: B7
    jp z, loc_0D39                          ; 0CF0: CA 39 0D
    cp $03                                  ; 0CF3: FE 03
    jp z, loc_0D39                          ; 0CF5: CA 39 0D
    cp $04                                  ; 0CF8: FE 04
    jp z, loc_0D39                          ; 0CFA: CA 39 0D
    ld de, $fee3                            ; 0CFD: 11 E3 FE
    cp $02                                  ; 0D00: FE 02
    jr z, loc_0D0B                          ; 0D02: 28 07
    cp $05                                  ; 0D04: FE 05
    jr z, loc_0D0B                          ; 0D06: 28 03
    ld de, $ff08                            ; 0D08: 11 08 FF
loc_0D0B:
    ld hl, (SpeedMiddle)                    ; 0D0B: 2A 1A C3
    add hl, de                              ; 0D0E: 19
    jp nc, loc_0D39                         ; 0D0F: D2 39 0D
    cp $04                                  ; 0D12: FE 04
    ld a, (PlayerControls)                  ; 0D14: 3A 16 C3
    ld b, (ix+13)                           ; 0D17: DD 46 0D
    jr c, loc_0D2C                          ; 0D1A: 38 10
    bit 3, a                                ; 0D1C: CB 5F
    jp nz, loc_0D39                         ; 0D1E: C2 39 0D
    ld a, b                                 ; 0D21: 78
    cp $02                                  ; 0D22: FE 02
    jr nz, loc_0D39                         ; 0D24: 20 13
    ld (ix+21), $02                         ; 0D26: DD 36 15 02
    jr loc_0D39                             ; 0D2A: 18 0D
loc_0D2C:
    bit 2, a                                ; 0D2C: CB 57
    jp nz, loc_0D39                         ; 0D2E: C2 39 0D
    ld a, b                                 ; 0D31: 78
    dec a                                   ; 0D32: 3D
    jr nz, loc_0D39                         ; 0D33: 20 04
    ld (ix+21), $01                         ; 0D35: DD 36 15 01
loc_0D39:
    ld a, (PlayerAnimationFrame)            ; 0D39: 3A 0A C3
    add a, a                                ; 0D3C: 87
    ld c, a                                 ; 0D3D: 4F
    ld b, $00                               ; 0D3E: 06 00
    ld hl, $0f8f                            ; 0D40: 21 8F 0F
    add hl, bc                              ; 0D43: 09
    ld a, ($c306)                           ; 0D44: 3A 06 C3
    add a, (hl)                             ; 0D47: 86
    ld ($c310), a                           ; 0D48: 32 10 C3
    inc hl                                  ; 0D4B: 23
    add a, (hl)                             ; 0D4C: 86
    ld ($c311), a                           ; 0D4D: 32 11 C3
    ld a, (PlayerControls)                  ; 0D50: 3A 16 C3
    ld ($c317), a                           ; 0D53: 32 17 C3
    ld a, ($c312)                           ; 0D56: 3A 12 C3
    or a                                    ; 0D59: B7
    ret z                                   ; 0D5A: C8
    ld a, $0e                               ; 0D5B: 3E 0E
    ld (ReloadBikeSprites), a               ; 0D5D: 32 69 C0
    ld a, $01                               ; 0D60: 3E 01
    ld ($c06e), a                           ; 0D62: 32 6E C0
    ld a, $0b                               ; 0D65: 3E 0B
    ld (PlayerObject), a                    ; 0D67: 32 00 C3
    ld a, $00                               ; 0D6A: 3E 00
    ld ($c301), a                           ; 0D6C: 32 01 C3
    ret                                     ; 0D6F: C9
loc_0D70:
    xor a                                   ; 0D70: AF
    ld ($c304), a                           ; 0D71: 32 04 C3
    ld a, ($c30d)                           ; 0D74: 3A 0D C3
    or a                                    ; 0D77: B7
    jr z, loc_0D87                          ; 0D78: 28 0D
    dec a                                   ; 0D7A: 3D
    jr z, loc_0D87                          ; 0D7B: 28 0A
    ld a, ($c30c)                           ; 0D7D: 3A 0C C3
    cp $05                                  ; 0D80: FE 05
    jr nc, loc_0D9E                         ; 0D82: 30 1A
    jp loc_0BAE                             ; 0D84: C3 AE 0B
loc_0D87:
    ld (ix+13), $01                         ; 0D87: DD 36 0D 01
    ld b, $02                               ; 0D8B: 06 02
    ld a, ($c30b)                           ; 0D8D: 3A 0B C3
    inc a                                   ; 0D90: 3C
    cp $19                                  ; 0D91: FE 19
    jr c, loc_0D97                          ; 0D93: 38 02
    dec a                                   ; 0D95: 3D
    dec b                                   ; 0D96: 05
loc_0D97:
    ld ($c30b), a                           ; 0D97: 32 0B C3
    ld a, b                                 ; 0D9A: 78
    ld (PlayerAnimationFrame), a            ; 0D9B: 32 0A C3
loc_0D9E:
    ld (ix+28), $00                         ; 0D9E: DD 36 1C 00
    ld a, ($c30c)                           ; 0DA2: 3A 0C C3
    ld de, $0200                            ; 0DA5: 11 00 02
    or a                                    ; 0DA8: B7
    jr z, loc_0DCE                          ; 0DA9: 28 23
    cp $04                                  ; 0DAB: FE 04
    jr nc, loc_0DB7                         ; 0DAD: 30 08
    dec d                                   ; 0DAF: 15
    dec a                                   ; 0DB0: 3D
    jr z, loc_0DCE                          ; 0DB1: 28 1B
    ld e, $80                               ; 0DB3: 1E 80
    jr loc_0DCE                             ; 0DB5: 18 17
loc_0DB7:
    ld (ix+28), $ff                         ; 0DB7: DD 36 1C FF
    ld a, (PlayerAnimationFrame)            ; 0DBB: 3A 0A C3
    inc d                                   ; 0DBE: 14
    cp $03                                  ; 0DBF: FE 03
    jr c, loc_0DCE                          ; 0DC1: 38 0B
    ld a, ($c30c)                           ; 0DC3: 3A 0C C3
    dec d                                   ; 0DC6: 15
    cp $06                                  ; 0DC7: FE 06
    jr z, loc_0DCE                          ; 0DC9: 28 03
    ld de, $0180                            ; 0DCB: 11 80 01
loc_0DCE:
    ld hl, (SpeedMiddle)                    ; 0DCE: 2A 1A C3
    ld a, h                                 ; 0DD1: 7C
    or a                                    ; 0DD2: B7
    jr nz, loc_0DF6                         ; 0DD3: 20 21
    ld a, l                                 ; 0DD5: 7D
    or a                                    ; 0DD6: B7
    jp z, loc_0C64                          ; 0DD7: CA 64 0C
    cp $46                                  ; 0DDA: FE 46
    jr nc, loc_0DF6                         ; 0DDC: 30 18
    srl d                                   ; 0DDE: CB 3A
    rr e                                    ; 0DE0: CB 1B
    cp $28                                  ; 0DE2: FE 28
    jr nc, loc_0DF6                         ; 0DE4: 30 10
    srl d                                   ; 0DE6: CB 3A
    rr e                                    ; 0DE8: CB 1B
    cp $14                                  ; 0DEA: FE 14
    jr nc, loc_0DF6                         ; 0DEC: 30 08
    srl e                                   ; 0DEE: CB 3B
    cp $0a                                  ; 0DF0: FE 0A
    jr nc, loc_0DF6                         ; 0DF2: 30 02
    srl e                                   ; 0DF4: CB 3B
loc_0DF6:
    ex de, hl                               ; 0DF6: EB
    ld ($c30e), hl                          ; 0DF7: 22 0E C3
    ld a, ($c31c)                           ; 0DFA: 3A 1C C3
    or a                                    ; 0DFD: B7
    jp z, loc_0C3B                          ; 0DFE: CA 3B 0C
    jp loc_0BE0                             ; 0E01: C3 E0 0B
loc_0E04:
    xor a                                   ; 0E04: AF
    ld ($c304), a                           ; 0E05: 32 04 C3
    ld a, ($c30d)                           ; 0E08: 3A 0D C3
    or a                                    ; 0E0B: B7
    jr z, loc_0E1D                          ; 0E0C: 28 0F
    dec a                                   ; 0E0E: 3D
    jr nz, loc_0E1D                         ; 0E0F: 20 0C
    ld a, ($c30c)                           ; 0E11: 3A 0C C3
    dec a                                   ; 0E14: 3D
    jr z, loc_0E34                          ; 0E15: 28 1D
    dec a                                   ; 0E17: 3D
    jr z, loc_0E34                          ; 0E18: 28 1A
    jp loc_0BAE                             ; 0E1A: C3 AE 0B
loc_0E1D:
    ld (ix+13), $02                         ; 0E1D: DD 36 0D 02
    ld b, $04                               ; 0E21: 06 04
    ld a, ($c30b)                           ; 0E23: 3A 0B C3
    inc a                                   ; 0E26: 3C
    cp $19                                  ; 0E27: FE 19
    jr c, loc_0E2D                          ; 0E29: 38 02
    dec a                                   ; 0E2B: 3D
    inc b                                   ; 0E2C: 04
loc_0E2D:
    ld ($c30b), a                           ; 0E2D: 32 0B C3
    ld a, b                                 ; 0E30: 78
    ld (PlayerAnimationFrame), a            ; 0E31: 32 0A C3
loc_0E34:
    ld (ix+28), $00                         ; 0E34: DD 36 1C 00
    ld a, ($c30c)                           ; 0E38: 3A 0C C3
    ld de, $0200                            ; 0E3B: 11 00 02
    or a                                    ; 0E3E: B7
    jr z, loc_0E64                          ; 0E3F: 28 23
    cp $03                                  ; 0E41: FE 03
    jr c, loc_0E4E                          ; 0E43: 38 09
    dec d                                   ; 0E45: 15
    cp $06                                  ; 0E46: FE 06
    jr z, loc_0E64                          ; 0E48: 28 1A
    ld e, $80                               ; 0E4A: 1E 80
    jr loc_0E64                             ; 0E4C: 18 16
loc_0E4E:
    ld (ix+28), $ff                         ; 0E4E: DD 36 1C FF
    ld a, (PlayerAnimationFrame)            ; 0E52: 3A 0A C3
    inc d                                   ; 0E55: 14
    cp $03                                  ; 0E56: FE 03
    jr nc, loc_0E64                         ; 0E58: 30 0A
    ld a, ($c30c)                           ; 0E5A: 3A 0C C3
    dec d                                   ; 0E5D: 15
    dec a                                   ; 0E5E: 3D
    jr z, loc_0E64                          ; 0E5F: 28 03
    ld de, $0180                            ; 0E61: 11 80 01
loc_0E64:
    ld hl, (SpeedMiddle)                    ; 0E64: 2A 1A C3
    ld a, h                                 ; 0E67: 7C
    or a                                    ; 0E68: B7
    jr nz, loc_0E8C                         ; 0E69: 20 21
    ld a, l                                 ; 0E6B: 7D
    or a                                    ; 0E6C: B7
    jp z, loc_0C64                          ; 0E6D: CA 64 0C
    cp $46                                  ; 0E70: FE 46
    jr nc, loc_0E8C                         ; 0E72: 30 18
    srl d                                   ; 0E74: CB 3A
    rr e                                    ; 0E76: CB 1B
    cp $28                                  ; 0E78: FE 28
    jr nc, loc_0E8C                         ; 0E7A: 30 10
    srl d                                   ; 0E7C: CB 3A
    rr e                                    ; 0E7E: CB 1B
    cp $14                                  ; 0E80: FE 14
    jr nc, loc_0E8C                         ; 0E82: 30 08
    srl e                                   ; 0E84: CB 3B
    cp $0a                                  ; 0E86: FE 0A
    jr nc, loc_0E8C                         ; 0E88: 30 02
    srl e                                   ; 0E8A: CB 3B
loc_0E8C:
    ex de, hl                               ; 0E8C: EB
    ld a, l                                 ; 0E8D: 7D
    cpl                                     ; 0E8E: 2F
    ld l, a                                 ; 0E8F: 6F
    ld a, h                                 ; 0E90: 7C
    cpl                                     ; 0E91: 2F
    ld h, a                                 ; 0E92: 67
    inc hl                                  ; 0E93: 23
    ld ($c30e), hl                          ; 0E94: 22 0E C3
    ld a, ($c31c)                           ; 0E97: 3A 1C C3
    or a                                    ; 0E9A: B7
    jp z, loc_0C3B                          ; 0E9B: CA 3B 0C
    jp loc_0BE0                             ; 0E9E: C3 E0 0B
loc_0EA1:
    ld a, (GameState)                       ; 0EA1: 3A 00 C0
    bit 2, a                                ; 0EA4: CB 57
    jr z, loc_0EAE                          ; 0EA6: 28 06
    ld a, $ff                               ; 0EA8: 3E FF
    ld (HaveDoneColdStart), a               ; 0EAA: 32 15 C0
    ret                                     ; 0EAD: C9
loc_0EAE:
    ld a, ($c013)                           ; 0EAE: 3A 13 C0
    cp $54                                  ; 0EB1: FE 54
    jr z, loc_0EC8                          ; 0EB3: 28 13
    jr c, loc_0EB9                          ; 0EB5: 38 02
    sub $02                                 ; 0EB7: D6 02
loc_0EB9:
    inc a                                   ; 0EB9: 3C
    ld ($c013), a                           ; 0EBA: 32 13 C0
    ld a, $01                               ; 0EBD: 3E 01
    ld ($c048), a                           ; 0EBF: 32 48 C0
    ld a, $ff                               ; 0EC2: 3E FF
    ld ($c067), a                           ; 0EC4: 32 67 C0
    ret                                     ; 0EC7: C9
loc_0EC8:
    ld (ix+1), $00                          ; 0EC8: DD 36 01 00
    ld a, (GameState)                       ; 0ECC: 3A 00 C0
    bit 5, a                                ; 0ECF: CB 6F
    ret nz                                  ; 0ED1: C0
    ld a, $81                               ; 0ED2: 3E 81
    ld (SoundTrigger), a                    ; 0ED4: 32 00 C1
    ld hl, $71dc                            ; 0ED7: 21 DC 71
    ld (SoundFunctionPointer), hl           ; 0EDA: 22 01 C1
    ret                                     ; 0EDD: C9
loc_0EDE:
    ld (ix+1), $80                          ; 0EDE: DD 36 01 80
    ld (ix+10), $03                         ; 0EE2: DD 36 0A 03
    ld a, ($c013)                           ; 0EE6: 3A 13 C0
    cp $54                                  ; 0EE9: FE 54
    jr z, loc_0EFB                          ; 0EEB: 28 0E
    jr c, loc_0EF1                          ; 0EED: 38 02
    sub $02                                 ; 0EEF: D6 02
loc_0EF1:
    inc a                                   ; 0EF1: 3C
    ld ($c013), a                           ; 0EF2: 32 13 C0
    ld a, $01                               ; 0EF5: 3E 01
    ld ($c048), a                           ; 0EF7: 32 48 C0
    ret                                     ; 0EFA: C9
loc_0EFB:
    ld hl, (SpeedMiddle)                    ; 0EFB: 2A 1A C3
    ld de, $fffe                            ; 0EFE: 11 FE FF
    add hl, de                              ; 0F01: 19
    jr c, loc_0F07                          ; 0F02: 38 03
    ld hl, $0000                            ; 0F04: 21 00 00
loc_0F07:
    ld (SpeedMiddle), hl                    ; 0F07: 22 1A C3
    ret                                     ; 0F0A: C9
loc_0F0B:
    ld hl, $0000                            ; 0F0B: 21 00 00
    ld ($c30e), hl                          ; 0F0E: 22 0E C3
    ld hl, (SpeedLow)                       ; 0F11: 2A 19 C3
    ld a, (SpeedHigh)                       ; 0F14: 3A 1B C3
    ld de, $ffcd                            ; 0F17: 11 CD FF
    add hl, de                              ; 0F1A: 19
    ld (SpeedLow), hl                       ; 0F1B: 22 19 C3
    adc a, $ff                              ; 0F1E: CE FF
    ld (SpeedHigh), a                       ; 0F20: 32 1B C3
    ld bc, $01ff                            ; 0F23: 01 FF 01
    ld a, ($c30d)                           ; 0F26: 3A 0D C3
    dec a                                   ; 0F29: 3D
    jr z, loc_0F2F                          ; 0F2A: 28 03
    ld bc, $0501                            ; 0F2C: 01 01 05
loc_0F2F:
    ld (ix+10), b                           ; 0F2F: DD 70 0A
    ld a, ($c314)                           ; 0F32: 3A 14 C3
    ld d, a                                 ; 0F35: 57
    bit 1, a                                ; 0F36: CB 4F
    jr nz, loc_0F52                         ; 0F38: 20 18
    ld a, b                                 ; 0F3A: 78
    add a, c                                ; 0F3B: 81
    ld (PlayerAnimationFrame), a            ; 0F3C: 32 0A C3
    ld a, d                                 ; 0F3F: 7A
    or a                                    ; 0F40: B7
    jr nz, loc_0F52                         ; 0F41: 20 0F
    ld a, $81                               ; 0F43: 3E 81
    ld (SoundTrigger), a                    ; 0F45: 32 00 C1
    ld hl, $7195                            ; 0F48: 21 95 71
    ld (SoundFunctionPointer), hl           ; 0F4B: 22 01 C1
    xor a                                   ; 0F4E: AF
    ld ($c308), a                           ; 0F4F: 32 08 C3
loc_0F52:
    inc a                                   ; 0F52: 3C
    cp $0f                                  ; 0F53: FE 0F
    jr c, loc_0F89                          ; 0F55: 38 32
    ld a, ($c30c)                           ; 0F57: 3A 0C C3
    or a                                    ; 0F5A: B7
    jr z, loc_0F7B                          ; 0F5B: 28 1E
    cp $03                                  ; 0F5D: FE 03
    jr z, loc_0F7B                          ; 0F5F: 28 1A
    cp $04                                  ; 0F61: FE 04
    jr z, loc_0F7B                          ; 0F63: 28 16
    ld de, $ff08                            ; 0F65: 11 08 FF
    cp $06                                  ; 0F68: FE 06
    jr z, loc_0F72                          ; 0F6A: 28 06
    dec a                                   ; 0F6C: 3D
    jr z, loc_0F72                          ; 0F6D: 28 03
    ld de, $fee3                            ; 0F6F: 11 E3 FE
loc_0F72:
    ld hl, (SpeedMiddle)                    ; 0F72: 2A 1A C3
    add hl, de                              ; 0F75: 19
    jr nc, loc_0F7B                         ; 0F76: 30 03
    xor a                                   ; 0F78: AF
    jr loc_0F89                             ; 0F79: 18 0E
loc_0F7B:
    ld (ix+11), $18                         ; 0F7B: DD 36 0B 18
    xor a                                   ; 0F7F: AF
    ld ($c304), a                           ; 0F80: 32 04 C3
    ld ($c31c), a                           ; 0F83: 32 1C C3
    ld ($c315), a                           ; 0F86: 32 15 C3
loc_0F89:
    ld ($c314), a                           ; 0F89: 32 14 C3
    jp loc_0BE0                             ; 0F8C: C3 E0 0B

; ----------------------------------------------------------------------------
; ROM data $0F8F-$1269 (731 bytes)
; ----------------------------------------------------------------------------
PlayerPhysicsTables:
    .incbin "../assets/player_physics_tables.bin"

; ============================================================================
; Code $126A
; ============================================================================
UpdateRoadCurve:
    ld hl, $c048                            ; 126A: 21 48 C0
    ld a, (hl)                              ; 126D: 7E
    or a                                    ; 126E: B7
    ret z                                   ; 126F: C8
    ld (hl), $00                            ; 1270: 36 00
    ld d, $00                               ; 1272: 16 00
    ld a, ($c013)                           ; 1274: 3A 13 C0
    sub $54                                 ; 1277: D6 54
    ld c, a                                 ; 1279: 4F
    or a                                    ; 127A: B7
    jp p, loc_1282                          ; 127B: F2 82 12
    ld d, $ff                               ; 127E: 16 FF
    neg                                     ; 1280: ED 44
loc_1282:
    add a, a                                ; 1282: 87
    ld l, a                                 ; 1283: 6F
    ld h, $00                               ; 1284: 26 00
    add hl, hl                              ; 1286: 29
    ld a, c                                 ; 1287: 79
    or a                                    ; 1288: B7
    jp p, loc_1293                          ; 1289: F2 93 12
    ld a, l                                 ; 128C: 7D
    cpl                                     ; 128D: 2F
    ld l, a                                 ; 128E: 6F
    ld a, h                                 ; 128F: 7C
    cpl                                     ; 1290: 2F
    ld h, a                                 ; 1291: 67
    inc hl                                  ; 1292: 23
loc_1293:
    ex de, hl                               ; 1293: EB
    ld hl, $0000                            ; 1294: 21 00 00
    ld bc, RoadCurvature                    ; 1297: 01 00 C6
    exx                                     ; 129A: D9
    ld de, $c55f                            ; 129B: 11 5F C5
    ld b, $88                               ; 129E: 06 88
loc_12A0:
    exx                                     ; 12A0: D9
    add hl, de                              ; 12A1: 19
    ld a, (bc)                              ; 12A2: 0A
    inc bc                                  ; 12A3: 03
    add a, h                                ; 12A4: 84
    exx                                     ; 12A5: D9
    ld (de), a                              ; 12A6: 12
    inc de                                  ; 12A7: 13
    djnz loc_12A0                           ; 12A8: 10 F6
    ret                                     ; 12AA: C9
DrawSpeed:
    ld hl, (SpeedMiddle)                    ; 12AB: 2A 1A C3
    ld (SpeedCopy), hl                      ; 12AE: 22 2A C0
    call loc_3734                           ; 12B1: CD 34 37
    ld hl, (SpeedMiddle)                    ; 12B4: 2A 1A C3
    ld e, l                                 ; 12B7: 5D
    ld d, h                                 ; 12B8: 54
    srl d                                   ; 12B9: CB 3A
    rr e                                    ; 12BB: CB 1B
    add hl, de                              ; 12BD: 19
    ex de, hl                               ; 12BE: EB
    ld a, e                                 ; 12BF: 7B
    or d                                    ; 12C0: B2
    ret z                                   ; 12C1: C8
    ld hl, ($c030)                          ; 12C2: 2A 30 C0
    add hl, de                              ; 12C5: 19
    ld a, h                                 ; 12C6: 7C
    cp $08                                  ; 12C7: FE 08
    jr c, loc_12CE                          ; 12C9: 38 03
    sub $08                                 ; 12CB: D6 08
    ld h, a                                 ; 12CD: 67
loc_12CE:
    ld ($c030), hl                          ; 12CE: 22 30 C0
    ld de, $0000                            ; 12D1: 11 00 00
    or a                                    ; 12D4: B7
    jr z, loc_12DC                          ; 12D5: 28 05
    neg                                     ; 12D7: ED 44
    ld e, a                                 ; 12D9: 5F
    ld d, $ff                               ; 12DA: 16 FF
loc_12DC:
    push de                                 ; 12DC: D5
    ld hl, $130b                            ; 12DD: 21 0B 13
    add hl, de                              ; 12E0: 19
    ld de, ScoreBCD                         ; 12E1: 11 04 C0
    ld b, $04                               ; 12E4: 06 04
    call WriteDataToVDP                     ; 12E6: CD 1E 00
    pop de                                  ; 12E9: D1
    push de                                 ; 12EA: D5
    ld hl, $131a                            ; 12EB: 21 1A 13
    add hl, de                              ; 12EE: 19
    ld de, $c008                            ; 12EF: 11 08 C0
    ld b, $08                               ; 12F2: 06 08
    call WriteDataToVDP                     ; 12F4: CD 1E 00
    pop de                                  ; 12F7: D1
    ld hl, $1329                            ; 12F8: 21 29 13
    add hl, de                              ; 12FB: 19
    ld de, CourseDataIndex                  ; 12FC: 11 11 C0
    ld b, $02                               ; 12FF: 06 02
    jp WriteDataToVDP                       ; 1301: C3 1E 00

; ----------------------------------------------------------------------------
; ROM data $1304-$1330 (45 bytes)
; ----------------------------------------------------------------------------
BcdDigitPatterns:
    .incbin "../assets/bcd_digit_patterns.bin"

; ============================================================================
; Code $1331
; ============================================================================
; State-machine dispatcher. Function table follows at $1356.
UpdateGameState:
    ld a, ($c048)                           ; 1331: 3A 48 C0
    or a                                    ; 1334: B7
    ret nz                                  ; 1335: C0
    ld ix, CurrentCourseSegment             ; 1336: DD 21 F0 C2
    ld a, (CurrentCourseSegment)            ; 133A: 3A F0 C2
    or a                                    ; 133D: B7
    call nz, loc_1347                       ; 133E: C4 47 13
    ld a, $01                               ; 1341: 3E 01
    ld ($c048), a                           ; 1343: 32 48 C0
    ret                                     ; 1346: C9
loc_1347:
    add a, a                                ; 1347: 87
    and $3e                                 ; 1348: E6 3E
    ld l, a                                 ; 134A: 6F
    ld h, $00                               ; 134B: 26 00
    ld de, GameStateDispatchBase            ; 134D: 11 54 13
    add hl, de                              ; 1350: 19
    ld e, (hl)                              ; 1351: 5E
    inc hl                                  ; 1352: 23
    ld d, (hl)                              ; 1353: 56
GameStateDispatchBase:
    ex de, hl                               ; 1354: EB
    jp (hl)                                 ; 1355: E9

; Game-state handlers. Index 0 intentionally lands on the preceding EX/JP stub;
; these are entries 1..31 selected from GameState & $3E.
GameStateHandlerTable:
    .dw StateHandler01                     ; 1356: 94 13  ; state 1
    .dw StateHandlerDefault                ; 1358: AB 13  ; state 2
    .dw StateHandlerDefault                ; 135A: AB 13  ; state 3
    .dw StateHandler04_05_20_21            ; 135C: CF 13  ; state 4
    .dw StateHandler04_05_20_21            ; 135E: CF 13  ; state 5
    .dw StateHandler06_07                  ; 1360: 56 14  ; state 6
    .dw StateHandler06_07                  ; 1362: 56 14  ; state 7
    .dw StateHandler08_09_24_25            ; 1364: 94 14  ; state 8
    .dw StateHandler08_09_24_25            ; 1366: 94 14  ; state 9
    .dw StateHandler10_26                  ; 1368: 01 15  ; state 10
    .dw StateHandlerDefault                ; 136A: AB 13  ; state 11
    .dw StateHandlerDefault                ; 136C: AB 13  ; state 12
    .dw StateHandlerDefault                ; 136E: AB 13  ; state 13
    .dw StateHandlerDefault                ; 1370: AB 13  ; state 14
    .dw StateHandlerDefault                ; 1372: AB 13  ; state 15
    .dw StateHandlerDefault                ; 1374: AB 13  ; state 16
    .dw StateHandlerDefault                ; 1376: AB 13  ; state 17
    .dw StateHandlerDefault                ; 1378: AB 13  ; state 18
    .dw StateHandlerDefault                ; 137A: AB 13  ; state 19
    .dw StateHandler04_05_20_21            ; 137C: CF 13  ; state 20
    .dw StateHandler04_05_20_21            ; 137E: CF 13  ; state 21
    .dw StateHandler22_23                  ; 1380: 89 15  ; state 22
    .dw StateHandler22_23                  ; 1382: 89 15  ; state 23
    .dw StateHandler08_09_24_25            ; 1384: 94 14  ; state 24
    .dw StateHandler08_09_24_25            ; 1386: 94 14  ; state 25
    .dw StateHandler10_26                  ; 1388: 01 15  ; state 26
    .dw StateHandlerDefault                ; 138A: AB 13  ; state 27
    .dw StateHandlerDefault                ; 138C: AB 13  ; state 28
    .dw StateHandlerDefault                ; 138E: AB 13  ; state 29
    .dw StateHandlerDefault                ; 1390: AB 13  ; state 30
    .dw StateHandlerDefault                ; 1392: AB 13  ; state 31

; ============================================================================
; Code $1394
; ============================================================================
StateHandler01:
    bit 0, (ix+8)                           ; 1394: DD CB 08 46
    jr nz, StateHandlerDefault              ; 1398: 20 11
    ld (ix+8), $01                          ; 139A: DD 36 08 01
    ld hl, RoadCurvature                    ; 139E: 21 00 C6
    ld de, $c601                            ; 13A1: 11 01 C6
    ld bc, $005f                            ; 13A4: 01 5F 00
    ld (hl), $00                            ; 13A7: 36 00
    ldir                                    ; 13A9: ED B0
StateHandlerDefault:
    call loc_13C1                           ; 13AB: CD C1 13
    sub $10                                 ; 13AE: D6 10
    ret c                                   ; 13B0: D8
    ld ($c2f4), a                           ; 13B1: 32 F4 C2
    dec (ix+1)                              ; 13B4: DD 35 01
    ret nz                                  ; 13B7: C0
    ld (ix+2), $00                          ; 13B8: DD 36 02 00
    ld (ix+8), $00                          ; 13BC: DD 36 08 00
    ret                                     ; 13C0: C9
loc_13C1:
    ld hl, (SpeedCopy)                      ; 13C1: 2A 2A C0
    ld de, ($c2f3)                          ; 13C4: ED 5B F3 C2
    add hl, de                              ; 13C8: 19
    ld ($c2f3), hl                          ; 13C9: 22 F3 C2
    ld a, h                                 ; 13CC: 7C
    cp d                                    ; 13CD: BA
    ret                                     ; 13CE: C9
StateHandler04_05_20_21:
    call loc_13C1                           ; 13CF: CD C1 13
    ret z                                   ; 13D2: C8
    ld b, $7e                               ; 13D3: 06 7E
    cp b                                    ; 13D5: B8
    call nc, loc_142B                       ; 13D6: D4 2B 14
    cp $60                                  ; 13D9: FE 60
    call nc, loc_1435                       ; 13DB: D4 35 14
    ld l, a                                 ; 13DE: 6F
    ld h, $00                               ; 13DF: 26 00
    ld de, $2353                            ; 13E1: 11 53 23
    add hl, de                              ; 13E4: 19
    ld a, (hl)                              ; 13E5: 7E
    ex af, af'                              ; 13E6: 08
    ld hl, $15cb                            ; 13E7: 21 CB 15
    ld a, (ix+0)                            ; 13EA: DD 7E 00
    ld b, a                                 ; 13ED: 47
    and $0f                                 ; 13EE: E6 0F
    cp $04                                  ; 13F0: FE 04
    jr z, loc_13F7                          ; 13F2: 28 03
    ld hl, $168b                            ; 13F4: 21 8B 16
loc_13F7:
    ld a, b                                 ; 13F7: 78
    and $10                                 ; 13F8: E6 10
    jp nz, loc_1413                         ; 13FA: C2 13 14
    ex af, af'                              ; 13FD: 08
    neg                                     ; 13FE: ED 44
    add a, $bf                              ; 1400: C6 BF
    ld e, a                                 ; 1402: 5F
    ld d, $00                               ; 1403: 16 00
    add hl, de                              ; 1405: 19
    ld de, $c65f                            ; 1406: 11 5F C6
    ex de, hl                               ; 1409: EB
    ld b, $60                               ; 140A: 06 60
loc_140C:
    ld a, (de)                              ; 140C: 1A
    ld (hl), a                              ; 140D: 77
    dec de                                  ; 140E: 1B
    dec hl                                  ; 140F: 2B
    djnz loc_140C                           ; 1410: 10 FA
    ret                                     ; 1412: C9
loc_1413:
    ex af, af'                              ; 1413: 08
    neg                                     ; 1414: ED 44
    add a, $bf                              ; 1416: C6 BF
    ld e, a                                 ; 1418: 5F
    ld d, $00                               ; 1419: 16 00
    add hl, de                              ; 141B: 19
    ld de, $c65f                            ; 141C: 11 5F C6
    ex de, hl                               ; 141F: EB
    ld b, $60                               ; 1420: 06 60
loc_1422:
    ld a, (de)                              ; 1422: 1A
    neg                                     ; 1423: ED 44
    ld (hl), a                              ; 1425: 77
    dec de                                  ; 1426: 1B
    dec hl                                  ; 1427: 2B
    djnz loc_1422                           ; 1428: 10 F8
    ret                                     ; 142A: C9
loc_142B:
    sub b                                   ; 142B: 90
    ld ($c2f7), a                           ; 142C: 32 F7 C2
    ld (ix+2), $00                          ; 142F: DD 36 02 00
    ld a, b                                 ; 1433: 78
    ret                                     ; 1434: C9
loc_1435:
    ld c, a                                 ; 1435: 4F
    ld hl, ($c2f5)                          ; 1436: 2A F5 C2
    ld a, (CurrentCourseSegment)            ; 1439: 3A F0 C2
    cp $04                                  ; 143C: FE 04
    ld a, $10                               ; 143E: 3E 10
    jr z, loc_1444                          ; 1440: 28 02
    ld a, $0a                               ; 1442: 3E 0A
loc_1444:
    ld d, $00                               ; 1444: 16 00
    bit 4, (ix+0)                           ; 1446: DD CB 00 66
    jr z, loc_144F                          ; 144A: 28 03
    neg                                     ; 144C: ED 44
    dec d                                   ; 144E: 15
loc_144F:
    ld e, a                                 ; 144F: 5F
    add hl, de                              ; 1450: 19
    ld ($c2f5), hl                          ; 1451: 22 F5 C2
    ld a, c                                 ; 1454: 79
    ret                                     ; 1455: C9
StateHandler06_07:
    call loc_13C1                           ; 1456: CD C1 13
    ret z                                   ; 1459: C8
    ld b, $3f                               ; 145A: 06 3F
    cp b                                    ; 145C: B8
    call nc, loc_142B                       ; 145D: D4 2B 14
    rrca                                    ; 1460: 0F
    and $1e                                 ; 1461: E6 1E
    ld l, a                                 ; 1463: 6F
    ld h, $00                               ; 1464: 26 00
    ld de, $1df3                            ; 1466: 11 F3 1D
    ld a, (ix+0)                            ; 1469: DD 7E 00
    cp $06                                  ; 146C: FE 06
    jr z, loc_1473                          ; 146E: 28 03
    ld de, $1dd3                            ; 1470: 11 D3 1D
loc_1473:
    add hl, de                              ; 1473: 19
    ld e, (hl)                              ; 1474: 5E
    inc hl                                  ; 1475: 23
    ld d, (hl)                              ; 1476: 56
    ld hl, RoadCurvature                    ; 1477: 21 00 C6
    ld bc, $0060                            ; 147A: 01 60 00
    ex de, hl                               ; 147D: EB
    ldir                                    ; 147E: ED B0
    ld hl, ($c2f5)                          ; 1480: 2A F5 C2
    ld de, $0002                            ; 1483: 11 02 00
    bit 0, (ix+0)                           ; 1486: DD CB 00 46
    jr nz, loc_148F                         ; 148A: 20 03
    ld de, $fffe                            ; 148C: 11 FE FF
loc_148F:
    add hl, de                              ; 148F: 19
    ld ($c2f5), hl                          ; 1490: 22 F5 C2
    ret                                     ; 1493: C9
StateHandler08_09_24_25:
    call loc_13C1                           ; 1494: CD C1 13
    ret z                                   ; 1497: C8
    ld b, $5f                               ; 1498: 06 5F
    cp b                                    ; 149A: B8
    call nc, loc_142B                       ; 149B: D4 2B 14
    cp $40                                  ; 149E: FE 40
    call nc, loc_14E1                       ; 14A0: D4 E1 14
    ld e, a                                 ; 14A3: 5F
    ld d, $00                               ; 14A4: 16 00
    ld hl, RoadCurvature                    ; 14A6: 21 00 C6
    add hl, de                              ; 14A9: 19
    push hl                                 ; 14AA: E5
    ld b, (hl)                              ; 14AB: 46
    ld hl, $174b                            ; 14AC: 21 4B 17
    ld a, (ix+0)                            ; 14AF: DD 7E 00
    and $0f                                 ; 14B2: E6 0F
    cp $08                                  ; 14B4: FE 08
    jr z, loc_14BB                          ; 14B6: 28 03
    ld hl, $180b                            ; 14B8: 21 0B 18
loc_14BB:
    add hl, de                              ; 14BB: 19
    add hl, de                              ; 14BC: 19
    ld a, e                                 ; 14BD: 7B
    ld e, (hl)                              ; 14BE: 5E
    inc hl                                  ; 14BF: 23
    ld d, (hl)                              ; 14C0: 56
    bit 4, (ix+0)                           ; 14C1: DD CB 00 66
    jr z, loc_14D0                          ; 14C5: 28 09
    ex af, af'                              ; 14C7: 08
    ld a, e                                 ; 14C8: 7B
    cpl                                     ; 14C9: 2F
    ld e, a                                 ; 14CA: 5F
    ld a, d                                 ; 14CB: 7A
    cpl                                     ; 14CC: 2F
    ld d, a                                 ; 14CD: 57
    inc de                                  ; 14CE: 13
    ex af, af'                              ; 14CF: 08
loc_14D0:
    ld h, b                                 ; 14D0: 60
    ld l, $00                               ; 14D1: 2E 00
    pop bc                                  ; 14D3: C1
    exx                                     ; 14D4: D9
    ld b, a                                 ; 14D5: 47
    inc b                                   ; 14D6: 04
loc_14D7:
    exx                                     ; 14D7: D9
    ld a, h                                 ; 14D8: 7C
    ld (bc), a                              ; 14D9: 02
    add hl, de                              ; 14DA: 19
    dec bc                                  ; 14DB: 0B
    exx                                     ; 14DC: D9
    djnz loc_14D7                           ; 14DD: 10 F8
    exx                                     ; 14DF: D9
    ret                                     ; 14E0: C9
loc_14E1:
    ld c, a                                 ; 14E1: 4F
    ld de, $0010                            ; 14E2: 11 10 00
    bit 0, (ix+0)                           ; 14E5: DD CB 00 46
    jr z, loc_14ED                          ; 14E9: 28 02
    ld e, $0a                               ; 14EB: 1E 0A
loc_14ED:
    bit 4, (ix+0)                           ; 14ED: DD CB 00 66
    jr nz, loc_14F8                         ; 14F1: 20 05
    ld a, e                                 ; 14F3: 7B
    neg                                     ; 14F4: ED 44
    ld e, a                                 ; 14F6: 5F
    dec d                                   ; 14F7: 15
loc_14F8:
    ld hl, ($c2f5)                          ; 14F8: 2A F5 C2
    add hl, de                              ; 14FB: 19
    ld ($c2f5), hl                          ; 14FC: 22 F5 C2
    ld a, c                                 ; 14FF: 79
    ret                                     ; 1500: C9
StateHandler10_26:
    call loc_13C1                           ; 1501: CD C1 13
    ret z                                   ; 1504: C8
    ld b, $5f                               ; 1505: 06 5F
    cp b                                    ; 1507: B8
    call nc, loc_142B                       ; 1508: D4 2B 14
    cp $40                                  ; 150B: FE 40
    call nc, loc_1571                       ; 150D: D4 71 15
    push af                                 ; 1510: F5
    ld e, a                                 ; 1511: 5F
    ld d, $00                               ; 1512: 16 00
    ld hl, RoadCurvature                    ; 1514: 21 00 C6
    add hl, de                              ; 1517: 19
    push hl                                 ; 1518: E5
    ld b, (hl)                              ; 1519: 46
    ld hl, $174b                            ; 151A: 21 4B 17
    add hl, de                              ; 151D: 19
    add hl, de                              ; 151E: 19
    ld a, e                                 ; 151F: 7B
    ld e, (hl)                              ; 1520: 5E
    inc hl                                  ; 1521: 23
    ld d, (hl)                              ; 1522: 56
    bit 4, (ix+0)                           ; 1523: DD CB 00 66
    jr z, loc_1532                          ; 1527: 28 09
    ex af, af'                              ; 1529: 08
    ld a, e                                 ; 152A: 7B
    cpl                                     ; 152B: 2F
    ld e, a                                 ; 152C: 5F
    ld a, d                                 ; 152D: 7A
    cpl                                     ; 152E: 2F
    ld d, a                                 ; 152F: 57
    inc de                                  ; 1530: 13
    ex af, af'                              ; 1531: 08
loc_1532:
    ld h, b                                 ; 1532: 60
    ld l, $00                               ; 1533: 2E 00
    pop bc                                  ; 1535: C1
    exx                                     ; 1536: D9
    ld b, a                                 ; 1537: 47
    inc b                                   ; 1538: 04
loc_1539:
    exx                                     ; 1539: D9
    ld a, h                                 ; 153A: 7C
    ld (bc), a                              ; 153B: 02
    add hl, de                              ; 153C: 19
    dec bc                                  ; 153D: 0B
    exx                                     ; 153E: D9
    djnz loc_1539                           ; 153F: 10 F8
    exx                                     ; 1541: D9
    pop af                                  ; 1542: F1
    cp $04                                  ; 1543: FE 04
    ret c                                   ; 1545: D8
    and $fc                                 ; 1546: E6 FC
    ld b, a                                 ; 1548: 47
    rrca                                    ; 1549: 0F
    and $3e                                 ; 154A: E6 3E
    ld l, a                                 ; 154C: 6F
    ld h, $00                               ; 154D: 26 00
    ld de, $18c9                            ; 154F: 11 C9 18
    add hl, de                              ; 1552: 19
    ld a, (hl)                              ; 1553: 7E
    inc hl                                  ; 1554: 23
    ld h, (hl)                              ; 1555: 66
    ld l, a                                 ; 1556: 6F
    ld de, RoadCurvature                    ; 1557: 11 00 C6
    bit 4, (ix+0)                           ; 155A: DD CB 00 66
    jp nz, loc_1569                         ; 155E: C2 69 15
loc_1561:
    ld a, (de)                              ; 1561: 1A
    sub (hl)                                ; 1562: 96
    ld (de), a                              ; 1563: 12
    inc hl                                  ; 1564: 23
    inc de                                  ; 1565: 13
    djnz loc_1561                           ; 1566: 10 F9
    ret                                     ; 1568: C9
loc_1569:
    ld a, (de)                              ; 1569: 1A
    add a, (hl)                             ; 156A: 86
    ld (de), a                              ; 156B: 12
    inc hl                                  ; 156C: 23
    inc de                                  ; 156D: 13
    djnz loc_1569                           ; 156E: 10 F9
    ret                                     ; 1570: C9
loc_1571:
    ld c, a                                 ; 1571: 4F
    ld de, $0020                            ; 1572: 11 20 00
    bit 4, (ix+0)                           ; 1575: DD CB 00 66
    jr nz, loc_1580                         ; 1579: 20 05
    dec d                                   ; 157B: 15
    ld a, e                                 ; 157C: 7B
    neg                                     ; 157D: ED 44
    ld e, a                                 ; 157F: 5F
loc_1580:
    ld hl, ($c2f5)                          ; 1580: 2A F5 C2
    add hl, de                              ; 1583: 19
    ld ($c2f5), hl                          ; 1584: 22 F5 C2
    ld a, c                                 ; 1587: 79
    ret                                     ; 1588: C9
StateHandler22_23:
    call loc_13C1                           ; 1589: CD C1 13
    ret z                                   ; 158C: C8
    ld b, $3f                               ; 158D: 06 3F
    cp b                                    ; 158F: B8
    call nc, loc_142B                       ; 1590: D4 2B 14
    rrca                                    ; 1593: 0F
    and $1e                                 ; 1594: E6 1E
    ld l, a                                 ; 1596: 6F
    ld h, $00                               ; 1597: 26 00
    ld de, $1df3                            ; 1599: 11 F3 1D
    ld a, (ix+0)                            ; 159C: DD 7E 00
    cp $16                                  ; 159F: FE 16
    jr z, loc_15A6                          ; 15A1: 28 03
    ld de, $1dd3                            ; 15A3: 11 D3 1D
loc_15A6:
    add hl, de                              ; 15A6: 19
    ld e, (hl)                              ; 15A7: 5E
    inc hl                                  ; 15A8: 23
    ld d, (hl)                              ; 15A9: 56
    ld hl, RoadCurvature                    ; 15AA: 21 00 C6
    ld b, $60                               ; 15AD: 06 60
loc_15AF:
    ld a, (de)                              ; 15AF: 1A
    neg                                     ; 15B0: ED 44
    ld (hl), a                              ; 15B2: 77
    inc hl                                  ; 15B3: 23
    inc de                                  ; 15B4: 13
    djnz loc_15AF                           ; 15B5: 10 F8
    ld hl, ($c2f5)                          ; 15B7: 2A F5 C2
    ld de, $0002                            ; 15BA: 11 02 00
    bit 0, (ix+0)                           ; 15BD: DD CB 00 46
    jr z, loc_15C6                          ; 15C1: 28 03
    ld de, $fffe                            ; 15C3: 11 FE FF
loc_15C6:
    add hl, de                              ; 15C6: 19
    ld ($c2f5), hl                          ; 15C7: 22 F5 C2
    ret                                     ; 15CA: C9

; ----------------------------------------------------------------------------
; ROM data $15CB-$23D2 (3592 bytes)
; ----------------------------------------------------------------------------
RoadCurvatureTables:
    .incbin "../assets/road_curvature_tables.bin"

; ============================================================================
; Code $23D3
; ============================================================================
UpdateSpeedDisplay:
    ld hl, $7850                            ; 23D3: 21 50 78
    call WriteAAndHToVDPControl             ; 23D6: CD 16 00
    ld hl, (SpeedMiddle)                    ; 23D9: 2A 1A C3
    ld de, $0064                            ; 23DC: 11 64 00
    ld b, $ff                               ; 23DF: 06 FF
    and a                                   ; 23E1: A7
loc_23E2:
    sbc hl, de                              ; 23E2: ED 52
    inc b                                   ; 23E4: 04
    jr nc, loc_23E2                         ; 23E5: 30 FB
    call WriteDigitBToVDP                   ; 23E7: CD 7D 24
    ld de, $0064                            ; 23EA: 11 64 00
    add hl, de                              ; 23ED: 19
    ld e, $0a                               ; 23EE: 1E 0A
    ld b, $ff                               ; 23F0: 06 FF
    ld a, l                                 ; 23F2: 7D
loc_23F3:
    sub e                                   ; 23F3: 93
    inc b                                   ; 23F4: 04
    jr nc, loc_23F3                         ; 23F5: 30 FC
    push af                                 ; 23F7: F5
    call WriteDigitBToVDP                   ; 23F8: CD 7D 24
    pop af                                  ; 23FB: F1
    add a, $0a                              ; 23FC: C6 0A
    ld b, a                                 ; 23FE: 47
    jp WriteDigitBToVDP                     ; 23FF: C3 7D 24
UpdateTimeLeft:
    ld hl, TimeLeft                         ; 2402: 21 0D C0
    ld a, (GameState)                       ; 2405: 3A 00 C0
    bit 5, a                                ; 2408: CB 6F
    jr nz, loc_2433                         ; 240A: 20 27
    dec hl                                  ; 240C: 2B
    ld a, (StartLightPhase)                 ; 240D: 3A 49 C0
    or a                                    ; 2410: B7
    ret nz                                  ; 2411: C0
    dec (hl)                                ; 2412: 35
    ret nz                                  ; 2413: C0
    ld (hl), $3c                            ; 2414: 36 3C
    inc hl                                  ; 2416: 23
    dec (hl)                                ; 2417: 35
    jp p, loc_2433                          ; 2418: F2 33 24
    inc (hl)                                ; 241B: 34
    ld hl, (SpeedMiddle)                    ; 241C: 2A 1A C3
    ld a, l                                 ; 241F: 7D
    or h                                    ; 2420: B4
    ret nz                                  ; 2421: C0
    ld a, (PlayerObject)                    ; 2422: 3A 00 C3
    cp $01                                  ; 2425: FE 01
    ret nz                                  ; 2427: C0
    ld a, ($c301)                           ; 2428: 3A 01 C3
    or a                                    ; 242B: B7
    ret p                                   ; 242C: F0
    ld hl, GameState                        ; 242D: 21 00 C0
    set 6, (hl)                             ; 2430: CB F6
    ret                                     ; 2432: C9
loc_2433:
    ld a, (hl)                              ; 2433: 7E
    ld b, $ff                               ; 2434: 06 FF
    ld e, $0a                               ; 2436: 1E 0A
loc_2438:
    sub e                                   ; 2438: 93
    inc b                                   ; 2439: 04
    jr nc, loc_2438                         ; 243A: 30 FC
    ld de, $381e                            ; 243C: 11 1E 38
    call loc_244C                           ; 243F: CD 4C 24
    add a, $0a                              ; 2442: C6 0A
    ld b, a                                 ; 2444: 47
    ld de, $3820                            ; 2445: 11 20 38
    call loc_244C                           ; 2448: CD 4C 24
    ret                                     ; 244B: C9
loc_244C:
    push hl                                 ; 244C: E5
    push af                                 ; 244D: F5
    sla b                                   ; 244E: CB 20
    ld h, $00                               ; 2450: 26 00
    ld l, b                                 ; 2452: 68
    ld bc, $2469                            ; 2453: 01 69 24
    add hl, bc                              ; 2456: 09
    ld a, (hl)                              ; 2457: 7E
    inc hl                                  ; 2458: 23
    ld b, (hl)                              ; 2459: 46
    call WriteAToVRAMDE                     ; 245A: CD 89 24
    ld hl, $0040                            ; 245D: 21 40 00
    add hl, de                              ; 2460: 19
    ex de, hl                               ; 2461: EB
    ld a, b                                 ; 2462: 78
    call WriteAToVRAMDE                     ; 2463: CD 89 24
    pop af                                  ; 2466: F1
    pop hl                                  ; 2467: E1
    ret                                     ; 2468: C9

; ----------------------------------------------------------------------------
; ROM data $2469-$247C (20 bytes)
; ----------------------------------------------------------------------------
TimeDigitPatterns:
    .incbin "../assets/time_digit_patterns.bin"

; ============================================================================
; Code $247D
; ============================================================================
WriteDigitBToVDP:
    ld a, b                                 ; 247D: 78
    add a, $30                              ; 247E: C6 30
    out (VDPDataPort), a                    ; 2480: D3 BE
    push af                                 ; 2482: F5
    pop af                                  ; 2483: F1
    ld a, $09                               ; 2484: 3E 09
    out (VDPDataPort), a                    ; 2486: D3 BE
    ret                                     ; 2488: C9
WriteAToVRAMDE:
    push af                                 ; 2489: F5
    ld a, e                                 ; 248A: 7B
    out (VDPControlPort), a                 ; 248B: D3 BF
    ld a, d                                 ; 248D: 7A
    or $40                                  ; 248E: F6 40
    out (VDPControlPort), a                 ; 2490: D3 BF
    pop af                                  ; 2492: F1
    out (VDPDataPort), a                    ; 2493: D3 BE
    ret                                     ; 2495: C9
; Object dispatcher. Handler table follows at $253D.
UpdateObjects:
    ld a, ($c045)                           ; 2496: 3A 45 C0
    or a                                    ; 2499: B7
    ret nz                                  ; 249A: C0
    ld ix, PlayerObject                     ; 249B: DD 21 00 C3
    ld b, $08                               ; 249F: 06 08
loc_24A1:
    push bc                                 ; 24A1: C5
    ld a, (ix+0)                            ; 24A2: DD 7E 00
    or a                                    ; 24A5: B7
    jr z, loc_24BB                          ; 24A6: 28 13
    ld hl, $24bb                            ; 24A8: 21 BB 24
    push hl                                 ; 24AB: E5
    add a, a                                ; 24AC: 87
    and $1e                                 ; 24AD: E6 1E
    ld d, $00                               ; 24AF: 16 00
    ld e, a                                 ; 24B1: 5F
    ld hl, ObjectDispatchBase               ; 24B2: 21 3B 25
    add hl, de                              ; 24B5: 19
    ld e, (hl)                              ; 24B6: 5E
    inc hl                                  ; 24B7: 23
    ld d, (hl)                              ; 24B8: 56
    ex de, hl                               ; 24B9: EB
    jp (hl)                                 ; 24BA: E9
loc_24BB:
    ld de, $0020                            ; 24BB: 11 20 00
    add ix, de                              ; 24BE: DD 19
    pop bc                                  ; 24C0: C1
    djnz loc_24A1                           ; 24C1: 10 DE
    ld iy, SpriteOutputBuffer               ; 24C3: FD 21 42 C4
    ld ix, PlayerObject                     ; 24C7: DD 21 00 C3
    ld b, $08                               ; 24CB: 06 08
loc_24CD:
    bit 7, (ix+1)                           ; 24CD: DD CB 01 7E
    call nz, loc_24F1                       ; 24D1: C4 F1 24
    ld de, $0020                            ; 24D4: 11 20 00
    add ix, de                              ; 24D7: DD 19
    djnz loc_24CD                           ; 24D9: 10 F2
    ld (iy+0), $d0                          ; 24DB: FD 36 00 D0
    ld a, $ff                               ; 24DF: 3E FF
    ld ($c045), a                           ; 24E1: 32 45 C0
    ret                                     ; 24E4: C9
loc_24E5:
    pop af                                  ; 24E5: F1
    ld (ix+0), $00                          ; 24E6: DD 36 00 00
    ld (ix+1), $00                          ; 24EA: DD 36 01 00
    jp loc_24BB                             ; 24EE: C3 BB 24
loc_24F1:
    push bc                                 ; 24F1: C5
    ld a, (ix+10)                           ; 24F2: DD 7E 0A
    add a, a                                ; 24F5: 87
    ld hl, $2554                            ; 24F6: 21 54 25
    ld e, a                                 ; 24F9: 5F
    ld d, $00                               ; 24FA: 16 00
    add hl, de                              ; 24FC: 19
    ld e, (hl)                              ; 24FD: 5E
    inc hl                                  ; 24FE: 23
    ld h, (hl)                              ; 24FF: 66
    ld l, e                                 ; 2500: 6B
    ld e, (ix+2)                            ; 2501: DD 5E 02
    ld b, (ix+7)                            ; 2504: DD 46 07
    ld c, (ix+6)                            ; 2507: DD 4E 06
loc_250A:
    ld a, (hl)                              ; 250A: 7E
    cp $80                                  ; 250B: FE 80
    jr z, ObjectDispatchBase                ; 250D: 28 2C
    add a, e                                ; 250F: 83
    cp $c8                                  ; 2510: FE C8
    jr nc, ObjectDispatchBase               ; 2512: 30 27
    ld (iy+0), a                            ; 2514: FD 77 00
    inc hl                                  ; 2517: 23
    ld a, (hl)                              ; 2518: 7E
    add a, c                                ; 2519: 81
    ld d, a                                 ; 251A: 57
    ld a, $00                               ; 251B: 3E 00
    bit 7, (hl)                             ; 251D: CB 7E
    jr z, loc_2522                          ; 251F: 28 01
    dec a                                   ; 2521: 3D
loc_2522:
    adc a, b                                ; 2522: 88
    or a                                    ; 2523: B7
    jr nz, loc_2537                         ; 2524: 20 11
    inc iy                                  ; 2526: FD 23
    ld (iy+0), d                            ; 2528: FD 72 00
    inc iy                                  ; 252B: FD 23
    inc hl                                  ; 252D: 23
    ld a, (hl)                              ; 252E: 7E
    ld (iy+0), a                            ; 252F: FD 77 00
    inc iy                                  ; 2532: FD 23
    inc hl                                  ; 2534: 23
    jr loc_250A                             ; 2535: 18 D3
loc_2537:
    inc hl                                  ; 2537: 23
    inc hl                                  ; 2538: 23
    jr loc_250A                             ; 2539: 18 CF
ObjectDispatchBase:
    pop bc                                  ; 253B: C1
    ret                                     ; 253C: C9

; Object handlers for object types 1..11. Type 0 returns through bytes at $253B.
ObjectHandlerTable:
    .dw ObjectHandlerType01                ; 253D: AF 09  ; object type 1
    .dw ObjectHandlerType02                ; 253F: 5D 2A  ; object type 2
    .dw ObjectHandlerTypes03To10           ; 2541: 3D 3C  ; object type 3
    .dw ObjectHandlerTypes03To10           ; 2543: 3D 3C  ; object type 4
    .dw ObjectHandlerTypes03To10           ; 2545: 3D 3C  ; object type 5
    .dw ObjectHandlerTypes03To10           ; 2547: 3D 3C  ; object type 6
    .dw ObjectHandlerTypes03To10           ; 2549: 3D 3C  ; object type 7
    .dw ObjectHandlerTypes03To10           ; 254B: 3D 3C  ; object type 8
    .dw ObjectHandlerTypes03To10           ; 254D: 3D 3C  ; object type 9
    .dw ObjectHandlerTypes03To10           ; 254F: 3D 3C  ; object type 10
    .dw ObjectHandlerType11                ; 2551: BF 7D  ; object type 11

; ----------------------------------------------------------------------------
; ROM data $2553-$2A5C (1290 bytes)
; ----------------------------------------------------------------------------
ObjectLayoutTables:
    .incbin "../assets/object_layout_tables.bin"

; ============================================================================
; Code $2A5D
; ============================================================================
ObjectHandlerType02:
    bit 7, (ix+1)                           ; 2A5D: DD CB 01 7E
    jr nz, loc_2ADA                         ; 2A61: 20 77
    ld a, (VBlankCounter)                   ; 2A63: 3A 73 C0
    rlca                                    ; 2A66: 07
    rlca                                    ; 2A67: 07
    rlca                                    ; 2A68: 07
    rlca                                    ; 2A69: 07
    and $7f                                 ; 2A6A: E6 7F
    sub $40                                 ; 2A6C: D6 40
    ld e, a                                 ; 2A6E: 5F
    ld a, r                                 ; 2A6F: ED 5F
    and $3f                                 ; 2A71: E6 3F
    sub $20                                 ; 2A73: D6 20
    add a, e                                ; 2A75: 83
    ld (ix+8), a                            ; 2A76: DD 77 08
    ld e, a                                 ; 2A79: 5F
    ld a, (Level)                           ; 2A7A: 3A C0 C4
    cp $02                                  ; 2A7D: FE 02
    ld a, e                                 ; 2A7F: 7B
    jr c, loc_2A84                          ; 2A80: 38 02
    neg                                     ; 2A82: ED 44
loc_2A84:
    ld (ix+19), a                           ; 2A84: DD 77 13
    ld (ix+9), $1c                          ; 2A87: DD 36 09 1C
    ld (ix+11), $06                         ; 2A8B: DD 36 0B 06
    ld (ix+12), $01                         ; 2A8F: DD 36 0C 01
    ld (ix+20), $08                         ; 2A93: DD 36 14 08
    xor a                                   ; 2A97: AF
    ld (ix+24), a                           ; 2A98: DD 77 18
    ld (ix+25), a                           ; 2A9B: DD 77 19
    ld b, a                                 ; 2A9E: 47
    ld c, a                                 ; 2A9F: 4F
    ld a, (SpeedHigh)                       ; 2AA0: 3A 1B C3
    or a                                    ; 2AA3: B7
    jr nz, loc_2AD4                         ; 2AA4: 20 2E
    ld a, (SpeedMiddle)                     ; 2AA6: 3A 1A C3
    cp $c8                                  ; 2AA9: FE C8
    jr nc, loc_2AD4                         ; 2AAB: 30 27
    ld (ix+25), $01                         ; 2AAD: DD 36 19 01
    ld hl, $2ccb                            ; 2AB1: 21 CB 2C
    ld a, ($c013)                           ; 2AB4: 3A 13 C0
    cp $7e                                  ; 2AB7: FE 7E
    jr nc, loc_2AC9                         ; 2AB9: 30 0E
    inc hl                                  ; 2ABB: 23
    inc hl                                  ; 2ABC: 23
    cp $54                                  ; 2ABD: FE 54
    jr nc, loc_2AC9                         ; 2ABF: 30 08
    inc hl                                  ; 2AC1: 23
    inc hl                                  ; 2AC2: 23
    cp $2a                                  ; 2AC3: FE 2A
    jr nc, loc_2AC9                         ; 2AC5: 30 02
    inc hl                                  ; 2AC7: 23
    inc hl                                  ; 2AC8: 23
loc_2AC9:
    ld a, r                                 ; 2AC9: ED 5F
    and (hl)                                ; 2ACB: A6
    inc hl                                  ; 2ACC: 23
    add a, (hl)                             ; 2ACD: 86
    ld (ix+8), a                            ; 2ACE: DD 77 08
    ld bc, $8600                            ; 2AD1: 01 00 86
loc_2AD4:
    ld (ix+3), b                            ; 2AD4: DD 70 03
    ld (ix+4), c                            ; 2AD7: DD 71 04
loc_2ADA:
    ld c, $00                               ; 2ADA: 0E 00
    ld a, (ix+3)                            ; 2ADC: DD 7E 03
    ld b, a                                 ; 2ADF: 47
    cp $41                                  ; 2AE0: FE 41
    jr c, loc_2AEA                          ; 2AE2: 38 06
    cp $5f                                  ; 2AE4: FE 5F
    jr nc, loc_2AEA                         ; 2AE6: 30 02
    ld c, $01                               ; 2AE8: 0E 01
loc_2AEA:
    ld a, (ix+24)                           ; 2AEA: DD 7E 18
    xor c                                   ; 2AED: A9
    jr z, loc_2B13                          ; 2AEE: 28 23
    ld a, c                                 ; 2AF0: 79
    or a                                    ; 2AF1: B7
    ld hl, $7153                            ; 2AF2: 21 53 71
    jr nz, loc_2AFA                         ; 2AF5: 20 03
    ld hl, $716d                            ; 2AF7: 21 6D 71
loc_2AFA:
    ld (SoundFunctionPointer), hl           ; 2AFA: 22 01 C1
    ld (ix+24), c                           ; 2AFD: DD 71 18
    ld a, b                                 ; 2B00: 78
    cp $5f                                  ; 2B01: FE 5F
    jr c, loc_2B13                          ; 2B03: 38 0E
    ld a, (ix+25)                           ; 2B05: DD 7E 19
    or a                                    ; 2B08: B7
    jr nz, loc_2B13                         ; 2B09: 20 08
    ld a, $06                               ; 2B0B: 3E 06
    ld (ix+25), a                           ; 2B0D: DD 77 19
    call UpdateScore                        ; 2B10: CD 53 35
loc_2B13:
    ld a, (ix+3)                            ; 2B13: DD 7E 03
    call loc_3BE0                           ; 2B16: CD E0 3B
    cp $ff                                  ; 2B19: FE FF
    jr nz, loc_2B22                         ; 2B1B: 20 05
    ld b, (ix+12)                           ; 2B1D: DD 46 0C
    jr loc_2B2D                             ; 2B20: 18 0B
loc_2B22:
    ld b, a                                 ; 2B22: 47
    ld (ix+12), a                           ; 2B23: DD 77 0C
    add a, a                                ; 2B26: 87
    ld c, a                                 ; 2B27: 4F
    add a, a                                ; 2B28: 87
    add a, c                                ; 2B29: 81
    ld (ix+11), a                           ; 2B2A: DD 77 0B
loc_2B2D:
    ld a, (Level)                           ; 2B2D: 3A C0 C4
    or a                                    ; 2B30: B7
    jr nz, loc_2B5E                         ; 2B31: 20 2B
    dec (ix+20)                             ; 2B33: DD 35 14
    jr nz, loc_2B5E                         ; 2B36: 20 26
    ld (ix+20), $08                         ; 2B38: DD 36 14 08
    ld c, $1d                               ; 2B3C: 0E 1D
    ld a, b                                 ; 2B3E: 78
    cp $01                                  ; 2B3F: FE 01
    jr z, loc_2B50                          ; 2B41: 28 0D
    ld c, $1b                               ; 2B43: 0E 1B
    ld a, (CurrentCourseSegment)            ; 2B45: 3A F0 C2
    and $0f                                 ; 2B48: E6 0F
    cp $02                                  ; 2B4A: FE 02
    jr nz, loc_2B50                         ; 2B4C: 20 02
    ld c, $19                               ; 2B4E: 0E 19
loc_2B50:
    ld a, (ix+9)                            ; 2B50: DD 7E 09
    cp c                                    ; 2B53: B9
    jr z, loc_2B5E                          ; 2B54: 28 08
    inc a                                   ; 2B56: 3C
    jr c, loc_2B5B                          ; 2B57: 38 02
    dec a                                   ; 2B59: 3D
    dec a                                   ; 2B5A: 3D
loc_2B5B:
    ld (ix+9), a                            ; 2B5B: DD 77 09
loc_2B5E:
    ld a, (ix+3)                            ; 2B5E: DD 7E 03
    cp $10                                  ; 2B61: FE 10
    jr c, loc_2B9F                          ; 2B63: 38 3A
    cp $50                                  ; 2B65: FE 50
    jr nc, loc_2B9F                         ; 2B67: 30 36
    ld a, b                                 ; 2B69: 78
    dec a                                   ; 2B6A: 3D
    jr z, loc_2B84                          ; 2B6B: 28 17
    ld b, a                                 ; 2B6D: 47
    ld a, (Course)                          ; 2B6E: 3A 10 C0
    cp $02                                  ; 2B71: FE 02
    jr c, loc_2B84                          ; 2B73: 38 0F
    ld a, (ix+8)                            ; 2B75: DD 7E 08
    sub b                                   ; 2B78: 90
    cp $60                                  ; 2B79: FE 60
    jr c, loc_2B81                          ; 2B7B: 38 04
    cp $a0                                  ; 2B7D: FE A0
    jr c, loc_2B84                          ; 2B7F: 38 03
loc_2B81:
    ld (ix+8), a                            ; 2B81: DD 77 08
loc_2B84:
    ld b, (ix+8)                            ; 2B84: DD 46 08
    ld a, (ix+19)                           ; 2B87: DD 7E 13
    cp b                                    ; 2B8A: B8
    jr z, loc_2B9F                          ; 2B8B: 28 12
    ld e, $ff                               ; 2B8D: 1E FF
    jr c, loc_2B93                          ; 2B8F: 38 02
    ld e, $01                               ; 2B91: 1E 01
loc_2B93:
    xor b                                   ; 2B93: A8
    ld a, e                                 ; 2B94: 7B
    jp p, loc_2B9B                          ; 2B95: F2 9B 2B
    ld a, e                                 ; 2B98: 7B
    neg                                     ; 2B99: ED 44
loc_2B9B:
    add a, b                                ; 2B9B: 80
    ld (ix+8), a                            ; 2B9C: DD 77 08
loc_2B9F:
    ld (ix+1), $80                          ; 2B9F: DD 36 01 80
    ld a, (SpeedHigh)                       ; 2BA3: 3A 1B C3
    rrca                                    ; 2BA6: 0F
    ld a, (SpeedMiddle)                     ; 2BA7: 3A 1A C3
    rra                                     ; 2BAA: 1F
    or a                                    ; 2BAB: B7
    rra                                     ; 2BAC: 1F
    or a                                    ; 2BAD: B7
    rra                                     ; 2BAE: 1F
    ld c, (ix+3)                            ; 2BAF: DD 4E 03
    ld b, $00                               ; 2BB2: 06 00
    ld hl, $2d5b                            ; 2BB4: 21 5B 2D
    add hl, bc                              ; 2BB7: 09
    ld h, (hl)                              ; 2BB8: 66
    ld c, $00                               ; 2BB9: 0E 00
    sub (ix+9)                              ; 2BBB: DD 96 09
    jr nc, loc_2BC3                         ; 2BBE: 30 03
    neg                                     ; 2BC0: ED 44
    inc c                                   ; 2BC2: 0C
loc_2BC3:
    ld e, a                                 ; 2BC3: 5F
    call MultiplyHLByB                      ; 2BC4: CD F1 05
    dec c                                   ; 2BC7: 0D
    jr nz, loc_2BD1                         ; 2BC8: 20 07
    ld a, l                                 ; 2BCA: 7D
    cpl                                     ; 2BCB: 2F
    ld l, a                                 ; 2BCC: 6F
    ld a, h                                 ; 2BCD: 7C
    cpl                                     ; 2BCE: 2F
    ld h, a                                 ; 2BCF: 67
    inc hl                                  ; 2BD0: 23
loc_2BD1:
    ld a, l                                 ; 2BD1: 7D
    add a, (ix+4)                           ; 2BD2: DD 86 04
    ld (ix+4), a                            ; 2BD5: DD 77 04
    ld a, h                                 ; 2BD8: 7C
    adc a, (ix+3)                           ; 2BD9: DD 8E 03
    ld (ix+3), a                            ; 2BDC: DD 77 03
    ld c, a                                 ; 2BDF: 4F
    add a, $5f                              ; 2BE0: C6 5F
    ld (ix+2), a                            ; 2BE2: DD 77 02
    ld a, c                                 ; 2BE5: 79
    cp $87                                  ; 2BE6: FE 87
    jp nc, loc_24E5                         ; 2BE8: D2 E5 24
    cp $60                                  ; 2BEB: FE 60
    jp nc, loc_2C78                         ; 2BED: D2 78 2C
    ld b, $00                               ; 2BF0: 06 00
    ld hl, $2cd3                            ; 2BF2: 21 D3 2C
    add hl, bc                              ; 2BF5: 09
    ld h, (hl)                              ; 2BF6: 66
    ld c, $00                               ; 2BF7: 0E 00
    ld a, (ix+8)                            ; 2BF9: DD 7E 08
    or a                                    ; 2BFC: B7
    jp p, loc_2C03                          ; 2BFD: F2 03 2C
    inc c                                   ; 2C00: 0C
    neg                                     ; 2C01: ED 44
loc_2C03:
    ld e, a                                 ; 2C03: 5F
    call MultiplyHLByB                      ; 2C04: CD F1 05
    ld a, h                                 ; 2C07: 7C
    ld b, $00                               ; 2C08: 06 00
    dec c                                   ; 2C0A: 0D
    jr nz, loc_2C15                         ; 2C0B: 20 08
    cpl                                     ; 2C0D: 2F
    ld h, a                                 ; 2C0E: 67
    ld a, l                                 ; 2C0F: 7D
    cpl                                     ; 2C10: 2F
    ld l, a                                 ; 2C11: 6F
    inc hl                                  ; 2C12: 23
    ld a, h                                 ; 2C13: 7C
    dec b                                   ; 2C14: 05
loc_2C15:
    add a, $84                              ; 2C15: C6 84
    ld (ix+6), a                            ; 2C17: DD 77 06
    ld a, $00                               ; 2C1A: 3E 00
    adc a, b                                ; 2C1C: 88
    ld (ix+7), a                            ; 2C1D: DD 77 07
    ld c, (ix+3)                            ; 2C20: DD 4E 03
    ld b, $00                               ; 2C23: 06 00
    ld hl, $c55f                            ; 2C25: 21 5F C5
    add hl, bc                              ; 2C28: 09
    ld a, (hl)                              ; 2C29: 7E
    ld e, $00                               ; 2C2A: 1E 00
    or a                                    ; 2C2C: B7
    jp p, loc_2C31                          ; 2C2D: F2 31 2C
    dec e                                   ; 2C30: 1D
loc_2C31:
    add a, (ix+6)                           ; 2C31: DD 86 06
    ld (ix+6), a                            ; 2C34: DD 77 06
    ld a, e                                 ; 2C37: 7B
    adc a, (ix+7)                           ; 2C38: DD 8E 07
    ld (ix+7), a                            ; 2C3B: DD 77 07
    ld hl, $2de3                            ; 2C3E: 21 E3 2D
    add hl, bc                              ; 2C41: 09
    ld a, (hl)                              ; 2C42: 7E
    add a, $07                              ; 2C43: C6 07
    add a, (ix+11)                          ; 2C45: DD 86 0B
    ld (ix+10), a                           ; 2C48: DD 77 0A
    ld a, (ix+7)                            ; 2C4B: DD 7E 07
    or a                                    ; 2C4E: B7
    ret nz                                  ; 2C4F: C0
    ld a, (ix+3)                            ; 2C50: DD 7E 03
    cp $4c                                  ; 2C53: FE 4C
    ret c                                   ; 2C55: D8
    cp $64                                  ; 2C56: FE 64
    ret nc                                  ; 2C58: D0
    ld a, (ix+12)                           ; 2C59: DD 7E 0C
    add a, a                                ; 2C5C: 87
    ld c, a                                 ; 2C5D: 4F
    ld b, $00                               ; 2C5E: 06 00
    ld hl, $2cc5                            ; 2C60: 21 C5 2C
    add hl, bc                              ; 2C63: 09
    ld a, (ix+6)                            ; 2C64: DD 7E 06
    add a, (hl)                             ; 2C67: 86
    ld b, a                                 ; 2C68: 47
    inc hl                                  ; 2C69: 23
    add a, (hl)                             ; 2C6A: 86
    ld hl, $c310                            ; 2C6B: 21 10 C3
    cp (hl)                                 ; 2C6E: BE
    ret c                                   ; 2C6F: D8
    inc hl                                  ; 2C70: 23
    ld a, b                                 ; 2C71: 78
    cp (hl)                                 ; 2C72: BE
    ret nc                                  ; 2C73: D0
    inc hl                                  ; 2C74: 23
    ld (hl), $01                            ; 2C75: 36 01
    ret                                     ; 2C77: C9
loc_2C78:
    ld b, $00                               ; 2C78: 06 00
    ld hl, $2cd3                            ; 2C7A: 21 D3 2C
    add hl, bc                              ; 2C7D: 09
    ld h, (hl)                              ; 2C7E: 66
    ld c, $00                               ; 2C7F: 0E 00
    ld a, (ix+8)                            ; 2C81: DD 7E 08
    or a                                    ; 2C84: B7
    jp p, loc_2C8B                          ; 2C85: F2 8B 2C
    inc c                                   ; 2C88: 0C
    neg                                     ; 2C89: ED 44
loc_2C8B:
    ld e, a                                 ; 2C8B: 5F
    push de                                 ; 2C8C: D5
    call MultiplyHLByB                      ; 2C8D: CD F1 05
    pop de                                  ; 2C90: D1
    ld a, h                                 ; 2C91: 7C
    add a, e                                ; 2C92: 83
    ld b, $00                               ; 2C93: 06 00
    dec c                                   ; 2C95: 0D
    jr nz, loc_2CA0                         ; 2C96: 20 08
    cpl                                     ; 2C98: 2F
    ld h, a                                 ; 2C99: 67
    ld a, l                                 ; 2C9A: 7D
    cpl                                     ; 2C9B: 2F
    ld l, a                                 ; 2C9C: 6F
    inc hl                                  ; 2C9D: 23
    ld a, h                                 ; 2C9E: 7C
    dec b                                   ; 2C9F: 05
loc_2CA0:
    add a, $84                              ; 2CA0: C6 84
    ld (ix+6), a                            ; 2CA2: DD 77 06
    ld a, $00                               ; 2CA5: 3E 00
    adc a, b                                ; 2CA7: 88
    ld (ix+7), a                            ; 2CA8: DD 77 07
    ld c, (ix+3)                            ; 2CAB: DD 4E 03
    ld b, $00                               ; 2CAE: 06 00
    ld hl, $c55f                            ; 2CB0: 21 5F C5
    add hl, bc                              ; 2CB3: 09
    ld a, (hl)                              ; 2CB4: 7E
    ld d, a                                 ; 2CB5: 57
    ld e, $00                               ; 2CB6: 1E 00
    ld a, ($c013)                           ; 2CB8: 3A 13 C0
    cp $54                                  ; 2CBB: FE 54
    ld a, d                                 ; 2CBD: 7A
    jp nc, loc_2C31                         ; 2CBE: D2 31 2C
    dec e                                   ; 2CC1: 1D
    jp loc_2C31                             ; 2CC2: C3 31 2C

; ----------------------------------------------------------------------------
; ROM data $2CC5-$2EF2 (558 bytes)
; ----------------------------------------------------------------------------
CoursePhysicsTables:
    .incbin "../assets/course_physics_tables.bin"

; ============================================================================
; Code $2EF3
; ============================================================================
UpdateBikeAnimation:
    ld hl, $c066                            ; 2EF3: 21 66 C0
    bit 0, (hl)                             ; 2EF6: CB 46
    jp nz, loc_2F82                         ; 2EF8: C2 82 2F
    ld hl, $c067                            ; 2EFB: 21 67 C0
    ld a, (hl)                              ; 2EFE: 7E
    or a                                    ; 2EFF: B7
    jr z, loc_2F04                          ; 2F00: 28 02
    dec (hl)                                ; 2F02: 35
    ret                                     ; 2F03: C9
loc_2F04:
    ld hl, $c044                            ; 2F04: 21 44 C0
    dec (hl)                                ; 2F07: 35
    jr nz, loc_2F3B                         ; 2F08: 20 31
    ld b, $03                               ; 2F0A: 06 03
    ld a, (Level)                           ; 2F0C: 3A C0 C4
    or a                                    ; 2F0F: B7
    jr nz, loc_2F13                         ; 2F10: 20 01
    dec b                                   ; 2F12: 05
loc_2F13:
    ld a, (GameState)                       ; 2F13: 3A 00 C0
    and $04                                 ; 2F16: E6 04
    jr z, loc_2F1C                          ; 2F18: 28 02
    ld b, $03                               ; 2F1A: 06 03
loc_2F1C:
    ld de, $3060                            ; 2F1C: 11 60 30
    ld hl, (SpeedMiddle)                    ; 2F1F: 2A 1A C3
    srl h                                   ; 2F22: CB 3C
    rr l                                    ; 2F24: CB 1D
    srl l                                   ; 2F26: CB 3D
    srl l                                   ; 2F28: CB 3D
    add hl, de                              ; 2F2A: 19
    ld a, (hl)                              ; 2F2B: 7E
    ld ($c044), a                           ; 2F2C: 32 44 C0
    ld a, b                                 ; 2F2F: 78
    or a                                    ; 2F30: B7
    jr z, loc_2F3B                          ; 2F31: 28 08
    ld hl, $c320                            ; 2F33: 21 20 C3
    ld c, $02                               ; 2F36: 0E 02
    call loc_2FCD                           ; 2F38: CD CD 2F
loc_2F3B:
    ld hl, $c06c                            ; 2F3B: 21 6C C0
    ld a, (hl)                              ; 2F3E: 7E
    or a                                    ; 2F3F: B7
    jp nz, loc_2F9E                         ; 2F40: C2 9E 2F
    inc hl                                  ; 2F43: 23
    ld a, (hl)                              ; 2F44: 7E
    or a                                    ; 2F45: B7
    jp nz, loc_2FA2                         ; 2F46: C2 A2 2F
    ld hl, ($c06f)                          ; 2F49: 2A 6F C0
    ld de, (SpeedMiddle)                    ; 2F4C: ED 5B 1A C3
    add hl, de                              ; 2F50: 19
    ld a, h                                 ; 2F51: 7C
    sub $1b                                 ; 2F52: D6 1B
    jr nc, loc_2F5A                         ; 2F54: 30 04
    ld ($c06f), hl                          ; 2F56: 22 6F C0
    ret                                     ; 2F59: C9
loc_2F5A:
    ld h, a                                 ; 2F5A: 67
    ld ($c06f), hl                          ; 2F5B: 22 6F C0
    ld b, $02                               ; 2F5E: 06 02
    ld hl, (LeftDistanceBCD)                ; 2F60: 2A 60 C0
    ld a, l                                 ; 2F63: 7D
    or a                                    ; 2F64: B7
    jr nz, loc_2F6B                         ; 2F65: 20 04
    ld a, h                                 ; 2F67: 7C
    cp $08                                  ; 2F68: FE 08
    ret c                                   ; 2F6A: D8
loc_2F6B:
    ld hl, $c380                            ; 2F6B: 21 80 C3
    ld a, ($c065)                           ; 2F6E: 3A 65 C0
    inc a                                   ; 2F71: 3C
    and $01                                 ; 2F72: E6 01
    add a, $03                              ; 2F74: C6 03
    ld c, a                                 ; 2F76: 4F
    call loc_2FCD                           ; 2F77: CD CD 2F
    ret nc                                  ; 2F7A: D0
    ld a, c                                 ; 2F7B: 79
    sub $03                                 ; 2F7C: D6 03
    ld ($c065), a                           ; 2F7E: 32 65 C0
    ret                                     ; 2F81: C9
loc_2F82:
    res 0, (hl)                             ; 2F82: CB 86
    ld hl, $c380                            ; 2F84: 21 80 C3
    ld c, $05                               ; 2F87: 0E 05
    ld b, $04                               ; 2F89: 06 04
    call loc_2FCD                           ; 2F8B: CD CD 2F
    ld hl, $c3c0                            ; 2F8E: 21 C0 C3
    ld c, $06                               ; 2F91: 0E 06
    ld b, $03                               ; 2F93: 06 03
    call loc_2FCD                           ; 2F95: CD CD 2F
    ld a, $78                               ; 2F98: 3E 78
    ld ($c067), a                           ; 2F9A: 32 67 C0
    ret                                     ; 2F9D: C9
loc_2F9E:
    ld c, $09                               ; 2F9E: 0E 09
    jr loc_2FA4                             ; 2FA0: 18 02
loc_2FA2:
    ld c, $0a                               ; 2FA2: 0E 0A
loc_2FA4:
    push hl                                 ; 2FA4: E5
    ld hl, ($c06f)                          ; 2FA5: 2A 6F C0
    ld de, (SpeedMiddle)                    ; 2FA8: ED 5B 1A C3
    add hl, de                              ; 2FAC: 19
    ld a, h                                 ; 2FAD: 7C
    sub $1b                                 ; 2FAE: D6 1B
    jr nc, loc_2FB7                         ; 2FB0: 30 05
    ld ($c06f), hl                          ; 2FB2: 22 6F C0
    pop hl                                  ; 2FB5: E1
    ret                                     ; 2FB6: C9
loc_2FB7:
    ld h, a                                 ; 2FB7: 67
    ld ($c06f), hl                          ; 2FB8: 22 6F C0
    pop hl                                  ; 2FBB: E1
    ld de, $c3c0                            ; 2FBC: 11 C0 C3
    ld a, (de)                              ; 2FBF: 1A
    or a                                    ; 2FC0: B7
    jr z, loc_2FC9                          ; 2FC1: 28 06
    ld de, $c3e0                            ; 2FC3: 11 E0 C3
    ld a, (de)                              ; 2FC6: 1A
    or a                                    ; 2FC7: B7
    ret nz                                  ; 2FC8: C0
loc_2FC9:
    ld a, c                                 ; 2FC9: 79
    ld (de), a                              ; 2FCA: 12
    dec (hl)                                ; 2FCB: 35
    ret                                     ; 2FCC: C9
loc_2FCD:
    ld de, $0020                            ; 2FCD: 11 20 00
loc_2FD0:
    ld a, (hl)                              ; 2FD0: 7E
    or a                                    ; 2FD1: B7
    jp z, loc_2FDA                          ; 2FD2: CA DA 2F
    add hl, de                              ; 2FD5: 19
    djnz loc_2FD0                           ; 2FD6: 10 F8
    and a                                   ; 2FD8: A7
    ret                                     ; 2FD9: C9
loc_2FDA:
    ld (hl), c                              ; 2FDA: 71
    scf                                     ; 2FDB: 37
    ret                                     ; 2FDC: C9

; ----------------------------------------------------------------------------
; ROM data $2FDD-$3087 (171 bytes)
; ----------------------------------------------------------------------------
BikeAnimationTables:
    .incbin "../assets/bike_animation_tables.bin"

; ============================================================================
; Code $3088
; ============================================================================
PatchRoadTilemap:
    ld iy, $c57e                            ; 3088: FD 21 7E C5
    ld de, $c034                            ; 308C: 11 34 C0
    ld ix, $3136                            ; 308F: DD 21 36 31
    ld hl, $3148                            ; 3093: 21 48 31
    exx                                     ; 3096: D9
    ld b, $09                               ; 3097: 06 09
loc_3099:
    exx                                     ; 3099: D9
    push hl                                 ; 309A: E5
    ld a, (iy+0)                            ; 309B: FD 7E 00
    or a                                    ; 309E: B7
    jp m, loc_310C                          ; 309F: FA 0C 31
    rrca                                    ; 30A2: 0F
    rrca                                    ; 30A3: 0F
    rrca                                    ; 30A4: 0F
    and $1f                                 ; 30A5: E6 1F
    sub (ix+0)                              ; 30A7: DD 96 00
    ld b, a                                 ; 30AA: 47
    jp c, loc_3129                          ; 30AB: DA 29 31
    ld a, (de)                              ; 30AE: 1A
    sub b                                   ; 30AF: 90
    jp z, loc_30FA                          ; 30B0: CA FA 30
    jp p, loc_30DC                          ; 30B3: F2 DC 30
loc_30B6:
    neg                                     ; 30B6: ED 44
    ld c, b                                 ; 30B8: 48
    ld b, a                                 ; 30B9: 47
    ld a, c                                 ; 30BA: 79
    dec c                                   ; 30BB: 0D
    ld (de), a                              ; 30BC: 12
    push de                                 ; 30BD: D5
loc_30BE:
    ld a, c                                 ; 30BE: 79
    add a, a                                ; 30BF: 87
    add a, c                                ; 30C0: 81
    ld c, $00                               ; 30C1: 0E 00
    ld d, c                                 ; 30C3: 51
    ld e, a                                 ; 30C4: 5F
    add hl, de                              ; 30C5: 19
    ld a, (hl)                              ; 30C6: 7E
    out (VDPControlPort), a                 ; 30C7: D3 BF
    inc hl                                  ; 30C9: 23
    ld a, (hl)                              ; 30CA: 7E
    out (VDPControlPort), a                 ; 30CB: D3 BF
    dec hl                                  ; 30CD: 2B
    xor a                                   ; 30CE: AF
    push af                                 ; 30CF: F5
    pop af                                  ; 30D0: F1
    out (VDPDataPort), a                    ; 30D1: D3 BE
    dec hl                                  ; 30D3: 2B
    dec hl                                  ; 30D4: 2B
    dec hl                                  ; 30D5: 2B
    djnz loc_30BE                           ; 30D6: 10 E6
    pop de                                  ; 30D8: D1
    jp loc_30FA                             ; 30D9: C3 FA 30
loc_30DC:
    ld c, b                                 ; 30DC: 48
    ld b, a                                 ; 30DD: 47
    ld a, c                                 ; 30DE: 79
    ld (de), a                              ; 30DF: 12
    push de                                 ; 30E0: D5
loc_30E1:
    ld a, c                                 ; 30E1: 79
    add a, a                                ; 30E2: 87
    add a, c                                ; 30E3: 81
    ld c, $00                               ; 30E4: 0E 00
    ld d, c                                 ; 30E6: 51
    ld e, a                                 ; 30E7: 5F
    add hl, de                              ; 30E8: 19
    ld a, (hl)                              ; 30E9: 7E
    out (VDPControlPort), a                 ; 30EA: D3 BF
    inc hl                                  ; 30EC: 23
    ld a, (hl)                              ; 30ED: 7E
    out (VDPControlPort), a                 ; 30EE: D3 BF
    inc hl                                  ; 30F0: 23
    ld a, (hl)                              ; 30F1: 7E
    push af                                 ; 30F2: F5
    pop af                                  ; 30F3: F1
    out (VDPDataPort), a                    ; 30F4: D3 BE
    inc hl                                  ; 30F6: 23
    djnz loc_30E1                           ; 30F7: 10 E8
    pop de                                  ; 30F9: D1
loc_30FA:
    pop hl                                  ; 30FA: E1
    ld bc, $0008                            ; 30FB: 01 08 00
    add iy, bc                              ; 30FE: FD 09
    ld c, $4e                               ; 3100: 0E 4E
    add hl, bc                              ; 3102: 09
    inc ix                                  ; 3103: DD 23
    inc ix                                  ; 3105: DD 23
    inc de                                  ; 3107: 13
    exx                                     ; 3108: D9
    djnz loc_3099                           ; 3109: 10 8E
    ret                                     ; 310B: C9
loc_310C:
    neg                                     ; 310C: ED 44
    ld bc, $0027                            ; 310E: 01 27 00
    add hl, bc                              ; 3111: 09
    rrca                                    ; 3112: 0F
    rrca                                    ; 3113: 0F
    rrca                                    ; 3114: 0F
    and $1f                                 ; 3115: E6 1F
    sub (ix+1)                              ; 3117: DD 96 01
    ld b, a                                 ; 311A: 47
    jp c, loc_3129                          ; 311B: DA 29 31
    ld a, (de)                              ; 311E: 1A
    sub b                                   ; 311F: 90
    jp z, loc_30FA                          ; 3120: CA FA 30
    jp p, loc_30DC                          ; 3123: F2 DC 30
    jp loc_30B6                             ; 3126: C3 B6 30
loc_3129:
    ld a, (de)                              ; 3129: 1A
    or a                                    ; 312A: B7
    jp z, loc_30FA                          ; 312B: CA FA 30
    ld b, a                                 ; 312E: 47
    xor a                                   ; 312F: AF
    ld c, a                                 ; 3130: 4F
    ld (de), a                              ; 3131: 12
    push de                                 ; 3132: D5
    jp loc_30E1                             ; 3133: C3 E1 30

; ----------------------------------------------------------------------------
; ROM data $3136-$3405 (720 bytes)
; ----------------------------------------------------------------------------
RoadPatchTilemapTable:
    .incbin "../assets/road_patch_tilemap_table.bin"

; ============================================================================
; Code $3406
; ============================================================================
UpdatePlayer:
    ld hl, $c2f2                            ; 3406: 21 F2 C2
    ld a, (hl)                              ; 3409: 7E
    or a                                    ; 340A: B7
    ret nz                                  ; 340B: C0
    ld hl, $0000                            ; 340C: 21 00 00
    ld a, (Course)                          ; 340F: 3A 10 C0
    add a, a                                ; 3412: 87
    add a, l                                ; 3413: 85
    ld l, a                                 ; 3414: 6F
    ld de, $670d                            ; 3415: 11 0D 67
    add hl, de                              ; 3418: 19
    ld e, (hl)                              ; 3419: 5E
    inc hl                                  ; 341A: 23
    ld d, (hl)                              ; 341B: 56
    ld a, (CourseDataIndex)                 ; 341C: 3A 11 C0
loc_341F:
    ld h, $00                               ; 341F: 26 00
    ld l, a                                 ; 3421: 6F
    ld c, a                                 ; 3422: 4F
    add hl, de                              ; 3423: 19
    ld a, (hl)                              ; 3424: 7E
    cp $ff                                  ; 3425: FE FF
    jp nz, loc_3431                         ; 3427: C2 31 34
    xor a                                   ; 342A: AF
    ld (CourseDataIndex), a                 ; 342B: 32 11 C0
    jp loc_341F                             ; 342E: C3 1F 34
loc_3431:
    ld e, c                                 ; 3431: 59
    inc e                                   ; 3432: 1C
    ld d, a                                 ; 3433: 57
    and $0f                                 ; 3434: E6 0F
    cp $04                                  ; 3436: FE 04
    jr nc, loc_3441                         ; 3438: 30 07
    inc hl                                  ; 343A: 23
    inc e                                   ; 343B: 1C
    ld c, (hl)                              ; 343C: 4E
    ld hl, $c2f1                            ; 343D: 21 F1 C2
    ld (hl), c                              ; 3440: 71
loc_3441:
    ld hl, CurrentCourseSegment             ; 3441: 21 F0 C2
    ld (hl), d                              ; 3444: 72
    ld hl, $0000                            ; 3445: 21 00 00
    ld a, ($c2f7)                           ; 3448: 3A F7 C2
    ld ($c2f4), a                           ; 344B: 32 F4 C2
    nop                                     ; 344E: 00
    nop                                     ; 344F: 00
    nop                                     ; 3450: 00
    ld a, e                                 ; 3451: 7B
    ld (CourseDataIndex), a                 ; 3452: 32 11 C0
    ld a, $ff                               ; 3455: 3E FF
    ld ($c2f2), a                           ; 3457: 32 F2 C2
    ld a, d                                 ; 345A: 7A
    and $1f                                 ; 345B: E6 1F
    ld l, a                                 ; 345D: 6F
    ld h, $00                               ; 345E: 26 00
    add hl, hl                              ; 3460: 29
    ld bc, $3489                            ; 3461: 01 89 34
    add hl, bc                              ; 3464: 09
    ld c, (hl)                              ; 3465: 4E
    inc hl                                  ; 3466: 23
    ld b, (hl)                              ; 3467: 46
    ld ($c2f5), bc                          ; 3468: ED 43 F5 C2
    bit 5, d                                ; 346C: CB 6A
    jr nz, loc_347D                         ; 346E: 20 0D
    bit 7, d                                ; 3470: CB 7A
    jr nz, loc_3483                         ; 3472: 20 0F
    bit 6, d                                ; 3474: CB 72
    ret z                                   ; 3476: C8
    ld a, $05                               ; 3477: 3E 05
    ld (BackgroundIndex), a                 ; 3479: 32 4B C0
    ret                                     ; 347C: C9
loc_347D:
    ld a, $03                               ; 347D: 3E 03
    ld ($c06c), a                           ; 347F: 32 6C C0
    ret                                     ; 3482: C9
loc_3483:
    ld a, $03                               ; 3483: 3E 03
    ld ($c06d), a                           ; 3485: 32 6D C0
    ret                                     ; 3488: C9

; ----------------------------------------------------------------------------
; ROM data $3489-$34BE (54 bytes)
; ----------------------------------------------------------------------------
CourseSegmentOffsets:
    .incbin "../assets/course_segment_offsets.bin"

; ============================================================================
; Code $34BF
; ============================================================================
InitializeRoad:
    ld de, $34d1                            ; 34BF: 11 D1 34
    ld hl, $7880                            ; 34C2: 21 80 78
    call DrawNullTerminatedTilemap          ; 34C5: CD FD 05
    ld de, $7055                            ; 34C8: 11 55 70
    ld hl, $7980                            ; 34CB: 21 80 79
    jp DrawNullTerminatedTilemap            ; 34CE: C3 FD 05

; ----------------------------------------------------------------------------
; ROM data $34D1-$3552 (130 bytes)
; ----------------------------------------------------------------------------
RoadTilemapInitialize:
    .incbin "../assets/road_tilemap_initialize.bin"

; ============================================================================
; Code $3553
; ============================================================================
UpdateScore:
    ld c, a                                 ; 3553: 4F
    ld a, (GameState)                       ; 3554: 3A 00 C0
    and $04                                 ; 3557: E6 04
    ret nz                                  ; 3559: C0
    ld a, c                                 ; 355A: 79
    add a, a                                ; 355B: 87
    add a, c                                ; 355C: 81
    ld c, a                                 ; 355D: 4F
    ld b, $00                               ; 355E: 06 00
    ld hl, $35d2                            ; 3560: 21 D2 35
    add hl, bc                              ; 3563: 09
    ld de, $c006                            ; 3564: 11 06 C0
    ld b, $03                               ; 3567: 06 03
    or a                                    ; 3569: B7
loc_356A:
    ld a, (de)                              ; 356A: 1A
    adc a, (hl)                             ; 356B: 8E
    daa                                     ; 356C: 27
    ld (de), a                              ; 356D: 12
    dec de                                  ; 356E: 1B
    dec hl                                  ; 356F: 2B
    djnz loc_356A                           ; 3570: 10 F8
    ld a, $ff                               ; 3572: 3E FF
    ld ($c072), a                           ; 3574: 32 72 C0
UpdateHighScore:
    ld de, $c006                            ; 3577: 11 06 C0
    ld hl, $c4c3                            ; 357A: 21 C3 C4
    ld b, $03                               ; 357D: 06 03
    xor a                                   ; 357F: AF
loc_3580:
    ld a, (de)                              ; 3580: 1A
    sbc a, (hl)                             ; 3581: 9E
    dec hl                                  ; 3582: 2B
    dec de                                  ; 3583: 1B
    djnz loc_3580                           ; 3584: 10 FA
    ret c                                   ; 3586: D8
    inc de                                  ; 3587: 13
    inc hl                                  ; 3588: 23
    ex de, hl                               ; 3589: EB
    ld bc, $0003                            ; 358A: 01 03 00
    ldir                                    ; 358D: ED B0
    ret                                     ; 358F: C9
DrawScore:
    ld hl, $c072                            ; 3590: 21 72 C0
    ld a, (hl)                              ; 3593: 7E
    or a                                    ; 3594: B7
    ret z                                   ; 3595: C8
    ld (hl), $00                            ; 3596: 36 00
    ld hl, $780e                            ; 3598: 21 0E 78
    call WriteAAndHToVDPControl             ; 359B: CD 16 00
    ld hl, ScoreBCD                         ; 359E: 21 04 C0
DrawBCDThreeBytes:
    ld bc, $0300                            ; 35A1: 01 00 03
loc_35A4:
    ld a, (hl)                              ; 35A4: 7E
    rrca                                    ; 35A5: 0F
    rrca                                    ; 35A6: 0F
    rrca                                    ; 35A7: 0F
    rrca                                    ; 35A8: 0F
    call loc_35B9                           ; 35A9: CD B9 35
    ld a, b                                 ; 35AC: 78
    dec a                                   ; 35AD: 3D
    jr nz, loc_35B1                         ; 35AE: 20 01
    ld c, b                                 ; 35B0: 48
loc_35B1:
    ld a, (hl)                              ; 35B1: 7E
    call loc_35B9                           ; 35B2: CD B9 35
    inc hl                                  ; 35B5: 23
    djnz loc_35A4                           ; 35B6: 10 EC
    ret                                     ; 35B8: C9
loc_35B9:
    and $0f                                 ; 35B9: E6 0F
    jr nz, loc_35C4                         ; 35BB: 20 07
    cp c                                    ; 35BD: B9
    jr nz, loc_35C4                         ; 35BE: 20 04
    ld a, $20                               ; 35C0: 3E 20
    jr loc_35C7                             ; 35C2: 18 03
loc_35C4:
    add a, $30                              ; 35C4: C6 30
    ld c, a                                 ; 35C6: 4F
loc_35C7:
    out (VDPDataPort), a                    ; 35C7: D3 BE
    ld a, $09                               ; 35C9: 3E 09
    push af                                 ; 35CB: F5
    pop af                                  ; 35CC: F1
    out (VDPDataPort), a                    ; 35CD: D3 BE
    ret                                     ; 35CF: C9

; ----------------------------------------------------------------------------
; ROM data $35D0-$35E4 (21 bytes)
; ----------------------------------------------------------------------------
ScoreBcdIncrementTable:
    .incbin "../assets/score_bcd_increment_table.bin"

; ============================================================================
; Code $35E5
; ============================================================================
DrawStartLights:
    ld hl, $7b86                            ; 35E5: 21 86 7B
    ld de, $3669                            ; 35E8: 11 69 36
    ld bc, $0207                            ; 35EB: 01 07 02
    call EmitTilemapRectangle               ; 35EE: CD 94 36
    ld hl, $7bb8                            ; 35F1: 21 B8 7B
    ld de, $3669                            ; 35F4: 11 69 36
    ld bc, $0207                            ; 35F7: 01 07 02
    call EmitTilemapRectangle               ; 35FA: CD 94 36
    ld a, $04                               ; 35FD: 3E 04
    ld (StartLightPhase), a                 ; 35FF: 32 49 C0
    ld a, $ae                               ; 3602: 3E AE
    ld (StartLightTimer), a                 ; 3604: 32 4A C0
    ld a, $05                               ; 3607: 3E 05
    ld (TextTrigger), a                     ; 3609: 32 64 C0
    ld a, $86                               ; 360C: 3E 86
    ld (SoundTrigger), a                    ; 360E: 32 00 C1
    ret                                     ; 3611: C9
UpdateStartLights:
    ld a, (StartLightPhase)                 ; 3612: 3A 49 C0
    or a                                    ; 3615: B7
    ret z                                   ; 3616: C8
    ld hl, StartLightTimer                  ; 3617: 21 4A C0
    dec (hl)                                ; 361A: 35
    ret nz                                  ; 361B: C0
    ld (hl), $30                            ; 361C: 36 30
    dec a                                   ; 361E: 3D
    ld (StartLightPhase), a                 ; 361F: 32 49 C0
    jp z, loc_364E                          ; 3622: CA 4E 36
    dec a                                   ; 3625: 3D
    ld c, a                                 ; 3626: 4F
    add a, a                                ; 3627: 87
    add a, a                                ; 3628: 87
    add a, c                                ; 3629: 81
    ld l, a                                 ; 362A: 6F
    ld h, $00                               ; 362B: 26 00
    ld de, $3685                            ; 362D: 11 85 36
    add hl, de                              ; 3630: 19
    ld c, (hl)                              ; 3631: 4E
    inc hl                                  ; 3632: 23
    ld e, (hl)                              ; 3633: 5E
    inc hl                                  ; 3634: 23
    ld d, (hl)                              ; 3635: 56
    inc hl                                  ; 3636: 23
    ld a, (hl)                              ; 3637: 7E
    inc hl                                  ; 3638: 23
    ld h, (hl)                              ; 3639: 66
    ld l, a                                 ; 363A: 6F
    ld b, $02                               ; 363B: 06 02
    push hl                                 ; 363D: E5
    push de                                 ; 363E: D5
    push bc                                 ; 363F: C5
    call EmitTilemapRectangle               ; 3640: CD 94 36
    pop bc                                  ; 3643: C1
    pop de                                  ; 3644: D1
    pop hl                                  ; 3645: E1
    ld a, l                                 ; 3646: 7D
    add a, $32                              ; 3647: C6 32
    ld l, a                                 ; 3649: 6F
    call EmitTilemapRectangle               ; 364A: CD 94 36
    ret                                     ; 364D: C9
loc_364E:
    ld hl, $7b86                            ; 364E: 21 86 7B
    ld de, $0100                            ; 3651: 11 00 01
    ld bc, $0207                            ; 3654: 01 07 02
    call FillTilemapRectangle               ; 3657: CD B1 36
    ld hl, $7bb8                            ; 365A: 21 B8 7B
    ld bc, $0207                            ; 365D: 01 07 02
    call FillTilemapRectangle               ; 3660: CD B1 36
    ld a, $0a                               ; 3663: 3E 0A
    ld (TextTrigger), a                     ; 3665: 32 64 C0
    ret                                     ; 3668: C9

; ----------------------------------------------------------------------------
; ROM data $3669-$3693 (43 bytes)
; ----------------------------------------------------------------------------
StartLightTilemaps:
    .incbin "../assets/start_light_tilemaps.bin"

; ============================================================================
; Code $3694
; ============================================================================
EmitTilemapRectangle:
    push bc                                 ; 3694: C5
    call WriteAAndHToVDPControl             ; 3695: CD 16 00
loc_3698:
    ld a, (de)                              ; 3698: 1A
    out (VDPDataPort), a                    ; 3699: D3 BE
    ld a, $09                               ; 369B: 3E 09
    push af                                 ; 369D: F5
    pop af                                  ; 369E: F1
    out (VDPDataPort), a                    ; 369F: D3 BE
    inc de                                  ; 36A1: 13
    djnz loc_3698                           ; 36A2: 10 F4
    pop bc                                  ; 36A4: C1
    ld a, l                                 ; 36A5: 7D
    add a, $40                              ; 36A6: C6 40
    ld l, a                                 ; 36A8: 6F
    ld a, h                                 ; 36A9: 7C
    adc a, $00                              ; 36AA: CE 00
    ld h, a                                 ; 36AC: 67
    dec c                                   ; 36AD: 0D
    jr nz, EmitTilemapRectangle             ; 36AE: 20 E4
    ret                                     ; 36B0: C9
FillTilemapRectangle:
    push bc                                 ; 36B1: C5
    call WriteAAndHToVDPControl             ; 36B2: CD 16 00
loc_36B5:
    ld a, e                                 ; 36B5: 7B
    out (VDPDataPort), a                    ; 36B6: D3 BE
    ld a, d                                 ; 36B8: 7A
    push af                                 ; 36B9: F5
    pop af                                  ; 36BA: F1
    out (VDPDataPort), a                    ; 36BB: D3 BE
    djnz loc_36B5                           ; 36BD: 10 F6
    pop bc                                  ; 36BF: C1
    ld a, l                                 ; 36C0: 7D
    add a, $40                              ; 36C1: C6 40
    ld l, a                                 ; 36C3: 6F
    ld a, h                                 ; 36C4: 7C
    adc a, $00                              ; 36C5: CE 00
    ld h, a                                 ; 36C7: 67
    dec c                                   ; 36C8: 0D
    jr nz, FillTilemapRectangle             ; 36C9: 20 E6
    ret                                     ; 36CB: C9
UpdateGearDisplay:
    ld hl, $c071                            ; 36CC: 21 71 C0
    ld a, (Gear)                            ; 36CF: 3A 18 C3
    cp (hl)                                 ; 36D2: BE
    ret z                                   ; 36D3: C8
    ld (hl), a                              ; 36D4: 77
    add a, a                                ; 36D5: 87
    add a, a                                ; 36D6: 87
    ld l, a                                 ; 36D7: 6F
    ld h, $00                               ; 36D8: 26 00
    ld de, $36ff                            ; 36DA: 11 FF 36
    add hl, de                              ; 36DD: 19
    ex de, hl                               ; 36DE: EB
    ld hl, $7824                            ; 36DF: 21 24 78
    call WriteAAndHToVDPControl             ; 36E2: CD 16 00
    ld a, (de)                              ; 36E5: 1A
    out (VDPDataPort), a                    ; 36E6: D3 BE
    inc de                                  ; 36E8: 13
    push af                                 ; 36E9: F5
    pop af                                  ; 36EA: F1
    ld a, (de)                              ; 36EB: 1A
    out (VDPDataPort), a                    ; 36EC: D3 BE
    inc de                                  ; 36EE: 13
    ld hl, $7864                            ; 36EF: 21 64 78
    call WriteAAndHToVDPControl             ; 36F2: CD 16 00
    ld a, (de)                              ; 36F5: 1A
    out (VDPDataPort), a                    ; 36F6: D3 BE
    inc de                                  ; 36F8: 13
    push af                                 ; 36F9: F5
    pop af                                  ; 36FA: F1
    ld a, (de)                              ; 36FB: 1A
    out (VDPDataPort), a                    ; 36FC: D3 BE
    ret                                     ; 36FE: C9

; ----------------------------------------------------------------------------
; ROM data $36FF-$370A (12 bytes)
; ----------------------------------------------------------------------------
RomData_36FF:
    .db $70, $09, $72, $0d, $71, $09, $71, $0d, $72, $09, $70, $0d ; 36FF: 70 09 72 0D 71 09 71 0D 72 09 70 0D

; ============================================================================
; Code $370B
; ============================================================================
UpdateLeftDistanceDisplay:
    ld hl, $7876                            ; 370B: 21 76 78
    call WriteAAndHToVDPControl             ; 370E: CD 16 00
    ld hl, LeftDistanceBCD                  ; 3711: 21 60 C0
    ld a, (hl)                              ; 3714: 7E
    or $30                                  ; 3715: F6 30
    out (VDPDataPort), a                    ; 3717: D3 BE
    ld a, $09                               ; 3719: 3E 09
    push af                                 ; 371B: F5
    pop af                                  ; 371C: F1
    out (VDPDataPort), a                    ; 371D: D3 BE
    ld a, $51                               ; 371F: 3E 51
    push af                                 ; 3721: F5
    pop af                                  ; 3722: F1
    out (VDPDataPort), a                    ; 3723: D3 BE
    ld a, $09                               ; 3725: 3E 09
    push af                                 ; 3727: F5
    pop af                                  ; 3728: F1
    out (VDPDataPort), a                    ; 3729: D3 BE
    ld hl, $c061                            ; 372B: 21 61 C0
    ld bc, $0101                            ; 372E: 01 01 01
    jp loc_35A4                             ; 3731: C3 A4 35
loc_3734:
    ld hl, (LeftDistanceBCD)                ; 3734: 2A 60 C0
    ld a, l                                 ; 3737: 7D
    or h                                    ; 3738: B4
    ret z                                   ; 3739: C8
    ld hl, (SpeedCopy)                      ; 373A: 2A 2A C0
    ld de, (DistanceTravelled2)             ; 373D: ED 5B 62 C0
    add hl, de                              ; 3741: 19
    ld (DistanceTravelled2), hl             ; 3742: 22 62 C0
    ld a, h                                 ; 3745: 7C
    cp $08                                  ; 3746: FE 08
    ret c                                   ; 3748: D8
    xor a                                   ; 3749: AF
    ld ($c063), a                           ; 374A: 32 63 C0
    ld hl, $c061                            ; 374D: 21 61 C0
    ld a, (hl)                              ; 3750: 7E
    sbc a, $01                              ; 3751: DE 01
    daa                                     ; 3753: 27
    ld (hl), a                              ; 3754: 77
    dec hl                                  ; 3755: 2B
    ld a, (hl)                              ; 3756: 7E
    sbc a, $00                              ; 3757: DE 00
    daa                                     ; 3759: 27
    ld (hl), a                              ; 375A: 77
    or a                                    ; 375B: B7
    jr nz, loc_3769                         ; 375C: 20 0B
    inc hl                                  ; 375E: 23
    ld a, (hl)                              ; 375F: 7E
    cp $04                                  ; 3760: FE 04
    jr nz, loc_3769                         ; 3762: 20 05
    ld a, $01                               ; 3764: 3E 01
    ld ($c066), a                           ; 3766: 32 66 C0
loc_3769:
    ld hl, (SpeedCopy)                      ; 3769: 2A 2A C0
    ld c, $04                               ; 376C: 0E 04
    ld a, h                                 ; 376E: 7C
    or a                                    ; 376F: B7
    ld a, l                                 ; 3770: 7D
    jr z, loc_377F                          ; 3771: 28 0C
    cp $2c                                  ; 3773: FE 2C
    jr nc, loc_3788                         ; 3775: 30 11
    dec c                                   ; 3777: 0D
    cp $15                                  ; 3778: FE 15
    jr nc, loc_3788                         ; 377A: 30 0C
    dec c                                   ; 377C: 0D
    jr loc_3788                             ; 377D: 18 09
loc_377F:
    ld c, $01                               ; 377F: 0E 01
    cp $96                                  ; 3781: FE 96
    jr nc, loc_3788                         ; 3783: 30 03
    dec c                                   ; 3785: 0D
    or a                                    ; 3786: B7
    ret z                                   ; 3787: C8
loc_3788:
    ld a, c                                 ; 3788: 79
    jp UpdateScore                          ; 3789: C3 53 35
MaybeLoadSceneryTiles:
    ld a, (ReloadBikeSprites)               ; 378C: 3A 69 C0
    or a                                    ; 378F: B7
    ret nz                                  ; 3790: C0
    ld a, (RoadsideSceneryLoadIndex)        ; 3791: 3A 68 C0
    or a                                    ; 3794: B7
    ret z                                   ; 3795: C8
    dec a                                   ; 3796: 3D
    jr nz, loc_37A8                         ; 3797: 20 0F
    ld a, (StageNumber)                     ; 3799: 3A 07 C0
    cp $04                                  ; 379C: FE 04
    ld a, $00                               ; 379E: 3E 00
    jr nz, loc_37A8                         ; 37A0: 20 06
    ld a, $03                               ; 37A2: 3E 03
    ld (LoadGoSign), a                      ; 37A4: 32 6A C0
    xor a                                   ; 37A7: AF
loc_37A8:
    ld (RoadsideSceneryLoadIndex), a        ; 37A8: 32 68 C0
    add a, a                                ; 37AB: 87
    add a, a                                ; 37AC: 87
    add a, a                                ; 37AD: 87
    add a, a                                ; 37AE: 87
    ld l, a                                 ; 37AF: 6F
    ld h, $00                               ; 37B0: 26 00
    add hl, hl                              ; 37B2: 29
    add hl, hl                              ; 37B3: 29
    ex de, hl                               ; 37B4: EB
    ld a, (StageNumber)                     ; 37B5: 3A 07 C0
    add a, a                                ; 37B8: 87
    ld l, a                                 ; 37B9: 6F
    ld h, $00                               ; 37BA: 26 00
    ld bc, $37cf                            ; 37BC: 01 CF 37
    add hl, bc                              ; 37BF: 09
    ld c, (hl)                              ; 37C0: 4E
    inc hl                                  ; 37C1: 23
    ld b, (hl)                              ; 37C2: 46
    ld hl, $5d40                            ; 37C3: 21 40 5D
    add hl, de                              ; 37C6: 19
    ex de, hl                               ; 37C7: EB
    add hl, bc                              ; 37C8: 09
    ld bc, $40be                            ; 37C9: 01 BE 40
    jp WriteDataToVDP                       ; 37CC: C3 1E 00

; ----------------------------------------------------------------------------
; ROM data $37CF-$37D8 (10 bytes)
; ----------------------------------------------------------------------------
RomData_37CF:
    .db $00, $c7, $80, $c8, $80, $ca, $40, $cd, $00, $c7 ; 37CF: 00 C7 80 C8 80 CA 40 CD 00 C7

; ============================================================================
; Code $37D9
; ============================================================================
MaybeReloadBikeSpritesA:
    ld a, (ReloadBikeSprites)               ; 37D9: 3A 69 C0
    or a                                    ; 37DC: B7
    ret z                                   ; 37DD: C8
    dec a                                   ; 37DE: 3D
    ld (ReloadBikeSprites), a               ; 37DF: 32 69 C0
    add a, a                                ; 37E2: 87
    add a, a                                ; 37E3: 87
    add a, a                                ; 37E4: 87
    add a, a                                ; 37E5: 87
    ld l, a                                 ; 37E6: 6F
    ld h, $00                               ; 37E7: 26 00
    add hl, hl                              ; 37E9: 29
    add hl, hl                              ; 37EA: 29
    add hl, hl                              ; 37EB: 29
    ex de, hl                               ; 37EC: EB
    ld hl, $d000                            ; 37ED: 21 00 D0
    ld a, ($c06e)                           ; 37F0: 3A 6E C0
    or a                                    ; 37F3: B7
    jr nz, loc_37F9                         ; 37F4: 20 03
    ld hl, BikeSpriteTiles                  ; 37F6: 21 A0 D8
loc_37F9:
    add hl, de                              ; 37F9: 19
    ex de, hl                               ; 37FA: EB
    ld bc, $4cc0                            ; 37FB: 01 C0 4C
    add hl, bc                              ; 37FE: 09
    ld bc, $80be                            ; 37FF: 01 BE 80
    ex de, hl                               ; 3802: EB
    jp WriteDataToVDP                       ; 3803: C3 1E 00
MaybeReloadBikeSpritesB:
    ld a, (ReloadBikeSprites)               ; 3806: 3A 69 C0
    or a                                    ; 3809: B7
    ret nz                                  ; 380A: C0
    ld a, (LoadGoSign)                      ; 380B: 3A 6A C0
    or a                                    ; 380E: B7
    ret z                                   ; 380F: C8
    dec a                                   ; 3810: 3D
    ld (LoadGoSign), a                      ; 3811: 32 6A C0
    add a, a                                ; 3814: 87
    add a, a                                ; 3815: 87
    add a, a                                ; 3816: 87
    add a, a                                ; 3817: 87
    ld l, a                                 ; 3818: 6F
    ld h, $00                               ; 3819: 26 00
    add hl, hl                              ; 381B: 29
    add hl, hl                              ; 381C: 29
    ex de, hl                               ; 381D: EB
    ld hl, $d700                            ; 381E: 21 00 D7
    ld a, (StageNumber)                     ; 3821: 3A 07 C0
    cp $04                                  ; 3824: FE 04
    jr z, loc_382B                          ; 3826: 28 03
    ld hl, GoSignTiles                      ; 3828: 21 E0 D7
loc_382B:
    add hl, de                              ; 382B: 19
    ex de, hl                               ; 382C: EB
    ld bc, $4400                            ; 382D: 01 00 44
    add hl, bc                              ; 3830: 09
    ld bc, $40be                            ; 3831: 01 BE 40
    ex de, hl                               ; 3834: EB
    jp WriteDataToVDP                       ; 3835: C3 1E 00
UpdateDistance:
    ld hl, (SpeedCopy)                      ; 3838: 2A 2A C0
    ld de, (DistanceTravelled1)             ; 383B: ED 5B 57 C0
    add hl, de                              ; 383F: 19
    ld (DistanceTravelled1), hl             ; 3840: 22 57 C0
    ld a, h                                 ; 3843: 7C
    cp d                                    ; 3844: BA
    jr nz, loc_3853                         ; 3845: 20 0C
    ld hl, ($c05a)                          ; 3847: 2A 5A C0
    ld de, ($c05c)                          ; 384A: ED 5B 5C C0
    add hl, de                              ; 384E: 19
    ld ($c05a), hl                          ; 384F: 22 5A C0
    ret                                     ; 3852: C9
loc_3853:
    ld hl, ($c2f5)                          ; 3853: 2A F5 C2
    bit 7, h                                ; 3856: CB 7C
    jr z, loc_3872                          ; 3858: 28 18
    ld a, l                                 ; 385A: 7D
    cpl                                     ; 385B: 2F
    ld l, a                                 ; 385C: 6F
    ld a, h                                 ; 385D: 7C
    cpl                                     ; 385E: 2F
    ld h, a                                 ; 385F: 67
    inc hl                                  ; 3860: 23
    ld a, l                                 ; 3861: 7D
    srl h                                   ; 3862: CB 3C
    rra                                     ; 3864: 1F
    srl h                                   ; 3865: CB 3C
    rra                                     ; 3867: 1F
    neg                                     ; 3868: ED 44
    ld e, a                                 ; 386A: 5F
    ld d, $ff                               ; 386B: 16 FF
    jr nz, loc_387C                         ; 386D: 20 0D
    inc d                                   ; 386F: 14
    jr loc_387C                             ; 3870: 18 0A
loc_3872:
    ld a, l                                 ; 3872: 7D
    srl h                                   ; 3873: CB 3C
    rra                                     ; 3875: 1F
    srl h                                   ; 3876: CB 3C
    rra                                     ; 3878: 1F
    ld d, $00                               ; 3879: 16 00
    ld e, a                                 ; 387B: 5F
loc_387C:
    ld hl, ($c05c)                          ; 387C: 2A 5C C0
    add hl, de                              ; 387F: 19
    ld de, ($c05a)                          ; 3880: ED 5B 5A C0
    add hl, de                              ; 3884: 19
    ld ($c05a), hl                          ; 3885: 22 5A C0
    ld hl, ($c2f5)                          ; 3888: 2A F5 C2
    ld d, l                                 ; 388B: 55
    ld c, h                                 ; 388C: 4C
    ld a, ($c053)                           ; 388D: 3A 53 C0
    add a, d                                ; 3890: 82
    ld ($c053), a                           ; 3891: 32 53 C0
    ld hl, (BackgroundXScroll)              ; 3894: 2A 51 C0
    ld d, h                                 ; 3897: 54
    ld e, l                                 ; 3898: 5D
    ld b, $00                               ; 3899: 06 00
    bit 7, c                                ; 389B: CB 79
    jr z, loc_38A1                          ; 389D: 28 02
    ld b, $ff                               ; 389F: 06 FF
loc_38A1:
    adc hl, bc                              ; 38A1: ED 4A
    or a                                    ; 38A3: B7
    sbc hl, de                              ; 38A4: ED 52
    ld a, l                                 ; 38A6: 7D
    ld ($c026), a                           ; 38A7: 32 26 C0
    ld a, ($c026)                           ; 38AA: 3A 26 C0
    or a                                    ; 38AD: B7
    ret z                                   ; 38AE: C8
    ld e, a                                 ; 38AF: 5F
    ld d, $00                               ; 38B0: 16 00
    jp p, loc_38B6                          ; 38B2: F2 B6 38
    dec d                                   ; 38B5: 15
loc_38B6:
    ld c, e                                 ; 38B6: 4B
    ld hl, (BackgroundXScroll)              ; 38B7: 2A 51 C0
    ex de, hl                               ; 38BA: EB
    add hl, de                              ; 38BB: 19
    res 1, h                                ; 38BC: CB 8C
    ld a, h                                 ; 38BE: 7C
    cp d                                    ; 38BF: BA
    jr z, loc_38D8                          ; 38C0: 28 16
    push hl                                 ; 38C2: E5
    push de                                 ; 38C3: D5
    ld a, (BackgroundIndex)                 ; 38C4: 3A 4B C0
    add a, a                                ; 38C7: 87
    ld e, a                                 ; 38C8: 5F
    ld d, $00                               ; 38C9: 16 00
    ld hl, $3939                            ; 38CB: 21 39 39
    add hl, de                              ; 38CE: 19
    ld e, (hl)                              ; 38CF: 5E
    inc hl                                  ; 38D0: 23
    ld d, (hl)                              ; 38D1: 56
    ex de, hl                               ; 38D2: EB
    ld (BackgroundDataPointer), hl          ; 38D3: 22 4D C0
    pop de                                  ; 38D6: D1
    pop hl                                  ; 38D7: E1
loc_38D8:
    ld (BackgroundXScroll), hl              ; 38D8: 22 51 C0
    ld a, e                                 ; 38DB: 7B
    and $f8                                 ; 38DC: E6 F8
    ld b, a                                 ; 38DE: 47
    ld a, l                                 ; 38DF: 7D
    and $f8                                 ; 38E0: E6 F8
    cp b                                    ; 38E2: B8
    ret z                                   ; 38E3: C8
    ld a, ($c026)                           ; 38E4: 3A 26 C0
    or a                                    ; 38E7: B7
    ld a, l                                 ; 38E8: 7D
    jp p, loc_38ED                          ; 38E9: F2 ED 38
    ld a, e                                 ; 38EC: 7B
loc_38ED:
    rrca                                    ; 38ED: 0F
    rrca                                    ; 38EE: 0F
    and $3e                                 ; 38EF: E6 3E
    ld c, a                                 ; 38F1: 4F
    ld b, $00                               ; 38F2: 06 00
    ex de, hl                               ; 38F4: EB
    ld hl, $7a40                            ; 38F5: 21 40 7A
    add hl, bc                              ; 38F8: 09
    ex de, hl                               ; 38F9: EB
    srl h                                   ; 38FA: CB 3C
    rr l                                    ; 38FC: CB 1D
    ld a, l                                 ; 38FE: 7D
    rra                                     ; 38FF: 1F
    rra                                     ; 3900: 1F
    and $3f                                 ; 3901: E6 3F
    ld c, a                                 ; 3903: 4F
    ld a, ($c026)                           ; 3904: 3A 26 C0
    or a                                    ; 3907: B7
    jp p, loc_3911                          ; 3908: F2 11 39
    ld a, c                                 ; 390B: 79
    add a, $21                              ; 390C: C6 21
    and $3f                                 ; 390E: E6 3F
    ld c, a                                 ; 3910: 4F
loc_3911:
    ld a, c                                 ; 3911: 79
    add a, a                                ; 3912: 87
    add a, c                                ; 3913: 81
    ld c, a                                 ; 3914: 4F
    ld b, $00                               ; 3915: 06 00
    ld hl, (BackgroundDataPointer)          ; 3917: 2A 4D C0
    add hl, bc                              ; 391A: 09
    ex de, hl                               ; 391B: EB
    call WriteAAndHToVDPControl             ; 391C: CD 16 00
    ld a, (de)                              ; 391F: 1A
    out (VDPDataPort), a                    ; 3920: D3 BE
    inc de                                  ; 3922: 13
    ld a, l                                 ; 3923: 7D
    add a, $40                              ; 3924: C6 40
    ld l, a                                 ; 3926: 6F
    call WriteAAndHToVDPControl             ; 3927: CD 16 00
    ld a, (de)                              ; 392A: 1A
    out (VDPDataPort), a                    ; 392B: D3 BE
    inc de                                  ; 392D: 13
    ld a, l                                 ; 392E: 7D
    add a, $40                              ; 392F: C6 40
    ld l, a                                 ; 3931: 6F
    call WriteAAndHToVDPControl             ; 3932: CD 16 00
    ld a, (de)                              ; 3935: 1A
    out (VDPDataPort), a                    ; 3936: D3 BE
    ret                                     ; 3938: C9

; ----------------------------------------------------------------------------
; ROM data $3939-$3944 (12 bytes)
; ----------------------------------------------------------------------------
RomData_3939:
    .db $55, $6d, $15, $6e, $d5, $6e, $95, $6f, $55, $6d, $56, $70 ; 3939: 55 6D 15 6E D5 6E 95 6F 55 6D 56 70

; ============================================================================
; Code $3945
; ============================================================================
LoadStagePalette:
    ld a, (LastPaletteLoadStage)            ; 3945: 3A 5E C0
    ld b, a                                 ; 3948: 47
    ld a, (StageNumber)                     ; 3949: 3A 07 C0
    cp b                                    ; 394C: B8
    ret z                                   ; 394D: C8
    ld (LastPaletteLoadStage), a            ; 394E: 32 5E C0
LoadStagePalettes:
    add a, a                                ; 3951: 87
    ld e, a                                 ; 3952: 5F
    add a, a                                ; 3953: 87
    push af                                 ; 3954: F5
    add a, a                                ; 3955: 87
    add a, e                                ; 3956: 83
    ld l, a                                 ; 3957: 6F
    ld h, $00                               ; 3958: 26 00
    ld de, $39b6                            ; 395A: 11 B6 39
    add hl, de                              ; 395D: 19
    ld de, Course                           ; 395E: 11 10 C0
    ld b, $0a                               ; 3961: 06 0A
    call WriteDataToVDP                     ; 3963: CD 1E 00
    pop af                                  ; 3966: F1
    ld l, a                                 ; 3967: 6F
    ld h, $00                               ; 3968: 26 00
    ld de, $39e8                            ; 396A: 11 E8 39
    add hl, de                              ; 396D: 19
    ld de, GameState                        ; 396E: 11 00 C0
    ld b, $04                               ; 3971: 06 04
    jp WriteDataToVDP                       ; 3973: C3 1E 00

; ----------------------------------------------------------------------------
; ROM data $3976-$39FB (134 bytes)
; ----------------------------------------------------------------------------
StagePalettesAndInitState:
    .incbin "../assets/stage_palettes_and_init_state.bin"

; ============================================================================
; Code $39FC
; ============================================================================
UpdateStageMessage:
    ld bc, $003c                            ; 39FC: 01 3C 00
    ld a, (GameState)                       ; 39FF: 3A 00 C0
    and $04                                 ; 3A02: E6 04
    jr nz, loc_3A13                         ; 3A04: 20 0D
    ld a, $01                               ; 3A06: 3E 01
    ld (TextTrigger), a                     ; 3A08: 32 64 C0
    ld bc, $0438                            ; 3A0B: 01 38 04
    ld a, $89                               ; 3A0E: 3E 89
    ld (SoundTrigger), a                    ; 3A10: 32 00 C1
loc_3A13:
    call WaitForVBlankAndClearPauseFlag     ; 3A13: CD 08 00
    push bc                                 ; 3A16: C5
    call UpdateObjects                      ; 3A17: CD 96 24
    pop bc                                  ; 3A1A: C1
    ld a, (Buttons)                         ; 3A1B: 3A 01 C0
    cpl                                     ; 3A1E: 2F
    ld e, a                                 ; 3A1F: 5F
    ld a, (ButtonsPrevious)                 ; 3A20: 3A 1A C0
    and e                                   ; 3A23: A3
    and $30                                 ; 3A24: E6 30
    jr nz, loc_3A2D                         ; 3A26: 20 05
    dec bc                                  ; 3A28: 0B
    ld a, b                                 ; 3A29: 78
    or c                                    ; 3A2A: B1
    jr nz, loc_3A13                         ; 3A2B: 20 E6
loc_3A2D:
    call UpdateHighScore                    ; 3A2D: CD 77 35
    jp loc_00E0                             ; 3A30: C3 E0 00
MaybeDrawText:
    ld hl, TextTrigger                      ; 3A33: 21 64 C0
    ld a, (hl)                              ; 3A36: 7E
    or a                                    ; 3A37: B7
    ret z                                   ; 3A38: C8
    ld (hl), $00                            ; 3A39: 36 00
    add a, a                                ; 3A3B: 87
    add a, a                                ; 3A3C: 87
    ld l, a                                 ; 3A3D: 6F
    ld h, $00                               ; 3A3E: 26 00
    ld de, $3a7d                            ; 3A40: 11 7D 3A
    add hl, de                              ; 3A43: 19
    ld e, (hl)                              ; 3A44: 5E
    inc hl                                  ; 3A45: 23
    ld d, (hl)                              ; 3A46: 56
    inc hl                                  ; 3A47: 23
    ld a, (hl)                              ; 3A48: 7E
    inc hl                                  ; 3A49: 23
    ld h, (hl)                              ; 3A4A: 66
    ld l, a                                 ; 3A4B: 6F
    ld a, (BackgroundXScroll)               ; 3A4C: 3A 51 C0
    rrca                                    ; 3A4F: 0F
    rrca                                    ; 3A50: 0F
    and $3e                                 ; 3A51: E6 3E
    ld c, a                                 ; 3A53: 4F
    ld b, $00                               ; 3A54: 06 00
    add hl, bc                              ; 3A56: 09
    ld a, h                                 ; 3A57: 7C
    cp $7a                                  ; 3A58: FE 7A
    jr c, loc_3A62                          ; 3A5A: 38 06
    ld h, $79                               ; 3A5C: 26 79
    ld a, l                                 ; 3A5E: 7D
    sub $40                                 ; 3A5F: D6 40
    ld l, a                                 ; 3A61: 6F
loc_3A62:
    call WriteAAndHToVDPControl             ; 3A62: CD 16 00
loc_3A65:
    ld a, (de)                              ; 3A65: 1A
    or a                                    ; 3A66: B7
    ret z                                   ; 3A67: C8
    out (VDPDataPort), a                    ; 3A68: D3 BE
    inc de                                  ; 3A6A: 13
    inc hl                                  ; 3A6B: 23
    inc hl                                  ; 3A6C: 23
    push af                                 ; 3A6D: F5
    pop af                                  ; 3A6E: F1
    ld a, $09                               ; 3A6F: 3E 09
    out (VDPDataPort), a                    ; 3A71: D3 BE
    ld a, h                                 ; 3A73: 7C
    cp $7a                                  ; 3A74: FE 7A
    jr c, loc_3A65                          ; 3A76: 38 ED
    ld hl, $79c0                            ; 3A78: 21 C0 79
    call WriteAAndHToVDPControl             ; 3A7B: CD 16 00
    jr loc_3A65                             ; 3A7E: 18 E5

; ----------------------------------------------------------------------------
; ROM data $3A80-$3B0A (139 bytes)
; ----------------------------------------------------------------------------
MessageStrings:
    .incbin "../assets/message_strings.bin"

; ============================================================================
; Code $3B0B
; ============================================================================
UpdateRoadsideScenery:
    ld a, $02                               ; 3B0B: 3E 02
    ld (TextTrigger), a                     ; 3B0D: 32 64 C0
    ld hl, $c380                            ; 3B10: 21 80 C3
    ld de, $001f                            ; 3B13: 11 1F 00
    ld b, $04                               ; 3B16: 06 04
    xor a                                   ; 3B18: AF
loc_3B19:
    ld (hl), a                              ; 3B19: 77
    inc hl                                  ; 3B1A: 23
    ld (hl), a                              ; 3B1B: 77
    add hl, de                              ; 3B1C: 19
    djnz loc_3B19                           ; 3B1D: 10 FA
    ld bc, $012c                            ; 3B1F: 01 2C 01
    ld a, $88                               ; 3B22: 3E 88
    ld (SoundTrigger), a                    ; 3B24: 32 00 C1
loc_3B27:
    call WaitForVBlankAndClearPauseFlag     ; 3B27: CD 08 00
    push bc                                 ; 3B2A: C5
    call UpdateObjects                      ; 3B2B: CD 96 24
    pop bc                                  ; 3B2E: C1
    dec bc                                  ; 3B2F: 0B
    ld a, c                                 ; 3B30: 79
    or b                                    ; 3B31: B0
    jr nz, loc_3B27                         ; 3B32: 20 F3
    ld a, (TimeLeft)                        ; 3B34: 3A 0D C0
    or a                                    ; 3B37: B7
    jr nz, loc_3B49                         ; 3B38: 20 0F
loc_3B3A:
    call WaitForVBlankAndClearPauseFlag     ; 3B3A: CD 08 00
    call UpdateObjects                      ; 3B3D: CD 96 24
    ld hl, (SpeedMiddle)                    ; 3B40: 2A 1A C3
    ld a, l                                 ; 3B43: 7D
    or h                                    ; 3B44: B4
    jr nz, loc_3B3A                         ; 3B45: 20 F3
    jr loc_3B73                             ; 3B47: 18 2A
loc_3B49:
    ld b, $1e                               ; 3B49: 06 1E
loc_3B4B:
    call WaitForVBlankAndClearPauseFlag     ; 3B4B: CD 08 00
    push bc                                 ; 3B4E: C5
    call UpdateObjects                      ; 3B4F: CD 96 24
    pop bc                                  ; 3B52: C1
    djnz loc_3B4B                           ; 3B53: 10 F6
    ld hl, TimeLeft                         ; 3B55: 21 0D C0
loc_3B58:
    push hl                                 ; 3B58: E5
    ld b, $08                               ; 3B59: 06 08
loc_3B5B:
    call WaitForVBlankAndClearPauseFlag     ; 3B5B: CD 08 00
    push bc                                 ; 3B5E: C5
    call UpdateObjects                      ; 3B5F: CD 96 24
    pop bc                                  ; 3B62: C1
    djnz loc_3B5B                           ; 3B63: 10 F6
    ld a, $05                               ; 3B65: 3E 05
    call UpdateScore                        ; 3B67: CD 53 35
    ld a, $87                               ; 3B6A: 3E 87
    ld (SoundTrigger), a                    ; 3B6C: 32 00 C1
    pop hl                                  ; 3B6F: E1
    dec (hl)                                ; 3B70: 35
    jr nz, loc_3B58                         ; 3B71: 20 E5
loc_3B73:
    ld b, $78                               ; 3B73: 06 78
loc_3B75:
    call WaitForVBlankAndClearPauseFlag     ; 3B75: CD 08 00
    push bc                                 ; 3B78: C5
    call UpdateObjects                      ; 3B79: CD 96 24
    pop bc                                  ; 3B7C: C1
    djnz loc_3B75                           ; 3B7D: 10 F6
    ld a, $03                               ; 3B7F: 3E 03
    ld (TextTrigger), a                     ; 3B81: 32 64 C0
loc_3B84:
    call WaitForVBlankAndClearPauseFlag     ; 3B84: CD 08 00
    call UpdateObjects                      ; 3B87: CD 96 24
    ld hl, (SpeedMiddle)                    ; 3B8A: 2A 1A C3
    ld a, l                                 ; 3B8D: 7D
    or h                                    ; 3B8E: B4
    jr nz, loc_3B84                         ; 3B8F: 20 F3
    ld b, $b4                               ; 3B91: 06 B4
loc_3B93:
    call WaitForVBlankAndClearPauseFlag     ; 3B93: CD 08 00
    push bc                                 ; 3B96: C5
    call UpdateObjects                      ; 3B97: CD 96 24
    pop bc                                  ; 3B9A: C1
    djnz loc_3B93                           ; 3B9B: 10 F6
    ld a, $04                               ; 3B9D: 3E 04
    ld (TextTrigger), a                     ; 3B9F: 32 64 C0
    ld hl, Course                           ; 3BA2: 21 10 C0
    ld a, (hl)                              ; 3BA5: 7E
    inc a                                   ; 3BA6: 3C
    cp $08                                  ; 3BA7: FE 08
    jr c, loc_3BC5                          ; 3BA9: 38 1A
    ld a, (Level)                           ; 3BAB: 3A C0 C4
    inc a                                   ; 3BAE: 3C
    cp $03                                  ; 3BAF: FE 03
    jr c, loc_3BC1                          ; 3BB1: 38 0E
    ld a, (TimePerStage)                    ; 3BB3: 3A 74 C0
    sub $02                                 ; 3BB6: D6 02
    cp $32                                  ; 3BB8: FE 32
    jr c, loc_3BC4                          ; 3BBA: 38 08
    ld (TimePerStage), a                    ; 3BBC: 32 74 C0
    jr loc_3BC4                             ; 3BBF: 18 03
loc_3BC1:
    ld (Level), a                           ; 3BC1: 32 C0 C4
loc_3BC4:
    xor a                                   ; 3BC4: AF
loc_3BC5:
    ld (hl), a                              ; 3BC5: 77
    ld a, $3c                               ; 3BC6: 3E 3C
    ld (TimeLeft), a                        ; 3BC8: 32 0D C0
    call WaitForVBlankAndClearPauseFlag     ; 3BCB: CD 08 00
    ld a, $80                               ; 3BCE: 3E 80
    ld (GameState), a                       ; 3BD0: 32 00 C0
    ld a, $64                               ; 3BD3: 3E 64
    ld ($c067), a                           ; 3BD5: 32 67 C0
    ld a, $03                               ; 3BD8: 3E 03
    ld (LoadGoSign), a                      ; 3BDA: 32 6A C0
    jp loc_012F                             ; 3BDD: C3 2F 01
loc_3BE0:
    ld c, a                                 ; 3BE0: 4F
    ld a, (CurrentCourseSegment)            ; 3BE1: 3A F0 C2
    and $1f                                 ; 3BE4: E6 1F
    ld e, a                                 ; 3BE6: 5F
    ld d, $00                               ; 3BE7: 16 00
    ld hl, $3c1d                            ; 3BE9: 21 1D 3C
    add hl, de                              ; 3BEC: 19
    ld a, (hl)                              ; 3BED: 7E
    or a                                    ; 3BEE: B7
    ret p                                   ; 3BEF: F0
    cp $ff                                  ; 3BF0: FE FF
    ret z                                   ; 3BF2: C8
    ld d, a                                 ; 3BF3: 57
    and $0f                                 ; 3BF4: E6 0F
    ld b, a                                 ; 3BF6: 47
    bit 6, d                                ; 3BF7: CB 72
    jr nz, loc_3C0B                         ; 3BF9: 20 10
    bit 5, d                                ; 3BFB: CB 6A
    jr nz, loc_3C14                         ; 3BFD: 20 15
    ld a, ($c2f4)                           ; 3BFF: 3A F4 C2
    cp c                                    ; 3C02: B9
    jr c, loc_3C07                          ; 3C03: 38 02
loc_3C05:
    ld a, b                                 ; 3C05: 78
    ret                                     ; 3C06: C9
loc_3C07:
    ld a, $02                               ; 3C07: 3E 02
    sub b                                   ; 3C09: 90
    ret                                     ; 3C0A: C9
loc_3C0B:
    ld a, ($c2f4)                           ; 3C0B: 3A F4 C2
    cp c                                    ; 3C0E: B9
    jr nc, loc_3C05                         ; 3C0F: 30 F4
    ld a, $01                               ; 3C11: 3E 01
    ret                                     ; 3C13: C9
loc_3C14:
    ld a, ($c2f4)                           ; 3C14: 3A F4 C2
    cp c                                    ; 3C17: B9
    jr c, loc_3C05                          ; 3C18: 38 EB
    ld a, $01                               ; 3C1A: 3E 01
    ret                                     ; 3C1C: C9

; ----------------------------------------------------------------------------
; ROM data $3C1D-$3C3C (32 bytes)
; ----------------------------------------------------------------------------
CourseCollisionTable:
    .incbin "../assets/course_collision_table.bin"

; ============================================================================
; Code $3C3D
; ============================================================================
ObjectHandlerTypes03To10:
    bit 7, (ix+1)                           ; 3C3D: DD CB 01 7E
    jr nz, loc_3C6D                         ; 3C41: 20 2A
    xor a                                   ; 3C43: AF
    ld (ix+3), a                            ; 3C44: DD 77 03
    ld (ix+4), a                            ; 3C47: DD 77 04
    ld (ix+16), a                           ; 3C4A: DD 77 10
    ld de, $3d96                            ; 3C4D: 11 96 3D
    ld a, (ix+0)                            ; 3C50: DD 7E 00
    cp $05                                  ; 3C53: FE 05
    jr nc, loc_3C65                         ; 3C55: 30 0E
    ld a, (StageNumber)                     ; 3C57: 3A 07 C0
    add a, a                                ; 3C5A: 87
    bit 0, (ix+0)                           ; 3C5B: DD CB 00 46
    jr z, loc_3C62                          ; 3C5F: 28 01
    inc a                                   ; 3C61: 3C
loc_3C62:
    ld de, $3da1                            ; 3C62: 11 A1 3D
loc_3C65:
    ld l, a                                 ; 3C65: 6F
    ld h, $00                               ; 3C66: 26 00
    add hl, de                              ; 3C68: 19
    ld a, (hl)                              ; 3C69: 7E
    ld (ix+17), a                           ; 3C6A: DD 77 11
loc_3C6D:
    ld a, (ix+0)                            ; 3C6D: DD 7E 00
    cp $05                                  ; 3C70: FE 05
    jr nz, loc_3C79                         ; 3C72: 20 05
    ld a, $3c                               ; 3C74: 3E 3C
    ld ($c067), a                           ; 3C76: 32 67 C0
loc_3C79:
    ld (ix+1), $80                          ; 3C79: DD 36 01 80
    ld a, (SpeedHigh)                       ; 3C7D: 3A 1B C3
    rrca                                    ; 3C80: 0F
    ld a, (SpeedMiddle)                     ; 3C81: 3A 1A C3
    rra                                     ; 3C84: 1F
    or a                                    ; 3C85: B7
    rra                                     ; 3C86: 1F
    ld c, (ix+3)                            ; 3C87: DD 4E 03
    ld b, $00                               ; 3C8A: 06 00
    ld hl, $2d5b                            ; 3C8C: 21 5B 2D
    add hl, bc                              ; 3C8F: 09
    ld h, (hl)                              ; 3C90: 66
    ld e, a                                 ; 3C91: 5F
    call MultiplyHLByB                      ; 3C92: CD F1 05
    ld a, h                                 ; 3C95: 7C
    or a                                    ; 3C96: B7
    rra                                     ; 3C97: 1F
    ld b, a                                 ; 3C98: 47
    ld a, l                                 ; 3C99: 7D
    rra                                     ; 3C9A: 1F
    add a, (ix+4)                           ; 3C9B: DD 86 04
    ld (ix+4), a                            ; 3C9E: DD 77 04
    ld a, b                                 ; 3CA1: 78
    adc a, (ix+3)                           ; 3CA2: DD 8E 03
    ld (ix+3), a                            ; 3CA5: DD 77 03
    ld c, a                                 ; 3CA8: 4F
    ld a, (ix+0)                            ; 3CA9: DD 7E 00
    cp $05                                  ; 3CAC: FE 05
    jr nz, loc_3D0C                         ; 3CAE: 20 5C
    ld a, c                                 ; 3CB0: 79
    cp $58                                  ; 3CB1: FE 58
    jr c, loc_3D19                          ; 3CB3: 38 64
    ld a, (ix+16)                           ; 3CB5: DD 7E 10
    or a                                    ; 3CB8: B7
    ld a, c                                 ; 3CB9: 79
    jr nz, loc_3D0C                         ; 3CBA: 20 50
    ld (ix+16), a                           ; 3CBC: DD 77 10
    ld a, (StageNumber)                     ; 3CBF: 3A 07 C0
    inc a                                   ; 3CC2: 3C
    cp $05                                  ; 3CC3: FE 05
    jr c, loc_3CD2                          ; 3CC5: 38 0B
    ld hl, GameState                        ; 3CC7: 21 00 C0
    set 5, (hl)                             ; 3CCA: CB EE
    xor a                                   ; 3CCC: AF
    ld (CourseDataIndex), a                 ; 3CCD: 32 11 C0
    jr loc_3D01                             ; 3CD0: 18 2F
loc_3CD2:
    ld b, a                                 ; 3CD2: 47
    ld a, (TimeLeft)                        ; 3CD3: 3A 0D C0
    ld hl, TimePerStage                     ; 3CD6: 21 74 C0
    add a, (hl)                             ; 3CD9: 86
    cp $64                                  ; 3CDA: FE 64
    jr c, loc_3CE0                          ; 3CDC: 38 02
    ld a, $63                               ; 3CDE: 3E 63
loc_3CE0:
    ld (TimeLeft), a                        ; 3CE0: 32 0D C0
    ld a, $01                               ; 3CE3: 3E 01
    ld (TimeLeftFrameCounter), a            ; 3CE5: 32 0C C0
    ld hl, $0004                            ; 3CE8: 21 04 00
    ld (LeftDistanceBCD), hl                ; 3CEB: 22 60 C0
    ld a, (CourseDataIndex)                 ; 3CEE: 3A 11 C0
    add a, $02                              ; 3CF1: C6 02
    ld (CourseDataIndex), a                 ; 3CF3: 32 11 C0
    ld a, $14                               ; 3CF6: 3E 14
    ld (MessageFlashFrameTimer), a          ; 3CF8: 32 78 C0
    ld a, $03                               ; 3CFB: 3E 03
    ld (MessageFlashCounter), a             ; 3CFD: 32 79 C0
    ld a, b                                 ; 3D00: 78
loc_3D01:
    ld (StageNumber), a                     ; 3D01: 32 07 C0
    ld (BackgroundIndex), a                 ; 3D04: 32 4B C0
    xor a                                   ; 3D07: AF
    ld ($c2f2), a                           ; 3D08: 32 F2 C2
    ld a, c                                 ; 3D0B: 79
loc_3D0C:
    ld a, c                                 ; 3D0C: 79
    cp $87                                  ; 3D0D: FE 87
    jr c, loc_3D19                          ; 3D0F: 38 08
    ld hl, RoadsideSceneryLoadIndex         ; 3D11: 21 68 C0
    ld (hl), $0b                            ; 3D14: 36 0B
    jp loc_24E5                             ; 3D16: C3 E5 24
loc_3D19:
    add a, $5f                              ; 3D19: C6 5F
    ld (ix+2), a                            ; 3D1B: DD 77 02
    ld hl, $2e6b                            ; 3D1E: 21 6B 2E
    ld b, $00                               ; 3D21: 06 00
    add hl, bc                              ; 3D23: 09
    ld a, (hl)                              ; 3D24: 7E
    bit 0, (ix+0)                           ; 3D25: DD CB 00 46
    jr nz, loc_3D2E                         ; 3D29: 20 03
    neg                                     ; 3D2B: ED 44
    dec b                                   ; 3D2D: 05
loc_3D2E:
    add a, $84                              ; 3D2E: C6 84
    ld (ix+5), a                            ; 3D30: DD 77 05
    ld a, $00                               ; 3D33: 3E 00
    adc a, b                                ; 3D35: 88
    ld (ix+8), a                            ; 3D36: DD 77 08
    ld a, c                                 ; 3D39: 79
    cp $60                                  ; 3D3A: FE 60
    jr c, loc_3D4F                          ; 3D3C: 38 11
    ld b, $00                               ; 3D3E: 06 00
    ld hl, $c55f                            ; 3D40: 21 5F C5
    add hl, bc                              ; 3D43: 09
    ld a, ($c5bf)                           ; 3D44: 3A BF C5
    or a                                    ; 3D47: B7
    jp p, loc_3D4C                          ; 3D48: F2 4C 3D
    dec b                                   ; 3D4B: 05
loc_3D4C:
    ld a, (hl)                              ; 3D4C: 7E
    jr loc_3D5B                             ; 3D4D: 18 0C
loc_3D4F:
    ld b, $00                               ; 3D4F: 06 00
    ld hl, $c55f                            ; 3D51: 21 5F C5
    add hl, bc                              ; 3D54: 09
    ld a, (hl)                              ; 3D55: 7E
    or a                                    ; 3D56: B7
    jp p, loc_3D5B                          ; 3D57: F2 5B 3D
    dec b                                   ; 3D5A: 05
loc_3D5B:
    add a, (ix+5)                           ; 3D5B: DD 86 05
    ld (ix+6), a                            ; 3D5E: DD 77 06
    ld a, b                                 ; 3D61: 78
    adc a, (ix+8)                           ; 3D62: DD 8E 08
    ld (ix+7), a                            ; 3D65: DD 77 07
    ld b, $00                               ; 3D68: 06 00
    ld hl, $2de3                            ; 3D6A: 21 E3 2D
    add hl, bc                              ; 3D6D: 09
    ld a, (hl)                              ; 3D6E: 7E
    add a, (ix+17)                          ; 3D6F: DD 86 11
    ld (ix+10), a                           ; 3D72: DD 77 0A
    ld a, (ix+7)                            ; 3D75: DD 7E 07
    or a                                    ; 3D78: B7
    ret nz                                  ; 3D79: C0
    ld a, (ix+3)                            ; 3D7A: DD 7E 03
    cp $4c                                  ; 3D7D: FE 4C
    ret c                                   ; 3D7F: D8
    cp $64                                  ; 3D80: FE 64
    ret nc                                  ; 3D82: D0
    ld hl, $c310                            ; 3D83: 21 10 C3
    ld a, (ix+6)                            ; 3D86: DD 7E 06
    bit 0, (ix+0)                           ; 3D89: DD CB 00 46
    jr nz, loc_3D94                         ; 3D8D: 20 05
    cp (hl)                                 ; 3D8F: BE
    ret c                                   ; 3D90: D8
    inc hl                                  ; 3D91: 23
    jr loc_3D97                             ; 3D92: 18 03
loc_3D94:
    inc hl                                  ; 3D94: 23
    cp (hl)                                 ; 3D95: BE
    ret nc                                  ; 3D96: D0
loc_3D97:
    inc hl                                  ; 3D97: 23
    ld (hl), $01                            ; 3D98: 36 01
    ret                                     ; 3D9A: C9

; ----------------------------------------------------------------------------
; ROM data $3D9B-$3DAA (16 bytes)
; ----------------------------------------------------------------------------
RomData_3D9B:
    .db $49, $4f, $49, $4f, $55, $5b, $1f, $19, $2b, $25, $37, $31, $43, $3d, $1f, $19 ; 3D9B: 49 4F 49 4F 55 5B 1F 19 2B 25 37 31 43 3D 1F 19

; ============================================================================
; Code $3DAB
; ============================================================================
DemoControls:
    ld c, $ff                               ; 3DAB: 0E FF
    ld b, $00                               ; 3DAD: 06 00
    ld a, ($c075)                           ; 3DAF: 3A 75 C0
    or a                                    ; 3DB2: B7
    ld a, ($c013)                           ; 3DB3: 3A 13 C0
    jr nz, loc_3E20                         ; 3DB6: 20 68
    cp $35                                  ; 3DB8: FE 35
    jr nc, loc_3DBD                         ; 3DBA: 30 01
    dec b                                   ; 3DBC: 05
loc_3DBD:
    cp $73                                  ; 3DBD: FE 73
    jr c, loc_3DC2                          ; 3DBF: 38 01
    dec b                                   ; 3DC1: 05
loc_3DC2:
    ld a, b                                 ; 3DC2: 78
    ld ($c075), a                           ; 3DC3: 32 75 C0
    ld hl, (SpeedMiddle)                    ; 3DC6: 2A 1A C3
    ld de, $ff24                            ; 3DC9: 11 24 FF
    add hl, de                              ; 3DCC: 19
    jr nc, loc_3E34                         ; 3DCD: 30 65
    push bc                                 ; 3DCF: C5
    ld ix, $c320                            ; 3DD0: DD 21 20 C3
    ld de, $0020                            ; 3DD4: 11 20 00
    ld b, $03                               ; 3DD7: 06 03
    ld hl, $0000                            ; 3DD9: 21 00 00
    ld c, l                                 ; 3DDC: 4D
loc_3DDD:
    ld a, (ix+0)                            ; 3DDD: DD 7E 00
    or a                                    ; 3DE0: B7
    jr z, loc_3DEF                          ; 3DE1: 28 0C
    ld a, (ix+3)                            ; 3DE3: DD 7E 03
    cp c                                    ; 3DE6: B9
    jr c, loc_3DEF                          ; 3DE7: 38 06
    ld c, a                                 ; 3DE9: 4F
    ld h, (ix+8)                            ; 3DEA: DD 66 08
    ld l, $ff                               ; 3DED: 2E FF
loc_3DEF:
    add ix, de                              ; 3DEF: DD 19
    djnz loc_3DDD                           ; 3DF1: 10 EA
    ld a, c                                 ; 3DF3: 79
    pop bc                                  ; 3DF4: C1
    cp $30                                  ; 3DF5: FE 30
    jr c, loc_3E34                          ; 3DF7: 38 3B
    ld a, l                                 ; 3DF9: 7D
    or a                                    ; 3DFA: B7
    jr z, loc_3E34                          ; 3DFB: 28 37
    ld a, h                                 ; 3DFD: 7C
    or a                                    ; 3DFE: B7
    jp p, loc_3E11                          ; 3DFF: F2 11 3E
    cp $a0                                  ; 3E02: FE A0
    jr c, loc_3E34                          ; 3E04: 38 2E
    ld a, ($c013)                           ; 3E06: 3A 13 C0
    cp $44                                  ; 3E09: FE 44
    jr c, loc_3E34                          ; 3E0B: 38 27
    res 3, c                                ; 3E0D: CB 99
    jr loc_3E34                             ; 3E0F: 18 23
loc_3E11:
    cp $60                                  ; 3E11: FE 60
    jr nc, loc_3E34                         ; 3E13: 30 1F
    ld a, ($c013)                           ; 3E15: 3A 13 C0
    cp $64                                  ; 3E18: FE 64
    jr nc, loc_3E34                         ; 3E1A: 30 18
    res 2, c                                ; 3E1C: CB 91
    jr loc_3E34                             ; 3E1E: 18 14
loc_3E20:
    cp $50                                  ; 3E20: FE 50
    jr nc, loc_3E28                         ; 3E22: 30 04
    res 2, c                                ; 3E24: CB 91
    jr loc_3E34                             ; 3E26: 18 0C
loc_3E28:
    cp $58                                  ; 3E28: FE 58
    jr c, loc_3E30                          ; 3E2A: 38 04
    res 3, c                                ; 3E2C: CB 99
    jr loc_3E34                             ; 3E2E: 18 04
loc_3E30:
    xor a                                   ; 3E30: AF
    ld ($c075), a                           ; 3E31: 32 75 C0
loc_3E34:
    xor a                                   ; 3E34: AF
    ld de, (SpeedMiddle)                    ; 3E35: ED 5B 1A C3
    ld hl, $ffa6                            ; 3E39: 21 A6 FF
    add hl, de                              ; 3E3C: 19
    jr nc, loc_3E40                         ; 3E3D: 30 01
    inc a                                   ; 3E3F: 3C
loc_3E40:
    ld hl, $ff4c                            ; 3E40: 21 4C FF
    add hl, de                              ; 3E43: 19
    jr nc, loc_3E47                         ; 3E44: 30 01
    inc a                                   ; 3E46: 3C
loc_3E47:
    ld (Gear), a                            ; 3E47: 32 18 C3
    ld hl, ($c2f5)                          ; 3E4A: 2A F5 C2
    bit 7, h                                ; 3E4D: CB 7C
    jr z, loc_3E58                          ; 3E4F: 28 07
    ld a, l                                 ; 3E51: 7D
    cpl                                     ; 3E52: 2F
    ld l, a                                 ; 3E53: 6F
    ld a, h                                 ; 3E54: 7C
    cpl                                     ; 3E55: 2F
    ld h, a                                 ; 3E56: 67
    inc hl                                  ; 3E57: 23
loc_3E58:
    ld a, l                                 ; 3E58: 7D
    or h                                    ; 3E59: B4
    jr z, loc_3E75                          ; 3E5A: 28 19
    ld de, $fe80                            ; 3E5C: 11 80 FE
    add hl, de                              ; 3E5F: 19
    jr nc, loc_3E67                         ; 3E60: 30 05
    ld hl, $ff01                            ; 3E62: 21 01 FF
    jr loc_3E6A                             ; 3E65: 18 03
loc_3E67:
    ld hl, $feed                            ; 3E67: 21 ED FE
loc_3E6A:
    ld de, (SpeedMiddle)                    ; 3E6A: ED 5B 1A C3
    add hl, de                              ; 3E6E: 19
    jr nc, loc_3E75                         ; 3E6F: 30 04
    res 4, c                                ; 3E71: CB A1
    jr loc_3E77                             ; 3E73: 18 02
loc_3E75:
    res 5, c                                ; 3E75: CB A9
loc_3E77:
    ld a, c                                 ; 3E77: 79
    ret                                     ; 3E78: C9

; ----------------------------------------------------------------------------
; ROM data $3E79-$7116 (12958 bytes) - multi-resource container.
; Split into named sub-assets (see docs/ASSET_RENAME_PLAN.md).
; ----------------------------------------------------------------------------
ContainerPadding:
    .incbin "../assets/container_padding.bin"
SpriteTilesCompressed:
    .incbin "../assets/sprite_tiles_compressed.bin"
TilePatternsCompressed:
    .incbin "../assets/tile_patterns_compressed.bin"
BackgroundTilesCompressed:
    .incbin "../assets/background_tiles_compressed.bin"
TitleGraphicsCompressed:
    .incbin "../assets/title_graphics_compressed.bin"
CourseData:
    .incbin "../assets/course_data.bin"
BackgroundScrollTilemap:
    .incbin "../assets/background_scroll_tilemap.bin"
RoadTilemapSecond:
    .incbin "../assets/road_tilemap_second.bin"

; ============================================================================
; Code $7117
; ============================================================================
SoundEntryStub:
    jp InitializeLowVoices                  ; 7117: C3 FC 71
; Main PSG sound update.
SoundUpdate:
    ld a, (SoundTrigger)                    ; 711A: 3A 00 C1
    cp $81                                  ; 711D: FE 81
    jr z, SoundCommand81                    ; 711F: 28 0F
    call CheckForNewSoundTrigger            ; 7121: CD 8B 74
    call UpdateEngineSounds                 ; 7124: CD 04 73
    ld ix, $c150                            ; 7127: DD 21 50 C1
    ld b, $0c                               ; 712B: 06 0C
    jp UpdateSoundLoop                      ; 712D: C3 34 75
SoundCommand81:
    call loc_714C                           ; 7130: CD 4C 71
    call UpdateEngineSounds                 ; 7133: CD 04 73
    ld ix, (SFXVoicePointer1)               ; 7136: DD 2A 08 C1
    call UpdateSFXVoice                     ; 713A: CD 07 72
    ld ix, (SFXVoicePointer2)               ; 713D: DD 2A 0A C1
    call UpdateSFXVoice                     ; 7141: CD 07 72
    ld ix, $c150                            ; 7144: DD 21 50 C1
    call UpdateSharedSFXMusicVoice          ; 7148: CD 9C 72
    ret                                     ; 714B: C9
loc_714C:
    ld hl, (SoundFunctionPointer)           ; 714C: 2A 01 C1
    ld a, l                                 ; 714F: 7D
    or h                                    ; 7150: B4
    ret z                                   ; 7151: C8
    jp (hl)                                 ; 7152: E9
SoundFunctionOvertakeHigh:
    ld bc, $0003                            ; 7153: 01 03 00
    call CheckSoundFlagsMask                ; 7156: CD C0 71
    ld hl, $77f3                            ; 7159: 21 F3 77
    ld ($c173), hl                          ; 715C: 22 73 C1
    ld hl, $783b                            ; 715F: 21 3B 78
    ld ($c193), hl                          ; 7162: 22 93 C1
    ld hl, $c170                            ; 7165: 21 70 C1
    ld de, $c190                            ; 7168: 11 90 C1
    jr SetSFXVoicePointers                  ; 716B: 18 61
SoundFunctionOvertakeLow:
    ld hl, $781a                            ; 716D: 21 1A 78
    ld ($c173), hl                          ; 7170: 22 73 C1
    ld hl, $785f                            ; 7173: 21 5F 78
    ld ($c193), hl                          ; 7176: 22 93 C1
    jr loc_71D5                             ; 7179: 18 5A
SoundFunctionBump:
    ld bc, $0102                            ; 717B: 01 02 01
    call CheckSoundFlagsMask                ; 717E: CD C0 71
    ld hl, $7880                            ; 7181: 21 80 78
    ld ($c1b3), hl                          ; 7184: 22 B3 C1
    ld hl, $7895                            ; 7187: 21 95 78
    ld ($c1d3), hl                          ; 718A: 22 D3 C1
    ld hl, $c1b0                            ; 718D: 21 B0 C1
    ld de, $c1d0                            ; 7190: 11 D0 C1
    jr SetSFXVoicePointers                  ; 7193: 18 39
SoundFunctionSkid:
    ld bc, $0102                            ; 7195: 01 02 01
    call CheckSoundFlagsMask                ; 7198: CD C0 71
    ld hl, $78ad                            ; 719B: 21 AD 78
    ld ($c1f3), hl                          ; 719E: 22 F3 C1
    ld hl, $78c0                            ; 71A1: 21 C0 78
    ld ($c213), hl                          ; 71A4: 22 13 C2
    ld hl, $c1f0                            ; 71A7: 21 F0 C1
    ld de, $c210                            ; 71AA: 11 10 C2
    jr SetSFXVoicePointers                  ; 71AD: 18 1F
SoundFunctionGoSign:
    ld bc, $0200                            ; 71AF: 01 00 02
    call CheckSoundFlagsMask                ; 71B2: CD C0 71
    ld hl, $78d7                            ; 71B5: 21 D7 78
    ld ($c233), hl                          ; 71B8: 22 33 C2
    ld hl, $c230                            ; 71BB: 21 30 C2
    jr loc_71D2                             ; 71BE: 18 12
CheckSoundFlagsMask:
    ld a, (SoundFlagsMask)                  ; 71C0: 3A 07 C1
    and c                                   ; 71C3: A1
    jr z, loc_71C9                          ; 71C4: 28 03
    pop af                                  ; 71C6: F1
    jr loc_71D5                             ; 71C7: 18 0C
loc_71C9:
    or b                                    ; 71C9: B0
    ld (SoundFlagsMask), a                  ; 71CA: 32 07 C1
    ret                                     ; 71CD: C9
SetSFXVoicePointers:
    ld (SFXVoicePointer2), de               ; 71CE: ED 53 0A C1
loc_71D2:
    ld (SFXVoicePointer1), hl               ; 71D2: 22 08 C1
loc_71D5:
    ld hl, $0000                            ; 71D5: 21 00 00
    ld (SoundFunctionPointer), hl           ; 71D8: 22 01 C1
    ret                                     ; 71DB: C9
SoundFunctionEngine:
    call ResetMusicVoices11To14             ; 71DC: CD E7 76
    ld a, $e7                               ; 71DF: 3E E7
    out (PSGPort), a                        ; 71E1: D3 7F
    ld a, $88                               ; 71E3: 3E 88
    ld ($c150), a                           ; 71E5: 32 50 C1
    ld hl, $0080                            ; 71E8: 21 80 00
    ld ($c15f), hl                          ; 71EB: 22 5F C1
    ld hl, $033d                            ; 71EE: 21 3D 03
    ld ($c11f), hl                          ; 71F1: 22 1F C1
    ld de, $c130                            ; 71F4: 11 30 C1
    ld hl, SoundVoices                      ; 71F7: 21 10 C1
    jr SetSFXVoicePointers                  ; 71FA: 18 D2
InitializeLowVoices:
    ld hl, $7796                            ; 71FC: 21 96 77
    ld de, SoundVoices                      ; 71FF: 11 10 C1
    ld b, $0a                               ; 7202: 06 0A
    jp loc_7516                             ; 7204: C3 16 75
UpdateSFXVoice:
    ld a, (ix+11)                           ; 7207: DD 7E 0B
    inc a                                   ; 720A: 3C
    ld (ix+11), a                           ; 720B: DD 77 0B
    sub (ix+10)                             ; 720E: DD 96 0A
    jp nz, UpdateSharedSFXMusicVoice        ; 7211: C2 9C 72
    ld e, (ix+3)                            ; 7214: DD 5E 03
    ld d, (ix+4)                            ; 7217: DD 56 04
loc_721A:
    ld a, (de)                              ; 721A: 1A
    inc de                                  ; 721B: 13
    cp $e0                                  ; 721C: FE E0
    jp nc, JumpToSoundRoutine               ; 721E: D2 46 72
    ld (ix+16), a                           ; 7221: DD 77 10
    ld a, (de)                              ; 7224: 1A
    inc de                                  ; 7225: 13
    ld (ix+15), a                           ; 7226: DD 77 0F
    bit 5, (ix+0)                           ; 7229: DD CB 00 6E
    jr z, loc_7234                          ; 722D: 28 05
    ld a, (de)                              ; 722F: 1A
    inc de                                  ; 7230: 13
    ld (ix+17), a                           ; 7231: DD 77 11
loc_7234:
    ld a, (de)                              ; 7234: 1A
    inc de                                  ; 7235: 13
    ld (ix+10), a                           ; 7236: DD 77 0A
    ld (ix+3), e                            ; 7239: DD 73 03
    ld (ix+4), d                            ; 723C: DD 72 04
    xor a                                   ; 723F: AF
    ld (ix+11), a                           ; 7240: DD 77 0B
    jp UpdateSharedSFXMusicVoice            ; 7243: C3 9C 72
JumpToSoundRoutine:
    cp $e0                                  ; 7246: FE E0
    jr z, loc_725D                          ; 7248: 28 13
    cp $e1                                  ; 724A: FE E1
    jr z, loc_727A                          ; 724C: 28 2C
    cp $e8                                  ; 724E: FE E8
    jr z, loc_7265                          ; 7250: 28 13
    cp $e9                                  ; 7252: FE E9
    jr z, loc_726C                          ; 7254: 28 16
    cp $e5                                  ; 7256: FE E5
    jr z, loc_7273                          ; 7258: 28 19
    jp UpdateSharedSFXMusicVoice            ; 725A: C3 9C 72
loc_725D:
    ld a, (de)                              ; 725D: 1A
    ld (ix+8), a                            ; 725E: DD 77 08
    inc de                                  ; 7261: 13
    jp loc_721A                             ; 7262: C3 1A 72
loc_7265:
    set 5, (ix+0)                           ; 7265: DD CB 00 EE
    jp loc_721A                             ; 7269: C3 1A 72
loc_726C:
    res 5, (ix+0)                           ; 726C: DD CB 00 AE
    jp loc_721A                             ; 7270: C3 1A 72
loc_7273:
    ex de, hl                               ; 7273: EB
    ld e, (hl)                              ; 7274: 5E
    inc hl                                  ; 7275: 23
    ld d, (hl)                              ; 7276: 56
    jp loc_721A                             ; 7277: C3 1A 72
loc_727A:
    call MuteSoundVoice                     ; 727A: CD DD 76
    ld a, (de)                              ; 727D: 1A
    ld hl, $76d9                            ; 727E: 21 D9 76
    ld c, a                                 ; 7281: 4F
    ld b, $00                               ; 7282: 06 00
    add hl, bc                              ; 7284: 09
    ld a, (SoundFlagsMask)                  ; 7285: 3A 07 C1
    and (hl)                                ; 7288: A6
    ld (SoundFlagsMask), a                  ; 7289: 32 07 C1
    xor a                                   ; 728C: AF
    ld (ix+11), a                           ; 728D: DD 77 0B
    ld hl, SoundVoices                      ; 7290: 21 10 C1
    ld (SFXVoicePointer1), hl               ; 7293: 22 08 C1
    ld hl, $c130                            ; 7296: 21 30 C1
    ld (SFXVoicePointer2), hl               ; 7299: 22 0A C1
UpdateSharedSFXMusicVoice:
    ld e, (ix+15)                           ; 729C: DD 5E 0F
    ld d, (ix+16)                           ; 729F: DD 56 10
    ld a, e                                 ; 72A2: 7B
    or d                                    ; 72A3: B2
    jr nz, loc_72AB                         ; 72A4: 20 05
    ld l, $0f                               ; 72A6: 2E 0F
    jp loc_72FB                             ; 72A8: C3 FB 72
loc_72AB:
    bit 5, (ix+0)                           ; 72AB: DD CB 00 6E
    jr z, loc_72C9                          ; 72AF: 28 18
    ld a, e                                 ; 72B1: 7B
    ld c, (ix+17)                           ; 72B2: DD 4E 11
    sub c                                   ; 72B5: 91
    bit 7, c                                ; 72B6: CB 79
    jr z, loc_72BF                          ; 72B8: 28 05
    jr c, loc_72C2                          ; 72BA: 38 06
    inc d                                   ; 72BC: 14
    jr loc_72C2                             ; 72BD: 18 03
loc_72BF:
    jr nc, loc_72C2                         ; 72BF: 30 01
    dec d                                   ; 72C1: 15
loc_72C2:
    ld e, a                                 ; 72C2: 5F
    ld (ix+15), e                           ; 72C3: DD 73 0F
    ld (ix+16), d                           ; 72C6: DD 72 10
loc_72C9:
    ld a, (ix+7)                            ; 72C9: DD 7E 07
    or a                                    ; 72CC: B7
    jr z, loc_72DA                          ; 72CD: 28 0B
    ld hl, $78e8                            ; 72CF: 21 E8 78
    call ReadFromWordTable                  ; 72D2: CD 5E 75
    call ApplyEnvelope                      ; 72D5: CD 6C 75
    jr loc_72E1                             ; 72D8: 18 07
loc_72DA:
    ld a, (ix+8)                            ; 72DA: DD 7E 08
    cpl                                     ; 72DD: 2F
    and $0f                                 ; 72DE: E6 0F
    ld l, a                                 ; 72E0: 6F
loc_72E1:
    ld a, (ix+1)                            ; 72E1: DD 7E 01
    cp $e0                                  ; 72E4: FE E0
    jr nz, loc_72EA                         ; 72E6: 20 02
    ld a, $c0                               ; 72E8: 3E C0
loc_72EA:
    ld c, a                                 ; 72EA: 4F
    ld a, e                                 ; 72EB: 7B
    and $0f                                 ; 72EC: E6 0F
    or c                                    ; 72EE: B1
    out (PSGPort), a                        ; 72EF: D3 7F
    ld a, e                                 ; 72F1: 7B
    and $f0                                 ; 72F2: E6 F0
    or d                                    ; 72F4: B2
    rrca                                    ; 72F5: 0F
    rrca                                    ; 72F6: 0F
    rrca                                    ; 72F7: 0F
    rrca                                    ; 72F8: 0F
    out (PSGPort), a                        ; 72F9: D3 7F
loc_72FB:
    ld a, (ix+1)                            ; 72FB: DD 7E 01
    add a, $10                              ; 72FE: C6 10
    or l                                    ; 7300: B5
    out (PSGPort), a                        ; 7301: D3 7F
    ret                                     ; 7303: C9
UpdateEngineSounds:
    ld a, (EngineSoundCounter)              ; 7304: 3A 04 C1
    inc a                                   ; 7307: 3C
    ld (EngineSoundCounter), a              ; 7308: 32 04 C1
    ld a, ($c290)                           ; 730B: 3A 90 C2
    or a                                    ; 730E: B7
    ret nz                                  ; 730F: C0
    ld a, (BikeRPM)                         ; 7310: 3A 1D C3
    ld c, a                                 ; 7313: 4F
    ld b, $00                               ; 7314: 06 00
    ld hl, $7407                            ; 7316: 21 07 74
    call loc_737C                           ; 7319: CD 7C 73
    ld a, (EngineToneFlag)                  ; 731C: 3A 1F C3
    or a                                    ; 731F: B7
    jr nz, loc_7341                         ; 7320: 20 1F
    ld de, ($c15f)                          ; 7322: ED 5B 5F C1
    sbc hl, de                              ; 7326: ED 52
    jr c, loc_732F                          ; 7328: 38 05
    jr z, loc_7330                          ; 732A: 28 04
    inc de                                  ; 732C: 13
    jr loc_7330                             ; 732D: 18 01
loc_732F:
    dec de                                  ; 732F: 1B
loc_7330:
    ex de, hl                               ; 7330: EB
    ld a, (EngineSoundCounter)              ; 7331: 3A 04 C1
    and $01                                 ; 7334: E6 01
    jr z, loc_733D                          ; 7336: 28 05
    ld de, $0020                            ; 7338: 11 20 00
    jr loc_7340                             ; 733B: 18 03
loc_733D:
    ld de, $ffe0                            ; 733D: 11 E0 FF
loc_7340:
    add hl, de                              ; 7340: 19
loc_7341:
    ld ($c15f), hl                          ; 7341: 22 5F C1
    ld a, ($c250)                           ; 7344: 3A 50 C2
    or a                                    ; 7347: B7
    ret nz                                  ; 7348: C0
    ld hl, $7383                            ; 7349: 21 83 73
    call loc_737C                           ; 734C: CD 7C 73
    ld a, (EngineToneFlag)                  ; 734F: 3A 1F C3
    or a                                    ; 7352: B7
    jr z, loc_735B                          ; 7353: 28 06
    xor a                                   ; 7355: AF
    ld (EngineToneFlag), a                  ; 7356: 32 1F C3
    jr loc_736C                             ; 7359: 18 11
loc_735B:
    ld de, ($c11f)                          ; 735B: ED 5B 1F C1
    sbc hl, de                              ; 735F: ED 52
    jr c, loc_7369                          ; 7361: 38 06
    jr z, loc_736B                          ; 7363: 28 06
    inc de                                  ; 7365: 13
    inc de                                  ; 7366: 13
    jr loc_736B                             ; 7367: 18 02
loc_7369:
    dec de                                  ; 7369: 1B
    dec de                                  ; 736A: 1B
loc_736B:
    ex de, hl                               ; 736B: EB
loc_736C:
    ld ($c11f), hl                          ; 736C: 22 1F C1
    ld a, l                                 ; 736F: 7D
    add a, $64                              ; 7370: C6 64
    ld ($c13f), a                           ; 7372: 32 3F C1
    ld a, $00                               ; 7375: 3E 00
    adc a, h                                ; 7377: 8C
    ld ($c140), a                           ; 7378: 32 40 C1
    ret                                     ; 737B: C9
loc_737C:
    add hl, bc                              ; 737C: 09
    add hl, bc                              ; 737D: 09
    ld a, (hl)                              ; 737E: 7E
    inc hl                                  ; 737F: 23
    ld h, (hl)                              ; 7380: 66
    ld l, a                                 ; 7381: 6F
    ret                                     ; 7382: C9

; ----------------------------------------------------------------------------
; ROM data $7383-$748A (264 bytes)
; ----------------------------------------------------------------------------
EngineToneTables:
    .incbin "../assets/engine_tone_tables.bin"

; ============================================================================
; Code $748B
; ============================================================================
; Dispatches a new sound trigger through the table at $74AC.
CheckForNewSoundTrigger:
    bit 7, a                                ; 748B: CB 7F
    jp z, ResetMusicVoices11To14            ; 748D: CA E7 76
    cp $94                                  ; 7490: FE 94
    jp nc, ResetMusicVoices11To14           ; 7492: D2 E7 76
    sub $80                                 ; 7495: D6 80
    ret z                                   ; 7497: C8
    ld c, a                                 ; 7498: 4F
    ld b, $00                               ; 7499: 06 00
    ld hl, MusicDataLookup                  ; 749B: 21 AC 74
    add hl, bc                              ; 749E: 09
    add hl, bc                              ; 749F: 09
    ld c, (hl)                              ; 74A0: 4E
    inc hl                                  ; 74A1: 23
    ld b, (hl)                              ; 74A2: 46
    ld de, MusicLoadFunctionLookup - MusicDataLookup - 1 ; 74A3: 11 1F 00
    add hl, de                              ; 74A6: 19
    ld a, (hl)                              ; 74A7: 7E
    inc hl                                  ; 74A8: 23
    ld h, (hl)                              ; 74A9: 66
    ld l, a                                 ; 74AA: 6F
    jp (hl)                                 ; 74AB: E9

; Two parallel tables indexed by SoundTrigger - $80.
; First: music/SFX stream pointer for triggers $80-$8F.
MusicDataLookup:
    .dw NoSongDataToLoad                   ; 74AC: 2E 75  ; trigger $80
    .dw NoSongDataToLoad                   ; 74AE: 2E 75  ; trigger $81
    .dw NoSongDataToLoad                   ; 74B0: 2E 75  ; trigger $82
    .dw NoSongDataToLoad                   ; 74B2: 2E 75  ; trigger $83
    .dw NoSongDataToLoad                   ; 74B4: 2E 75  ; trigger $84
    .dw NoSongDataToLoad                   ; 74B6: 2E 75  ; trigger $85
    .dw Track86_RaceStart                  ; 74B8: 5C 79  ; trigger $86
    .dw Track87_TimeCountdown              ; 74BA: A6 79  ; trigger $87
    .dw Track88_Congratulations            ; 74BC: BC 79  ; trigger $88
    .dw Track89_GameOver                   ; 74BE: 42 7A  ; trigger $89
    .dw Track8A_EasterEggTheme             ; 74C0: 73 7B  ; trigger $8A
    .dw Track8B_Explosion                  ; 74C2: 38 7D  ; trigger $8B
    .dw Track8C_UnusedSFX1                 ; 74C4: 64 7D  ; trigger $8C
    .dw Track8D_UnusedSFX2                 ; 74C6: 74 7D  ; trigger $8D
    .dw NoSongDataToLoad                   ; 74C8: 2E 75  ; trigger $8E
    .dw Track8F_TitleScreen                ; 74CA: 83 7D  ; trigger $8F

; Second: loader routine for triggers $80-$8F.
MusicLoadFunctionLookup:
    .dw NoSongDataToLoad                   ; 74CC: 2E 75  ; trigger $80
    .dw NoSongDataToLoad                   ; 74CE: 2E 75  ; trigger $81
    .dw NoSongDataToLoad                   ; 74D0: 2E 75  ; trigger $82
    .dw NoSongDataToLoad                   ; 74D2: 2E 75  ; trigger $83
    .dw NoSongDataToLoad                   ; 74D4: 2E 75  ; trigger $84
    .dw StopMusicAndVoice3                 ; 74D6: 03 75  ; trigger $85
    .dw LoadMusicVoice11                   ; 74D8: EC 74  ; trigger $86
    .dw LoadMusicVoice11                   ; 74DA: EC 74  ; trigger $87
    .dw LoadMusicVoice11AndStopVoice3      ; 74DC: F1 74  ; trigger $88
    .dw LoadMusicVoice11AndStopVoice3      ; 74DE: F1 74  ; trigger $89
    .dw LoadMusicVoice11AndStopVoice3      ; 74E0: F1 74  ; trigger $8A
    .dw LoadMusicVoice12AndStopVoice3      ; 74E2: F6 74  ; trigger $8B
    .dw LoadMusicVoice14                   ; 74E4: 0C 75  ; trigger $8C
    .dw LoadMusicVoice14                   ; 74E6: 0C 75  ; trigger $8D
    .dw NoSongDataToLoad                   ; 74E8: 2E 75  ; trigger $8E
    .dw LoadMusicVoice11AndStopVoice3      ; 74EA: F1 74  ; trigger $8F

; ============================================================================
; Code $74EC
; ============================================================================
LoadMusicVoice11:
    ld de, $c250                            ; 74EC: 11 50 C2
    jr loc_7512                             ; 74EF: 18 21
LoadMusicVoice11AndStopVoice3:
    ld de, $c250                            ; 74F1: 11 50 C2
    jr loc_74F9                             ; 74F4: 18 03
LoadMusicVoice12AndStopVoice3:
    ld de, $c270                            ; 74F6: 11 70 C2
loc_74F9:
    push bc                                 ; 74F9: C5
    xor a                                   ; 74FA: AF
    ld ($c150), a                           ; 74FB: 32 50 C1
    call loc_76F4                           ; 74FE: CD F4 76
    jr loc_7513                             ; 7501: 18 10
StopMusicAndVoice3:
    xor a                                   ; 7503: AF
    ld ($c150), a                           ; 7504: 32 50 C1
    call loc_76F4                           ; 7507: CD F4 76
    jr NoSongDataToLoad                     ; 750A: 18 22
LoadMusicVoice14:
    call loc_7702                           ; 750C: CD 02 77
    ld de, $c2b0                            ; 750F: 11 B0 C2
loc_7512:
    push bc                                 ; 7512: C5
loc_7513:
    pop hl                                  ; 7513: E1
    ld b, (hl)                              ; 7514: 46
    inc hl                                  ; 7515: 23
loc_7516:
    push bc                                 ; 7516: C5
    ld bc, $0009                            ; 7517: 01 09 00
    ldir                                    ; 751A: ED B0
    ld a, $20                               ; 751C: 3E 20
    ld (de), a                              ; 751E: 12
    inc de                                  ; 751F: 13
    ld a, $01                               ; 7520: 3E 01
    ld (de), a                              ; 7522: 12
    inc de                                  ; 7523: 13
    xor a                                   ; 7524: AF
    ld b, $15                               ; 7525: 06 15
loc_7527:
    ld (de), a                              ; 7527: 12
    inc de                                  ; 7528: 13
    djnz loc_7527                           ; 7529: 10 FC
    pop bc                                  ; 752B: C1
    djnz loc_7516                           ; 752C: 10 E8
NoSongDataToLoad:
    ld a, $80                               ; 752E: 3E 80
    ld (SoundTrigger), a                    ; 7530: 32 00 C1
    ret                                     ; 7533: C9
UpdateSoundLoop:
    push bc                                 ; 7534: C5
    bit 7, (ix+0)                           ; 7535: DD CB 00 7E
    call nz, UpdateVoice                    ; 7539: C4 45 75
    ld de, $0020                            ; 753C: 11 20 00
    add ix, de                              ; 753F: DD 19
    pop bc                                  ; 7541: C1
    djnz UpdateSoundLoop                    ; 7542: 10 F0
    ret                                     ; 7544: C9
UpdateVoice:
    ld a, (ix+11)                           ; 7545: DD 7E 0B
    inc a                                   ; 7548: 3C
    ld (ix+11), a                           ; 7549: DD 77 0B
    sub (ix+10)                             ; 754C: DD 96 0A
    call z, GetNextSoundDataByte            ; 754F: CC A1 75
    bit 2, (ix+0)                           ; 7552: DD CB 00 56
    jp z, UpdateSharedSFXMusicVoice         ; 7556: CA 9C 72
    ld l, $0f                               ; 7559: 2E 0F
    jp loc_72FB                             ; 755B: C3 FB 72
ReadFromWordTable:
    dec a                                   ; 755E: 3D
    ld c, a                                 ; 755F: 4F
    ld b, $00                               ; 7560: 06 00
    add hl, bc                              ; 7562: 09
    add hl, bc                              ; 7563: 09
    ld a, (hl)                              ; 7564: 7E
    inc hl                                  ; 7565: 23
    ld h, (hl)                              ; 7566: 66
    ld l, a                                 ; 7567: 6F
    ret                                     ; 7568: C9
ResetEnvelopeCounter:
    ld (ix+13), a                           ; 7569: DD 77 0D
ApplyEnvelope:
    push hl                                 ; 756C: E5
    ld a, (ix+13)                           ; 756D: DD 7E 0D
    srl a                                   ; 7570: CB 3F
    push af                                 ; 7572: F5
    ld c, a                                 ; 7573: 4F
    ld b, $00                               ; 7574: 06 00
    add hl, bc                              ; 7576: 09
    pop af                                  ; 7577: F1
    ld a, (hl)                              ; 7578: 7E
    pop hl                                  ; 7579: E1
    jr c, loc_7590                          ; 757A: 38 14
    rrca                                    ; 757C: 0F
    rrca                                    ; 757D: 0F
    rrca                                    ; 757E: 0F
    rrca                                    ; 757F: 0F
    or a                                    ; 7580: B7
    jr z, ResetEnvelopeCounter              ; 7581: 28 E6
    cp $10                                  ; 7583: FE 10
    jr nz, loc_758C                         ; 7585: 20 05
    dec (ix+13)                             ; 7587: DD 35 0D
    jr ApplyEnvelope                        ; 758A: 18 E0
loc_758C:
    cp $20                                  ; 758C: FE 20
    jr z, loc_759B                          ; 758E: 28 0B
loc_7590:
    inc (ix+13)                             ; 7590: DD 34 0D
    or $f0                                  ; 7593: F6 F0
    add a, (ix+8)                           ; 7595: DD 86 08
    inc a                                   ; 7598: 3C
    jr c, loc_759C                          ; 7599: 38 01
loc_759B:
    xor a                                   ; 759B: AF
loc_759C:
    cpl                                     ; 759C: 2F
    and $0f                                 ; 759D: E6 0F
    ld l, a                                 ; 759F: 6F
    ret                                     ; 75A0: C9
GetNextSoundDataByte:
    ld e, (ix+3)                            ; 75A1: DD 5E 03
    ld d, (ix+4)                            ; 75A4: DD 56 04
loc_75A7:
    ld a, (de)                              ; 75A7: 1A
    inc de                                  ; 75A8: 13
    cp $e0                                  ; 75A9: FE E0
    jp nc, DispatchSoundCommand             ; 75AB: D2 FD 75
    bit 4, (ix+0)                           ; 75AE: DD CB 00 66
    jp nz, SoundDataIsSongTrigger           ; 75B2: C2 F7 75
    or a                                    ; 75B5: B7
    jp p, loc_75DE                          ; 75B6: F2 DE 75
    sub $80                                 ; 75B9: D6 80
    jr z, loc_75C0                          ; 75BB: 28 03
    add a, (ix+5)                           ; 75BD: DD 86 05
loc_75C0:
    ld hl, $770b                            ; 75C0: 21 0B 77
    ld c, a                                 ; 75C3: 4F
    ld b, $00                               ; 75C4: 06 00
    add hl, bc                              ; 75C6: 09
    add hl, bc                              ; 75C7: 09
    ld a, (hl)                              ; 75C8: 7E
    ld (ix+15), a                           ; 75C9: DD 77 0F
    inc hl                                  ; 75CC: 23
    ld a, (hl)                              ; 75CD: 7E
    ld (ix+16), a                           ; 75CE: DD 77 10
    bit 5, (ix+0)                           ; 75D1: DD CB 00 6E
    jr z, SoundDataBit5Zero                 ; 75D5: 28 19
    ld a, (de)                              ; 75D7: 1A
    inc de                                  ; 75D8: 13
    ld (ix+17), a                           ; 75D9: DD 77 11
loc_75DC:
    ld a, (de)                              ; 75DC: 1A
loc_75DD:
    inc de                                  ; 75DD: 13
loc_75DE:
    ld (ix+10), a                           ; 75DE: DD 77 0A
loc_75E1:
    xor a                                   ; 75E1: AF
    ld (ix+13), a                           ; 75E2: DD 77 0D
    ld (ix+3), e                            ; 75E5: DD 73 03
    ld (ix+4), d                            ; 75E8: DD 72 04
    xor a                                   ; 75EB: AF
    ld (ix+11), a                           ; 75EC: DD 77 0B
    ret                                     ; 75EF: C9
SoundDataBit5Zero:
    ld a, (de)                              ; 75F0: 1A
    or a                                    ; 75F1: B7
    jp p, loc_75DD                          ; 75F2: F2 DD 75
    jr loc_75E1                             ; 75F5: 18 EA
SoundDataIsSongTrigger:
    ld (SoundTrigger), a                    ; 75F7: 32 00 C1
    jp loc_75DC                             ; 75FA: C3 DC 75
; Dispatches sound script opcodes E0-ED through the table at $7617.
DispatchSoundCommand:
    cp $ee                                  ; 75FD: FE EE
    ret z                                   ; 75FF: C8
    ld hl, SoundCommandReturnStub           ; 7600: 21 13 76
    push hl                                 ; 7603: E5
    and $1f                                 ; 7604: E6 1F
    ld hl, SoundCommandDispatchTable        ; 7606: 21 17 76
    ld c, a                                 ; 7609: 4F
    ld b, $00                               ; 760A: 06 00
    add hl, bc                              ; 760C: 09
    add hl, bc                              ; 760D: 09
    ld a, (hl)                              ; 760E: 7E
    inc hl                                  ; 760F: 23
    ld h, (hl)                              ; 7610: 66
    ld l, a                                 ; 7611: 6F
    jp (hl)                                 ; 7612: E9
; Return continuation pushed by DispatchSoundCommand before indirect JP.
SoundCommandReturnStub:
    inc de                                  ; 7613: 13
    jp loc_75A7                             ; 7614: C3 A7 75

; Script opcodes E0..ED.
SoundCommandDispatchTable:
    .dw SoundRoutineE0                     ; 7617: 3B 76  ; opcode $E0
    .dw SoundRoutineE1                     ; 7619: BF 76  ; opcode $E1
    .dw SoundRoutineE2                     ; 761B: 40 76  ; opcode $E2
    .dw SoundRoutineE3                     ; 761D: 4A 76  ; opcode $E3
    .dw SoundRoutineE4                     ; 761F: 44 76  ; opcode $E4
    .dw SoundRoutineE5                     ; 7621: 67 76  ; opcode $E5
    .dw SoundRoutineE6                     ; 7623: 6D 76  ; opcode $E6
    .dw SoundRoutineE7                     ; 7625: 88 76  ; opcode $E7
    .dw SoundRoutineE8                     ; 7627: B3 76  ; opcode $E8
    .dw SoundRoutineE9                     ; 7629: B9 76  ; opcode $E9
    .dw SoundRoutineEA                     ; 762B: 9B 76  ; opcode $EA
    .dw SoundRoutineEB                     ; 762D: 33 76  ; opcode $EB
    .dw SoundRoutineEC                     ; 762F: 4F 76  ; opcode $EC
    .dw SoundRoutineED                     ; 7631: 59 76  ; opcode $ED

; ============================================================================
; Code $7633
; ============================================================================
SoundRoutineEB:
    ld a, (de)                              ; 7633: 1A
    add a, (ix+5)                           ; 7634: DD 86 05
    ld (ix+5), a                            ; 7637: DD 77 05
    ret                                     ; 763A: C9
SoundRoutineE0:
    ld a, (de)                              ; 763B: 1A
    ld (ix+8), a                            ; 763C: DD 77 08
    ret                                     ; 763F: C9
SoundRoutineE2:
    ld a, $e3                               ; 7640: 3E E3
    jr loc_7646                             ; 7642: 18 02
SoundRoutineE4:
    ld a, $e7                               ; 7644: 3E E7
loc_7646:
    out (PSGPort), a                        ; 7646: D3 7F
    dec de                                  ; 7648: 1B
    ret                                     ; 7649: C9
SoundRoutineE3:
    ld a, (de)                              ; 764A: 1A
    ld (ix+7), a                            ; 764B: DD 77 07
    ret                                     ; 764E: C9
SoundRoutineEC:
    set 4, (ix+0)                           ; 764F: DD CB 00 E6
    set 2, (ix+0)                           ; 7653: DD CB 00 D6
    jr loc_7665                             ; 7657: 18 0C
SoundRoutineED:
    res 4, (ix+0)                           ; 7659: DD CB 00 A6
    res 2, (ix+0)                           ; 765D: DD CB 00 96
    xor a                                   ; 7661: AF
    ld ($c2b0), a                           ; 7662: 32 B0 C2
loc_7665:
    dec de                                  ; 7665: 1B
    ret                                     ; 7666: C9
SoundRoutineE5:
    ex de, hl                               ; 7667: EB
    ld e, (hl)                              ; 7668: 5E
    inc hl                                  ; 7669: 23
    ld d, (hl)                              ; 766A: 56
    dec de                                  ; 766B: 1B
    ret                                     ; 766C: C9
SoundRoutineE6:
    ld a, (de)                              ; 766D: 1A
    ld c, a                                 ; 766E: 4F
    inc de                                  ; 766F: 13
    ld a, (de)                              ; 7670: 1A
    ld b, a                                 ; 7671: 47
    push bc                                 ; 7672: C5
    push ix                                 ; 7673: DD E5
    pop hl                                  ; 7675: E1
    dec (ix+9)                              ; 7676: DD 35 09
    ld c, (ix+9)                            ; 7679: DD 4E 09
    dec (ix+9)                              ; 767C: DD 35 09
    ld b, $00                               ; 767F: 06 00
    add hl, bc                              ; 7681: 09
    ld (hl), d                              ; 7682: 72
    dec hl                                  ; 7683: 2B
    ld (hl), e                              ; 7684: 73
    pop de                                  ; 7685: D1
    dec de                                  ; 7686: 1B
    ret                                     ; 7687: C9
SoundRoutineE7:
    push ix                                 ; 7688: DD E5
    pop hl                                  ; 768A: E1
    ld c, (ix+9)                            ; 768B: DD 4E 09
    ld b, $00                               ; 768E: 06 00
    add hl, bc                              ; 7690: 09
    ld e, (hl)                              ; 7691: 5E
    inc hl                                  ; 7692: 23
    ld d, (hl)                              ; 7693: 56
    inc (ix+9)                              ; 7694: DD 34 09
    inc (ix+9)                              ; 7697: DD 34 09
    ret                                     ; 769A: C9
SoundRoutineEA:
    ld a, (de)                              ; 769B: 1A
    inc de                                  ; 769C: 13
    add a, $12                              ; 769D: C6 12
    ld c, a                                 ; 769F: 4F
    ld b, $00                               ; 76A0: 06 00
    push ix                                 ; 76A2: DD E5
    pop hl                                  ; 76A4: E1
    add hl, bc                              ; 76A5: 09
    ld a, (hl)                              ; 76A6: 7E
    or a                                    ; 76A7: B7
    jr nz, loc_76AC                         ; 76A8: 20 02
    ld a, (de)                              ; 76AA: 1A
    ld (hl), a                              ; 76AB: 77
loc_76AC:
    inc de                                  ; 76AC: 13
    dec (hl)                                ; 76AD: 35
    jp nz, SoundRoutineE5                   ; 76AE: C2 67 76
    inc de                                  ; 76B1: 13
    ret                                     ; 76B2: C9
SoundRoutineE8:
    set 5, (ix+0)                           ; 76B3: DD CB 00 EE
    dec de                                  ; 76B7: 1B
    ret                                     ; 76B8: C9
SoundRoutineE9:
    res 5, (ix+0)                           ; 76B9: DD CB 00 AE
    dec de                                  ; 76BD: 1B
    ret                                     ; 76BE: C9
SoundRoutineE1:
    call MuteSoundVoice                     ; 76BF: CD DD 76
    ld a, (de)                              ; 76C2: 1A
    ld hl, $76d9                            ; 76C3: 21 D9 76
    ld c, a                                 ; 76C6: 4F
    ld b, $00                               ; 76C7: 06 00
    add hl, bc                              ; 76C9: 09
    ld a, (SoundFlagsMask)                  ; 76CA: 3A 07 C1
    and (hl)                                ; 76CD: A6
    ld (SoundFlagsMask), a                  ; 76CE: 32 07 C1
    ld a, $00                               ; 76D1: 3E 00
    ld (ix+0), a                            ; 76D3: DD 77 00
    pop hl                                  ; 76D6: E1
    pop hl                                  ; 76D7: E1
    ret                                     ; 76D8: C9

; ----------------------------------------------------------------------------
; ROM data $76D9-$76DC (4 bytes)
; ----------------------------------------------------------------------------
RomData_76D9:
    .db $ff, $00, $fe, $fd                  ; 76D9: FF 00 FE FD

; ============================================================================
; Code $76DD
; ============================================================================
MuteSoundVoice:
    ld a, (ix+1)                            ; 76DD: DD 7E 01
    add a, $10                              ; 76E0: C6 10
    or $0f                                  ; 76E2: F6 0F
    out (PSGPort), a                        ; 76E4: D3 7F
    ret                                     ; 76E6: C9
ResetMusicVoices11To14:
    ld hl, $c250                            ; 76E7: 21 50 C2
    ld de, $c251                            ; 76EA: 11 51 C2
    ld bc, $007f                            ; 76ED: 01 7F 00
    ld (hl), $00                            ; 76F0: 36 00
    ldir                                    ; 76F2: ED B0
loc_76F4:
    ld hl, $76fe                            ; 76F4: 21 FE 76
    ld c, $7f                               ; 76F7: 0E 7F
    ld b, $04                               ; 76F9: 06 04
    otir                                    ; 76FB: ED B3
    ret                                     ; 76FD: C9

; ----------------------------------------------------------------------------
; ROM data $76FE-$7701 (4 bytes)
; ----------------------------------------------------------------------------
RomData_76FE:
    .db $9f, $bf, $df, $ff                  ; 76FE: 9F BF DF FF

; ============================================================================
; Code $7702
; ============================================================================
loc_7702:
    ld a, $df                               ; 7702: 3E DF
    out (PSGPort), a                        ; 7704: D3 7F
    ld a, $ff                               ; 7706: 3E FF
    out (PSGPort), a                        ; 7708: D3 7F
    ret                                     ; 770A: C9

; ----------------------------------------------------------------------------
; ROM data $770B-$795B (593 bytes)
; ----------------------------------------------------------------------------
PsgNoteTablesAndSfx:
    .incbin "../assets/psg_note_tables_and_sfx.bin"

; ----------------------------------------------------------------------------
; ROM data $795C-$79A5 (74 bytes)
; ----------------------------------------------------------------------------
Track86_RaceStart:
    .incbin "../assets/track86_race_start.bin"

; ----------------------------------------------------------------------------
; ROM data $79A6-$79BB (22 bytes)
; ----------------------------------------------------------------------------
Track87_TimeCountdown:
    .incbin "../assets/track87_time_countdown.bin"

; ----------------------------------------------------------------------------
; ROM data $79BC-$7A41 (134 bytes)
; ----------------------------------------------------------------------------
Track88_Congratulations:
    .incbin "../assets/track88_congratulations.bin"

; ----------------------------------------------------------------------------
; ROM data $7A42-$7B72 (305 bytes)
; ----------------------------------------------------------------------------
Track89_GameOver:
    .incbin "../assets/track89_game_over.bin"

; ----------------------------------------------------------------------------
; ROM data $7B73-$7D37 (453 bytes)
; ----------------------------------------------------------------------------
Track8A_EasterEggTheme:
    .incbin "../assets/track8a_easter_egg_theme.bin"

; ----------------------------------------------------------------------------
; ROM data $7D38-$7D63 (44 bytes)
; ----------------------------------------------------------------------------
Track8B_Explosion:
    .incbin "../assets/track8b_explosion.bin"

; ----------------------------------------------------------------------------
; ROM data $7D64-$7D73 (16 bytes)
; ----------------------------------------------------------------------------
Track8C_UnusedSFX1:
    .db $01, $a0, $e0, $01, $6e, $7d, $00, $00, $07, $0f, $e4, $b1, $fd, $0c, $e1, $00 ; 7D64: 01 A0 E0 01 6E 7D 00 00 07 0F E4 B1 FD 0C E1 00

; ----------------------------------------------------------------------------
; ROM data $7D74-$7D82 (15 bytes)
; ----------------------------------------------------------------------------
Track8D_UnusedSFX2:
    .db $01, $80, $e0, $01, $7e, $7d, $00, $00, $04, $0f, $e4, $c0, $0c, $e1, $00 ; 7D74: 01 80 E0 01 7E 7D 00 00 04 0F E4 C0 0C E1 00

; ----------------------------------------------------------------------------
; ROM data $7D83-$7DBE (60 bytes)
; ----------------------------------------------------------------------------
Track8F_TitleScreen:
    .incbin "../assets/track8f_title_screen.bin"

; ============================================================================
; Code $7DBF
; ============================================================================
ObjectHandlerType11:
    bit 7, (ix+1)                           ; 7DBF: DD CB 01 7E
    jr nz, loc_7DD2                         ; 7DC3: 20 0D
    ld (ix+10), $61                         ; 7DC5: DD 36 0A 61
    ld (ix+16), $00                         ; 7DC9: DD 36 10 00
    ld a, $8b                               ; 7DCD: 3E 8B
    ld (SoundTrigger), a                    ; 7DCF: 32 00 C1
loc_7DD2:
    ld (ix+1), $80                          ; 7DD2: DD 36 01 80
    ld a, $ff                               ; 7DD6: 3E FF
    ld ($c067), a                           ; 7DD8: 32 67 C0
    ld hl, (SpeedMiddle)                    ; 7DDB: 2A 1A C3
    ld de, $fff8                            ; 7DDE: 11 F8 FF
    add hl, de                              ; 7DE1: 19
    jr c, loc_7DE7                          ; 7DE2: 38 03
    ld hl, $0000                            ; 7DE4: 21 00 00
loc_7DE7:
    ld (SpeedMiddle), hl                    ; 7DE7: 22 1A C3
    inc (ix+16)                             ; 7DEA: DD 34 10
    ld a, ($c310)                           ; 7DED: 3A 10 C3
    cp $09                                  ; 7DF0: FE 09
    ret c                                   ; 7DF2: D8
    ld a, $00                               ; 7DF3: 3E 00
    ld ($c310), a                           ; 7DF5: 32 10 C3
    inc (ix+10)                             ; 7DF8: DD 34 0A
    ld a, (PlayerAnimationFrame)            ; 7DFB: 3A 0A C3
    cp $6b                                  ; 7DFE: FE 6B
    ret c                                   ; 7E00: D8
    ld a, $01                               ; 7E01: 3E 01
    ld (PlayerObject), a                    ; 7E03: 32 00 C3
    ld a, $41                               ; 7E06: 3E 41
    ld ($c301), a                           ; 7E08: 32 01 C3
    ld a, $0e                               ; 7E0B: 3E 0E
    ld (ReloadBikeSprites), a               ; 7E0D: 32 69 C0
    xor a                                   ; 7E10: AF
    ld ($c06e), a                           ; 7E11: 32 6E C0
    ret                                     ; 7E14: C9

; Unused ROM padding before the Sega header.
UnusedROMPadding:
    .fill 475, $ff                 ; 7E15: FF FF FF FF FF FF FF FF ... $7FEF

; Standard 16-byte Sega header at the end of a 32 KiB ROM.
SegaHeader:
    .db "TMR SEGA"                      ; 7FF0: 54 4D 52 20 53 45 47 41
    .db $19, $86, $73, $83, $81, $40, $00, $4c  ; 7FF8: 19 86 73 83 81 40 00 4C
