#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
loongarch_world_detect.py

用途：
1. 判断单个 LoongArch ELF 文件是新世界 / 旧世界 / 未知 / 冲突
2. 判断当前系统用户态生态是新世界 / 旧世界 / 混合 / 未知
3. 尝试判断当前固件是新世界 / 旧世界 / 未知
4. 输出结构化 JSON，给上层程序直接消费

判定原则（按可靠性排序）：
- ELF e_flags[7:6]：主判断依据
- PT_INTERP：动态 glibc 程序的辅助依据
- 系统生态：抽样多个宿主原生二进制
- 固件：解析 SMBIOS entry point 的表地址，检测是否为 0x9... DMW 虚拟地址

注意：
- 没有任何脚本能做到 100% 绝对正确，尤其是：
  1) 极早期新世界二进制可能没有 OBJ-v1 标记
  2) 新世界系统上可能通过兼容层运行旧世界程序
  3) 固件信息在某些系统里不可见或被内核屏蔽
"""


"""
用法
e_flags[7:6] 是 LoongArch ELF ABI 版本位，1 对应新世界风格，0 对应旧世界风格；而新旧世界动态程序的 interpreter 路径分别是 /lib64/ld-linux-loongarch-lp64d.so.1 和 /lib64/ld.so.1。

另外，早期新世界工具链生成的某些产物可能还没有 OBJ-v1 标记，所以脚本在 e_flags=0 但 PT_INTERP 明显是新世界时，会给出 new + medium confidence，而不是直接误判成旧世界。

bash
# 1) 只判断当前系统
python3 loongarch_world_detect.py --pretty

# 2) 判断当前系统 + 指定二进制
python3 loongarch_world_detect.py --pretty /bin/ls /usr/bin/env /path/to/your/app

# 3) 只判断文件，不碰系统和固件
python3 loongarch_world_detect.py --no-system --no-firmware --pretty /path/to/file
你最终最好看这几个字段：

binary_detections[].world：某个 ELF 自己属于哪个世界。

system_userland.world：当前宿主用户态生态。

firmware.world：当前固件风格。

overall.world：汇总结果；如果出现 mixed，就说明不能再强行压成一个单值。

设计说明
这类判断里，最不推荐拿来当主依据的是“发行版名字”“内核版本”“某个商业软件是否存在”这类启发式线索，因为底层兼容已经在演进，这些信号只能做旁证，不适合做最终裁决。

固件层面，旧世界的典型特征是把很多表地址以 0x9... 这种 DMW 虚拟地址形式传递，而新世界则传物理地址，所以脚本把 SMBIOS 表地址是否为 0x9... 当成强旧世界信号；但如果系统根本不给你这个地址，脚本就会老老实实返回 unknown。
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import sys
from collections import Counter
from dataclasses import dataclass, asdict
from typing import Optional, List, Dict, Any

EM_LOONGARCH = 258
PT_INTERP = 3

INTERP_NEW = "/lib64/ld-linux-loongarch-lp64d.so.1"
INTERP_OLD = "/lib64/ld.so.1"

WORLD_NEW = "new"
WORLD_OLD = "old"
WORLD_MIXED = "mixed"
WORLD_UNKNOWN = "unknown"
WORLD_CONFLICT = "conflict"

CONF_HIGH = "high"
CONF_MEDIUM = "medium"
CONF_LOW = "low"

SYSTEM_SAMPLE_CANDIDATES = [
    "/usr/bin/env",
    "/bin/sh",
    "/usr/bin/sh",
    "/bin/ls",
    "/usr/bin/ls",
    "/lib64/libc.so.6",
]

def _exists_regular(path: str) -> bool:
    try:
        return os.path.isfile(path) or os.path.islink(path)
    except Exception:
        return False

@dataclass
class ELFInfo:
    path: str
    ok: bool
    error: Optional[str] = None
    bits: Optional[int] = None
    endian: Optional[str] = None
    e_machine: Optional[int] = None
    e_flags: Optional[int] = None
    e_flags_low_byte: Optional[int] = None
    abi_version_bits: Optional[int] = None
    base_abi_bits: Optional[int] = None
    e_phoff: Optional[int] = None
    e_phentsize: Optional[int] = None
    e_phnum: Optional[int] = None
    interp: Optional[str] = None

@dataclass
class Detection:
    target: str
    kind: str
    world: str
    confidence: str
    reasons: List[str]
    warnings: List[str]
    details: Dict[str, Any]

def parse_elf(path: str) -> ELFInfo:
    try:
        with open(path, "rb") as f:
            ident = f.read(16)
            if len(ident) < 16:
                return ELFInfo(path=path, ok=False, error="file too short for ELF ident")

            if ident[:4] != b"\x7fELF":
                return ELFInfo(path=path, ok=False, error="not an ELF file")

            ei_class = ident[4]
            ei_data = ident[5]

            if ei_class == 1:
                bits = 32
                hdr_size = 52
                hdr_fmt = None  # set after endianness
            elif ei_class == 2:
                bits = 64
                hdr_size = 64
                hdr_fmt = None
            else:
                return ELFInfo(path=path, ok=False, error=f"unsupported EI_CLASS={ei_class}")

            if ei_data == 1:
                endian = "little"
                prefix = "<"
            elif ei_data == 2:
                endian = "big"
                prefix = ">"
            else:
                return ELFInfo(path=path, ok=False, error=f"unsupported EI_DATA={ei_data}")

            if bits == 32:
                hdr_fmt = prefix + "HHIIIIIHHHHHH"
            else:
                hdr_fmt = prefix + "HHIQQQIHHHHHH"

            rest = f.read(hdr_size - 16)
            if len(rest) != hdr_size - 16:
                return ELFInfo(path=path, ok=False, error="truncated ELF header")

            fields = struct.unpack(hdr_fmt, rest)
            (
                e_type,
                e_machine,
                e_version,
                e_entry,
                e_phoff,
                e_shoff,
                e_flags,
                e_ehsize,
                e_phentsize,
                e_phnum,
                e_shentsize,
                e_shnum,
                e_shstrndx,
            ) = fields

            interp = _read_pt_interp(
                f=f,
                bits=bits,
                prefix=prefix,
                e_phoff=e_phoff,
                e_phentsize=e_phentsize,
                e_phnum=e_phnum,
            )

            return ELFInfo(
                path=path,
                ok=True,
                bits=bits,
                endian=endian,
                e_machine=e_machine,
                e_flags=e_flags,
                e_flags_low_byte=(e_flags & 0xFF),
                abi_version_bits=((e_flags >> 6) & 0b11),
                base_abi_bits=(e_flags & 0b111),
                e_phoff=e_phoff,
                e_phentsize=e_phentsize,
                e_phnum=e_phnum,
                interp=interp,
            )
    except PermissionError as e:
        return ELFInfo(path=path, ok=False, error=f"permission denied: {e}")
    except FileNotFoundError:
        return ELFInfo(path=path, ok=False, error="file not found")
    except OSError as e:
        return ELFInfo(path=path, ok=False, error=f"os error: {e}")
    except Exception as e:
        return ELFInfo(path=path, ok=False, error=f"unexpected error: {e}")

def _read_pt_interp(
    f,
    bits: int,
    prefix: str,
    e_phoff: int,
    e_phentsize: int,
    e_phnum: int,
) -> Optional[str]:
    if not e_phoff or not e_phentsize or not e_phnum:
        return None

    if bits == 64:
        ph_fmt = prefix + "IIQQQQQQ"
        ph_min = struct.calcsize(ph_fmt)
    else:
        ph_fmt = prefix + "IIIIIIII"
        ph_min = struct.calcsize(ph_fmt)

    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        f.seek(off)
        raw = f.read(e_phentsize)
        if len(raw) < ph_min:
            return None

        if bits == 64:
            p_type, p_flags, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_align = struct.unpack(
                ph_fmt, raw[:ph_min]
            )
        else:
            p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align = struct.unpack(
                ph_fmt, raw[:ph_min]
            )

        if p_type != PT_INTERP:
            continue

        if p_filesz <= 0 or p_filesz > 4096:
            return None

        f.seek(p_offset)
        data = f.read(p_filesz)
        if not data:
            return None

        data = data.split(b"\x00", 1)[0]
        try:
            return data.decode("utf-8", errors="replace")
        except Exception:
            return None

    return None

def classify_interp(interp: Optional[str]) -> Optional[str]:
    if interp == INTERP_NEW:
        return WORLD_NEW
    if interp == INTERP_OLD:
        return WORLD_OLD
    return None

def detect_binary_world(path: str) -> Detection:
    elf = parse_elf(path)

    if not elf.ok:
        return Detection(
            target=path,
            kind="binary",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=[],
            warnings=[elf.error or "unknown parse error"],
            details={"elf": asdict(elf)},
        )

    reasons: List[str] = []
    warnings: List[str] = []

    if elf.e_machine != EM_LOONGARCH:
        return Detection(
            target=path,
            kind="binary",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=[],
            warnings=[f"ELF is not EM_LOONGARCH (e_machine={elf.e_machine})"],
            details={"elf": asdict(elf)},
        )

    flag_world = None
    flag_conf = CONF_LOW

    if elf.abi_version_bits == 1:
        flag_world = WORLD_NEW
        flag_conf = CONF_HIGH
        reasons.append("e_flags[7:6] == 1 (OBJ-v1 / new-world style)")
    elif elf.abi_version_bits == 0:
        flag_world = WORLD_OLD
        # 注意：v0 可能是旧世界，也可能是非常早期的新世界产物
        flag_conf = CONF_MEDIUM if elf.interp is None else CONF_HIGH
        reasons.append("e_flags[7:6] == 0 (OBJ-v0 / old-world style, or very early new-world build)")
    else:
        warnings.append(f"e_flags[7:6] is reserved value {elf.abi_version_bits}")

    interp_world = classify_interp(elf.interp)
    if elf.interp is not None:
        if interp_world == WORLD_NEW:
            reasons.append(f"PT_INTERP == {INTERP_NEW}")
        elif interp_world == WORLD_OLD:
            reasons.append(f"PT_INTERP == {INTERP_OLD}")
        else:
            warnings.append(f"unrecognized PT_INTERP: {elf.interp}")

    # 主规则：e_flags 优先；PT_INTERP 作为辅助/兜底
    if flag_world == WORLD_NEW:
        if interp_world in (None, WORLD_NEW):
            return Detection(
                target=path,
                kind="binary",
                world=WORLD_NEW,
                confidence=CONF_HIGH,
                reasons=reasons,
                warnings=warnings,
                details={"elf": asdict(elf)},
            )
        else:
            warnings.append("e_flags says new but PT_INTERP says old; binary looks inconsistent")
            return Detection(
                target=path,
                kind="binary",
                world=WORLD_CONFLICT,
                confidence=CONF_LOW,
                reasons=reasons,
                warnings=warnings,
                details={"elf": asdict(elf)},
            )

    if flag_world == WORLD_OLD:
        if interp_world == WORLD_OLD:
            return Detection(
                target=path,
                kind="binary",
                world=WORLD_OLD,
                confidence=CONF_HIGH,
                reasons=reasons,
                warnings=warnings,
                details={"elf": asdict(elf)},
            )
        if interp_world == WORLD_NEW:
            warnings.append(
                "e_flags is OBJ-v0 but PT_INTERP is new-world; likely an early new-world binary built before OBJ-v1 became common"
            )
            return Detection(
                target=path,
                kind="binary",
                world=WORLD_NEW,
                confidence=CONF_MEDIUM,
                reasons=reasons,
                warnings=warnings,
                details={"elf": asdict(elf)},
            )
        return Detection(
            target=path,
            kind="binary",
            world=WORLD_OLD,
            confidence=flag_conf,
            reasons=reasons,
            warnings=warnings,
            details={"elf": asdict(elf)},
        )

    # 没有有效 e_flags 时，退化到 PT_INTERP
    if interp_world == WORLD_NEW:
        return Detection(
            target=path,
            kind="binary",
            world=WORLD_NEW,
            confidence=CONF_MEDIUM,
            reasons=reasons,
            warnings=warnings,
            details={"elf": asdict(elf)},
        )
    if interp_world == WORLD_OLD:
        return Detection(
            target=path,
            kind="binary",
            world=WORLD_OLD,
            confidence=CONF_MEDIUM,
            reasons=reasons,
            warnings=warnings,
            details={"elf": asdict(elf)},
        )

    warnings.append("insufficient evidence from both e_flags and PT_INTERP")
    return Detection(
        target=path,
        kind="binary",
        world=WORLD_UNKNOWN,
        confidence=CONF_LOW,
        reasons=reasons,
        warnings=warnings,
        details={"elf": asdict(elf)},
    )

def detect_userland_world(sample_paths: Optional[List[str]] = None) -> Detection:
    sample_paths = sample_paths or SYSTEM_SAMPLE_CANDIDATES

    samples = []
    for path in sample_paths:
        if not _exists_regular(path):
            continue
        d = detect_binary_world(path)
        samples.append(
            {
                "path": path,
                "world": d.world,
                "confidence": d.confidence,
                "reasons": d.reasons,
                "warnings": d.warnings,
            }
        )

    worlds = [x["world"] for x in samples if x["world"] in (WORLD_NEW, WORLD_OLD)]
    reasons = []
    warnings = []

    if not samples:
        return Detection(
            target="current-system-userland",
            kind="userland",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=[],
            warnings=["no sample binaries found"],
            details={"samples": samples},
        )

    if not worlds:
        warnings.append("no conclusive host-native LoongArch samples found")
        return Detection(
            target="current-system-userland",
            kind="userland",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=reasons,
            warnings=warnings,
            details={"samples": samples},
        )

    count = Counter(worlds)

    if len(count) == 1:
        world = worlds[0]
        n = count[world]
        conf = CONF_HIGH if n >= 3 else CONF_MEDIUM
        reasons.append(f"{n} host-native samples agree on {world}")
        return Detection(
            target="current-system-userland",
            kind="userland",
            world=world,
            confidence=conf,
            reasons=reasons,
            warnings=warnings,
            details={"samples": samples, "counts": dict(count)},
        )

    warnings.append("host-native samples disagree; system appears mixed or compatibility layer is involved")
    return Detection(
        target="current-system-userland",
        kind="userland",
        world=WORLD_MIXED,
        confidence=CONF_MEDIUM,
        reasons=["sampled host binaries do not agree"],
        warnings=warnings,
        details={"samples": samples, "counts": dict(count)},
    )

def _checksum_ok(blob: bytes, length: int) -> bool:
    if length <= 0 or len(blob) < length:
        return False
    return (sum(blob[:length]) & 0xFF) == 0

def parse_smbios_entry_point(path: str = "/sys/firmware/dmi/tables/smbios_entry_point") -> Dict[str, Any]:
    if not os.path.exists(path):
        return {"ok": False, "error": f"{path} not found"}

    try:
        with open(path, "rb") as f:
            data = f.read()
    except Exception as e:
        return {"ok": False, "error": str(e)}

    if data.startswith(b"_SM3_"):
        if len(data) < 24:
            return {"ok": False, "error": "SMBIOS3 entry point too short"}
        length = data[6]
        addr = struct.unpack_from("<Q", data, 16)[0]
        major = data[7]
        minor = data[8]
        return {
            "ok": True,
            "format": "SMBIOS3",
            "major": major,
            "minor": minor,
            "entry_length": length,
            "checksum_ok": _checksum_ok(data, length),
            "table_address": addr,
            "table_address_hex": f"0x{addr:016x}",
        }

    if data.startswith(b"_SM_"):
        if len(data) < 31:
            return {"ok": False, "error": "SMBIOS2 entry point too short"}
        length = data[5]
        addr = struct.unpack_from("<I", data, 24)[0]
        major = data[6]
        minor = data[7]
        return {
            "ok": True,
            "format": "SMBIOS2",
            "major": major,
            "minor": minor,
            "entry_length": length,
            "checksum_ok": _checksum_ok(data, length),
            "table_address": addr,
            "table_address_hex": f"0x{addr:08x}",
        }

    return {"ok": False, "error": "unknown SMBIOS entry point format"}

def classify_firmware_from_smbios() -> Detection:
    info = parse_smbios_entry_point()

    if not info.get("ok"):
        return Detection(
            target="current-firmware",
            kind="firmware",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=[],
            warnings=[info.get("error", "cannot read SMBIOS entry point")],
            details={"smbios_entry_point": info},
        )

    addr = info.get("table_address")
    reasons = []
    warnings = []

    if not isinstance(addr, int) or addr == 0:
        warnings.append("SMBIOS table address missing or zero")
        return Detection(
            target="current-firmware",
            kind="firmware",
            world=WORLD_UNKNOWN,
            confidence=CONF_LOW,
            reasons=reasons,
            warnings=warnings,
            details={"smbios_entry_point": info},
        )

    top_nibble = (addr >> 60) & 0xF

    # 旧世界典型特征：0x9... DMW 虚拟地址
    if top_nibble == 0x9:
        reasons.append("SMBIOS table address starts with 0x9..., matching old-world DMW virtual address style")
        return Detection(
            target="current-firmware",
            kind="firmware",
            world=WORLD_OLD,
            confidence=CONF_HIGH,
            reasons=reasons,
            warnings=warnings,
            details={"smbios_entry_point": info},
        )

    # 新世界典型特征：物理地址。这里保守一些，只把“低地址且不是 0x9...”认作新世界。
    if addr < (1 << 52):
        reasons.append("SMBIOS table address looks like a low physical address, matching new-world firmware style")
        return Detection(
            target="current-firmware",
            kind="firmware",
            world=WORLD_NEW,
            confidence=CONF_MEDIUM,
            reasons=reasons,
            warnings=warnings,
            details={"smbios_entry_point": info},
        )

    warnings.append("SMBIOS table address is neither 0x9... nor a clearly low physical address")
    return Detection(
        target="current-firmware",
        kind="firmware",
        world=WORLD_UNKNOWN,
        confidence=CONF_LOW,
        reasons=reasons,
        warnings=warnings,
        details={"smbios_entry_point": info},
    )

def summarize_overall(userland: Optional[Detection], firmware: Optional[Detection]) -> Dict[str, Any]:
    candidates = []
    notes = []

    if userland is not None:
        if userland.world == WORLD_MIXED:
            return {
                "world": WORLD_MIXED,
                "confidence": userland.confidence,
                "notes": ["userland itself is mixed; do not compress into a single new/old verdict"],
            }
        if userland.world in (WORLD_NEW, WORLD_OLD):
            candidates.append(("userland", userland.world, userland.confidence))

    if firmware is not None and firmware.world in (WORLD_NEW, WORLD_OLD):
        candidates.append(("firmware", firmware.world, firmware.confidence))

    if not candidates:
        return {
            "world": WORLD_UNKNOWN,
            "confidence": CONF_LOW,
            "notes": ["no conclusive userland/firmware verdict available"],
        }

    worlds = {x[1] for x in candidates}
    if len(worlds) == 1:
        world = next(iter(worlds))
        conf = CONF_HIGH if any(x[2] == CONF_HIGH for x in candidates) else CONF_MEDIUM
        return {
            "world": world,
            "confidence": conf,
            "notes": [f"all available layers agree on {world}"],
        }

    return {
        "world": WORLD_MIXED,
        "confidence": CONF_MEDIUM,
        "notes": ["userland and firmware disagree; machine is in a mixed transition/compatibility state"],
    }

def build_report(paths: List[str], detect_system: bool, detect_firmware: bool) -> Dict[str, Any]:
    report: Dict[str, Any] = {
        "schema_version": 1,
        "binary_detections": [],
        "system_userland": None,
        "firmware": None,
        "overall": None,
        "notes": [
            "e_flags is primary evidence for ELF binaries",
            "PT_INTERP is secondary evidence and only applies to dynamic glibc executables",
            "system userland is sampled from host-native binaries, not from the current process itself",
            "firmware verdict is separate from userland verdict",
        ],
    }

    for path in paths:
        report["binary_detections"].append(asdict(detect_binary_world(path)))

    userland_det = detect_userland_world() if detect_system else None
    firmware_det = classify_firmware_from_smbios() if detect_firmware else None

    if userland_det is not None:
        report["system_userland"] = asdict(userland_det)
    if firmware_det is not None:
        report["firmware"] = asdict(firmware_det)

    report["overall"] = summarize_overall(userland_det, firmware_det)
    return report

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Detect whether LoongArch binaries / system / firmware are new-world or old-world."
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="ELF files to inspect, e.g. /bin/ls /usr/bin/bash ./a.out",
    )
    parser.add_argument(
        "--no-system",
        action="store_true",
        help="Do not inspect current system userland",
    )
    parser.add_argument(
        "--no-firmware",
        action="store_true",
        help="Do not inspect current firmware via SMBIOS entry point",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print JSON",
    )

    args = parser.parse_args()

    report = build_report(
        paths=args.paths,
        detect_system=not args.no_system,
        detect_firmware=not args.no_firmware,
    )

    if args.pretty:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=False))
    else:
        print(json.dumps(report, ensure_ascii=False, separators=(",", ":")))

    return 0

if __name__ == "__main__":
    raise SystemExit(main())