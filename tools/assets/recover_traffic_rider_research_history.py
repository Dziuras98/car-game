#!/usr/bin/env python3
"""Recover retained Traffic Rider research from every commit on the PR branch.

This tool is intentionally read-only with respect to Git history. It walks all
commits between the PR base and head, extracts every unique text version of
Traffic Rider model records and related data/code, and produces an artifact
that can be audited before canonical machine-readable migration.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_ROOT = REPOSITORY_ROOT / "artifacts/traffic_rider_research_history"
SNAPSHOT_ROOT = OUTPUT_ROOT / "snapshots"
MAX_TEXT_BYTES = 768 * 1024

TEXT_SUFFIXES = {
    ".md",
    ".txt",
    ".csv",
    ".data",
    ".json",
    ".gd",
    ".tres",
    ".tscn",
    ".yml",
    ".yaml",
    ".toml",
    ".ini",
}

PATH_TOKENS = (
    "traffic_rider",
    "docs/vehicles/traffic/",
    "bmw_4_series",
    "4_series_f32",
    "silverado",
    "renault_clio",
    "chevrolet_cruze",
    "ford_e150",
    "ford_excursion",
    "ford_f150",
    "transit_connect",
    "freelander",
    "golf_vii",
    "kia_ceed",
    "renault_maxity",
    "mazda_2",
    "mazda_3",
    "sprinter",
    "unimog",
    "nissan_atlas",
    "nissan_atleon",
    "octavia",
    "amarok",
)

PARAMETER_PATTERN = re.compile(
    r"(?i)(?:"
    r"engine|motor|power|torque|curve|rpm|idle|redline|limiter|governor|"
    r"transmission|gearbox|gear|ratio|reverse|final[ -]?drive|clutch|converter|lock[ -]?up|"
    r"mass|weight|kerb|curb|din|axle|payload|gvw|wheelbase|track|centre of mass|center of mass|"
    r"tyre|tire|wheel radius|rolling radius|drag|frontal area|cd\b|"
    r"acceleration|0.?100|top speed|braking|gradeability|"
    r"firing|collector|turbo|supercharger|audio|sound|"
    r"xdrive|haldex|4motion|awd|4wd|transfer case|differential|portal|battery|inverter|regenerative"
    r")"
)
NUMBER_PATTERN = re.compile(r"[-+]?\d+(?:[.,]\d+)?")


@dataclass(frozen=True)
class ChangedPath:
    status: str
    path: str
    previous_path: str | None = None


def run_git(*args: str, text: bool = True) -> str | bytes:
    result = subprocess.run(
        ["git", *args],
        cwd=REPOSITORY_ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=text,
    )
    return result.stdout


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def relevant_path(path: str) -> bool:
    normalized = path.replace("\\", "/").lower()
    suffix = Path(normalized).suffix
    return suffix in TEXT_SUFFIXES and any(token in normalized for token in PATH_TOKENS)


def changed_paths(commit_sha: str) -> list[ChangedPath]:
    output = str(run_git("diff-tree", "--root", "--no-commit-id", "--name-status", "-r", "-M", commit_sha))
    result: list[ChangedPath] = []
    for line in output.splitlines():
        fields = line.split("\t")
        if len(fields) < 2:
            continue
        status = fields[0]
        if status.startswith("R") or status.startswith("C"):
            if len(fields) >= 3:
                result.append(ChangedPath(status=status, path=fields[2], previous_path=fields[1]))
        else:
            result.append(ChangedPath(status=status, path=fields[1]))
    return result


def commit_metadata(commit_sha: str) -> dict[str, str]:
    separator = "\x1f"
    output = str(run_git("show", "-s", f"--format=%H{separator}%P{separator}%aI{separator}%s", commit_sha)).strip()
    fields = output.split(separator, 3)
    return {
        "sha": fields[0],
        "parents": fields[1].split() if len(fields) > 1 and fields[1] else [],
        "authored_at": fields[2] if len(fields) > 2 else "",
        "message": fields[3] if len(fields) > 3 else "",
    }


def file_bytes_at(commit_sha: str, path: str) -> bytes | None:
    try:
        return bytes(run_git("show", f"{commit_sha}:{path}", text=False))
    except subprocess.CalledProcessError:
        return None


def git_blob_sha(commit_sha: str, path: str) -> str:
    try:
        return str(run_git("rev-parse", f"{commit_sha}:{path}")).strip()
    except subprocess.CalledProcessError:
        return ""


def decode_text(content: bytes) -> str | None:
    if not content or len(content) > MAX_TEXT_BYTES or b"\x00" in content:
        return None
    for encoding in ("utf-8", "utf-8-sig", "cp1252"):
        try:
            return content.decode(encoding)
        except UnicodeDecodeError:
            continue
    return None


def parameter_hits(text: str, path: str, commit_sha: str) -> list[dict[str, object]]:
    hits: list[dict[str, object]] = []
    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        line = raw_line.strip()
        if not line or not PARAMETER_PATTERN.search(line) or not NUMBER_PATTERN.search(line):
            continue
        hits.append(
            {
                "commit_sha": commit_sha,
                "path": path,
                "line": line_number,
                "text": line[:500],
            }
        )
    return hits


def rev_list(base_sha: str, head_sha: str) -> list[str]:
    output = str(run_git("rev-list", "--reverse", "--ancestry-path", f"{base_sha}..{head_sha}"))
    return [line.strip() for line in output.splitlines() if line.strip()]


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    base_sha = os.environ.get("TRAFFIC_RIDER_BASE_SHA", "").strip()
    head_sha = os.environ.get("TRAFFIC_RIDER_HEAD_SHA", "HEAD").strip() or "HEAD"
    if not base_sha:
        raise SystemExit("TRAFFIC_RIDER_BASE_SHA is required")

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    SNAPSHOT_ROOT.mkdir(parents=True, exist_ok=True)

    commits = rev_list(base_sha, head_sha)
    commit_rows: list[dict[str, object]] = []
    version_rows: list[dict[str, object]] = []
    all_hits: list[dict[str, object]] = []
    stored_content_hashes: dict[str, str] = {}
    relevant_changed_paths = 0

    for index, commit_sha in enumerate(commits, start=1):
        metadata = commit_metadata(commit_sha)
        commit_changes: list[dict[str, str | None]] = []
        for changed in changed_paths(commit_sha):
            if not relevant_path(changed.path) and not (
                changed.previous_path and relevant_path(changed.previous_path)
            ):
                continue
            relevant_changed_paths += 1
            commit_changes.append(
                {
                    "status": changed.status,
                    "path": changed.path,
                    "previous_path": changed.previous_path,
                }
            )
            if changed.status.startswith("D") or not relevant_path(changed.path):
                continue
            content = file_bytes_at(commit_sha, changed.path)
            if content is None:
                continue
            text = decode_text(content)
            if text is None:
                continue
            content_sha256 = sha256_bytes(content)
            snapshot_relative = stored_content_hashes.get(content_sha256)
            if snapshot_relative is None:
                suffix = Path(changed.path).suffix or ".txt"
                snapshot_relative = f"snapshots/{content_sha256}{suffix}"
                snapshot_path = OUTPUT_ROOT / snapshot_relative
                snapshot_path.parent.mkdir(parents=True, exist_ok=True)
                snapshot_path.write_bytes(content)
                stored_content_hashes[content_sha256] = snapshot_relative
            hits = parameter_hits(text, changed.path, commit_sha)
            all_hits.extend(hits)
            version_rows.append(
                {
                    "commit_index": index,
                    "commit_sha": commit_sha,
                    "commit_message": metadata["message"],
                    "authored_at": metadata["authored_at"],
                    "path": changed.path,
                    "previous_path": changed.previous_path,
                    "change_status": changed.status,
                    "git_blob_sha": git_blob_sha(commit_sha, changed.path),
                    "content_sha256": content_sha256,
                    "size_bytes": len(content),
                    "snapshot": snapshot_relative,
                    "parameter_hit_count": len(hits),
                }
            )
        commit_rows.append({**metadata, "index": index, "relevant_changes": commit_changes})
        print(
            f"[{index:03d}/{len(commits):03d}] {commit_sha[:12]} "
            f"{metadata['message']} — {len(commit_changes)} relevant change(s)"
        )

    summary = {
        "generator": "tools/assets/recover_traffic_rider_research_history.py",
        "base_sha": base_sha,
        "head_sha": str(run_git("rev-parse", head_sha)).strip(),
        "commit_count": len(commits),
        "relevant_changed_path_count": relevant_changed_paths,
        "text_version_count": len(version_rows),
        "unique_snapshot_count": len(stored_content_hashes),
        "parameter_hit_count": len(all_hits),
    }
    write_json(OUTPUT_ROOT / "summary.json", summary)
    write_json(OUTPUT_ROOT / "commits.json", commit_rows)
    write_json(OUTPUT_ROOT / "versions.json", version_rows)
    write_json(OUTPUT_ROOT / "parameter_hits.json", all_hits)
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
