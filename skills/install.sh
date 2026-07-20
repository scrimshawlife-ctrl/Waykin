#!/usr/bin/env bash
# Install Waykin skill pack into Grok Build discovery paths.
# Usage: ./skills/install.sh [--user-only] [--repo-only]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
USER_SKILLS="${HOME}/.grok/skills"
REPO_SKILLS="${REPO_ROOT}/.grok/skills"
MODE="${1:-both}"

SKILLS=(
  waykin-build
  waykin-validate
  waykin-ui-review
  waykin-device-testing
  waykin-ar-debug
  waykin-audio
  waykin-healthkit
  waykin-performance
  waykin-pr-review
  waykin-release
)

install_one() {
  local name="$1"
  local dest_root="$2"
  local src="${SCRIPT_DIR}/${name}"
  local dest="${dest_root}/${name}"
  if [[ ! -f "${src}/SKILL.md" ]]; then
    echo "FAIL: missing ${src}/SKILL.md"
    return 1
  fi
  mkdir -p "${dest}"
  # Copy skill tree
  rsync -a --delete \
    --exclude '.DS_Store' \
    "${src}/" "${dest}/"
  # Embed shared repo context for offline skill use
  mkdir -p "${dest}/references"
  cp -f "${SCRIPT_DIR}/_shared/references/REPO_CONTEXT.md" \
    "${dest}/references/REPO_CONTEXT.md"
  echo "installed: ${dest}"
}

case "${MODE}" in
  --user-only) TARGETS=("${USER_SKILLS}") ;;
  --repo-only) TARGETS=("${REPO_SKILLS}") ;;
  both|*) TARGETS=("${USER_SKILLS}" "${REPO_SKILLS}") ;;
esac

echo "=== Waykin skill pack install ==="
echo "source: ${SCRIPT_DIR}"
echo "repo:   ${REPO_ROOT}"

for root in "${TARGETS[@]}"; do
  mkdir -p "${root}"
  for s in "${SKILLS[@]}"; do
    install_one "${s}" "${root}"
  done
done

echo ""
echo "=== Discovery check ==="
for s in "${SKILLS[@]}"; do
  ok=0
  for root in "${TARGETS[@]}"; do
    if [[ -f "${root}/${s}/SKILL.md" ]]; then
      ok=1
      # minimal frontmatter check
      if ! head -5 "${root}/${s}/SKILL.md" | grep -q "^name:"; then
        echo "WARN: ${root}/${s}/SKILL.md missing name frontmatter"
      fi
    fi
  done
  if [[ $ok -eq 1 ]]; then
    echo "OK  /${s}"
  else
    echo "MISSING ${s}"
  fi
done

echo ""
echo "Skills should appear as /waykin-* within a few seconds (Grok auto-reloads)."
echo "Invoke e.g. /waykin-validate or ask: run Waykin validate skill"
