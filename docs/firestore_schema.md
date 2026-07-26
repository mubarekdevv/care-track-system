# Firestore Schema — Child Ecosystem Platform

**Version:** 1.0 (Phase 2)  
**Tenancy:** One school per Firebase deployment  
**Legacy collection:** `children` (student profiles — name retained for compatibility)

---

## Design principles

1. **Child/student is the hub** — enrollments link students to classes; academics and health hang off enrollment + student id.
2. **No synthetic data** — empty collections until users/admins create records.
3. **Admin bootstraps structure** — grades, classes, subjects, teacher assignments exist before parent enrollment.
4. **Healthcare is opt-in** — gated by parent permission.
5. **Single school** — every document includes `schoolId` for future portability; v1 apps assume one active school.

---

## Collection map

```
schools/{schoolId}
grade_levels/{gradeLevelId}
class_rooms/{classRoomId}
subjects/{subjectId}
class_subjects/{classSubjectId}      ← teacher ↔ class ↔ subject

users/{uid}                          ← all roles incl. Admin
parent_student_relationships/{parentId_studentId}
parent_invitations/{invitationId}
children/{studentId}                 ← student profile (legacy name)
enrollments/{enrollmentId}           ← student in class for a term

assignments/{assignmentId}
assessments/{assessmentId}           ← grades / scores
attendance/{attendanceId}            ← one doc per student per date (or composite id)

health_profiles/{studentId}          ← doc id = studentId, optional
healthcare_access/{studentId}        ← parent permission gate
health_appointments/{appointmentId}  ← existing

message_threads/{threadId}           ← existing
messages/{messageId}                 ← existing (subcollection optional later)

notifications/{notificationId}
marketplace_orders/{orderId}         ← existing
products/{productId}                 ← Phase 10
```

---

## Document schemas

### `schools/{schoolId}`

| Field | Type | Notes |
|-------|------|-------|
| name | string | Display name |
| type | string | `school` \| `childcare` |
| address | string? | |
| timezone | string | IANA e.g. `America/New_York` |
| isActive | bool | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `grade_levels/{gradeLevelId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| name | string | e.g. `Grade 4`, `Kindergarten` |
| sortOrder | int | For UI ordering |
| band | string? | `elementary`, `middle`, `high` |
| isActive | bool | |

### `class_rooms/{classRoomId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| gradeLevelId | string | |
| name | string | e.g. `4-A`, `Homeroom Lions` |
| homeroomTeacherId | string? | `users` uid |
| capacity | int? | |
| isActive | bool | |

### `subjects/{subjectId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| name | string | Mathematics, Science, … |
| code | string? | `MATH-4` |
| isActive | bool | |

### `class_subjects/{classSubjectId}`

Links a **class + subject + teacher**. When a student enrolls in the class, they inherit these teacher connections.

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| classRoomId | string | |
| subjectId | string | |
| teacherId | string | `users` uid |
| isActive | bool | |

**Composite uniqueness (app-enforced):** `(classRoomId, subjectId)` one active row.

### `users/{uid}`

| Field | Type | Notes |
|-------|------|-------|
| uid | string | |
| email | string | |
| fullName | string | |
| role | string | `Admin` \| `Parent` \| `Teacher` \| `Child` \| `Healthcare` |
| profilePic | string? | |
| schoolId | string | Same for all users in deployment |
| phone | string? | |
| teacherProfile | map? | `{ employeeId, department }` |
| healthcareProfile | map? | `{ clinicName, licenseId, room }` |
| linkedStudentId | string? | For `Child` role — points to `children` doc |
| mustChangePassword | bool | Force password change UI on first login |
| passwordChangedAt | timestamp? | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `parent_student_relationships/{parentId_studentId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| parentId | string | `users` uid |
| studentId | string | `children` doc id |
| relationshipType | string | `mother` \| `father` \| `guardian` \| `other` |
| isPrimary | bool | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `parent_invitations/{invitationId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| studentId | string | |
| studentUserId | string | |
| parentEmail | string | |
| parentName | string | |
| relationshipType | string | |
| status | string | `pending` \| `accepted` \| `expired` |
| createdParentId | string? | |
| createdAt | timestamp | |

### `children/{studentId}` — Student profile

| Field | Type | Notes |
|-------|------|-------|
| schemaVersion | int | `1` for Phase 2+ |
| schoolId | string | |
| parentId | string | Primary parent uid |
| fullName | string | Was `name` — **migration maps both** |
| name | string? | Legacy alias; write both during transition |
| dateOfBirth | timestamp? | Preferred over raw `age` |
| age | int? | Legacy; computed from DOB when missing |
| gender | string? | `male` \| `female` \| `other` \| `prefer_not_to_say` |
| imageUrl | string | |
| accountMode | string | `parent_managed` \| `self_login` |
| studentUserId | string? | Firebase uid when self-login |
| studentEmail | string? | Display only; canonical email in Auth |
| activeEnrollmentId | string? | Current enrollment |
| gradeLevelId | string? | Denormalized from enrollment |
| classRoomId | string? | Denormalized from enrollment |
| healthModuleEnabled | bool | Default `false` |
| vaccinations | string[] | Legacy simple list — migrate to `health_profiles` later |
| latestHeight | number? | Legacy — move to health profile |
| latestWeight | number? | |
| lastCheckup | string? | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `enrollments/{enrollmentId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| studentId | string | |
| parentId | string | Denormalized for queries |
| classRoomId | string | |
| gradeLevelId | string | |
| status | string | `active` \| `withdrawn` \| `graduated` |
| enrolledAt | timestamp | |
| withdrawnAt | timestamp? | |

**On create:** App loads `class_subjects` for `classRoomId` → parent UI shows subjects + teachers (read-only).

### `assignments/{assignmentId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| classRoomId | string | |
| subjectId | string | |
| teacherId | string | |
| title | string | |
| description | string? | |
| dueAt | timestamp? | |
| createdAt | timestamp | |
| attachmentUrls | string[]? | |

### `assessments/{assessmentId}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| studentId | string | |
| enrollmentId | string | |
| subjectId | string | |
| teacherId | string | |
| title | string | e.g. `Math Quiz 3` |
| score | number | |
| maxScore | number | |
| publishedAt | timestamp | Parents see only after published |
| createdAt | timestamp | |

**Rule:** No document → no grade in UI.

### `attendance/{attendanceId}`

Suggested id: `{studentId}_{yyyyMMdd}`

| Field | Type | Notes |
|-------|------|-------|
| schoolId | string | |
| studentId | string | |
| classRoomId | string | |
| date | timestamp | Date-only semantics |
| status | string | `present` \| `absent` \| `late` \| `excused` |
| markedBy | string | teacher uid |
| markedAt | timestamp | |

### `health_profiles/{studentId}`

Only exists when `healthModuleEnabled == true`.

| Field | Type | Notes |
|-------|------|-------|
| studentId | string | |
| bloodType | string? | |
| allergies | string[] | |
| medicalConditions | string[] | |
| disabilities | string[] | |
| emergencyContacts | array | `{ name, phone, relation }` |
| currentMedications | string[] | |
| latestHeight | number? | |
| latestWeight | number? | |
| lastCheckup | string? | |
| vaccinations | array | `{ name, dose, date, provider }` |
| updatedAt | timestamp | |

### `healthcare_access/{studentId}`

| Field | Type | Notes |
|-------|------|-------|
| studentId | string | |
| parentId | string | |
| granted | bool | Parent toggle |
| grantedAt | timestamp? | |
| revokedAt | timestamp? | |
| allowedProfessionalIds | string[]? | Optional allow-list; empty = any school healthcare user |

Healthcare queries: `healthcare_access` where `granted == true` (+ allow-list check).

### `notifications/{notificationId}`

| Field | Type | Notes |
|-------|------|-------|
| recipientId | string | user uid |
| recipientRole | string | |
| type | string | See enum in `NotificationType` |
| title | string | |
| body | string | |
| relatedStudentId | string? | |
| relatedEntityId | string? | order, thread, etc. |
| isRead | bool | |
| createdAt | timestamp | |

### Existing collections (unchanged Phase 2)

- **`message_threads`** — extend later with `classRoomId`, `studentId`
- **`messages`** — unchanged
- **`marketplace_orders`** — unchanged
- **`health_appointments`** — add `schoolId`, `studentId` when health module wired

---

## Indexes (Firestore console)

| Collection | Fields | Use |
|------------|--------|-----|
| enrollments | classRoomId, status | Teacher roster |
| enrollments | studentId, status | Student active class |
| enrollments | parentId, status | Parent children in school |
| class_subjects | classRoomId, isActive | Teacher list for class |
| class_subjects | teacherId, isActive | Teacher's classes |
| assessments | studentId, publishedAt | Parent grades |
| attendance | classRoomId, date | Daily attendance sheet |
| notifications | recipientId, createdAt | Notification center |
| children | parentId | Existing parent query |
| children | schoolId, classRoomId | Class roster denorm |

---

## Security rules (outline — implement Phase 3)

```
// Pseudocode — not production rules yet
match /schools/{id} { allow read: if authed; allow write: if isAdmin(); }
match /children/{id} {
  allow read: if isAdmin() || isParent(id) || isTeacherOfStudent(id) || isHealthcareGranted(id);
  allow write: if isAdmin() || isParent(id);
}
match /health_profiles/{studentId} {
  allow read: if healthModuleEnabled(studentId) && (isParent || grantedHealthcare);
}
match /assessments/{id} {
  allow read: if published && (isParentOfStudent || isTeacher || isStudent);
  allow write: if isTeacher();
}
```

---

## Admin bootstrap flow (Phase 3 UI)

1. First registered user OR seed script → `Admin`
2. Admin creates school profile (or reads singleton)
3. Admin defines grade levels → classes → subjects
4. Admin assigns teachers to `class_subjects`
5. Admin invites / registers teachers & healthcare staff
6. Parents enroll students → `enrollments` created → teachers notified

---

## AI module hooks (Phase 11 — schema reserved)

| Collection | Purpose |
|------------|---------|
| `ai_documents/{docId}` | Ingested school policies / curriculum PDFs metadata |
| `ai_chunks/{chunkId}` | RAG chunks scoped by `schoolId` |

No implementation in Phase 2 — interfaces only in `lib/ai/`.
