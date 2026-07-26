# Product roadmap — Child & Student Care

Single-school Flutter + Firebase app. Status as of June 2026.

## Done

| Area | Status |
|------|--------|
| Architecture + schema docs | Done |
| Admin bootstrap, catalog Grades 1–5, CRUD | Done |
| Parent: enroll child, teachers preview, real children | Done |
| Marketplace UI (local catalog), cart | Done |
| Messaging (threads) | Partial / existing |
| Teacher: real roster + overview | Done |
| Teacher: homework → Firestore `assignments` | **This commit** |
| Profile photo instant preview | Done |
| Theme light/dark on dashboards | Mostly done |

## Next (recommended order)

### A. Teacher — attendance to Firestore
- [ ] Save present/absent to `attendance/{studentId_yyyyMMdd}`
- [ ] Load today’s marks when opening Attendance tab
- **Why next:** Completes daily teacher workflow after roster + homework

### B. Teacher — grades / assessments
- [ ] Publish `assessments` from grade entry sheet (no fake scores)
- [ ] Parent Reports show only published assessments

### C. Parent — reports & timeline
- [ ] Reports screen: stream assessments per child
- [ ] Timeline: enrollment events, assignments due (real)

### D. Parent — child homework view
- [ ] Load assignments for child’s `classRoomId`
- [ ] Optional: mark homework complete (future)

### E. Child role
- [ ] Replace gamification demo with assignments/tasks from Firestore (if self-login or linked student)
- [ ] Or keep playful UI but honest empty states until linked

### F. Healthcare
- [ ] Opt-in health module on child profile
- [ ] Healthcare dashboard from `health_profiles` / appointments (partial exists)

### G. Admin polish
- [ ] Show catalog teacher names on Assign Teachers tab
- [ ] List pending teachers without `schoolId`

### H. Billing / marketplace checkout
- [ ] Deferred per PHASE2_DECISIONS — keep honest placeholder

### I. AI module (Phase 11 skeleton)
- [ ] Contracts only until core flows stable

### J. Cleanup
- [ ] Remove `parent_demo_data.dart`, deprecated `firestore_service.dart`
- [ ] Firestore security rules hardening for production

## How to use this doc

Pick the **first unchecked** item in section A→J for the next coding session. After each subtask: test in app, atomic git commit, update checkboxes here.
