# Session Setup: 2026-05-25

Initial setup performed for user `who` on Ubuntu 24.04.

## Hook Location

```
~/.config/git/hooks/post-push
```

Global `core.hooksPath` set to `$HOME/.config/git/hooks`.

## Cron Job

- **Name:** Daily Git Push Summary
- **Job ID:** 79563d1fc4f8
- **Schedule:** `0 17 * * *` (daily at 17:00 Asia/Jakarta)
- **Delivery:** origin (Telegram)
- **Prompt language:** Indonesian (Bahasa Indonesia)

## Log File

```
~/.hermes/hermes-agent/cron/output/git-activity.log
```

## User Environment

- PHP multi-version (7.4–8.4) via ondrej/php
- Valet Linux v2.4.4 serving `.test` domain
- MariaDB 10.11 (root uses unix_socket auth by default)
- Projects in `/home/who/herd/` and `/media/who/Dota 2/Herd/` (mirrored/symlinked content)
- Node.js via nvm (v16, v24)
- `~/.local/bin/` for custom scripts (user does NOT want ~/.zshrc modified)

## Future Plans

- Integrate with ClickUp API for automatic task creation from push activity
