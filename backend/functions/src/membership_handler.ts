import * as functions from "firebase-functions";
import { admin } from "./admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

/**
 * Upgrades user membership
 */
export const upgradeMembership = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { tier, durationDays, subscriptionId } = data;
  
  if (!tier || !durationDays) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "tier and durationDays are required"
    );
  }

  const validTiers = ["free", "premium", "pro"];
  if (!validTiers.includes(tier)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid membership tier"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + durationDays);

    // Update user document
    await db.collection("users").doc(uid).update({
      membershipTier: tier,
      membershipExpiry: Timestamp.fromDate(expiry),
      subscriptionId: subscriptionId || `sub_${Date.now()}`,
      lastActive: FieldValue.serverTimestamp(),
    });

    // Log subscription
    await db
      .collection("users")
      .doc(uid)
      .collection("subscriptions")
      .add({
        tier,
        startDate: FieldValue.serverTimestamp(),
        expiryDate: Timestamp.fromDate(expiry),
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
      timestamp: FieldValue.serverTimestamp(),
    });

    functions.logger.info(`User ${uid} upgraded to ${tier}`);

    return {
      success: true,
      tier,
      expiry: expiry.toISOString(),
      message: `Successfully upgraded to ${tier}`,
    };
  } catch (error) {
    functions.logger.error("Error upgrading membership:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to upgrade membership"
    );
  }
});

/**
 * Cancels user membership
 */
export const cancelMembership = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    // Update user to free tier
    await db.collection("users").doc(uid).update({
      membershipTier: "free",
      membershipExpiry: null,
      lastActive: FieldValue.serverTimestamp(),
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
        cancelledAt: FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();

    // Create audit log
    await db.collection("auditLogs").add({
      action: "membership_cancelled",
      actorId: uid,
      targetType: "user",
      targetId: uid,
      timestamp: FieldValue.serverTimestamp(),
    });

    functions.logger.info(`User ${uid} cancelled membership`);

    return {
      success: true,
      message: "Membership cancelled successfully",
    };
  } catch (error) {
    functions.logger.error("Error cancelling membership:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to cancel membership"
    );
  }
});

/**
 * Scheduled function to check and expire memberships
 * Runs daily
 */
export const checkMembershipExpiry = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = Timestamp.now();

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
            expiredAt: FieldValue.serverTimestamp(),
          });
        });
      }

      await batch.commit();

      functions.logger.info(
        `Expired ${expiredUsers.size} memberships successfully`
      );

      return null;
    } catch (error) {
      functions.logger.error("Error checking membership expiry:", error);
      return null;
    }
  });
