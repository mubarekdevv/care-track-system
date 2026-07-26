import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const USERS = "users";
const CHILDREN = "children";
const RELATIONSHIPS = "parent_student_relationships";
const ENROLLMENTS = "enrollments";
const CLASS_SUBJECTS = "class_subjects";

function generateTempPassword(length = 12): string {
  const chars =
    "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#$";
  let result = "";
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

async function getUserRole(uid: string): Promise<string> {
  const doc = await db.collection(USERS).doc(uid).get();
  if (!doc.exists) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "User profile not found."
    );
  }
  return (doc.data()?.role as string) ?? "";
}

async function enrollStudentIfNeeded(params: {
  studentId: string;
  parentId: string;
  schoolId: string;
  classRoomId: string;
  gradeLevelId: string;
  fullName: string;
}): Promise<void> {
  const { studentId, parentId, schoolId, classRoomId, gradeLevelId, fullName } =
    params;

  const enrollmentRef = db.collection(ENROLLMENTS).doc();
  const batch = db.batch();

  batch.set(enrollmentRef, {
    schoolId,
    studentId,
    parentId,
    classRoomId,
    gradeLevelId,
    status: "active",
    enrolledAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.set(
    db.collection(CHILDREN).doc(studentId),
    {
      activeEnrollmentId: enrollmentRef.id,
      gradeLevelId,
      classRoomId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await batch.commit();

  const assignments = await db
    .collection(CLASS_SUBJECTS)
    .where("classRoomId", "==", classRoomId)
    .where("isActive", "==", true)
    .get();

  const notified = new Set<string>();
  for (const doc of assignments.docs) {
    const teacherId = doc.data().teacherId as string | undefined;
    if (!teacherId || notified.has(teacherId)) continue;
    notified.add(teacherId);
    await db.collection("notifications").add({
      recipientId: teacherId,
      recipientRole: "Teacher",
      type: "enrollment_created",
      title: "New student enrolled",
      body: `${fullName} joined your class.`,
      relatedStudentId: studentId,
      relatedEntityId: enrollmentRef.id,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

/**
 * Scenario 1: Parent adds child with student email + temporary password.
 */
export const createStudentAccount = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in as a parent."
      );
    }

    const parentId = context.auth.uid;
    const role = await getUserRole(parentId);
    if (role !== "Parent") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only parents can create student accounts."
      );
    }

    const fullName = (data.fullName as string | undefined)?.trim();
    const studentEmail = (data.studentEmail as string | undefined)
      ?.trim()
      .toLowerCase();
    const relationshipType =
      (data.relationshipType as string | undefined) ?? "guardian";
    const schoolId = (data.schoolId as string | undefined) ?? "school_default";
    const gradeLevelId = data.gradeLevelId as string | undefined;
    const classRoomId = data.classRoomId as string | undefined;
    const gender = data.gender as string | undefined;
    const vaccinations = (data.vaccinations as string[] | undefined) ?? [];
    const dateOfBirth = data.dateOfBirth as string | undefined;

    if (!fullName || !studentEmail) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "fullName and studentEmail are required."
      );
    }

    const parentDoc = await db.collection(USERS).doc(parentId).get();
    const parentSchoolId =
      (parentDoc.data()?.schoolId as string | undefined) ?? schoolId;

    let age: number | null = null;
    let dobTimestamp: admin.firestore.Timestamp | null = null;
    if (dateOfBirth) {
      const parsed = new Date(dateOfBirth);
      if (!isNaN(parsed.getTime())) {
        dobTimestamp = admin.firestore.Timestamp.fromDate(parsed);
        const now = new Date();
        age = now.getFullYear() - parsed.getFullYear();
        if (
          now.getMonth() < parsed.getMonth() ||
          (now.getMonth() === parsed.getMonth() && now.getDate() < parsed.getDate())
        ) {
          age--;
        }
      }
    }

    const temporaryPassword = generateTempPassword();
    let studentUser;
    try {
      studentUser = await auth.createUser({
        email: studentEmail,
        password: temporaryPassword,
        displayName: fullName,
      });
    } catch (e: unknown) {
      const err = e as { code?: string; message?: string };
      if (err.code === "auth/email-already-exists") {
        throw new functions.https.HttpsError(
          "already-exists",
          "This student email is already registered."
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        err.message ?? "Could not create student login."
      );
    }

    const studentId = db.collection(CHILDREN).doc().id;

    try {
      const batch = db.batch();

      batch.set(db.collection(USERS).doc(studentUser.uid), {
        uid: studentUser.uid,
        email: studentEmail,
        fullName,
        role: "Child",
        schoolId: parentSchoolId,
        linkedStudentId: studentId,
        mustChangePassword: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(db.collection(CHILDREN).doc(studentId), {
        schemaVersion: 1,
        schoolId: parentSchoolId,
        parentId,
        fullName,
        name: fullName,
        ...(age != null ? { age } : {}),
        ...(dobTimestamp ? { dateOfBirth: dobTimestamp } : {}),
        ...(gender ? { gender } : {}),
        vaccinations,
        imageUrl: "",
        accountMode: "self_login",
        studentUserId: studentUser.uid,
        studentEmail,
        healthModuleEnabled: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const relId = `${parentId}_${studentId}`;
      batch.set(db.collection(RELATIONSHIPS).doc(relId), {
        schoolId: parentSchoolId,
        parentId,
        studentId,
        relationshipType,
        isPrimary: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (gradeLevelId && classRoomId) {
        await enrollStudentIfNeeded({
          studentId,
          parentId,
          schoolId: parentSchoolId,
          classRoomId,
          gradeLevelId,
          fullName,
        });
      }

      return {
        studentId,
        studentUserId: studentUser.uid,
        studentEmail,
        temporaryPassword,
      };
    } catch (e) {
      await auth.deleteUser(studentUser.uid).catch(() => undefined);
      throw e;
    }
  }
);

/**
 * Scenario 2: Student links a parent — creates parent Auth + relationship.
 */
export const createParentForStudent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be signed in as a student."
      );
    }

    const studentUserId = context.auth.uid;
    const role = await getUserRole(studentUserId);
    if (role !== "Child") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only student accounts can invite a parent."
      );
    }

    const parentName = (data.parentName as string | undefined)?.trim();
    const parentEmail = (data.parentEmail as string | undefined)
      ?.trim()
      .toLowerCase();
    const relationshipType =
      (data.relationshipType as string | undefined) ?? "guardian";

    if (!parentName || !parentEmail) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "parentName and parentEmail are required."
      );
    }

    const studentProfile = await db.collection(USERS).doc(studentUserId).get();
    const studentId = studentProfile.data()?.linkedStudentId as
      | string
      | undefined;
    if (!studentId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Student profile is not linked. Complete registration first."
      );
    }

    const childDoc = await db.collection(CHILDREN).doc(studentId).get();
    const schoolId =
      (childDoc.data()?.schoolId as string | undefined) ?? "school_default";

    const temporaryPassword = generateTempPassword();
    let parentUser;
    try {
      parentUser = await auth.createUser({
        email: parentEmail,
        password: temporaryPassword,
        displayName: parentName,
      });
    } catch (e: unknown) {
      const err = e as { code?: string; message?: string };
      if (err.code === "auth/email-already-exists") {
        throw new functions.https.HttpsError(
          "already-exists",
          "This parent email is already registered."
        );
      }
      throw new functions.https.HttpsError(
        "internal",
        err.message ?? "Could not create parent login."
      );
    }

    try {
      const batch = db.batch();

      batch.set(db.collection(USERS).doc(parentUser.uid), {
        uid: parentUser.uid,
        email: parentEmail,
        fullName: parentName,
        role: "Parent",
        schoolId,
        mustChangePassword: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const relId = `${parentUser.uid}_${studentId}`;
      batch.set(db.collection(RELATIONSHIPS).doc(relId), {
        schoolId,
        parentId: parentUser.uid,
        studentId,
        relationshipType,
        isPrimary: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batch.set(
        db.collection(CHILDREN).doc(studentId),
        {
          parentId: parentUser.uid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      batch.set(db.collection("parent_invitations").doc(), {
        schoolId,
        studentId,
        studentUserId,
        parentEmail,
        parentName,
        relationshipType,
        status: "accepted",
        createdParentId: parentUser.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return {
        parentId: parentUser.uid,
        parentEmail,
        temporaryPassword,
      };
    } catch (e) {
      await auth.deleteUser(parentUser.uid).catch(() => undefined);
      throw e;
    }
  }
);
