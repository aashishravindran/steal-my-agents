#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$REPO_DIR/agents"

# ── Banner ──────────────────────────────────────────────────────────────────
echo ""
echo "  steal-my-agents installer"
echo "  Claude Code custom agents"
echo "────────────────────────────────────────────"
echo ""

# ── Choose install target ────────────────────────────────────────────────────
echo "Where do you want to install?"
echo "  [1] Global  (~/.claude/agents/)   — available in every project"
echo "  [2] Local   (./.claude/agents/)   — available in current directory only"
echo ""
read -rp "Choice [1/2, default=1]: " target_choice
target_choice="${target_choice:-1}"

if [[ "$target_choice" == "2" ]]; then
  TARGET_DIR="$(pwd)/.claude/agents"
  echo "  -> Installing into $(pwd)/.claude/agents/"
else
  TARGET_DIR="$HOME/.claude/agents"
  echo "  -> Installing into ~/.claude/agents/"
fi
echo ""

# ── Discover available agents ────────────────────────────────────────────────
agent_files=()
while IFS= read -r -d '' f; do
  agent_files+=("$f")
done < <(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' -print0 2>/dev/null | sort -z)

if [[ ${#agent_files[@]} -eq 0 ]]; then
  echo "No agents found in $AGENTS_DIR"
  exit 1
fi

echo "Available agents:"
echo ""
declare -a agent_names
declare -a agent_descs
for i in "${!agent_files[@]}"; do
  f="${agent_files[$i]}"
  # Extract name: from YAML frontmatter
  name=$(awk '/^---/{p++} p==1 && /^name:/{gsub(/^name:[[:space:]]*/, ""); print; exit}' "$f")
  name="${name:-$(basename "$f" .md)}"
  # Extract first sentence of description
  desc=$(awk '/^---/{p++} p==1 && /^description:/{
    gsub(/^description:[[:space:]]*"?/, "")
    gsub(/"$/, "")
    # grab up to first period or newline
    match($0, /[^.]+\./)
    if (RSTART) print substr($0, RSTART, RLENGTH)
    else print substr($0, 1, 80)
    exit
  }' "$f")
  agent_names+=("$name")
  agent_descs+=("$desc")
  printf "  [%d] %-25s %s\n" "$((i+1))" "$name" "$desc"
done

echo ""
read -rp "Which agents? (numbers separated by spaces, or Enter for ALL): " selection
echo ""

# ── Build list of chosen indices ─────────────────────────────────────────────
declare -a chosen_indices
if [[ -z "$selection" ]]; then
  for i in "${!agent_files[@]}"; do
    chosen_indices+=("$i")
  done
else
  for token in $selection; do
    idx=$((token - 1))
    if [[ $idx -ge 0 && $idx -lt ${#agent_files[@]} ]]; then
      chosen_indices+=("$idx")
    else
      echo "  Warning: '$token' is out of range, skipping."
    fi
  done
fi

if [[ ${#chosen_indices[@]} -eq 0 ]]; then
  echo "Nothing to install."
  exit 0
fi

# ── Install ──────────────────────────────────────────────────────────────────
mkdir -p "$TARGET_DIR"
installed=0
skipped=0
overwritten=0

for idx in "${chosen_indices[@]}"; do
  src="${agent_files[$idx]}"
  name="${agent_names[$idx]}"
  dest="$TARGET_DIR/$(basename "$src")"

  if [[ -f "$dest" ]]; then
    if diff -q "$src" "$dest" > /dev/null 2>&1; then
      echo "  SKIP  $name  (already installed, identical)"
      ((skipped++)) || true
      continue
    else
      read -rp "  $name already exists and differs. Overwrite? [y/N]: " ow
      if [[ "${ow,,}" != "y" ]]; then
        echo "  SKIP  $name"
        ((skipped++)) || true
        continue
      fi
      cp "$src" "$dest"
      echo "  OVERWRITE  $name  -> $dest"
      ((overwritten++)) || true
      continue
    fi
  fi

  cp "$src" "$dest"
  echo "  INSTALL  $name  -> $dest"
  ((installed++)) || true
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────"
echo "  Done."
[[ $installed  -gt 0 ]] && echo "  Installed:   $installed agent(s)"
[[ $overwritten -gt 0 ]] && echo "  Overwritten: $overwritten agent(s)"
[[ $skipped    -gt 0 ]] && echo "  Skipped:     $skipped agent(s)"
echo ""
echo "  Restart Claude Code to pick up new agents."
echo ""
