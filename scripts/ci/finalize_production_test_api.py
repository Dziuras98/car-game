from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS_ROOT = ROOT / "scripts"


def normalize_transmission_assignments() -> int:
    changed = 0
    assignment_pattern = re.compile(
        r"(?m)^(?P<indent>\s*)(?P<target>[A-Za-z_][A-Za-z0-9_]*)\.transmission_type = CarSpecs\.TransmissionType\.(?P<first>[A-Z_]+)\n"
        r"(?P=indent)(?P=target)\.transmission_type = CarSpecs\.TransmissionType\.(?P<second>[A-Z_]+)$"
    )
    for path in sorted(SCRIPTS_ROOT.rglob("*.gd")):
        text = path.read_text(encoding="utf-8")

        def keep_final_meaning(match: re.Match[str]) -> str:
            first = match.group("first")
            second = match.group("second")
            if first == "MANUAL" and second == "DIRECT_DRIVE":
                selected = "MANUAL"
            elif first == "DIRECT_DRIVE" and second == "AUTOMATIC":
                selected = "AUTOMATIC"
            else:
                selected = second
            return (
                f'{match.group("indent")}{match.group("target")}.transmission_type = '
                f'CarSpecs.TransmissionType.{selected}'
            )

        updated = assignment_pattern.sub(keep_final_meaning, text)
        updated = updated.replace("compatibility setters resolve to the last selected transmission mode", "enum assignment selects exactly one transmission mode")
        updated = updated.replace("compatibility setter selects automatic mode", "enum assignment selects automatic mode")
        updated = updated.replace("compatibility setter cannot leave both modes active", "enum state cannot expose both transmission modes")
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
    return changed


def main() -> None:
    changed = normalize_transmission_assignments()
    print(f"Normalized enum-only transmission setup in {changed} files")


if __name__ == "__main__":
    main()
