# Как проверяется byte exact

## Независимая сборка кода

`tools/miniz80asm.py` — двухпроходный ассемблер:

1. раскрывает `.include`;
2. на первом проходе вычисляет адреса labels и размеры instructions/data;
3. на втором проходе кодирует Z80-инструкции из mnemonic/operands;
4. разрешает absolute и relative labels;
5. вставляет `.db`, `.dw` и `.incbin`;
6. создаёт ROM, map и listing.

Комментарии вида `; 0038: F5` не участвуют в кодировании. Поэтому совпадение нельзя получить простым копированием reference bytes из комментариев.

## Проверки `build.py`

После сборки выполняются пять независимых проверок:

```text
size   32768
crc32  071b045e
md5    2864be0d35269c5030a7f297f70e3ac3
sha1   e601257f6477b85eb0b25a5b6d46ebc070d8a05a
sha256 0d35d0e232d64e714fa5d07e45acaf01ea9fb5a8f88fe9ac8018719ac2818d6f
```

Команда с reference ROM дополнительно сравнивает каждый байт и сообщает первый mismatch:

```sh
python build.py --compare "/path/to/Hang-On (Europe).sms"
```

## Воспроизведённый результат этой поставки

Перед упаковкой проект был собран из чистого source/assets. Полученный ROM:

- имеет размер 32 768 байт;
- совпадает с переданным ROM по `cmp`/побайтовому сравнению;
- имеет все указанные выше hashes.

## Проверка после изменения

После любого изменения source или asset достаточно запустить:

```sh
python build.py --clean --compare "/path/to/reference.sms"
```

Если изменение сохраняет layout и intended bytes, verification останется зелёной. Если нет, build завершится с ненулевым exit code.
