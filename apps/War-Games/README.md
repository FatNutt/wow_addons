# Better Addons WoW Template — Midnight 12.0+

> Clone. Rename. Code. Tag. Ship. A production-ready WoW addon starter with CI/CD that packages and uploads to CurseForge, Wago, and WoWInterface automatically.

## Quickstart

**One command** — clone, rename all files/globals/TOC metadata, fresh git history:

```bash
curl -fsSL https://raw.githubusercontent.com/FRIKKern/Better-Addons-WoW-Template/main/setup.sh | bash -s -- "WarGamesName" "FatNutt"
```

Then:

```bash
cd WarGamesName
ln -s "$(pwd)" "/path/to/WoW/_retail_/Interface/AddOns/WarGamesName"
# Code → /reload in-game → repeat
git tag v1.0.0 && git push origin v1.0.0  # GitHub Actions ships it
```

<details>
<summary>Alternative: manual clone + Claude Code rename</summary>

```bash
git clone https://github.com/FRIKKern/Better-Addons-WoW-Template.git WarGamesName
cd WarGamesName
# With Claude Code:
/wow-setup WarGamesName "FatNutt" "Short description"
# Or run the setup script directly:
bash setup.sh "WarGamesName" "FatNutt"
```
</details>

## What's Included

```
WarGames.toc              # Addon metadata — Interface 120001 (Midnight)
Init.lua                 # Namespace, events, SavedVariables, slash commands
Core.lua                 # Feature logic, combat queue, hooks, frame creation
Config.lua               # Settings API panel (checkboxes, sliders, dropdowns)
CLAUDE.md                # AI instructions — deprecated APIs, Secret Values, patterns
.cursorrules             # Cursor IDE instructions (same rules, compact format)
Libs/embeds.xml          # Library loader (LibStub, CallbackHandler)
setup.sh                 # Bootstrap script — clone + rename in one command
.pkgmeta                 # BigWigsMods/packager config — externals, ignores, nolib
.github/workflows/
  release.yml            # Tag push → lint → package → upload to 4 platforms
  lint.yml               # Luacheck on every push to main and every PR
.claude/                 # Claude Code skills — 11 commands, 9 agents, 4 modes
.luacheckrc              # WoW-aware Luacheck config with all globals declared
.luarc.json              # Lua Language Server config (Lua 5.1, WoW builtins disabled)
.vscode/                 # VS Code settings + recommended extensions
.editorconfig            # Consistent formatting across editors
.gitignore               # Ignores Libs/, .release/, IDE temp files
LICENSE                  # MIT
CHANGELOG.md             # Keep a Changelog format
```

## CI/CD Pipeline

This is the core value proposition. Push a tag, get a release on four platforms.

### Release Flow (`release.yml`)

```
git tag v1.0.0 → git push origin v1.0.0
                         │
                    GitHub Actions
                         │
              ┌──────────┴──────────┐
              │                     │
          Luacheck              Package
        (lint check)         BigWigsMods/packager@v2
              │                     │
              │              ┌──────┼──────┬──────────┐
              │              │      │      │          │
              │          CurseForge Wago  WoWI  GitHub Release
              │              │      │      │          │
              └──────────────┴──────┴──────┴──────────┘
```

The packager automatically:
- Replaces `@project-version@` tokens with the tag name
- Fetches libraries from `.pkgmeta` externals
- Generates a changelog from git history
- Creates both full and `-nolib` zip packages
- Uploads to every platform where a secret is configured

### Lint Flow (`lint.yml`)

Runs Luacheck on every push to `main` and every pull request. The `.luacheckrc` declares all WoW globals so you get real signal, not noise.

### Required Secrets

Add these in your GitHub repo under **Settings > Secrets and variables > Actions**:

| Secret | Platform | Where to Get It |
|--------|----------|-----------------|
| `CF_API_KEY` | CurseForge | [Author Dashboard](https://authors.curseforge.com) > API Tokens |
| `WAGO_API_TOKEN` | Wago Addons | [Account > API Keys](https://addons.wago.io/account/apikeys) |
| `WOWI_API_TOKEN` | WoWInterface | File Management > API Token |

GitHub Releases uses the built-in `GITHUB_TOKEN` — no setup needed.
Missing a secret? That platform is simply skipped. Start with just GitHub Releases (zero config), add others later.

**Also required:** Go to **Settings > Actions > General > Workflow permissions** and select **Read and write permissions**.

### Platform IDs

Update these in `WarGames.toc` with your real project IDs:

```
## X-Curse-Project-ID: 123456
## X-Wago-ID: abcdefgh
## X-WoWI-ID: 12345
```

## Claude Code Integration

All skills are built into this template — no plugin install required. Clone the repo, open [Claude Code](https://claude.ai/claude-code), and every command works immediately.

### Slash Commands

| Command | What It Does |
|---------|-------------|
| `/wow-setup` | One-command rename — files, globals, TOC, all references |
| `/wow-create` | Generate a complete addon from a description |
| `/wow-review` | Audit for deprecated APIs, taint risks, Secret Values issues |
| `/wow-api` | Look up any WoW API function or event |
| `/wow-debug` | Diagnose in-game errors and symptoms |
| `/wow-migrate` | Update pre-12.0 code to Midnight compatibility |
| `/wow-mode` | Set development philosophy (faithful, boundary, enhancement, perf) |
| `/wow-init` | Initialize a new addon project directory |
| `/wow-news` | Latest WoW addon ecosystem news |
| `/wow-research` | Research and verify API claims and patterns |
| `/wow-verify` | Verify code snippets against the current live patch |

### Specialized Agents

9 agents auto-activate for complex tasks: **Coder**, **Scaffold**, **Reviewer**, **Debugger**, **Migrator**, **Researcher**, **Generalist**, **Skin Designer**, **News Desk**.

### Development Modes

4 modes shape how Claude approaches your code: **Blizzard Faithful** (safe, spec-compliant), **Boundary Pusher** (experimental), **Enhancement Artist** (UI-focused), **Performance Zealot** (optimized). Switch with `/wow-mode`.

The `CLAUDE.md` file teaches AI assistants the Midnight 12.0+ rules: which APIs are removed, how Secret Values work, and what patterns to follow. It works with Claude Code, Cursor (via `.cursorrules`), and any LLM that reads project context.

## Template Features

**Midnight 12.0+ Ready** — Interface 120001, no deprecated APIs, Secret Values handled via `issecretvalue()` + `ns.SafeValue()` guard pattern.

**Pure Blizzard API** — No Ace3 dependency. Namespace pattern (`local addonName, ns = ...`), table-dispatch events, modern Settings API (11.0.2+ signatures).

**Addon Compartment** — Minimap dropdown entry with click/hover handlers, registered via TOC metadata.

**Combat Lockdown Queue** — Operations deferred during combat, flushed on `PLAYER_REGEN_ENABLED`.

**SavedVariables with Migration** — Default merging on load, schema versioning pattern for future DB restructuring.

**hooksecurefunc Examples** — The Midnight-safe way to modify Blizzard frames, with `IsForbidden()` guards.

## License

MIT — see [LICENSE](LICENSE).
