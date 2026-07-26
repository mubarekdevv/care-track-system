# Architecture Overview

Child Ecosystem Platform — Flutter + Firebase (single school per deployment).

## Documents

| Doc | Purpose |
|-----|---------|
| [PHASE2_DECISIONS.md](./PHASE2_DECISIONS.md) | Stakeholder decisions (admin role, tenancy, student modes, health opt-in) |
| [firestore_schema.md](./firestore_schema.md) | Collections, fields, indexes, security outline |
| [MIGRATION.md](./MIGRATION.md) | Legacy `children` → `StudentModel` migration plan |

## Layer diagram (target)

```
screens / widgets
       ↓
providers (ChangeNotifier — Phase 3+)
       ↓
repositories (abstract — lib/data/repositories/)
       ↓
Firebase (Firestore, Auth, Storage)
```

## Phase status

| Phase | Status |
|-------|--------|
| 1 Architecture audit | ✅ Complete |
| 2 Entity & schema design | ✅ Complete |
| 3 Admin bootstrap & Firestore repos | ✅ Complete (this commit) |
| 4 Parent module (real workflows) | 🟡 In progress |
| 5 Teacher academic (attendance, assessments) | 🔜 Next — see [ROADMAP.md](./ROADMAP.md) |
| 6–12 | See [ROADMAP.md](./ROADMAP.md) |

## Key code locations (Phase 2)

| Path | Contents |
|------|----------|
| `lib/core/domain/domain_enums.dart` | Roles, enrollment, attendance, notification enums |
| `lib/core/config/school_config.dart` | Single-school `SCHOOL_ID` |
| `lib/models/student_model.dart` | Canonical student profile |
| `lib/models/*` | School, class, enrollment, academic, health, notification models |
| `lib/data/repositories/*.dart` | Repository interfaces (no Firebase impl yet) |
| `lib/ai/*.dart` | Future AI service contracts |

## Deprecated (do not extend)

- `lib/core/constants/parent_demo_data.dart`
- `lib/services/firestore_service.dart`

Existing UI still compiles — demo data removal happens Phase 4+.
