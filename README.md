# GitHub Org Labels batch update

Script to batch-delete all existing labels in the repositories of a GitHub organization and recreate them based on a standard configuration defined in a local JSON file.

## Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) installed
- [`jq`](https://jqlang.github.io/jq/) installed
- An active `gh` authentication with sufficient permissions on the org (`repo` scope, plus `admin:org` if you need to read private repos/org settings)

### Authentication

```bash
gh auth login
```

If you already have a `GITHUB_TOKEN` environment variable set, `gh` will use it automatically instead of the interactive login. To use the credentials saved by `gh auth login` instead:

```bash
unset GITHUB_TOKEN
gh auth login
```

Check authentication status with:

```bash
gh auth status
```

The script also checks this automatically at startup and will fail with an error if `gh` is not authenticated.

## Labels file

Create a `labels.json` file (or any name you prefer) with the list of desired labels:

```json
[
  { "name": "bug", "color": "d73a4a", "description": "Something isn't working" },
  { "name": "enhancement", "color": "a2eeef", "description": "New feature or request" },
  { "name": "Low Priority", "color": "cfd3d7", "description": "Low priority issue" }
]
```

## Usage

```bash
chmod +x reset-labels.sh
./reset-labels.sh [options] [org] [labels.json]
```

- `[org]` — GitHub organization name (optional, default: `top-solution`)
- `[labels.json]` — path to the JSON file with the labels (optional, default: `labels.json` in the current directory)

### Options

- `-h`, `--help` — show usage and exit
- `--dry-run` — show what would be deleted/created without making any actual changes

### Examples

```bash
# use default org (top-solution) and labels.json in the current directory
./reset-labels.sh

# specify a different org
./reset-labels.sh my-org

# use a different JSON file
./reset-labels.sh my-org config/labels-prod.json

# preview changes without applying them
./reset-labels.sh --dry-run my-org

# show help
./reset-labels.sh -h
```

## What the script does

For each repository in the organization:

1. Deletes **all** existing labels in the repo
2. Creates the new labels read from the JSON file

With `--dry-run`, the script only prints what it *would* delete and create, without performing any actual changes.

## ⚠️ Warning

- This operation is **destructive**: deleting labels also removes their association with issues/PRs that used them.
- The script iterates over **all** repositories in the org (limit 1000). For orgs with many repos, consider adding a `sleep` between iterations to avoid hitting GitHub's API rate limit.
- Recommended: run with `--dry-run` first, or test on a single repo / staging org, before running the script for real in production.
