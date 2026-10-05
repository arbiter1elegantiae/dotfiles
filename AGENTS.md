# Agent contribution rules

These rules apply to the whole repository, including delegated agents. GitHub
issues are the source of truth for specifications and acceptance criteria. The
owner's
[`dotfiles` project board](https://github.com/users/arbiter1elegantiae/projects/3)
provides scheduling and visibility.

## Issue-first development

1. Read the relevant code, repository instructions, and recent history. Search
   existing issues before creating a new specification or duplicating work.
2. Create or update a GitHub issue using the feature, bug, or documentation
   template. Describe the problem, bounded scope, acceptance criteria,
   verification, dependencies, and affected files. Research can precede approval;
   implementation requires the owner's approval of the specification.
3. Approval may be recorded in the issue or explicitly given in the current
   conversation. Keep any approval record brief. A template submission alone
   is not approval. The owner/coordinator marks approved, available work
   `agent:ready`.
4. Obtain a coordinated claim before implementation. Record an opaque worker ID,
   branch, intended file scope, and verification plan on the issue. Keep checkout
   paths and private session details in local coordination only.
5. Keep changes within the approved scope. When an agreed decision changes the
   specification, edit the relevant issue sections. Obtain owner approval before
   implementing a materially expanded specification; use a separate issue for a
   distinct objective.
6. When authorized, open a PR referencing the issue and describing the change,
   checks performed, results, and remaining limitations. Use `Closes #<number>`
   only when the PR satisfies the issue; otherwise use `Refs #<number>`.
7. Leave review and merge to the owner unless explicitly authorized otherwise.
   An implementation is ready for review when its acceptance criteria and
   relevant checks pass; the issue is complete after the change is merged.

## Writing issues and PRs

- Keep each issue focused on one bounded outcome. Its description should state
  the current problem, scope, acceptance criteria, and verification plan in plain
  language understandable to both people and coding agents.
- Update the relevant description sections when requirements change. Do not
  append conversation transcripts, decision diaries, command output, or routine
  activity logs. Remove superseded details rather than making readers reconstruct
  the current specification from comments.
- Reserve comments for concise coordination information that affects action:
  approvals, claims, unresolved blockers, or handoffs. Update an existing status
  comment instead of posting repetitive progress reports.
- Keep PR descriptions focused on the final change, the linked issue, relevant
  checks and results, and remaining limitations. Summarize the outcome rather
  than narrating the implementation history; link logs only when useful.
- Do not publish local absolute paths, local usernames, hostnames, machine or
  session identifiers, private configuration, or credentials to GitHub. Use
  repository-relative paths and opaque worker/worktree IDs. Sanitize evidence
  before sharing; describe a reproducible sandbox rather than the private
  workstation. Apply this rule to issues, comments, PRs, and committed files.

## Labels and project tracking

Use one primary issue type label:

| Label | Meaning |
| --- | --- |
| `enhancement` | New behavior or an improvement; feature template |
| `bug` | Existing behavior fails; bug template |
| `documentation` | Documentation-only change; documentation template |

Use at most one coordination label at a time:

| Label | Meaning |
| --- | --- |
| `agent:ready` | Owner-approved specification, available for assignment |
| `agent:claimed` | Assigned to one agent, including while awaiting PR review |
| `agent:blocked` | Assigned work waiting for a dependency or decision |

Unapproved issues have no coordination label. A blocked issue retains its owner
and claim; document the blocker and switch back to `agent:claimed` when resolved.
Releasing a claim requires a handoff comment explaining the remaining work,
branch/worktree state, and checks, followed by `agent:ready`. Remove coordination
labels when the issue closes.

Use GitHub MCP for issue operations when available. Use `gh` for project
operations when MCP lacks access. The board is project **3**, owned by
`arbiter1elegantiae`. Inspect its current fields, options, and issue membership
before updates; do not hard-code field or option IDs. For example:

```sh
gh project field-list 3 --owner arbiter1elegantiae --format json --limit 100
gh project item-list 3 --owner arbiter1elegantiae --format json --limit 100
```

Check returned totals and retrieve further results if the limit truncates them;
use paginated `gh api graphql` queries when needed. Add the issue only if it is
not already present. Use the board's existing `Status` options:

| Status | Workflow stage |
| --- | --- |
| `Backlog` | Specification awaiting approval or scheduling |
| `Ready` | Owner-approved, available work (`agent:ready`) |
| `In progress` | Claimed implementation (`agent:claimed`) |
| `In review` | Published PR awaiting review; retain `agent:claimed` |
| `Done` | Change merged and issue closed; remove coordination labels |

There is no `Blocked` status: retain the current stage and use `agent:blocked`
with an explanatory issue comment. Leave `Priority`, `Size`, estimates, and
dates to owner-approved scheduling. Re-read fields before mutations; do not
invent fields/options or silently change project structure.

The CLI's `read:project` scope permits inspection; project mutations require
`project` scope. If writes are unavailable, report the intended board update on
the issue and to the owner; issue work can continue independently. Do not change
authentication or token scopes without the owner's request.

## Concurrent agents: claims, worktrees, and sandboxes

- A coordinator (the owner or an explicitly designated coordinating agent)
  serializes claims and assigns one implementing agent per issue. A label or
  comment is not an atomic lock: agents must not race to self-claim an issue.
- Use the issue assignee for the responsible GitHub account and a claim comment
  with an opaque worker ID. Agents sharing credentials are not distinct GitHub
  assignees. Keep the worker-to-session and worktree-path mappings local.
- Use an issue branch named `<type>/issue-<number>-<short-slug>`, for example
  `docs/issue-5-agent-workflow`. A single-agent task may use the current checkout
  if it is available; never discard unrelated local changes to prepare it.
- Concurrent implementations require separate Git worktrees and issue branches.
  The coordinator prepares them from the agreed base (normally current
  `origin/main`) and assigns the path before agents start. Treat the shared
  primary checkout as read-only during concurrent work. Example:

  ```sh
  git fetch origin
  git worktree add -b feat/issue-12-config ../dotfiles-issue-12 origin/main
  ```

- Declare intended files/components before assignment. Serialize work that
  overlaps shared files such as `bootstrap.sh`, `README.md`, CI workflows, or
  `nvim/lazy-lock.json`, or split it into dependency issues. Distinct labels and
  branches do not prevent conflicting edits. Do not edit another agent's scope
  without coordinator agreement.
- Worktrees isolate tracked code, but share Git metadata, host tools, and user
  configuration. Do not change shared Git settings or another worktree's files.
  Use disposable containers **in addition** to worktrees for package installation
  and Linux bootstrap tests; use the disposable macOS CI runner for macOS tests.
  Never mount the host home/configuration into an installation sandbox.
- Resolve integration conflicts in coordination with the affected worker. Do not
  reset, force-push, delete branches, or remove worktrees to resolve conflicts.
  Clean up only after the owner approves and all work has been preserved.

## Commits and pull requests

Recent history uses `feat:`, `fix:`, and `test:`. Continue that Conventional
Commit-style format with imperative, concise subjects:

```text
<type>[(scope)]: <description>
```

Use `feat`, `fix`, `docs`, `test`, `ci`, `refactor`, or `chore`; optional scopes
name the affected component (`bootstrap`, `zsh`, `nvim`, `ghostty`, `herdr`, or
`workflow`). Example: `docs(workflow): define issue-first agent contributions`.
Keep commits focused, refer to the issue in the body (`Refs #5`), and use the same
subject convention for PR titles. Do not rewrite older commits to normalize them.

Issue approval authorizes scoped implementation, not automatic publication.
Commit, push, create a PR, amend/rebase history, or merge only when explicitly
authorized. Before a commit, inspect status, diff, and recent history; stage only
intended files. Preserve unrelated/untracked work and never commit credentials.

## Repository-specific verification

- Keep configuration structure, naming, and style consistent with nearby files.
  Prefer small changes and the existing test scripts over new infrastructure.
- Run checks appropriate to the issue. `sh tests/check.sh` runs the existing
  fast suite; `./tests/bootstrap-links.sh` checks linking/backups/idempotency.
  See README for dependencies and clean-container installation commands.
- Never run the full bootstrap on the host workstation to test installation.
  Use `tests/smoke/Dockerfile` or the guarded macOS CI sandbox. Preserve tracked
  plugin locks unless updating them is part of the approved issue.
- Add meaningful regression coverage for behavior changes when warranted.
  Documentation-only or low-impact reversible edits do not require new tests;
  validate their structure, links, and `git diff --check` instead.
- Report exactly what was checked and what is blocked or unverified. Do not
  describe a PR as ready while required checks are failing or still running.
