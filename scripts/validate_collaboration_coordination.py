#!/usr/bin/env python3
"""Validate repository-native GitHub Project coordination artifacts."""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "docs/collaboration/GITHUB_PROJECT_COORDINATION.md",
    "docs/collaboration/ACTIVE_WORK.md",
    "AGENTS.md",
    ".github/ISSUE_TEMPLATE/agent-task.yml",
    ".github/ISSUE_TEMPLATE/validation-task.yml",
    ".github/ISSUE_TEMPLATE/defect.yml",
    ".github/pull_request_template.md",
    "scripts/sync_github_project.sh",
]
FIELDS = [
    "Execution Status", "Workstream", "Agent", "Agent Lane", "Priority", "Risk",
    "Dependency", "Base SHA", "Head SHA", "Handoff State", "Evidence",
]
PROHIBITED_AUTHORIZATIONS = [
    "multiplayer is authorized", "a marketplace is authorized", "creator sdk is authorized",
    "backend platform is authorized", "account system is authorized",
    "narrative engine is authorized", "ai gameplay runtime is authorized",
    "additional companions are authorized",
]


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def read(relative: str, errors: list[str]) -> str:
    path = ROOT / relative
    if not path.is_file():
        errors.append(f"missing file: {relative}")
        return ""
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    texts = {relative: read(relative, errors) for relative in REQUIRED_FILES}
    doc = texts[REQUIRED_FILES[0]]

    for field in FIELDS:
        require(errors, field in doc, f"coordination doc missing field: {field}")
    for token in ("agent_claim:", "frozen_paths_acknowledged", "dependency_state"):
        require(errors, token in doc, f"claim schema missing: {token}")
    for token in ("agent_handoff:", "head_sha:", "test_totals:", "handoff_state:"):
        require(errors, token in doc, f"handoff schema missing: {token}")

    combined = "\n".join(texts.values())
    require(errors, "https://github.com/users/scrimshawlife-ctrl/projects/1" in combined,
            "Project #1 URL is missing")
    require(errors, "https://github.com/scrimshawlife-ctrl/Waykin/issues/47" in combined,
            "Issue #47 URL is missing")

    required_template_ids = {
        ".github/ISSUE_TEMPLATE/agent-task.yml": [
            "outcome", "workstream", "agent_lane", "dependencies", "intended_paths",
            "frozen_paths", "acceptance_criteria", "required_validation", "non_goals",
            "evidence_boundary",
        ],
        ".github/ISSUE_TEMPLATE/validation-task.yml": [
            "implementation_dependency", "exact_build_or_sha", "environment",
            "protocol_scope", "observed_evidence", "inferred_evidence",
            "not_computable_fields", "pass_fail_exit_criteria",
        ],
        ".github/ISSUE_TEMPLATE/defect.yml": [
            "reproducible_behavior", "expected_behavior", "exact_sha", "environment",
            "reproduction_steps", "bounded_affected_surface", "evidence",
            "prohibited_opportunistic_expansion",
        ],
    }
    for path, ids in required_template_ids.items():
        for identifier in ids:
            require(errors, f"id: {identifier}" in texts[path],
                    f"{path} missing key: {identifier}")

    pr = texts[".github/pull_request_template.md"]
    for key in (
        "issue:", "agent:", "lane:", "base_sha:", "head_sha:", "workstream:",
        "dependency_state:", "handoff_state:", "evidence:", "Exact test total",
        "OBSERVED", "INFERRED", "Physical-Device Evidence Declaration",
    ):
        require(errors, key in pr, f"pull request template missing: {key}")

    lowered = combined.lower()
    for phrase in PROHIBITED_AUTHORIZATIONS:
        require(errors, phrase not in lowered, f"prohibited scope authorization: {phrase}")

    if errors:
        print("COLLABORATION_COORDINATION=FAIL")
        for error in errors:
            print(f"- {error}")
        return 1
    print("COLLABORATION_COORDINATION=PASS")
    print(f"FILES_CHECKED={len(REQUIRED_FILES)}")
    print(f"FIELDS_DOCUMENTED={len(FIELDS)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
