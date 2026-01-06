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
exports.checkMembershipExpiry = exports.cancelMembership = exports.upgradeMembership = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Upgrades user membership
 */
exports.upgradeMembership = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { tier, durationDays, subscriptionId } = data;
    if (!tier || !durationDays) {
        throw new functions.https.HttpsError("invalid-argument", "tier and durationDays are required");
    }
    const validTiers = ["free", "premium", "pro"];
    if (!validTiers.includes(tier)) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid membership tier");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    try {
        const expiry = new Date();
        expiry.setDate(expiry.getDate() + durationDays);
        // Update user document
        await db.collection("users").doc(uid).update({
            membershipTier: tier,
            membershipExpiry: firestore_1.Timestamp.fromDate(expiry),
            subscriptionId: subscriptionId || `sub_${Date.now()}`,
            lastActive: firestore_1.FieldValue.serverTimestamp(),
        });
        // Log subscription
        await db
            .collection("users")
            .doc(uid)
            .collection("subscriptions")
            .add({
            tier,
            startDate: firestore_1.FieldValue.serverTimestamp(),
            expiryDate: firestore_1.Timestamp.fromDate(expiry),
            subscriptionId: subscriptionId || `sub_${Date.now()}`,
            status: "active",
            durationDays,
        });
        // Create audit log
        await db.collection("auditLogs").add({
            action: "membership_upgraded",
            actorId: uid,
            targetType: "user",
            targetId: uid,
            details: {
                tier,
                expiryDate: expiry.toISOString(),
            },
            timestamp: firestore_1.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`User ${uid} upgraded to ${tier}`);
        return {
            success: true,
            tier,
            expiry: expiry.toISOString(),
            message: `Successfully upgraded to ${tier}`,
        };
    }
    catch (error) {
        functions.logger.error("Error upgrading membership:", error);
        throw new functions.https.HttpsError("internal", "Failed to upgrade membership");
    }
});
/**
 * Cancels user membership
 */
exports.cancelMembership = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    try {
        // Update user to free tier
        await db.collection("users").doc(uid).update({
            membershipTier: "free",
            membershipExpiry: null,
            lastActive: firestore_1.FieldValue.serverTimestamp(),
        });
        // Mark subscriptions as cancelled
        const subscriptionsSnapshot = await db
            .collection("users")
            .doc(uid)
            .collection("subscriptions")
            .where("status", "==", "active")
            .get();
        const batch = db.batch();
        subscriptionsSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, {
                status: "cancelled",
                cancelledAt: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
        // Create audit log
        await db.collection("auditLogs").add({
            action: "membership_cancelled",
            actorId: uid,
            targetType: "user",
            targetId: uid,
            timestamp: firestore_1.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`User ${uid} cancelled membership`);
        return {
            success: true,
            message: "Membership cancelled successfully",
        };
    }
    catch (error) {
        functions.logger.error("Error cancelling membership:", error);
        throw new functions.https.HttpsError("internal", "Failed to cancel membership");
    }
});
/**
 * Scheduled function to check and expire memberships
 * Runs daily
 */
exports.checkMembershipExpiry = functions.pubsub
    .schedule("every 24 hours")
    .onRun(async (context) => {
    const db = admin_1.admin.firestore();
    const now = firestore_1.Timestamp.now();
    try {
        // Find users with expired memberships
        const expiredUsers = await db
            .collection("users")
            .where("membershipExpiry", "<=", now)
            .where("membershipTier", "!=", "free")
            .get();
        functions.logger.info(`Found ${expiredUsers.size} expired memberships`);
        const batch = db.batch();
        expiredUsers.docs.forEach((doc) => {
            batch.update(doc.ref, {
                membershipTier: "free",
                membershipExpiry: null,
            });
        });
        // Mark subscriptions as expired
        for (const doc of expiredUsers.docs) {
            const subscriptionsSnapshot = await db
                .collection("users")
                .doc(doc.id)
                .collection("subscriptions")
                .where("status", "==", "active")
                .where("expiryDate", "<=", now)
                .get();
            subscriptionsSnapshot.docs.forEach((subDoc) => {
                batch.update(subDoc.ref, {
                    status: "expired",
                    expiredAt: firestore_1.FieldValue.serverTimestamp(),
                });
            });
        }
        await batch.commit();
        functions.logger.info(`Expired ${expiredUsers.size} memberships successfully`);
        return null;
    }
    catch (error) {
        functions.logger.error("Error checking membership expiry:", error);
        return null;
    }
});
//# sourceMappingURL=membership_handler.js.map