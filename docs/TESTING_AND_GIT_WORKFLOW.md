# Testing and Git Workflow

Workflow for human reviewers and **Cursor agents** working on Gods and Wizards.

---

## Golden rules

1. **One milestone at a time.** Finish, report, and wait for review before starting the next.
2. **Headless core first.** `godot_game/core/` must not depend on UI, Node3D, input, or scenes.
3. **One authoritative `GameState`.** UI/3D/embodied code reads state and submits legal actions — never direct mutation.
4. **Tests are sacred.** Do not delete, weaken, skip, or rewrite tests to force progress.
5. **Never push broken code to `main`.**

---

## Start of every milestone

### 1. Check Git status

```powershell
cd "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards"
git status --short --branch
git log --oneline --decorate --max-count=5
```

Confirm you are on the intended branch and the working tree is clean (or intentionally dirty for WIP).

### 2. Create or switch to a milestone branch

Do **not** implement milestone work directly on `main` unless explicitly instructed.

```powershell
git checkout main
git pull origin main
git checkout -b milestone/human-player-mode
```

**Suggested branch names:**

- `milestone/human-player-mode`
- `milestone/2d-board-mode`
- `milestone/rules-balancing-sim`
- `milestone/reporting-polish`
- `docs/project-handoff`

### 3. Plan before coding

Restate:

- Milestone goal
- Files likely to change
- Tests to add/update **first**
- Acceptance criteria
- What is **explicitly out of scope**

See [NEXT_MILESTONES.md](NEXT_MILESTONES.md) for proposed next work.

---

## Test-first implementation loop

1. **Write or update tests** for the milestone behaviour.
2. **Run tests** and confirm new tests **fail for the expected reason** (where practical).
3. **Implement the smallest change** needed to pass.
4. **Run the full Godot test suite** (not just one module).
5. Fix until **0 failures**.
6. **Stop.** Summarise results and suggest a commit message. Wait for human review.

---

## Full test command

```powershell
& "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\scripts\Invoke-GodotHeadless.ps1" -ArgumentList @("--headless", "--path", "C:\Users\joesa\Documents\Cursor\BoardGame\gods-and-wizards\godot_game", "-s", "res://tests/test_runner.gd")
```

### Optional filters

```powershell
# Architecture-only (fast-ish scan of constraints)
& "C:\Tools\Godot\godot.exe.exe" --headless --path "...\godot_game" -s res://tests/test_runner.gd -- --suite=architecture

# Integration rules tests
& "C:\Tools\Godot\godot.exe.exe" --headless --path "...\godot_game" -s res://tests/test_runner.gd -- --suite=integration
```

### After adding new global classes

If tests fail with “Identifier X not declared”, run import once:

```powershell
& "C:\Tools\Godot\godot.exe.exe" --headless --path "...\godot_game" --import
```

---

## Commit discipline

### When to commit

- **Do commit** when the milestone is complete and **all tests pass**.
- **Do commit** docs-only handoffs (like this file) when requested.
- **Do not commit** unless the user asks, or the milestone workflow explicitly calls for it after passing tests.
- **Do not push failing WIP to `main`.** Use a milestone branch for WIP; push only when tests pass (unless human explicitly wants a failing WIP branch preserved remotely).

### Suggested commit message format

```
M14: add human player action selection shell
M15: add 2D board state view
Docs: update project handoff and workflow
Fix: aggregate production lines in turn report
```

Use imperative mood, milestone prefix when applicable, and focus on **why** not just file names.

### Example end-of-milestone commit flow

```powershell
git status --short
git diff

git add docs/ godot_game/
git commit -m "M14: add human player action selection shell"

& "C:\Tools\Godot\godot.exe.exe" --headless --path "...\godot_game" -s res://tests/test_runner.gd

git push -u origin milestone/human-player-mode
```

Open a PR to `main` after push (human review).

---

## Push policy

| Target | Policy |
|---|---|
| `main` | Only merge when tests pass and milestone is reviewed |
| `milestone/*` | Push WIP for backup/review; prefer passing tests before push |
| Force push | **Never** on `main` without explicit human approval |

Remote: `origin` → https://github.com/Joesalmon1985/Gods-and-Wizards.git

---

## Rollback and recovery

### View history

```powershell
git log --oneline --decorate --graph --max-count=20
git show e3e4c55
```

### Inspect a previous commit without changing branches

```powershell
git checkout e3e4c55 -- godot_game/core/sim/bot_game_session.gd
# or browse detached:
git switch --detach e3e4c55
```

Return to branch: `git switch main`

### Create a recovery branch from an old commit

```powershell
git checkout -b recovery/pre-m14-baseline e3e4c55
```

### Revert a bad merge commit (safe)

```powershell
git revert -m 1 <merge-commit-hash>
```

### Destructive operations — avoid unless explicitly approved

- `git reset --hard`
- `git push --force` (especially to `main`)
- `git clean -fdx`

If history must be rewritten, discuss with the human first.

---

## Agent checklist (copy/paste)

```
[ ] git status --short --branch
[ ] On milestone branch (not main) unless docs-only hotfix
[ ] Tests written/updated before implementation
[ ] New tests failed for expected reason (if applicable)
[ ] Full test suite: 0 failures
[ ] No core/ dependency on UI/Node3D/input
[ ] No direct GameState mutation from ui/integration/embodied/run_modes
[ ] Summary: files changed, tests added, risks, suggested commit message
[ ] Stopped — waiting for human review
```

---

## Related docs

- [PROJECT_STATUS.md](PROJECT_STATUS.md) — current state snapshot
- [NEXT_MILESTONES.md](NEXT_MILESTONES.md) — proposed upcoming work
- [run_modes.md](run_modes.md) — how to run headless and wizard-world modes
