#!/usr/bin/env bash
# Install Waykin skill pack into Grok Build discovery paths.
# Works for every collaborator (Daniel, Prabu / prabu-openclaw, agents).
#
# Usage:
#   ./skills/install.sh              # user + repo
#   ./skills/install.sh --user-only  # ~/.grok/skills only
#   ./skills/install.sh --repo-only  # .grok/skills only (committed for team)
#   ./skills/install.sh --check      # verify install without writing
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

copy_tree() {
  local src="$1"
  local dest="$2"
  mkdir -p "${dest}"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude '.DS_Store' "${src}/" "${dest}/"
  else
    # Portable fallback (no rsync on some CI / minimal images)
    rm -rf "${dest}"
    mkdir -p "${dest}"
    # shellcheck disable=SC2038
    (cd "${src}" && tar cf - .) | (cd "${dest}" && tar xf -)
  fi
}

install_one() {
  local name="$1"
  local dest_root="$2"
  local src="${SCRIPT_DIR}/${name}"
  local dest="${dest_root}/${name}"
  if [[ ! -f "${src}/SKILL.md" ]]; then
    echo "FAIL: missing ${src}/SKILL.md"
    return 1
  fi
  copy_tree "${src}" "${dest}"
  mkdir -p "${dest}/references"
  cp -f "${SCRIPT_DIR}/_shared/references/REPO_CONTEXT.md" \
    "${dest}/references/REPO_CONTEXT.md"
  # Ensure readable for all collaborators on shared machines
  chmod -R a+rX "${dest}" 2>/dev/null || true
  echo "installed: ${dest}"
}

check_one() {
  local name="$1"
  local dest_root="$2"
  local skill="${dest_root}/${name}/SKILL.md"
  local ctx="${dest_root}/${name}/references/REPO_CONTEXT.md"
  if [[ -f "${skill}" && -f "${ctx}" ]]; then
    if head -5 "${skill}" | grep -q "^name:[[:space:]]*${name}"; then
      echo "OK  ${dest_root}/${name}"
      return 0
    fi
  fi
  echo "MISSING_OR_INVALID ${dest_root}/${name}"
  return 1
}

if [[ "${MODE}" == "--check" ]]; then
  FAIL=0
  for root in "${USER_SKILLS}" "${REPO_SKILLS}"; do
    for s in "${SKILLS[@]}"; do
      check_one "${s}" "${root}" || FAIL=1
    done
  done
  exit "${FAIL}"
fi

case "${MODE}" in
  --user-only) TARGETS=("${USER_SKILLS}") ;;
  --repo-only) TARGETS=("${REPO_SKILLS}") ;;
  both|*) TARGETS=("${USER_SKILLS}" "${REPO_SKILLS}") ;;
esac

echo "=== Waykin skill pack install ==="
echo "user:   ${USER:-$(id -un 2>/dev/null || echo unknown)}"
echo "home:   ${HOME}"
echo "source: ${SCRIPT_DIR}"
echo "repo:   ${REPO_ROOT}"
echo "mode:   ${MODE}"

for root in "${TARGETS[@]}"; do
  mkdir -p "${root}"
  for s in "${SKILLS[@]}"; do
    install_one "${s}" "${root}"
  done
done

echo ""
echo "=== Discovery check ==="
FAIL=0
for s in "${SKILLS[@]}"; do
  ok=0
  for root in "${TARGETS[@]}"; do
    if [[ -f "${root}/${s}/SKILL.md" ]]; then
      ok=1
    fi
  done
  if [[ $ok -eq 1 ]]; then
    echo "OK  /${s}"
  else
    echo "MISSING ${s}"
    FAIL=1
  fi
done

echo ""
echo "Collaborators: after git pull, skills live in .grok/skills/ (tracked)."
echo "Optional personal install: ./skills/install.sh --user-only"
echo "Slash: /waykin-build /waykin-validate /waykin-ui-review ..."
exit "${FAIL}"
