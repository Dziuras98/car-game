#!/usr/bin/env python3
"""Run Traffic Rider research recovery across all non-base PR ancestors."""

from __future__ import annotations

import recover_traffic_rider_research_history as recovery


def full_rev_list(base_sha: str, head_sha: str) -> list[str]:
    output = str(recovery.run_git("rev-list", "--reverse", f"{base_sha}..{head_sha}"))
    return [line.strip() for line in output.splitlines() if line.strip()]


recovery.rev_list = full_rev_list

if __name__ == "__main__":
    recovery.main()
