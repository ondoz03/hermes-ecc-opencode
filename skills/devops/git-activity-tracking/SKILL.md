---
name: git-activity-tracking
description: 'Track git push activity via post-push hooks and deliver daily summaries via Hermes cron.'
tags: [git, cron, hooks, tracking, productivity, hermes]
---

# Git Activity Tracking — Daily Push Summaries

Set up automatic recording of git pushes and daily delivery of a human-readable summary via Hermes cron.

Useful for:
- Keeping a log of what you shipped each day without manual note-taking
- Remote team standup prep
- Future integration with project management tools (ClickUp, Linear, Jira)

## Architecture

```
git push
   ↓
post-push hook (~/.config/git/hooks/post-push)
   ↓
appends to log file: ~/.hermes/hermes-agent/cron/output/git-activity.log
   ↓
Hermes cron job (daily at 17:00)
   ↓
reads today's log entries → generates summary → delivers to Telegram (origin)
```

## Setup

### 1. Create Global Git Hooks Directory

```bash
mkdir -p ~/.config/git/hooks
git config --global core.hooksPath "$HOME/.config/git/hooks"
```

### 2. Create the post-push Hook

Write `~/.config/git/hooks/post-push`:

```bash
#!/bin/bash
# Git post-push hook — logs push activity for daily summary

LOG_FILE="$HOME/.hermes/hermes-agent/cron/output/git-activity.log"
mkdir -p "$(dirname "$LOG_FILE")"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

while read local_ref local_sha remote_ref remote_sha
do
    # Skip deletions (local_sha = 000...)
    if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
        continue
    fi

    REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
    BRANCH=$(echo "$remote_ref" | sed 's|refs/heads/||')

    # Get new commits being pushed
    if [ "$remote_sha" != "0000000000000000000000000000000000000000" ]; then
        COMMITS=$(git log --oneline "$remote_sha..$local_sha" 2>/dev/null)
    else
        # New branch — get all commits
        COMMITS=$(git log --oneline "$local_sha" 2>/dev/null | head -20)
    fi

    if [ -n "$REPO" ]; then
        {
            echo "[$TIMESTAMP] repo=$REPO branch=$BRANCH"
            if [ -n "$COMMITS" ]; then
                echo "Commits:"
                echo "$COMMITS"
            fi
            echo "---"
        } >> "$LOG_FILE"
    fi
done
```

Make it executable:

```bash
chmod +x ~/.config/git/hooks/post-push
```

### 3. Create the Daily Summary Cron Job

```bash
hermes cron create \
  --name "Daily Git Push Summary" \
  --schedule "0 17 * * *" \
  --deliver origin \
  --prompt 'Baca file /home/who/.hermes/hermes-agent/cron/output/git-activity.log dan buat ringkasan aktivitas push GIT hari ini (tanggal hari ini) dalam Bahasa Indonesia.

Format ringkasan:
- Kelompokkan per repository
- Untuk tiap repo: sebut branch, jumlah commit, dan daftar commit message
- Jika tidak ada aktivitas hari ini, bilang aja "Tidak ada push hari ini"

Kirim hasil ringkasan ke user. Tandai summary dengan judul "📊 Daily Git Summary - [tanggal]".'
```

Alternatively, use the cronjob tool directly with:

```json
{
  "action": "create",
  "name": "Daily Git Push Summary",
  "schedule": "0 17 * * *",
  "deliver": "origin",
  "prompt": "Baca file ... dan buat ringkasan ..."
}
```

## How It Works

1. Every `git push` triggers the **post-push hook**
2. The hook reads the refspec from stdin (format: `local_ref local_sha remote_ref remote_sha`)
3. It diffs the old remote SHA against the new local SHA → captures commit messages
4. Appends a structured log entry: `[timestamp] repo=xxx branch=yyy` + commit list
5. At 17:00 daily, the **cron job** reads the log for today's entries
6. The cron agent groups by repo, counts commits, and writes a Telegram summary
7. Log file accumulates across days — the cron job only reads current-date entries

## Future Enhancements

- **ClickUp / Linear integration**: Replace the cron prompt with a script that calls the ClickUp/Linear API to create tasks from push activity
- **Per-project filtering**: Only track specific repos by checking REPO against a whitelist in the hook
- **Per-project TERAX.md / AGENTS.md**: If projects have their own agent context files, the hook could also append an agent-readable summary
- **Notifications on push failure**: Extend the hook to also capture failed pushes (non-zero exit from git push) and alert the user

## Pitfalls

- **sudo unavailable in hooks**: The global hooks path at `~/.config/git/hooks` uses the user's git config — no sudo needed. If `core.hooksPath` is set system-wide, the user-level path may be ignored.
- **Existing hooksPath**: If the user already has a global hooks path configured, the post-push hook should be added to that existing directory instead.
- **Log file growth**: The log file grows unbounded. Add logrotate or a cron job to archive/truncate entries older than 30 days.
- **Commit message formatting**: The hook captures `git log --oneline` output. If the user writes long or multi-line commit messages, they'll be truncated. Adjust the `--format` flag if needed (e.g., `--format="%h %s"`).
- **Language**: The cron prompt in this skill uses Indonesian (`Baca file ... dalam Bahasa Indonesia`). Adjust for the user's language.
- **New branches**: When pushing a new branch (remote_sha = 000...), the hook falls back to the full log of the branch (capped at 20 commits). This may be noisy for large branches.
- **Force pushes**: Force pushes rewrite history — the hook captures the new SHA range. The log entry only shows current commits, not what was overwritten.
