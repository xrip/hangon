#!/usr/bin/env python3
"""A small, dependency-free two-pass Z80 assembler.

It intentionally implements only ordinary Z80 syntax and directives used by
this reconstruction.  It is not tied to the reference ROM: instruction bytes
are generated from mnemonics and resolved expressions.
"""
from __future__ import annotations

import argparse
import ast
import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


class AsmError(RuntimeError):
    pass


@dataclass(frozen=True)
class SourceLine:
    path: Path
    number: int
    text: str


@dataclass(frozen=True)
class ListingEntry:
    address: int
    data: bytes
    source: SourceLine


REG8 = {"b": 0, "c": 1, "d": 2, "e": 3, "h": 4, "l": 5, "(hl)": 6, "a": 7}
REG16 = {"bc": 0, "de": 1, "hl": 2, "sp": 3}
REG16_AF = {"bc": 0, "de": 1, "hl": 2, "af": 3}
COND = {"nz": 0, "z": 1, "nc": 2, "c": 3, "po": 4, "pe": 5, "p": 6, "m": 7}
JR_COND = {"nz": 0, "z": 1, "nc": 2, "c": 3}
ROT = {"rlc": 0, "rrc": 1, "rl": 2, "rr": 3, "sla": 4, "sra": 5, "sll": 6, "srl": 7}
ALU = {"add": 0, "adc": 1, "sub": 2, "sbc": 3, "and": 4, "xor": 5, "or": 6, "cp": 7}
INDEX_PREFIX = {"ix": 0xDD, "iy": 0xFD}

FIXED = {
    "nop": (0x00,), "rlca": (0x07,), "rrca": (0x0F,), "rla": (0x17,),
    "rra": (0x1F,), "daa": (0x27,), "cpl": (0x2F,), "scf": (0x37,),
    "ccf": (0x3F,), "halt": (0x76,), "ret": (0xC9,), "exx": (0xD9,),
    "di": (0xF3,), "ei": (0xFB,), "neg": (0xED, 0x44),
    "retn": (0xED, 0x45), "reti": (0xED, 0x4D),
    "rrd": (0xED, 0x67), "rld": (0xED, 0x6F),
    "ldi": (0xED, 0xA0), "cpi": (0xED, 0xA1), "ini": (0xED, 0xA2),
    "outi": (0xED, 0xA3), "ldd": (0xED, 0xA8), "cpd": (0xED, 0xA9),
    "ind": (0xED, 0xAA), "outd": (0xED, 0xAB), "ldir": (0xED, 0xB0),
    "cpir": (0xED, 0xB1), "inir": (0xED, 0xB2), "otir": (0xED, 0xB3),
    "lddr": (0xED, 0xB8), "cpdr": (0xED, 0xB9), "indr": (0xED, 0xBA),
    "otdr": (0xED, 0xBB),
}


def fail(line: SourceLine, message: str) -> "NoReturn":
    raise AsmError(f"{line.path}:{line.number}: {message}\n    {line.text.rstrip()}")


def strip_comment(text: str) -> str:
    quote: str | None = None
    escaped = False
    out: list[str] = []
    for ch in text:
        if escaped:
            out.append(ch)
            escaped = False
            continue
        if ch == "\\" and quote:
            out.append(ch)
            escaped = True
            continue
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch == '"':
            quote = ch
            out.append(ch)
        elif ch == ";":
            break
        else:
            out.append(ch)
    return "".join(out).strip()


def split_csv(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    escaped = False
    for i, ch in enumerate(text):
        if escaped:
            escaped = False
            continue
        if ch == "\\" and quote:
            escaped = True
            continue
        if quote:
            if ch == quote:
                quote = None
            continue
        if ch == '"':
            quote = ch
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            parts.append(text[start:i].strip())
            start = i + 1
    parts.append(text[start:].strip())
    return [part for part in parts if part]


def parse_string(token: str) -> bytes | None:
    token = token.strip()
    if len(token) < 2 or token[0] not in ('"', "'") or token[-1] != token[0]:
        return None
    try:
        value = ast.literal_eval(token)
    except (SyntaxError, ValueError) as exc:
        raise AsmError(f"invalid string literal {token!r}: {exc}") from exc
    if not isinstance(value, str):
        return None
    try:
        return value.encode("latin-1")
    except UnicodeEncodeError as exc:
        raise AsmError(f"string contains a non-byte character: {token!r}") from exc


_ALLOWED_BINOPS = {
    ast.Add: lambda a, b: a + b,
    ast.Sub: lambda a, b: a - b,
    ast.Mult: lambda a, b: a * b,
    ast.FloorDiv: lambda a, b: a // b,
    ast.Div: lambda a, b: a // b,
    ast.Mod: lambda a, b: a % b,
    ast.LShift: lambda a, b: a << b,
    ast.RShift: lambda a, b: a >> b,
    ast.BitOr: lambda a, b: a | b,
    ast.BitAnd: lambda a, b: a & b,
    ast.BitXor: lambda a, b: a ^ b,
}
_ALLOWED_UNARY = {ast.UAdd: lambda a: a, ast.USub: lambda a: -a, ast.Invert: lambda a: ~a}


def eval_expr(expr: str, symbols: dict[str, int], allow_unresolved: bool = False) -> int:
    expr = expr.strip()
    expr = re.sub(r"\$([0-9a-fA-F]+)", r"0x\1", expr)
    expr = re.sub(r"%([01]+)", r"0b\1", expr)
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError as exc:
        raise AsmError(f"invalid expression {expr!r}") from exc

    def walk(node: ast.AST) -> int:
        if isinstance(node, ast.Expression):
            return walk(node.body)
        if isinstance(node, ast.Constant) and isinstance(node.value, int):
            return node.value
        if isinstance(node, ast.Name):
            key = node.id.lower()
            if key in symbols:
                return symbols[key]
            if allow_unresolved:
                return 0
            raise AsmError(f"unknown symbol {node.id!r}")
        if isinstance(node, ast.BinOp) and type(node.op) in _ALLOWED_BINOPS:
            return _ALLOWED_BINOPS[type(node.op)](walk(node.left), walk(node.right))
        if isinstance(node, ast.UnaryOp) and type(node.op) in _ALLOWED_UNARY:
            return _ALLOWED_UNARY[type(node.op)](walk(node.operand))
        raise AsmError(f"unsupported expression element in {expr!r}")

    return walk(tree)


def byte(value: int, what: str = "byte") -> int:
    if not -128 <= value <= 0xFF:
        raise AsmError(f"{what} value {value} is outside 8-bit range")
    return value & 0xFF


def word(value: int, what: str = "word") -> tuple[int, int]:
    if not -32768 <= value <= 0xFFFF:
        raise AsmError(f"{what} value {value} is outside 16-bit range")
    value &= 0xFFFF
    return value & 0xFF, value >> 8


def normalize_operand(op: str) -> str:
    op = op.strip().lower()
    op = re.sub(r"\s+", " ", op)
    op = re.sub(r"\(\s*", "(", op)
    op = re.sub(r"\s*\)", ")", op)
    op = re.sub(r"\s*\+\s*", "+", op)
    op = re.sub(r"\s*-\s*", "-", op)
    return op


def indexed_operand(op: str, symbols: dict[str, int], allow_unresolved: bool) -> tuple[str, int] | None:
    op = normalize_operand(op)
    match = re.fullmatch(r"\((ix|iy)(?:(\+|-)(.+))?\)", op)
    if not match:
        return None
    idx, sign, expr = match.groups()
    if expr is None:
        displacement = 0
    else:
        displacement = eval_expr(expr, symbols, allow_unresolved)
        if sign == "-":
            displacement = -displacement
    if not allow_unresolved and not -128 <= displacement <= 127:
        raise AsmError(f"indexed displacement {displacement} is outside -128..127")
    return idx, displacement & 0xFF


def memory_expr(op: str) -> str | None:
    op = op.strip()
    if len(op) >= 2 and op[0] == "(" and op[-1] == ")":
        return op[1:-1].strip()
    return None


def relative(target: int, pc: int, size: int, allow_unresolved: bool) -> int:
    displacement = (target - (pc + size))
    if allow_unresolved:
        return displacement & 0xFF
    if not -128 <= displacement <= 127:
        raise AsmError(f"relative target ${target & 0xFFFF:04x} is {displacement} bytes away")
    return displacement & 0xFF


def encode_ld(ops: list[str], pc: int, symbols: dict[str, int], allow_unresolved: bool) -> bytes:
    if len(ops) != 2:
        raise AsmError("ld requires two operands")
    dst, src = map(normalize_operand, ops)

    fixed = {
        ("i", "a"): (0xED, 0x47), ("r", "a"): (0xED, 0x4F),
        ("a", "i"): (0xED, 0x57), ("a", "r"): (0xED, 0x5F),
        ("sp", "hl"): (0xF9,),
    }
    if (dst, src) in fixed:
        return bytes(fixed[(dst, src)])
    if dst == "sp" and src in INDEX_PREFIX:
        return bytes((INDEX_PREFIX[src], 0xF9))

    dst_idx_mem = indexed_operand(dst, symbols, allow_unresolved)
    src_idx_mem = indexed_operand(src, symbols, allow_unresolved)

    # IX/IY 16-bit loads.
    if dst in INDEX_PREFIX:
        prefix = INDEX_PREFIX[dst]
        src_mem = memory_expr(src)
        if src_mem is not None and src_idx_mem is None:
            value = eval_expr(src_mem, symbols, allow_unresolved)
            lo, hi = word(value)
            return bytes((prefix, 0x2A, lo, hi))
        value = eval_expr(src, symbols, allow_unresolved)
        lo, hi = word(value)
        return bytes((prefix, 0x21, lo, hi))
    if src in INDEX_PREFIX:
        dst_mem = memory_expr(dst)
        if dst_mem is None or dst_idx_mem is not None:
            raise AsmError(f"unsupported ld {dst}, {src}")
        value = eval_expr(dst_mem, symbols, allow_unresolved)
        lo, hi = word(value)
        return bytes((INDEX_PREFIX[src], 0x22, lo, hi))

    # Indexed 8-bit memory operations.
    if dst_idx_mem or src_idx_mem:
        if dst_idx_mem and src_idx_mem:
            raise AsmError("Z80 cannot load indexed memory directly to indexed memory")
        idx, displacement = dst_idx_mem or src_idx_mem  # type: ignore[misc]
        prefix = INDEX_PREFIX[idx]
        if dst_idx_mem:
            if src in REG8 and src != "(hl)":
                return bytes((prefix, 0x70 + REG8[src], displacement))
            value = eval_expr(src, symbols, allow_unresolved)
            return bytes((prefix, 0x36, displacement, byte(value, "immediate")))
        if dst in REG8 and dst != "(hl)":
            return bytes((prefix, 0x46 + REG8[dst] * 8, displacement))
        raise AsmError(f"unsupported ld {dst}, {src}")

    # IXH/IXL/IYH/IYL forms, included for completeness of this source subset.
    idx_regs = {"ixh": ("ix", 4), "ixl": ("ix", 5), "iyh": ("iy", 4), "iyl": ("iy", 5)}
    if dst in idx_regs or src in idx_regs:
        idx = idx_regs.get(dst, idx_regs.get(src))[0]  # type: ignore[index]
        prefix = INDEX_PREFIX[idx]
        def rcode(name: str) -> int:
            if name in idx_regs:
                if idx_regs[name][0] != idx:
                    raise AsmError("cannot mix IX and IY half registers")
                return idx_regs[name][1]
            if name in REG8 and name != "(hl)":
                return REG8[name]
            raise AsmError(f"invalid indexed half-register operand {name}")
        if dst in idx_regs and src not in REG8 and src not in idx_regs:
            value = eval_expr(src, symbols, allow_unresolved)
            return bytes((prefix, 0x06 + rcode(dst) * 8, byte(value, "immediate")))
        return bytes((prefix, 0x40 + rcode(dst) * 8 + rcode(src)))

    dst_mem = memory_expr(dst)
    src_mem = memory_expr(src)

    # Accumulator and register-pair special memory forms.
    if dst == "a" and src in ("(bc)", "(de)"):
        return bytes((0x0A if src == "(bc)" else 0x1A,))
    if src == "a" and dst in ("(bc)", "(de)"):
        return bytes((0x02 if dst == "(bc)" else 0x12,))

    if dst_mem is not None and dst not in ("(bc)", "(de)", "(hl)"):
        value = eval_expr(dst_mem, symbols, allow_unresolved)
        lo, hi = word(value)
        if src == "a":
            return bytes((0x32, lo, hi))
        if src == "hl":
            return bytes((0x22, lo, hi))
        if src in REG16 and src != "hl":
            return bytes((0xED, 0x43 + REG16[src] * 0x10, lo, hi))
        raise AsmError(f"unsupported ld {dst}, {src}")

    if src_mem is not None and src not in ("(bc)", "(de)", "(hl)"):
        value = eval_expr(src_mem, symbols, allow_unresolved)
        lo, hi = word(value)
        if dst == "a":
            return bytes((0x3A, lo, hi))
        if dst == "hl":
            return bytes((0x2A, lo, hi))
        if dst in REG16 and dst != "hl":
            return bytes((0xED, 0x4B + REG16[dst] * 0x10, lo, hi))
        raise AsmError(f"unsupported ld {dst}, {src}")

    if dst in REG16:
        value = eval_expr(src, symbols, allow_unresolved)
        lo, hi = word(value)
        return bytes((0x01 + REG16[dst] * 0x10, lo, hi))

    if dst in REG8:
        if src in REG8:
            if dst == "(hl)" and src == "(hl)":
                raise AsmError("ld (hl),(hl) encodes HALT and is not accepted")
            return bytes((0x40 + REG8[dst] * 8 + REG8[src],))
        value = eval_expr(src, symbols, allow_unresolved)
        return bytes((0x06 + REG8[dst] * 8, byte(value, "immediate")))

    raise AsmError(f"unsupported ld {dst}, {src}")


def encode_inc_dec(mnemonic: str, ops: list[str], symbols: dict[str, int], allow_unresolved: bool) -> bytes:
    if len(ops) != 1:
        raise AsmError(f"{mnemonic} requires one operand")
    op = normalize_operand(ops[0])
    is_dec = mnemonic == "dec"
    if op in REG16:
        return bytes(((0x0B if is_dec else 0x03) + REG16[op] * 0x10,))
    if op in INDEX_PREFIX:
        return bytes((INDEX_PREFIX[op], 0x2B if is_dec else 0x23))
    idx_mem = indexed_operand(op, symbols, allow_unresolved)
    if idx_mem:
        idx, displacement = idx_mem
        return bytes((INDEX_PREFIX[idx], 0x35 if is_dec else 0x34, displacement))
    if op in REG8:
        return bytes(((0x05 if is_dec else 0x04) + REG8[op] * 8,))
    idx_regs = {"ixh": (0xDD, 4), "ixl": (0xDD, 5), "iyh": (0xFD, 4), "iyl": (0xFD, 5)}
    if op in idx_regs:
        prefix, reg = idx_regs[op]
        return bytes((prefix, (0x05 if is_dec else 0x04) + reg * 8))
    raise AsmError(f"unsupported {mnemonic} {op}")


def encode_alu(mnemonic: str, ops: list[str], symbols: dict[str, int], allow_unresolved: bool) -> bytes:
    y = ALU[mnemonic]
    normalized = [normalize_operand(op) for op in ops]

    # 16-bit arithmetic first.
    if mnemonic == "add" and len(normalized) == 2 and normalized[0] in ("hl", "ix", "iy"):
        dst, src = normalized
        if dst == "hl":
            if src not in REG16:
                raise AsmError(f"invalid add hl, {src}")
            return bytes((0x09 + REG16[src] * 0x10,))
        pairs = {"bc": 0, "de": 1, dst: 2, "sp": 3}
        if src not in pairs:
            raise AsmError(f"invalid add {dst}, {src}")
        return bytes((INDEX_PREFIX[dst], 0x09 + pairs[src] * 0x10))
    if mnemonic in ("adc", "sbc") and len(normalized) == 2 and normalized[0] == "hl":
        src = normalized[1]
        if src not in REG16:
            raise AsmError(f"invalid {mnemonic} hl, {src}")
        base = 0x4A if mnemonic == "adc" else 0x42
        return bytes((0xED, base + REG16[src] * 0x10))

    # ADD/ADC/SBC use explicit A in canonical source; tolerate decoder form too.
    if mnemonic in ("add", "adc", "sbc"):
        if len(normalized) == 2:
            if normalized[0] != "a":
                raise AsmError(f"{mnemonic} 8-bit form requires accumulator A")
            operand = normalized[1]
        elif len(normalized) == 1:
            operand = normalized[0]
        else:
            raise AsmError(f"{mnemonic} has invalid operand count")
    else:
        if len(normalized) != 1:
            raise AsmError(f"{mnemonic} requires one operand")
        operand = normalized[0]

    idx_mem = indexed_operand(operand, symbols, allow_unresolved)
    if idx_mem:
        idx, displacement = idx_mem
        return bytes((INDEX_PREFIX[idx], 0x80 + y * 8 + 6, displacement))
    if operand in REG8:
        return bytes((0x80 + y * 8 + REG8[operand],))
    value = eval_expr(operand, symbols, allow_unresolved)
    return bytes((0xC6 + y * 8, byte(value, "immediate")))


def encode_cb(mnemonic: str, ops: list[str], symbols: dict[str, int], allow_unresolved: bool) -> bytes:
    normalized = [normalize_operand(op) for op in ops]
    if mnemonic in ROT:
        if len(normalized) != 1:
            raise AsmError(f"{mnemonic} requires one operand")
        y = ROT[mnemonic]
        operand = normalized[0]
        idx_mem = indexed_operand(operand, symbols, allow_unresolved)
        if idx_mem:
            idx, displacement = idx_mem
            return bytes((INDEX_PREFIX[idx], 0xCB, displacement, y * 8 + 6))
        if operand not in REG8:
            raise AsmError(f"invalid {mnemonic} operand {operand}")
        return bytes((0xCB, y * 8 + REG8[operand]))

    if len(normalized) != 2:
        raise AsmError(f"{mnemonic} requires bit number and operand")
    bit_no = eval_expr(normalized[0], symbols, allow_unresolved)
    if not allow_unresolved and not 0 <= bit_no <= 7:
        raise AsmError(f"bit number {bit_no} is outside 0..7")
    bit_no &= 7
    operand = normalized[1]
    idx_mem = indexed_operand(operand, symbols, allow_unresolved)
    x = {"bit": 1, "res": 2, "set": 3}[mnemonic]
    if idx_mem:
        idx, displacement = idx_mem
        return bytes((INDEX_PREFIX[idx], 0xCB, displacement, x * 0x40 + bit_no * 8 + 6))
    if operand not in REG8:
        raise AsmError(f"invalid {mnemonic} operand {operand}")
    return bytes((0xCB, x * 0x40 + bit_no * 8 + REG8[operand]))


def encode_instruction(text: str, pc: int, symbols: dict[str, int], allow_unresolved: bool = False) -> bytes:
    text = text.strip()
    if not text:
        return b""
    fields = text.split(None, 1)
    mnemonic = fields[0].lower()
    ops = split_csv(fields[1]) if len(fields) == 2 else []
    normalized_ops = [normalize_operand(op) for op in ops]

    if not ops and mnemonic in FIXED:
        return bytes(FIXED[mnemonic])
    if mnemonic == "ex" and normalized_ops == ["af", "af'"]:
        return bytes((0x08,))
    if mnemonic == "ex" and normalized_ops == ["de", "hl"]:
        return bytes((0xEB,))
    if mnemonic == "ex" and normalized_ops == ["(sp)", "hl"]:
        return bytes((0xE3,))
    if mnemonic == "ex" and len(normalized_ops) == 2 and normalized_ops[0] == "(sp)" and normalized_ops[1] in INDEX_PREFIX:
        return bytes((INDEX_PREFIX[normalized_ops[1]], 0xE3))
    if mnemonic == "im":
        if len(ops) != 1:
            raise AsmError("im requires one operand")
        mode = eval_expr(ops[0], symbols, allow_unresolved)
        opcodes = {0: 0x46, 1: 0x56, 2: 0x5E}
        if mode not in opcodes:
            raise AsmError("interrupt mode must be 0, 1, or 2")
        return bytes((0xED, opcodes[mode]))
    if mnemonic == "rst":
        if len(ops) != 1:
            raise AsmError("rst requires one operand")
        target = eval_expr(ops[0], symbols, allow_unresolved)
        if not allow_unresolved and (target & 7 or not 0 <= target <= 0x38):
            raise AsmError("rst target must be $00,$08,...,$38")
        return bytes((0xC7 + (target & 0x38),))
    if mnemonic == "ld":
        return encode_ld(ops, pc, symbols, allow_unresolved)
    if mnemonic in ("inc", "dec"):
        return encode_inc_dec(mnemonic, ops, symbols, allow_unresolved)
    if mnemonic in ALU:
        return encode_alu(mnemonic, ops, symbols, allow_unresolved)
    if mnemonic in ROT or mnemonic in ("bit", "res", "set"):
        return encode_cb(mnemonic, ops, symbols, allow_unresolved)

    if mnemonic == "djnz":
        if len(ops) != 1:
            raise AsmError("djnz requires one target")
        target = eval_expr(ops[0], symbols, allow_unresolved)
        return bytes((0x10, relative(target, pc, 2, allow_unresolved)))
    if mnemonic == "jr":
        if len(ops) == 1:
            target = eval_expr(ops[0], symbols, allow_unresolved)
            return bytes((0x18, relative(target, pc, 2, allow_unresolved)))
        if len(ops) == 2 and normalized_ops[0] in JR_COND:
            target = eval_expr(ops[1], symbols, allow_unresolved)
            return bytes((0x20 + JR_COND[normalized_ops[0]] * 8, relative(target, pc, 2, allow_unresolved)))
        raise AsmError("jr accepts target or condition,target")
    if mnemonic == "jp":
        if len(ops) == 1:
            operand = normalized_ops[0]
            if operand == "(hl)":
                return bytes((0xE9,))
            if operand in ("(ix)", "(iy)"):
                return bytes((INDEX_PREFIX[operand[1:3]], 0xE9))
            target = eval_expr(ops[0], symbols, allow_unresolved)
            lo, hi = word(target)
            return bytes((0xC3, lo, hi))
        if len(ops) == 2 and normalized_ops[0] in COND:
            target = eval_expr(ops[1], symbols, allow_unresolved)
            lo, hi = word(target)
            return bytes((0xC2 + COND[normalized_ops[0]] * 8, lo, hi))
        raise AsmError("jp accepts target, (hl)/(ix)/(iy), or condition,target")
    if mnemonic == "call":
        if len(ops) == 1:
            target = eval_expr(ops[0], symbols, allow_unresolved)
            lo, hi = word(target)
            return bytes((0xCD, lo, hi))
        if len(ops) == 2 and normalized_ops[0] in COND:
            target = eval_expr(ops[1], symbols, allow_unresolved)
            lo, hi = word(target)
            return bytes((0xC4 + COND[normalized_ops[0]] * 8, lo, hi))
        raise AsmError("call accepts target or condition,target")
    if mnemonic == "ret" and len(ops) == 1 and normalized_ops[0] in COND:
        return bytes((0xC0 + COND[normalized_ops[0]] * 8,))
    if mnemonic in ("push", "pop"):
        if len(ops) != 1:
            raise AsmError(f"{mnemonic} requires one operand")
        operand = normalized_ops[0]
        if operand in INDEX_PREFIX:
            return bytes((INDEX_PREFIX[operand], 0xE5 if mnemonic == "push" else 0xE1))
        if operand not in REG16_AF:
            raise AsmError(f"invalid {mnemonic} register {operand}")
        base = 0xC5 if mnemonic == "push" else 0xC1
        return bytes((base + REG16_AF[operand] * 0x10,))
    if mnemonic == "out":
        if len(ops) != 2:
            raise AsmError("out requires two operands")
        dst, src = normalized_ops
        if dst == "(c)":
            if src not in REG8 or src == "(hl)":
                raise AsmError(f"invalid out (c), {src}")
            return bytes((0xED, 0x41 + REG8[src] * 8))
        expr = memory_expr(ops[0])
        if expr is None or src != "a":
            raise AsmError("immediate-port out syntax is out (port),a")
        port = eval_expr(expr, symbols, allow_unresolved)
        return bytes((0xD3, byte(port, "port")))
    if mnemonic == "in":
        if len(ops) == 1 and normalized_ops[0] == "(c)":
            return bytes((0xED, 0x70))
        if len(ops) != 2:
            raise AsmError("in requires one or two operands")
        dst, src = normalized_ops
        if src == "(c)":
            if dst not in REG8 or dst == "(hl)":
                raise AsmError(f"invalid in {dst}, (c)")
            return bytes((0xED, 0x40 + REG8[dst] * 8))
        expr = memory_expr(ops[1])
        if dst != "a" or expr is None:
            raise AsmError("immediate-port in syntax is in a,(port)")
        port = eval_expr(expr, symbols, allow_unresolved)
        return bytes((0xDB, byte(port, "port")))

    raise AsmError(f"unsupported instruction {text!r}")


class Assembler:
    def __init__(self, source: Path):
        self.source = source.resolve()
        self.lines = self._load(self.source, [])
        self.symbols: dict[str, int] = {}
        self.display_names: dict[str, str] = {}
        self.listing: list[ListingEntry] = []

    def _load(self, path: Path, stack: list[Path]) -> list[SourceLine]:
        path = path.resolve()
        if path in stack:
            cycle = " -> ".join(str(p) for p in stack + [path])
            raise AsmError(f"recursive include: {cycle}")
        result: list[SourceLine] = []
        for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(True), 1):
            clean = strip_comment(raw)
            match = re.fullmatch(r"\.include\s+([\"'])(.+)\1", clean, re.IGNORECASE)
            if match:
                child = (path.parent / match.group(2)).resolve()
                result.extend(self._load(child, stack + [path]))
            else:
                result.append(SourceLine(path, number, raw))
        return result

    @staticmethod
    def _label_and_body(clean: str) -> tuple[str | None, str]:
        match = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):(?:\s*(.*))?$", clean)
        if not match:
            return None, clean
        return match.group(1), (match.group(2) or "").strip()

    def _define(self, name: str, value: int, line: SourceLine, allow_same: bool = False) -> None:
        key = name.lower()
        if key in self.symbols and not (allow_same and self.symbols[key] == value):
            fail(line, f"symbol {name} is already defined")
        self.symbols[key] = value
        self.display_names[key] = name

    def _line_size_or_data(self, body: str, pc: int, line: SourceLine, pass_no: int) -> tuple[int, bytes | None, int | None]:
        # Returns (size, data-on-pass2, new-pc-for-org).
        lower = body.lower()
        allow_unresolved = pass_no == 1
        if lower.startswith(".org "):
            try:
                value = eval_expr(body[5:], self.symbols, allow_unresolved)
            except AsmError as exc:
                fail(line, str(exc))
            return 0, None, value
        if lower.startswith(".incbin "):
            match = re.fullmatch(r"\.incbin\s+([\"'])(.+)\1", body, re.IGNORECASE)
            if not match:
                fail(line, "invalid .incbin syntax")
            path = (line.path.parent / match.group(2)).resolve()
            try:
                data = path.read_bytes()
            except OSError as exc:
                fail(line, f"cannot read incbin file {path}: {exc}")
            return len(data), data if pass_no == 2 else None, None
        if lower.startswith(".db") and (len(body) == 3 or body[3].isspace()):
            items = split_csv(body[3:].strip())
            data = bytearray()
            for item in items:
                string = parse_string(item)
                if string is not None:
                    data.extend(string)
                else:
                    try:
                        value = eval_expr(item, self.symbols, allow_unresolved)
                        data.append(byte(value))
                    except AsmError as exc:
                        fail(line, str(exc))
            return len(data), bytes(data) if pass_no == 2 else None, None
        if lower.startswith(".dw") and (len(body) == 3 or body[3].isspace()):
            items = split_csv(body[3:].strip())
            data = bytearray()
            for item in items:
                try:
                    value = eval_expr(item, self.symbols, allow_unresolved)
                    data.extend(word(value))
                except AsmError as exc:
                    fail(line, str(exc))
            return len(data), bytes(data) if pass_no == 2 else None, None
        if lower.startswith(".fill "):
            items = split_csv(body[6:])
            if not 1 <= len(items) <= 2:
                fail(line, ".fill syntax is .fill count[, value]")
            try:
                count = eval_expr(items[0], self.symbols, allow_unresolved)
                value = eval_expr(items[1], self.symbols, allow_unresolved) if len(items) == 2 else 0
                if count < 0:
                    raise AsmError("negative .fill count")
                data = bytes([byte(value)]) * count
            except AsmError as exc:
                fail(line, str(exc))
            return count, data if pass_no == 2 else None, None
        try:
            data = encode_instruction(body, pc, self.symbols, allow_unresolved)
        except AsmError as exc:
            fail(line, str(exc))
        return len(data), data if pass_no == 2 else None, None

    def assemble(self) -> bytes:
        # Pass 1: symbols and sizes.
        pc = 0
        for line in self.lines:
            clean = strip_comment(line.text)
            if not clean:
                continue
            label, body = self._label_and_body(clean)
            if label:
                self._define(label, pc, line)
            if not body:
                continue
            equ = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s+equ\s+(.+)", body, re.IGNORECASE)
            if equ:
                try:
                    value = eval_expr(equ.group(2), self.symbols, False)
                except AsmError as exc:
                    fail(line, str(exc))
                self._define(equ.group(1), value, line)
                continue
            size, _, new_pc = self._line_size_or_data(body, pc, line, 1)
            if new_pc is not None:
                if new_pc < pc:
                    fail(line, f".org ${new_pc:04x} moves backwards from ${pc:04x}")
                pc = new_pc
            else:
                pc += size

        # Pass 2: emit bytes.
        output = bytearray()
        pc = 0
        self.listing.clear()
        for line in self.lines:
            clean = strip_comment(line.text)
            if not clean:
                continue
            _, body = self._label_and_body(clean)
            if not body:
                continue
            if re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s+equ\s+(.+)", body, re.IGNORECASE):
                continue
            size, data, new_pc = self._line_size_or_data(body, pc, line, 2)
            if new_pc is not None:
                if new_pc < pc:
                    fail(line, f".org ${new_pc:04x} moves backwards from ${pc:04x}")
                if new_pc > pc:
                    output.extend(b"\x00" * (new_pc - pc))
                pc = new_pc
                continue
            assert data is not None and len(data) == size
            if pc != len(output):
                fail(line, f"internal output position mismatch: pc=${pc:04x}, file=${len(output):04x}")
            output.extend(data)
            self.listing.append(ListingEntry(pc, data, line))
            pc += size
        return bytes(output)

    def write_map(self, path: Path) -> None:
        rows = sorted((value, self.display_names[key]) for key, value in self.symbols.items())
        path.write_text("".join(f"{value:04X} {name}\n" for value, name in rows), encoding="utf-8")

    def write_listing(self, path: Path) -> None:
        lines: list[str] = []
        for entry in self.listing:
            data = entry.data
            offset = 0
            while offset < len(data):
                chunk = data[offset:offset + 8]
                source_text = entry.source.text.rstrip() if offset == 0 else ""
                lines.append(f"{entry.address + offset:04X}  {' '.join(f'{b:02X}' for b in chunk):<23}  {source_text}\n")
                offset += len(chunk)
            if not data:
                lines.append(f"{entry.address:04X}  {'':23}  {entry.source.text.rstrip()}\n")
        path.write_text("".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Assemble the Hang-On Z80 reconstruction")
    parser.add_argument("source", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--map", dest="map_file", type=Path)
    parser.add_argument("--listing", type=Path)
    args = parser.parse_args()

    try:
        assembler = Assembler(args.source)
        data = assembler.assemble()
    except (AsmError, OSError) as exc:
        parser.exit(1, f"error: {exc}\n")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(data)
    if args.map_file:
        args.map_file.parent.mkdir(parents=True, exist_ok=True)
        assembler.write_map(args.map_file)
    if args.listing:
        args.listing.parent.mkdir(parents=True, exist_ok=True)
        assembler.write_listing(args.listing)
    digest = hashlib.sha256(data).hexdigest()
    print(f"assembled {len(data)} bytes -> {args.output}")
    print(f"sha256 {digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
