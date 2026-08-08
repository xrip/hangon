# Результаты статического анализа

## Идентификация ROM

| Поле | Значение |
|---|---:|
| Размер | 32 768 байт |
| Адресное пространство ROM | `$0000-$7FFF` |
| CRC32 | `071b045e` |
| MD5 | `2864be0d35269c5030a7f297f70e3ac3` |
| SHA-1 | `e601257f6477b85eb0b25a5b6d46ebc070d8a05a` |
| SHA-256 | `0d35d0e232d64e714fa5d07e45acaf01ea9fb5a8f88fe9ac8018719ac2818d6f` |
| Sega header | `$7FF0-$7FFF` |

ROM имеет размер 32 КиБ и полностью отображается в CPU `$0000-$7FFF`; внешнего mapper/bank switching в этой ревизии нет.

## Покрытие кода

| Метрика | Значение |
|---|---:|
| Z80-инструкций | 4 559 |
| Байтов подтверждённого кода | 8 823 |
| Доля ROM | 26,93% |
| Базовых блоков/entry points | 258 |
| Раздельных диапазонов кода | 36 |
| Прямых целей управления внутри ROM | 459 |
| Конфликтов разметки code/data | 0 |
| Недокументированных инструкций | 0 |

Распознавание начиналось с reset (`$0000`), IM 1 IRQ (`$0038`) и NMI (`$0066`), затем рекурсивно проходило все прямые `CALL`, `JP`, `JR` и `DJNZ`. Цели косвенных переходов добавлялись после анализа таблиц и записей function pointers. Дополнительно были найдены исполняемые блоки, не имеющие обычной прямой ссылки в ROM: копируемый в RAM IRQ handler, delay routine, sound entry stub и continuation sound dispatcher.

## Диапазоны подтверждённого кода

```text
0000-001C  001E-002B  0030-0064  0066-00A1  00A7-04FB
05F1-0758  0764-07C0  07C4-080C  0959-0F8E  126A-1303
1331-1355  1394-15CA  23D3-2468  247D-253C  2A5D-2CC4
2EF3-2FDC  3088-3135  3406-3488  34BF-34D0  3553-35CF
35E5-3668  3694-36FE  370B-37CE  37D9-3938  3945-3975
39FC-3A7F  3B0B-3C1C  3C3D-3D9A  3DAB-3E78  7117-7382
748B-74AB  74EC-7616  7633-76D8  76DD-76FD  7702-770A
7DBF-7E14
```

## Косвенные переходы

### Game-state dispatcher — `$1355`

`GameState` маскируется, умножается на два и индексирует таблицу около `$1354`. Entries 1-31 представлены в `GameStateHandlerTable` с адреса `$1356`. Нулевая запись намеренно попадает на двухбайтовый `EX DE,HL / JP (HL)` stub непосредственно перед таблицей.

### Object dispatcher — `$24BA`

Тип объекта выбирает handler из `ObjectHandlerTable` (`$253D`). Type 0 указывает на `$253B`, где находятся `POP BC / RET`; types 1-11 имеют восстановленные цели.

### Runtime sound-function pointer — `$7152`

Адрес функции хранится в `SoundFunctionPointer` (`$C101`) и затем выполняется через `JP (HL)`. В коде обнаружены записи следующих допустимых целей:

```text
7153 SoundFunctionOvertakeHigh
716D SoundFunctionOvertakeLow
717B SoundFunctionBump
7195 SoundFunctionSkid
71AF SoundFunctionGoSign
71DC SoundFunctionEngine
```

### Sound-trigger dispatcher — `$74AB`

Триггер индексирует две параллельные таблицы: `MusicDataLookup` (`$74AC`) и `MusicLoadFunctionLookup` (`$74CC`), по 16 words для значений `$80-$8F`. Обе сохранены символически.

### Sound-script dispatcher — `$7612`

Команды `$E0-$ED` индексируют `SoundCommandDispatchTable` в `$7617`. Перед `JP (HL)` код кладёт `$7613` на стек; `SoundCommandReturnStub` увеличивает script pointer и возвращается в общий decoder.

## Код, копируемый в RAM

Во время старта 42 байта `$03B3-$03DC` копируются в `$C4D0`. IRQ vector проверяет VDP status и при line interrupt прыгает непосредственно в `$C4D0`.

Этот блок оставлен обычным Z80-кодом в ROM source. Его относительные переходы остаются корректными после копирования, а абсолютные обращения уже адресуют RAM/VDP. Такое представление одновременно читаемо и byte exact.

## Почему часть ROM остаётся binary assets

Рекурсивный disassembler не должен трактовать произвольные данные как инструкции. Большие непокрытые диапазоны содержат:

- tile/pattern data и sprite graphics;
- tilemaps и course/road data;
- пользовательские compressed streams;
- PSG music/SFX streams;
- таблицы чисел, координат и layout data;
- текст и Sega header.

Известные function tables переведены в `.dw`, а остальные диапазоны вынесены в `assets/` как бинарные файлы с осмысленными именами (например `road_tilemap_hud_labels.bin`, `road_curvature_tables.bin`, `track86_race_start.bin`). Полное сопоставление имён и адресов см. в `docs/ASSET_RENAME_PLAN.md`. Это сохраняет точное расположение и позволяет постепенно заменять каждый asset на структурированный исходник.

## Ограничение семантической реконструкции

Byte exact доказан для всех 32 768 байт. Семантические имена функций различаются по уровню уверенности: аппаратные routines, VDP helpers, dispatchers и sound engine имеют высокую уверенность; часть gameplay handlers пока названа нейтрально по типу/состоянию. Это лучше, чем закреплять неподтверждённые названия как факт.
