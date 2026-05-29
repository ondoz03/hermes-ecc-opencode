# Repo Split: Public vs Private

## Why Split?

Hermes skills and ECC configs are safe to share, but `memories/` and `config/` contain:
- Machine IPs, hardware specs, personal paths
- Bug bounty targets and recon data
- API tokens (in .env and config)
- Session-history-derived facts about the user

## Split Strategy

| Repo | Visibility | Contents |
|------|-----------|----------|
| `ondoz03/hermes-ecc-opencode` | **Public** | `skills/`, `local-bin/`, `reference/`, `ecc-setup.sh/.ps1`, `README.md` |
| `ondoz03/hermes-ecc-private` | **Private** | `memories/`, `config/`, `notes/` |

## Cleanup Steps (Public Repo)

```
rm -rf memories/ config/ notes/ skills-registry.txt
git init --orphan clean-branch
git add -A
git commit -m "public release"
git remote add origin <public-repo-url>
git push -u origin main
```

## Maintenance

- **Daily backup** writes to **private** repo only (contains memories + config)
- **Public** repo updated manually when skill structure changes significantly
- The setup script (`ecc-setup.sh`) clones from public repo; skills/memories come from there
- Private repo is cloned only for personal restore
