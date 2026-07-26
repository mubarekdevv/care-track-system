# Parent–student account flows

## Collections

| Collection | Doc ID | Purpose |
|------------|--------|---------|
| `parent_student_relationships` | `{parentId}_{studentId}` | Many-to-many parent ↔ student with `relationshipType` |
| `parent_invitations` | auto | Audit trail when student provisions a parent (Scenario 2) |
| `users` | Auth uid | `mustChangePassword`, `linkedStudentId` (Child role) |
| `children` | student profile id | `studentUserId`, `studentEmail`, `accountMode` |

Passwords exist **only** in Firebase Authentication.

## Callable functions (`functions/`)

Deploy once before using add-child or link-parent in the app:

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes
```

| Function | Caller | Action |
|----------|--------|--------|
| `createStudentAccount` | Parent | Auth user + child profile + relationship + optional enrollment |
| `createParentForStudent` | Student | Parent Auth + relationship + invitation record |

## Scenario 1 — Parent first

1. Welcome → **How will you join?** → Parent path → register → login  
2. Parent dashboard → **Enroll child** → enter student email + relationship  
3. App shows **temporary password** once (copy/share)  
4. Student signs in → **Set your password** screen → child dashboard  

## Scenario 2 — Student first

1. Welcome → Student path → **Student sign up**  
2. **Your school profile** (DOB, gender, grade)  
3. **Connect a parent?** → optional `createParentForStudent`  
4. Parent signs in with temp password → forced password change  

## Testing checklist

- [ ] Deploy functions + rules  
- [ ] Parent A cannot read Parent B's children (rules + app)  
- [ ] Add child creates relationship doc `{parentId}_{studentId}`  
- [ ] Student first login forces password change  
- [ ] Parent list still shows children after relationship migration  
