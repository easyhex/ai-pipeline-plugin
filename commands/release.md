---
description: Cut a product release — pick the next semver from shipped-since-last-release features, generate a human-register CHANGELOG (including a mid-based "requirements changed" section), stamp versions into features.md, and tag locally. Never pushes.
argument-hint: "[major|minor|patch — optional override]"
---

# /release — cut a product release

Releases give humans a version they can name, reference in requirements ("required since v1.3"), and hand to a stakeholder.

## Phase 1: Collect

1. Last release tag: `LAST_TAG=$(git tag --list 'v*' --sort=-version:refname | head -1)`. **First release** (empty `LAST_TAG`): skip Phase 3 entirely and OMIT the "Requirements changed" section from the CHANGELOG — write one line instead: `Requirements baseline established (N requirements across M features).`
2. Shipped-but-unstamped features: entries in `docs/features.md` Shipped section without an `in v` stamp.
3. Fixes since `$LAST_TAG`: `git log $LAST_TAG..HEAD --oneline | grep -E '^\w+ fix'` (best-effort).

If nothing shipped and no fixes → STOP: "Nothing to release since $LAST_TAG."

## Phase 2: Pick the version

Propose the next semver as a frontier question (per `docs-meta/ELICITATION.md`):

```
❓ 1. Version for this release?
Shipped: <list>. Any BREAKING rows in requirement change histories since $LAST_TAG: <yes/no, list>.
➡️ Recommended: vX.Y.Z — <breaking → major (or minor while 0.x) / features → minor / fixes only → patch>
```

`$ARGUMENTS` (major|minor|patch) pre-answers this question. Wait for confirmation.

## Phase 3: Requirements diff (by mid)

Mid matching is **global across the whole directory, never per-path** — files may have been renamed or deleted between releases and mids survive renames:

```bash
# ALL files under docs/requirements/ as of the last release (rename-proof):
git ls-tree -r --name-only "$LAST_TAG" docs/requirements/ > /tmp/req-files-old.txt
# Old side: every mid + its block, from every old file (git show "$LAST_TAG:<path>")
# New side: every mid + its block, from every current docs/requirements/F-*.md
```

Build two maps `{mid → block text}` and classify by set logic: mid only in new → `added`; mid in both with differing block text → `changed`; mid only in old, or present with `status: removed` → `removed`. Never match by FR number, title, or filename. Collect into the changelog section below.

## Phase 4: Write CHANGELOG.md

Prepend a section to `CHANGELOG.md` (create the file if missing). **Human register — write from spec Goals and requirement texts, never from commit messages.** Prose in the conversation's language; IDs and version numbers English.

```markdown
## vX.Y.Z — YYYY-MM-DD

### Features
- <F-ID> <slug> — <one sentence from the spec's Goal>

### Fixes
- <one line each, or omit section>

### Requirements changed since <LAST_TAG>
- Added: F-007/FR-03 (<mid>) — <criterion, one line>
- Changed: F-004/NFR-01 (<mid>) — <what changed>  [BREAKING if so marked]
- Removed: ...

Traceability: docs/TRACEABILITY.md · Requirements: docs/requirements/
```

## Phase 5: Stamp + tag

1. In `docs/features.md`: append ` in vX.Y.Z` to each newly released feature's `shipped YYYY-MM-DD` stamp; append a Change-history row; bump `doc_version`.
2. Commit:
   ```bash
   git add CHANGELOG.md docs/features.md
   git commit -m "release: vX.Y.Z"
   git tag vX.Y.Z
   ```
3. Print: `✓ Released vX.Y.Z (local tag). Push manually: git push && git push origin vX.Y.Z`

## Constraints

- Do NOT push — tags and commits stay local; the user pushes manually (git policy).
- Never edit a `mid:` line, and never renumber requirements during a release.
- CHANGELOG entries come from specs and requirement files, not from `git log` prose.
