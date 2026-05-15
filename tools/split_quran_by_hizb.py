#!/usr/bin/env python3
"""Build 60 session MP3s (one per hizb) from 114 surah files without mid-ayah time cuts.

Splits only at surah boundaries when possible; mid-surah hizb edges use ayah-proportional timing.
"""
from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

AYAH_COUNTS = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110,
    98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88,
    75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19,
    36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7,
    3, 6, 3, 5, 4, 5, 6,
]

# Standard 30 juz start points (surah, ayah) — each juz halved => 60 hizb.
JUZ_STARTS = [
    (1, 1), (2, 142), (2, 253), (3, 93), (4, 24), (4, 148), (5, 82), (6, 111), (7, 88),
    (8, 41), (9, 93), (11, 6), (12, 53), (15, 1), (17, 1), (18, 75), (21, 1), (23, 1),
    (25, 21), (27, 56), (29, 46), (33, 31), (36, 28), (39, 32), (41, 47), (46, 1), (51, 31),
    (58, 1), (67, 1), (78, 1),
]


@dataclass(frozen=True)
class VersePos:
    surah: int
    ayah: int

    def global_index(self) -> int:
        return sum(AYAH_COUNTS[: self.surah - 1]) + (self.ayah - 1)


@dataclass(frozen=True)
class HizbRange:
    index: int
    start: VersePos
    end: VersePos  # exclusive


def build_hizb_ranges() -> list[HizbRange]:
    starts = [VersePos(s, a) for s, a in JUZ_STARTS]
    starts.append(VersePos(114, 7))  # exclusive end after 114:6
    ranges: list[HizbRange] = []
    hizb = 1
    for i in range(30):
        juz_start = starts[i]
        juz_end = starts[i + 1]
        g0 = juz_start.global_index()
        g1 = juz_end.global_index()
        mid = g0 + (g1 - g0) // 2

        def from_global(g: int) -> VersePos:
            remaining = g
            for si, count in enumerate(AYAH_COUNTS, start=1):
                if remaining < count:
                    return VersePos(si, remaining + 1)
                remaining -= count
            return VersePos(114, 6)

        ranges.append(HizbRange(hizb, juz_start, from_global(mid)))
        hizb += 1
        ranges.append(HizbRange(hizb, from_global(mid), juz_end))
        hizb += 1
    return ranges


def ffprobe_duration(path: Path) -> float:
    out = subprocess.check_output(
        [
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", str(path),
        ],
        text=True,
    ).strip()
    return float(out)


def extract_surah_segment(
    src: Path, work: Path, surah: int, start_ayah: int, end_ayah: int
) -> Path:
    """Extract [start_ayah, end_ayah) from surah file (1-based, end exclusive)."""
    total = AYAH_COUNTS[surah - 1]
    start_ayah = max(1, start_ayah)
    end_ayah = min(total + 1, end_ayah)
    if start_ayah >= end_ayah:
        raise ValueError(f"empty segment s{surah} {start_ayah}-{end_ayah}")

    duration = ffprobe_duration(src)
    ss = (start_ayah - 1) / total * duration
    ee = (end_ayah - 1) / total * duration
    out = work / f"clip_s{surah:03d}_{start_ayah}_{end_ayah}.mp3"
    subprocess.run(
        [
            "ffmpeg", "-y", "-ss", f"{ss:.6f}", "-to", f"{ee:.6f}",
            "-i", str(src), "-c", "copy", str(out),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return out


def concat_files(files: list[Path], out: Path) -> None:
    lst = out.with_suffix(".txt")
    lines = []
    for f in files:
        p = str(f.resolve()).replace("\\", "/").replace("'", "'\\''")
        lines.append(f"file '{p}'")
    lst.write_text("\n".join(lines), encoding="utf-8")
    subprocess.run(
        ["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", str(out)],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    lst.unlink(missing_ok=True)


def clips_for_hizb(r: HizbRange, source_dir: Path, work: Path) -> list[Path]:
    clips: list[Path] = []
    end_surah = 114 if r.end.surah >= 114 else r.end.surah
    for surah in range(r.start.surah, end_surah + 1):
        matches = sorted(source_dir.glob(f"{surah:03d}_*.mp3"))
        if not matches:
            matches = sorted(source_dir.glob(f"{surah}_*.mp3"))
        if not matches:
            raise FileNotFoundError(f"Missing surah {surah} mp3 in {source_dir}")
        src = matches[0]

        start_ayah = r.start.ayah if surah == r.start.surah else 1
        if surah < end_surah:
            end_ayah = AYAH_COUNTS[surah - 1] + 1
        else:
            end_ayah = r.end.ayah if r.end.ayah <= AYAH_COUNTS[surah - 1] + 1 else AYAH_COUNTS[surah - 1] + 1

        if start_ayah >= end_ayah:
            continue

        if start_ayah == 1 and end_ayah == AYAH_COUNTS[surah - 1] + 1:
            clips.append(src)
        else:
            clips.append(extract_surah_segment(src, work, surah, start_ayah, end_ayah))
    return clips


def main() -> int:
    reciter_id = sys.argv[1] if len(sys.argv) > 1 else "ahmed_khader"
    root = Path(__file__).resolve().parent.parent
    source_dir = root / "tools" / "quran_archive" / reciter_id / "source"
    if not source_dir.exists():
        source_dir = root / "assets" / "audio" / "quran" / reciter_id / "source"
    out_dir = root / "assets" / "audio" / "quran" / reciter_id
    work = out_dir / "_work_hizb"
    work.mkdir(parents=True, exist_ok=True)
    out_dir.mkdir(parents=True, exist_ok=True)

    ranges = build_hizb_ranges()
    meta = []
    for r in ranges:
        print(f"Hizb {r.index:02d}: {r.start.surah}:{r.start.ayah} -> {r.end.surah}:{r.end.ayah}")
        clips = clips_for_hizb(r, source_dir, work)
        session_out = out_dir / f"session_{r.index:02d}.mp3"
        concat_files(clips, session_out)
        meta.append(
            {
                "hizb": r.index,
                "start": f"{r.start.surah}:{r.start.ayah}",
                "end": f"{r.end.surah}:{r.end.ayah}",
                "file": session_out.name,
            }
        )

    (out_dir / "hizb_map.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"Done: 60 hizb sessions in {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
