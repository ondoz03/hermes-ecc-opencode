---
name: obsidian
description: Read, search, create, and edit notes in the Obsidian vault.
platforms: [linux, macos, windows]
---

# Obsidian Vault

Use this skill for filesystem-first Obsidian vault work: reading notes, listing notes, searching note files, creating notes, appending content, and adding wikilinks.

## Vault path

Use a known or resolved vault path before calling file tools.

The documented vault-path convention is the `OBSIDIAN_VAULT_PATH` environment variable, for example from `~/.hermes/.env`. If it is unset, use `~/Documents/Obsidian Vault`.

File tools do not expand shell variables. Do not pass paths containing `$OBSIDIAN_VAULT_PATH` to `read_file`, `write_file`, `patch`, or `search_files`; resolve the vault path first and pass a concrete absolute path. Vault paths may contain spaces, which is another reason to prefer file tools over shell commands.

If the vault path is unknown, `terminal` is acceptable for resolving `OBSIDIAN_VAULT_PATH` or checking whether the fallback path exists. Once the path is known, switch back to file tools.

## Read a note

Use `read_file` with the resolved absolute path to the note. Prefer this over `cat` because it provides line numbers and pagination.

## List notes

Use `search_files` with `target: "files"` and the resolved vault path. Prefer this over `find` or `ls`.

- To list all markdown notes, use `pattern: "*.md"` under the vault path.
- To list a subfolder, search under that subfolder's absolute path.

## Search

Use `search_files` for both filename and content searches. Prefer this over `grep`, `find`, or `ls`.

- For filenames, use `search_files` with `target: "files"` and a filename `pattern`.
- For note contents, use `search_files` with `target: "content"`, the content regex as `pattern`, and `file_glob: "*.md"` when you want to restrict matches to markdown notes.

## Create a note

Use `write_file` with the resolved absolute path and the full markdown content. Prefer this over shell heredocs or `echo` because it avoids shell quoting issues and returns structured results.

## Append to a note

Prefer a native file-tool workflow when it is not awkward:

- Read the target note with `read_file`.
- Use `patch` for an anchored append when there is stable context, such as adding a section after an existing heading or appending before a known trailing block.
- Use `write_file` when rewriting the whole note is clearer than constructing a fragile patch.

For an anchored append with `patch`, replace the anchor with the anchor plus the new content.

For a simple append with no stable context, `terminal` is acceptable if it is the clearest safe option.

## Targeted edits

Use `patch` for focused note changes when the current content gives you stable context. Prefer this over shell text rewriting.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, use these to link related content.

**Naming convention**: Use kebab-case for filenames (`bug-bounty-methodology.md`) but natural case with spaces in wikilinks (`[[Bug Bounty Methodology]]`). Obsidian resolves these flexibly — it ignores case, hyphens, and spaces when matching wikilinks to filenames. This lets you write readable links in note bodies while keeping file paths URL-safe.

## Vault Structure for Knowledge Management

For structured knowledge work (bug bounty, research, project docs), organize the vault with a **top-level folder-by-category** layout. This maximizes Obsidian's Graph View usefulness:

```
📂 vault/
├── 📁 Targets/         ← one note per target/entity being researched
├── 📁 Techniques/      ← reusable methods, checklists, tool guides
├── 📁 References/      ← external docs, disclosed reports, snippets
└── 📊 Progress.md      ← daily log linking everything
```

### Graph View Optimization

- **Hub note**: Keep a `Progress.md` or `Index.md` at the root that links to every major note. This becomes the central node in your graph, preventing orphan notes.
- **Cross-link targets → techniques**: Every target note should link to the techniques used against it. Every technique note should link back to targets it was tested on. This creates bidirectional edges in the graph.
- **Backlink density**: Aim for 2-8 inline wikilinks per note. Too few → orphan nodes. Too many → noisy graph.
- **Use `[[Note]]` inline**, not just at the bottom in a "Related" section. Inline links give the graph context about WHERE the connection exists in the content.
- **Avoid dead links**: When writing a wikilink to a note that doesn't exist yet, either create a stub note (just a title and frontmatter) or remove the link. Dead links show as broken edges in graph view.
- **Progress note syncing**: Each session, update `Progress.md` with what was done and what links to what. This serves as both a hunting log and a graph anchor.
