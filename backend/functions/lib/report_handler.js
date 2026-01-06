"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.reviewReport = exports.createReport = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const firestore_1 = require("firebase-admin/firestore");
const REPORT_THRESHOLD_AUTO_HIDE = 3; // Auto-hide after 3 reports
const REPORT_THRESHOLD_HIGH_PRIORITY = 5; // High priority review
const REPORT_THRESHOLD_AUTO_BAN = 10; // Auto-ban after 10 reports
/**
 * Creates a new report with automated moderation.
 */
exports.createReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to report");
    }
    const { targetType, targetId, reasonCode, detailsText, evidence } = data;
    if (!targetType || !targetId || !reasonCode) {
        throw new functions.https.HttpsError("invalid-argument", "Missing required fields");
    }
    const db = admin_1.admin.firestore();
    const reporterId = context.auth.uid;
    try {
        // Check if user has already reported this target
        const existingReport = await db
            .collection("reports")
            .where("reporterId", "==", reporterId)
            .where("targetId", "==", targetId)
            .get();
        if (!existingReport.empty) {
            throw new functions.https.HttpsError("already-exists", "You have already reported this content");
        }
        // Count total reports for this target
        const allReportsSnapshot = await db
            .collection("reports")
            .where("targetId", "==", targetId)
            .get();
        const totalReports = allReportsSnapshot.size + 1;
        const reportData = {
            reporterId,
            targetType,
            targetId,
            reasonCode,
            detailsText: detailsText || "",
            evidence: evidence || [],
            createdAt: firestore_1.FieldValue.serverTimestamp(),
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
                .set({
                reportCount: firestore_1.FieldValue.increment(1),
            }, { merge: true });
        }
        else if (targetType === "user") {
            await db
                .collection("users")
                .doc(targetId)
                .set({
                reportCount: firestore_1.FieldValue.increment(1),
            }, { merge: true });
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
            timestamp: firestore_1.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`Report created for ${targetType} ${targetId}. Total: ${totalReports}, Action: ${actionTaken}`);
        return {
            success: true,
            reportId: reportRef.id,
            totalReports,
            actionTaken,
            message: actionTaken !== "none"
                ? `Report submitted. Content has been ${actionTaken}.`
                : "Report submitted for review.",
        };
    }
    catch (error) {
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
async function autoHideContent(db, targetType, targetId) {
    if (targetType === "post") {
        await db.collection("posts").doc(targetId).update({
            status: "hidden",
            hiddenAt: firestore_1.FieldValue.serverTimestamp(),
            hiddenReason: "auto_moderation",
        });
        functions.logger.info(`Auto-hidden post: ${targetId}`);
    }
}
/**
 * Add to moderation queue
 */
async function addToModerationQueue(db, targetType, targetId, priority) {
    await db.collection("moderationQueue").add({
        targetType,
        targetId,
        priority,
        status: "pending",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
    functions.logger.info(`Added ${targetType} ${targetId} to moderation queue with ${priority} priority`);
}
/**
 * Auto-suspend user when threshold is reached
 */
async function autoSuspendUser(db, userId) {
    await db.collection("users").doc(userId).update({
        isSuspended: true,
        suspendedAt: firestore_1.FieldValue.serverTimestamp(),
        suspendedReason: "auto_moderation",
    });
    functions.logger.warn(`Auto-suspended user: ${userId}`);
}
/**
 * Review and resolve a report (admin function)
 */
exports.reviewReport = functions.https.onCall(async (data, context) => {
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
        throw new functions.https.HttpsError("invalid-argument", "reportId and action are required");
    }
    const db = admin_1.admin.firestore();
    try {
        const reportDoc = await db.collection("reports").doc(reportId).get();
        if (!reportDoc.exists) {
            throw new functions.https.HttpsError("not-found", "Report not found");
        }
        const report = reportDoc.data();
        // Update report status
        await db.collection("reports").doc(reportId).update({
            status: action === "resolve" ? "resolved" : "dismissed",
            reviewedBy: context.auth.uid,
            reviewedAt: firestore_1.FieldValue.serverTimestamp(),
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
            timestamp: firestore_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            message: `Report ${action === "resolve" ? "resolved" : "dismissed"}`,
        };
    }
    catch (error) {
        functions.logger.error("Error reviewing report:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", "Failed to review report");
    }
});
//# sourceMappingURL=report_handler.js.map