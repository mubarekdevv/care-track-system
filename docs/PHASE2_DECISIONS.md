# Phase 2 — Product & Deployment Decisions

Recorded from stakeholder review (May 2026). These decisions drive the data model and repository design.

## Deployment model

| Decision | Choice | Implication |
|----------|--------|-------------|
| Tenancy | **One school per deployment** | Each customer (school / childcare) gets its own Firebase project (or isolated config). No multi-school UI in v1. |
| School identity | Single `schools/{schoolId}` document | App reads `SchoolConfig.defaultSchoolId` at startup (from env / remote config later). |
| Future AI | Per-school data isolation | RAG / fine-tuning uses only that deployment's Firestore — aligns with single-tenant sales model. |

## Roles

| Decision | Choice |
|----------|--------|
| School setup | **In-app Admin role first** — admin seeds grades, classes, subjects, teacher assignments before parents enroll students. |
| Roles v1 | `Admin`, `Parent`, `Teacher`, `Child`, `Healthcare` |

## Student accounts

| Mode | When | Behavior |
|------|------|----------|
| **Parent-managed** (default) | Young children, no phone | Student profile exists; no login. Parent acts on their behalf. |
| **Self-login** (optional) | Older students with device | Firebase Auth user linked via `studentUserId`. Gamification, tasks, safe ecosystem. |

Product vision (Phase 5+): educational screen-time hub, task/todo tracking, badges, optional reward unlocks, future safe-browsing controls — requires self-login path but **never mandatory**.

## Healthcare

| Decision | Choice |
|----------|--------|
| Default | **Off** — `healthModuleEnabled: false` on student profile |
| Opt-in | Parent enables later → creates `health_profiles` + `healthcare_access` |
| Vaccinations | Optional structured records — not forced at registration |

## Billing

Deferred until post-MVP. No payment integration in current phases. Billing UI will be hidden or placeholder until a dedicated commerce phase.

## Data migration (existing `children` collection)

**Strategy: extend in place (non-breaking).**

- Keep collection name `children` for backward compatibility during transition.
- Add new optional fields with safe defaults (`schemaVersion: 1`).
- `StudentModel.fromLegacyChild()` maps old documents.
- Phase 4 UI writes new fields; old docs remain valid until parents re-save or admin migration tool runs.
- No destructive migration required for dev/staging.

## Repository layer

Phase 2 introduces **interfaces only**. Firebase implementations land in Phase 3.

## Demo data policy (effective Phase 4)

- `ParentDemoData` is **deprecated** — must not be used in new code.
- Grades, attendance, reports appear only from Firestore writes by teachers/admins.
