import * as functions from "firebase-functions";
import { admin } from "./admin";
import { FieldValue } from "firebase-admin/firestore";

const REPORT_THRESHOLD_AUTO_HIDE = 3;  // Auto-hide after 3 reports
const REPORT_THRESHOLD_HIGH_PRIORITY = 5;  // High priority review
const REPORT_THRESHOLD_AUTO_BAN = 10;  // Auto-ban after 10 reports

interface ReportData {
  reporterId: string;
  targetType: "post" | "user";
  targetId: string;
  reasonCode: "spam" | "abuse" | "nudity" | "other";
  detailsText?: string;
  evidence?: string[];
  createdAt: admin.firestore.FieldValue;
  status: "pending" | "reviewed" | "resolved" | "dismissed";
  autoHidden: boolean;
  reportCount: number;
}

/**
 * Creates a new report with automated moderation.
 */
export const createReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to report"
    );
  }

  const { targetType, targetId, reasonCode, detailsText, evidence } = data;

  if (!targetType || !targetId || !reasonCode) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields"
    );
  }

  const db = admin.firestore();
  const reporterId = context.auth.uid;

  try {
    // Check if user has already reported this target
    const existingReport = await db
      .collection("reports")
      .where("reporterId", "==", reporterId)
      .where("targetId", "==", targetId)
      .get();

    if (!existingReport.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "You have already reported this content"
      );
    }

    // Count total reports for this target
    const allReportsSnapshot = await db
      .collection("reports")
      .where("targetId", "==", targetId)
      .get();

    const totalReports = allReportsSnapshot.size + 1;

    const reportData: ReportData = {
      reporterId,
      targetType,
      targetId,
      reasonCode,
      detailsText: detailsText || "",
      evidence: evidence || [],
      createdAt: FieldValue.serverTimestamp(),
      status: "pending",
      autoHidden: false,
      reportCount: totalReports,
    };

    // Create report
    const reportRef = await db.collection("reports").add(reportData);

    // Automated moderation logic
    let actionTaken = "none";

    // Threshold 1: Auto-hide (3 reports)
    if (totalReports >= REPORT_THRESHOLD_AUTO_HIDE) {
      await autoHideContent(db, targetType, targetId);
      await db.collection("reports").doc(reportRef.id).update({
        autoHidden: true,
      });
      actionTaken = "hidden";
    }

    // Threshold 2: High priority queue (5 reports)
    if (totalReports >= REPORT_THRESHOLD_HIGH_PRIORITY) {
      await addToModerationQueue(db, targetType, targetId, "high");
      actionTaken = "high_priority";
    }

    // Threshold 3: Auto-ban user (10 reports)
    if (totalReports >= REPORT_THRESHOLD_AUTO_BAN && targetType === "user") {
      await autoSuspendUser(db, targetId);
      actionTaken = "suspended";
    }

    // Update target's report count
    if (targetType === "post") {
      await db
        .collection("posts")
        .doc(targetId)
        .set(
          {
            reportCount: FieldValue.increment(1),
          },
          { merge: true }
        );
    } else if (targetType === "user") {
      await db
        .collection("users")
        .doc(targetId)
        .set(
          {
            reportCount: FieldValue.increment(1),
          },
          { merge: true }
        );
    }

    // Create audit log
    await db.collection("auditLogs").add({
      action: "report_created",
      actorId: reporterId,
      targetType,
      targetId,
      details: {
        reasonCode,
        totalReports,
        actionTaken,
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    functions.logger.info(
      `Report created for ${targetType} ${targetId}. Total: ${totalReports}, Action: ${actionTaken}`
    );

    return {
      success: true,
      reportId: reportRef.id,
      totalReports,
      actionTaken,
      message: actionTaken !== "none" 
        ? `Report submitted. Content has been ${actionTaken}.`
        : "Report submitted for review.",
    };
  } catch (error) {
    functions.logger.error("Error creating report:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "Failed to create report");
  }
});

/**
 * Auto-hide content when threshold is reached
 */
async function autoHideContent(
  db: admin.firestore.Firestore,
  targetType: string,
  targetId: string
): Promise<void> {
  if (targetType === "post") {
    await db.collection("posts").doc(targetId).update({
      status: "hidden",
      hiddenAt: FieldValue.serverTimestamp(),
      hiddenReason: "auto_moderation",
    });
    functions.logger.info(`Auto-hidden post: ${targetId}`);
  }
}

/**
 * Add to moderation queue
 */
async function addToModerationQueue(
  db: admin.firestore.Firestore,
  targetType: string,
  targetId: string,
  priority: string
): Promise<void> {
  await db.collection("moderationQueue").add({
    targetType,
    targetId,
    priority,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });
  functions.logger.info(
    `Added ${targetType} ${targetId} to moderation queue with ${priority} priority`
  );
}

/**
 * Auto-suspend user when threshold is reached
 */
async function autoSuspendUser(
  db: admin.firestore.Firestore,
  userId: string
): Promise<void> {
  await db.collection("users").doc(userId).update({
    isSuspended: true,
    suspendedAt: FieldValue.serverTimestamp(),
    suspendedReason: "auto_moderation",
  });

  functions.logger.warn(`Auto-suspended user: ${userId}`);
}

/**
 * Review and resolve a report (admin function)
 */
export const reviewReport = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Not authenticated");
  }

  // TODO: Check if user is admin
  // const isAdmin = await checkAdminStatus(context.auth.uid);
  // if (!isAdmin) {
  //   throw new functions.https.HttpsError("permission-denied", "Admin only");
  // }

  const { reportId, action, reviewNote } = data;

  if (!reportId || !action) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "reportId and action are required"
    );
  }

  const db = admin.firestore();

  try {
    const reportDoc = await db.collection("reports").doc(reportId).get();
    
    if (!reportDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Report not found");
    }

    const report = reportDoc.data() as ReportData;

    // Update report status
    await db.collection("reports").doc(reportId).update({
      status: action === "resolve" ? "resolved" : "dismissed",
      reviewedBy: context.auth.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      reviewNote: reviewNote || "",
    });

    // Create audit log
    await db.collection("auditLogs").add({
      action: "report_reviewed",
      actorId: context.auth.uid,
      targetType: report.targetType,
      targetId: report.targetId,
      details: {
        reportId,
        action,
        reviewNote,
      },
      timestamp: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: `Report ${action === "resolve" ? "resolved" : "dismissed"}`,
    };
  } catch (error) {
    functions.logger.error("Error reviewing report:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "Failed to review report");
  }
});
