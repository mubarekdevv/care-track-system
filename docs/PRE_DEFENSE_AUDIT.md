# Pre-defense audit — KidCare

**Last updated:** project state before presentation. Run `scripts\verify_build.bat` on your PC before defense day.

---

## Compile safety (your biggest fear)

| Check | Command | Pass criteria |
|--------|---------|----------------|
| Dependencies | `flutter pub get` | No errors |
| Static analysis | `flutter analyze` | No **error** level issues |
| Full compile | `flutter build web` or `flutter build apk` | Build succeeds |

**Known fix already applied:** `Color.withValues()` was replaced with `withOpacity()` for older Flutter SDKs.

**If compile fails:** read the **first** error only; fix imports, typos, missing params. Do not hot-reload — use **full restart** (`R` or stop + `flutter run`).

---

## Features — completed vs partial

### Done (demo-ready if data + rules deployed)

| Area | Status |
|------|--------|
| Auth (login, register, roles) | Done |
| Admin school bootstrap + grade catalog | Done |
| Parent enroll child + health concerns | Done |
| Teacher profile setup (grades/subjects after login) | Done |
| Healthcare profile setup (services after login) | Done |
| Teacher roster / attendance / homework | Done |
| Student My Tasks + Turn in homework | Done (needs rules + linked profile) |
| Parent ↔ Child 6-digit link codes (both directions) | Done |
| Parent School Messages + back navigation | Done |
| Healthcare auto-link / doctor matching | Done (needs admin health services) |
| Marketplace UI + cart (local catalog) | UI done; not a full payment backend |
| Dark / light theme | Done |

### Partial / do not claim as “fully production”

| Area | Reality |
|------|---------|
| README | Outdated vs current app |
| AI homework assistant | Stub only (`ai_assistant_service.dart`) |
| Some dashboard stats | Illustrative or depends on live Firestore data |
| Child profile “Assigned Class” | May show placeholder if not wired to enrollment |
| Multi-school | Single default school (`school_default`) |
| Automated tests | Minimal (`test/widget_test.dart` only) |
| Unknown role | Shows “under construction” placeholder |

---

## Runtime errors seen in your terminal (must fix before demo)

### 1. `permission-denied` (Firestore)

**Cause:** App rules on Firebase Console may be **older** than `firestore.rules` in the repo.

**Fix:**
```bat
firebase deploy --only firestore:rules
```

**Critical rules for child demo:**
- `children` — student can read own doc (`studentUserId` / `linkedStudentId`)
- `enrollments` — child can read own enrollment
- `family_link_codes` — create/read/link
- `assignment_submissions` — student turn-in

### 2. `setState() or markNeedsBuild() called during build`

**Cause:** Child dashboard bound gamification during `didChangeDependencies`.

**Fix:** Applied — binding runs in `addPostFrameCallback`. Full restart after pull.

---

## Presentation test matrix (run in order)

Use **fresh full restart** after rule deploy. Tick when pass.

### Compile (day before)
- [ ] `scripts\verify_build.bat` succeeds
- [ ] Same device/emulator as defense day

### Admin (once)
- [ ] Login → bootstrap school
- [ ] Load Grades 1–5 catalog
- [ ] Enable health services (if demoing clinic)
- [ ] Assign teacher to Grade + Subject

### Parent
- [ ] Register / login
- [ ] Enroll child → teacher visible
- [ ] View link code on child card (pin icon)
- [ ] Link with code (child registered first)
- [ ] School Messages open + back works

### Teacher
- [ ] Register → teaching profile setup
- [ ] Roster shows enrolled students
- [ ] Create homework → appears for student
- [ ] Turn-in count updates after student submits

### Child
- [ ] Self-register OR link parent code
- [ ] Connect parent screen → **Continue** exits to dashboard
- [ ] Profile → My parent link code
- [ ] My Tasks shows homework
- [ ] Turn in → no permission error

### Healthcare (optional)
- [ ] Register → select services
- [ ] Parent enroll with matching concern → doctor linked or waiting

---

## Demo disaster plan

| Problem | Action |
|---------|--------|
| App won’t compile | Run `verify_build.bat`; fix first analyzer error; use yesterday’s APK backup |
| Firebase offline | Short screen recording of golden path |
| Empty teacher roster | Re-assign teacher in Admin; confirm parent enrollment active |
| Child no homework | Teacher posted assignment; child linked; rules deployed |
| Permission errors | Deploy rules; sign out/in |

---

## Honest answer for examiners

> “This is a **functional prototype** for one school on Firebase. Core flows are implemented and tested manually. Marketplace payments, multi-tenant SaaS, and AI tutoring are future work.”

That is accurate and defensible.
