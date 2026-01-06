import * as admin from "firebase-admin";
import "firebase-admin/firestore";

// Initialize Firebase Admin SDK once
if (!admin.apps.length) {
  admin.initializeApp();
}

// Wait for firestore to be ready
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const FieldPath = admin.firestore.FieldPath;

// Export documentId() as a helper function for convenience
// Use the static method directly from the class
const documentId = () => admin.firestore.FieldPath.documentId();

export { admin, db, FieldValue, FieldPath, documentId };
