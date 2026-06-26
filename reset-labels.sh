#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ORG="top-solution"
DRY_RUN=false

usage() {
  cat <<EOF
Usage: $0 [options] [org] [labels.json]

Batch-delete all labels in every repo of a GitHub org and recreate them
from a JSON file.

Arguments:
  org           GitHub organization name (default: $DEFAULT_ORG)
  labels.json   Path to the labels JSON file (default: labels.json)

Options:
  -h, --help    Show this help message and exit
  --dry-run     Show what would be done without making any changes

Examples:
  $0
  $0 my-org
  $0 my-org config/labels-prod.json
  $0 --dry-run my-org
EOF
}

# parse options and positional args
args=()
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    *)
      args+=("$arg")
      ;;
  esac
done

ORG="${args[0]:-$DEFAULT_ORG}"
LABELS_FILE="${args[1]:-labels.json}"

# fail early if gh is not authenticated
if ! gh auth status > /dev/null 2>&1; then
  echo "Error: gh is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

if [ ! -f "$LABELS_FILE" ]; then
  echo "Error: labels file '$LABELS_FILE' not found." >&2
  exit 1
fi

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] No changes will be made."
fi

repos=$(gh repo list "$ORG" --limit 1000 --json name -q '.[].name')

for repo in $repos; do
  echo "==> $repo"

  # delete all existing labels (handles names with spaces)
  gh label list -R "$ORG/$repo" --json name -q '.[].name' | while IFS= read -r l; do
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] would delete label: $l"
    else
      gh label delete "$l" -R "$ORG/$repo" --yes
    fi
  done

  # create new labels from the JSON file
  jq -c '.[]' "$LABELS_FILE" | while read -r row; do
    name=$(echo "$row" | jq -r '.name')
    color=$(echo "$row" | jq -r '.color')
    desc=$(echo "$row" | jq -r '.description')
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY RUN] would create label: $name (color: $color, desc: $desc)"
    else
      gh label create "$name" -R "$ORG/$repo" --color "$color" --description "$desc"
    fi
  done
done