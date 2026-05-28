# Plan: Import Nim Idle Clicker into clicky

## Goal

Copy the Nim idle clicker project from
`~/git/birbparty/incremental-examples/nim/` into this repo (`~/git/clicky/`),
fix the asset path so it works from the new directory layout, verify the build,
commit, and open a PR.

---

## Context

### Source project

| Path (relative to `incremental-examples/nim/`) | Purpose |
|---|---|
| `src/idle_clicker.nim` | Entry point — opens window, calls `run()` |
| `src/game/run.nim` | Game state, update loop, draw loop; exports `run*`, `WindowW*`, `WindowH*` |
| `src/game/ui_helpers.nim` | `drawCenteredText`, `drawUpgradeButton`, font-size constants |
| `idle_clicker.nimble` | Nimble package — `srcDir = "src"`, `bin = @["idle_clicker"]` |
| `nim_setup.sh` | Idempotent macOS toolchain setup (Xcode CLT, Homebrew, Nim) |
| `scripts/build_and_run.sh` | `cd` to project root → `nimble build -d:release` → `./idle_clicker` |
| `scripts/build_timed.sh` | Same build with elapsed-time output |

Asset lives at `incremental-examples/assets/coin_sheet.png` (shared with other
language ports). The nim binary references it as `"../assets/coin_sheet.png"`,
which is relative to the CWD when the game runs. In the new layout the binary
lands at the clicky repo root and must find `assets/coin_sheet.png` there.

### Destination layout (clicky root)

```
clicky/
  assets/
    coin_sheet.png        ← copy from incremental-examples/assets/
  src/
    idle_clicker.nim
    game/
      run.nim             ← CoinSheetPath constant updated (see below)
      ui_helpers.nim
  idle_clicker.nimble
  nim_setup.sh
  scripts/
    build_and_run.sh
    build_timed.sh
  .agents/
    plans/
      initial/
        plan.md           ← this file
```

---

## Steps

### Step 1 — Create the feature branch

```bash
cd /Users/punk1290/git/clicky
git checkout -b feat/import-nim-idle-clicker
```

### Step 2 — Create directories

```bash
mkdir -p /Users/punk1290/git/clicky/assets
mkdir -p /Users/punk1290/git/clicky/src/game
mkdir -p /Users/punk1290/git/clicky/scripts
```

### Step 3 — Copy source files

```bash
SRC=/Users/punk1290/git/birbparty/incremental-examples
DST=/Users/punk1290/git/clicky

cp "$SRC/nim/src/idle_clicker.nim"       "$DST/src/idle_clicker.nim"
cp "$SRC/nim/src/game/run.nim"           "$DST/src/game/run.nim"
cp "$SRC/nim/src/game/ui_helpers.nim"    "$DST/src/game/ui_helpers.nim"
cp "$SRC/nim/idle_clicker.nimble"        "$DST/idle_clicker.nimble"
cp "$SRC/nim/nim_setup.sh"               "$DST/nim_setup.sh"
cp "$SRC/nim/scripts/build_and_run.sh"   "$DST/scripts/build_and_run.sh"
cp "$SRC/nim/scripts/build_timed.sh"     "$DST/scripts/build_timed.sh"
cp "$SRC/assets/coin_sheet.png"          "$DST/assets/coin_sheet.png"
```

### Step 4 — Fix the asset path in run.nim

In `src/game/run.nim`, the constant:

```nim
CoinSheetPath = "../assets/coin_sheet.png"
```

must become:

```nim
CoinSheetPath = "assets/coin_sheet.png"
```

**Why:** The build scripts `cd` to the clicky repo root before running the
binary. From the repo root, `"../assets/"` would look one directory above clicky,
which doesn't contain the asset. `"assets/coin_sheet.png"` resolves correctly
from the repo root.

Use a targeted in-place edit (sed or direct file edit). Do not touch any other
line in the file.

```bash
sed -i '' 's|"../assets/coin_sheet.png"|"assets/coin_sheet.png"|' \
  /Users/punk1290/git/clicky/src/game/run.nim
```

Verify the change:

```bash
grep "CoinSheetPath" /Users/punk1290/git/clicky/src/game/run.nim
# Expected:  CoinSheetPath = "assets/coin_sheet.png"
```

### Step 5 — Make scripts executable

```bash
chmod +x /Users/punk1290/git/clicky/nim_setup.sh
chmod +x /Users/punk1290/git/clicky/scripts/build_and_run.sh
chmod +x /Users/punk1290/git/clicky/scripts/build_timed.sh
```

### Step 6 — Ensure .gitignore covers build artifacts

The existing `.gitignore` already contains `nimcache/` and `nimblecache/`.
What is currently **missing** and must be added:

- `idle_clicker` — the compiled binary (must never be committed)

Append only the missing entry (do NOT overwrite the file):

```bash
echo 'idle_clicker' >> /Users/punk1290/git/clicky/.gitignore
```

Verify:

```bash
grep 'idle_clicker' /Users/punk1290/git/clicky/.gitignore
# Expected: idle_clicker
```

The modified `.gitignore` will be staged in Step 8.

### Step 7 — Build verification

Install dependencies (naylib compiles bundled raylib C sources — takes a few
minutes on first run, fast on subsequent runs).

`-d` here means `--depsOnly`: fetch and install naylib without building the
local `idle_clicker` package itself. The actual binary is produced by
`nimble build` in the next command.

```bash
cd /Users/punk1290/git/clicky
nimble install -d --accept
```

Then build:

```bash
nimble build -d:release
```

Verify the binary exists:

```bash
ls -lh /Users/punk1290/git/clicky/idle_clicker
```

**If nimble install fails** with a naylib version conflict, try:

```bash
nimble install naylib --accept
nimble build -d:release
```

**Do not skip or paper over build failures.** If the build fails, investigate
the error, fix it, and rebuild before proceeding.

### Step 8 — Commit

Stage only the new/modified files (not the built binary):

```bash
cd /Users/punk1290/git/clicky
git add assets/coin_sheet.png
git add src/
git add idle_clicker.nimble
git add nim_setup.sh
git add scripts/
git add .gitignore
git add .agents/plans/initial/plan.md
```

Commit:

```bash
git commit -m "$(cat <<'EOF'
Import Nim idle clicker from incremental-examples

Copies the naylib (raylib) idle clicker into this standalone repo.
Asset path updated from ../assets/ to assets/ to match the new
working-directory convention (binary runs from the repo root).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### Step 9 — Push and open PR

```bash
git push -u origin feat/import-nim-idle-clicker
```

Then open a PR with `gh`:

```bash
gh pr create \
  --title "Import Nim idle clicker from incremental-examples" \
  --body "$(cat <<'EOF'
## Summary

- Copies the Nim + naylib idle clicker from birbparty/incremental-examples into this standalone repo
- Fixes asset path: `../assets/coin_sheet.png` → `assets/coin_sheet.png` (binary runs from repo root)
- Includes nimble package config, setup script, and build scripts

## Test plan

- [ ] `nimble install -d --accept` completes without error
- [ ] `nimble build -d:release` produces `./idle_clicker`
- [ ] Binary launches, displays coin sprite, click/upgrades work

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Acceptance criteria

1. All source files present at their expected paths (see layout above).
2. `grep CoinSheetPath src/game/run.nim` → `"assets/coin_sheet.png"` (not `../assets/`).
3. `nimble build -d:release` exits 0.
4. `./idle_clicker` binary exists in repo root.
5. `.gitignore` covers `idle_clicker` (binary), `nimcache/`, and `nimblecache/` (the latter two were already present).
6. PR open on GitHub against `main`.

---

## What NOT to do

- Do not modify any nim source logic (game state, rendering, input handling).
- Do not rename any procs, types, or constants.
- Do not add new dependencies to `idle_clicker.nimble`.
- Do not push to `main` directly.
- Do not commit `idle_clicker` binary or `nimcache/` directory.
