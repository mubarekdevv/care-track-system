# Migration Plan — `children` → Student Ecosystem Model

**Phase:** 2 (design) → 3 (repository impl) → 4 (parent UI)  
**Risk:** Low — additive, non-breaking

---

## Current state

Documents in `children`:

```json
{
  "name": "Emma",
  "age": 8,
  "parentId": "uid...",
  "imageUrl": "https://...",
  "vaccinations": ["MMR"],
  "latestHeight": 120.5,
  "latestWeight": 25.0,
  "lastCheckup": "2026-01-15"
}
```

Code path: `ChildModel` → `ChildProvider` → parent & healthcare dashboards.

---

## Target state

Same collection, enriched documents (`schemaVersion: 1`):

```json
{
  "schemaVersion": 1,
  "schoolId": "school_default",
  "name": "Emma",
  "fullName": "Emma",
  "age": 8,
  "dateOfBirth": null,
  "gender": null,
  "parentId": "uid...",
  "imageUrl": "...",
  "accountMode": "parent_managed",
  "studentUserId": null,
  "activeEnrollmentId": null,
  "gradeLevelId": null,
  "classRoomId": null,
  "healthModuleEnabled": false,
  "vaccinations": ["MMR"],
  "latestHeight": 120.5,
  "latestWeight": 25.0,
  "lastCheckup": "2026-01-15",
  "createdAt": "...",
  "updatedAt": "..."
}
```

---

## Why keep `children` collection name?

- Avoid breaking existing Firestore rules, indexes, and `DatabaseService` during Phase 2–3.
- Rename to `students` is optional cosmetic refactor once all code uses `StudentRepository`.
- `StudentModel` is the canonical Dart type; maps to `children` collection.

---

## Code migration steps

| Step | Phase | Action |
|------|-------|--------|
| 1 | **2** ✅ | Add `StudentModel`, enums, repository interfaces |
| 2 | **2** ✅ | Add `StudentModel.fromLegacyMap()` / `toMap()` dual-write `name` + `fullName` |
| 3 | **3** | Implement `StudentRepository` wrapping Firestore |
| 4 | **3** | `ChildProvider` delegates to repository (adapter keeps `ChildModel` export temporarily) |
| 5 | **4** | New Add Student form writes school/class/enrollment fields |
| 6 | **4** | Remove `ParentDemoData` imports from UI |
| 7 | **6** | Teacher roster reads `enrollments`, not fake lists |
| 8 | **Optional** | Admin migration tool: backfill `schemaVersion`, `schoolId`, `healthModuleEnabled: false` |

---

## Backfill script (admin — Phase 3)

Run once per deployment after Admin sets `schoolId`:

```dart
// tool/backfill_student_schema.dart (Phase 3)
// For each doc in children where schemaVersion is null:
//   - set schemaVersion: 1
//   - set schoolId: SchoolConfig.defaultSchoolId
//   - set fullName: name
//   - set accountMode: parent_managed
//   - set healthModuleEnabled: false
//   - set createdAt/updatedAt if missing
```

---

## Healthcare legacy fields

Height, weight, vaccinations on student doc remain readable until Phase 7 moves them to `health_profiles` when parent opts in. No data loss.

---

## Rollback

All new fields are optional. Old app versions ignore unknown fields. New app reads with defaults via `fromLegacyMap`.

---

## Verification checklist (after Phase 4)

- [ ] New parent sees empty dashboard (no fake stats)
- [ ] Existing child still appears in parent list
- [ ] Add student with class → enrollment doc created
- [ ] Parent sees subject/teacher list from `class_subjects`
- [ ] No grades until teacher publishes assessment
