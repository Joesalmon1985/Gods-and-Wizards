# Autonomous Session Log — Macro Foundation

**Session start:** 2026-06-11  
**Branch:** `milestone/macro-foundation-autonomous`  
**Baseline tag:** `checkpoint/macro-foundation-baseline` @ `3242cff` (M14 + build legality)

---

## Assumptions

- `origin/main` may lag build-legality merge; work based on `milestone/build-rule-legality-tests` @ `c421ec5` fast-forwarded into M14.
- Old M14 stash (`stash@{0}`) not reapplied — WIP already present on branch.
- 3D wizard mode unchanged; no NN training, drafting, or embodied combat loop.
- Phase 9 (read-only 2D) only if Phases 4–8 green and time permits.

---

## Phase checklist

| Phase | Status | Commit | Notes |
|-------|--------|--------|-------|
| M14 finish | pass | `3242cff` | Human turn shell committed on M14 branch |
| Autonomous branch + tag | pass | tag only | `checkpoint/macro-foundation-baseline` |
| Docs update | pending | | |
| Macro training env | pending | | |
| Batch balance runner | pending | | |
| Balance config skeleton | pending | | |
| Read-only 2D board | pending | | |

---

## Blockers / stashes

*(Updated at session end)*

---

## End state

*(Updated at session end)*
