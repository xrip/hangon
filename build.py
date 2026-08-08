#!/usr/bin/env python3
"""Build and verify the byte-exact Hang-On (Europe) ROM reconstruction."""
from __future__ import annotations

import argparse
import hashlib
import shutil
import sys
import zlib
from pathlib import Path

from tools.miniz80asm import AsmError, Assembler

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "src" / "hangon_europe.asm"
BUILD_DIR = ROOT / "build"
OUTPUT = BUILD_DIR / "hangon-europe.sms"
MAP_FILE = BUILD_DIR / "hangon-europe.map"
LISTING_FILE = BUILD_DIR / "hangon-europe.lst"

EXPECTED_SIZE = 32_768
EXPECTED_SHA256 = "0d35d0e232d64e714fa5d07e45acaf01ea9fb5a8f88fe9ac8018719ac2818d6f"
EXPECTED_SHA1 = "e601257f6477b85eb0b25a5b6d46ebc070d8a05a"
EXPECTED_MD5 = "2864be0d35269c5030a7f297f70e3ac3"
EXPECTED_CRC32 = "071b045e"


def digest(data: bytes, algorithm: str) -> str:
    return hashlib.new(algorithm, data).hexdigest()


def first_difference(actual: bytes, reference: bytes) -> str:
    common = min(len(actual), len(reference))
    for offset in range(common):
        if actual[offset] != reference[offset]:
            return (
                f"first difference at 0x{offset:04X}: "
                f"built=0x{actual[offset]:02X}, reference=0x{reference[offset]:02X}"
            )
    if len(actual) != len(reference):
        return f"files share {common} bytes but lengths differ: {len(actual)} vs {len(reference)}"
    return "no difference"


def build(write_listing: bool = True) -> bytes:
    assembler = Assembler(SOURCE)
    data = assembler.assemble()

    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(data)
    assembler.write_map(MAP_FILE)
    if write_listing:
        assembler.write_listing(LISTING_FILE)

    return data


def verify(data: bytes) -> list[tuple[str, str, str]]:
    actual = {
        "size": str(len(data)),
        "sha256": digest(data, "sha256"),
        "sha1": digest(data, "sha1"),
        "md5": digest(data, "md5"),
        "crc32": f"{zlib.crc32(data) & 0xFFFFFFFF:08x}",
    }
    expected = {
        "size": str(EXPECTED_SIZE),
        "sha256": EXPECTED_SHA256,
        "sha1": EXPECTED_SHA1,
        "md5": EXPECTED_MD5,
        "crc32": EXPECTED_CRC32,
    }
    return [(name, actual[name], expected[name]) for name in expected]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--compare",
        type=Path,
        metavar="ROM",
        help="also compare every byte against a supplied reference ROM",
    )
    parser.add_argument(
        "--no-listing",
        action="store_true",
        help="skip generation of the large annotated .lst file",
    )
    parser.add_argument(
        "--clean",
        action="store_true",
        help="remove build outputs before building",
    )
    args = parser.parse_args()

    if args.clean and BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)

    try:
        data = build(write_listing=not args.no_listing)
    except (AsmError, OSError) as exc:
        print(f"build failed: {exc}", file=sys.stderr)
        return 1

    failed = False
    print(f"built: {OUTPUT}")
    for name, actual, expected in verify(data):
        status = "OK" if actual == expected else "FAIL"
        print(f"{name:7s} {actual}  [{status}]")
        failed |= actual != expected

    if args.compare:
        try:
            reference = args.compare.read_bytes()
        except OSError as exc:
            print(f"cannot read reference ROM: {exc}", file=sys.stderr)
            return 1
        exact = data == reference
        print(f"compare {'byte-for-byte identical' if exact else first_difference(data, reference)}")
        failed |= not exact

    if failed:
        print("verification failed", file=sys.stderr)
        return 1

    print("verification passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
