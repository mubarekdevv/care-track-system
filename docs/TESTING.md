# How to test this app

You test **in the Flutter app you are building** (`flutter run`). That is the real product. Firebase Console is only for **checking data** or **resetting** a test project — not for day-to-day parent/teacher flows.

## What you need

1. Firebase project linked in `firebase_options.dart` (already configured for this repo).
2. Run the app from **cmd** (recommended on Windows):

```bat
cd c:\Users\hp\Desktop\flutterrr\Flutter-Projects\child_and_student_care_and_tracking_app
flutter pub get
flutter run
```

3. Optional: open [Firebase Console](https://console.firebase.google.com) → your project → **Firestore** / **Authentication** / **Storage** to verify documents after each step.

## Who is Admin?

- On a **new empty** Firebase project, the **first person who registers and completes school setup** becomes **Admin**.
- That screen says: *"I understand this account will be set as Admin"* — that is intentional for a one-school deployment.

## Admin setup (do this before parents add children)

| Step | Where in app | What happens |
|------|----------------|---------------|
| 1 | Register → First admin setup | School document created |
| 2 | Admin dashboard → **Load / complete Grades 1–5 catalog** | Grades, classes, subjects, default teacher names (catalog) |
| 3 | Admin → **Teachers** tab → *Link registered teachers* | Sets `schoolId` on teacher users |
| 4 | Teachers register separately (role Teacher) | New Auth users |
| 5 | Admin → **Teachers** tab → assign Class + Subject + Teacher | Links real Firebase user to a slot |
| 6 | Parent registers | Can enroll child |

If parents only see **Grade 1** and one teacher, the catalog was not fully loaded. Admin should tap **Load / complete Grades 1–5 catalog** again (it adds missing grades 2–5).

## Role-by-role (all in the app)

### Admin
- Sign in → Admin dashboard.
- Confirm **5 grade levels** on Home stats.
- Open **Grades** / **Classes** / **Subjects** — edit if needed.
- **Marketplace** is parent-only; admin does not need it for school setup.

### Parent
- Register (after school exists).
- **Enroll Your Child** → pick grade → see teacher cards → save.
- Check **Marketplace** tab (UI only; cart uses local catalog).
- Profile photo: tap avatar on dashboard profile — should show preview immediately; upload may finish in background.

### Teacher
- Register as Teacher.
- Admin links account and assigns class/subject.
- **Attendance** tab shows enrolled students (empty until a parent enrolls).

## When to use Firebase Console

| Goal | Console area |
|------|----------------|
| See if enrollment was created | Firestore → `enrollments` |
| See child profile | Firestore → `children` |
| See grades / teachers catalog | `grade_levels`, `class_subjects`, `subjects` |
| Photo upload failed | Storage → rules; Auth signed-in user |
| Reset everything | Delete collections / test users (careful) |

## Appearance (light / dark)

- Open any role dashboard → **Profile** tab → **Appearance** → choose Light, Dark, or Auto.
- After a hot restart, the whole app (overview, shop, admin, auth screens) should follow your choice.
- If one screen stays light, hot restart once (`R` in terminal) so theme changes apply everywhere.

## GitHub: pushes work but contribution count does not rise

The green **contribution graph** on your GitHub profile is **not** the same as commits on the repo.

| What you see | What it counts |
|--------------|----------------|
| Repo → **Commits** tab | All commits on that branch ✓ |
| Profile → green squares | Only commits that match **all** rules below |

Commits count on your profile only when:

1. **Author email** on the commit matches a **verified** email on your GitHub account  
   - GitHub → Settings → Emails → same address as `git config user.email`
2. Commit is on the **default branch** (`main`) or `gh-pages`
3. Repo is **public**, or you enabled [private contributions](https://github.com/settings/profile) 
4. You are the author or co-author (not only committer with different email)

Check locally (cmd):

```bat
git log -1 --format=fuller
```

If `Author` / `Commit` email is `noreply` or a different address, fix:

```bat
git config user.email "your-verified-email@example.com"
```

Future commits will count; old commits need `git commit --amend` only if not pushed yet.

---

## Profile photos slow or failing?

1. Confirm **Firebase Storage** is enabled and rules allow authenticated uploads.
2. Use a **real device or emulator with Google Play** / network (not offline).
3. Child photo: enrollment saves first; photo may appear a few seconds later.
4. If upload fails, a snackbar or error on profile will mention timeout (45s).

## Suggested test order

1. Fresh Auth user → Admin setup → Load catalog → verify 5 grades in app.
2. Register parent → enroll child in Grade 3 → see multiple teachers.
3. Register teacher → admin assign → teacher sees student on Attendance.
4. Parent → Marketplace → no yellow overflow on product cards.
