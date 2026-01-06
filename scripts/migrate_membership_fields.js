#!/usr/bin/env node

/**
 * Migration script to add membership fields to existing users
 * Run this with: node scripts/migrate_membership_fields.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('../backend/service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateMembershipFields() {
  console.log('🔄 Starting membership fields migration...\n');

  try {
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();

    if (snapshot.empty) {
      console.log('⚠️  No users found in database');
      return;
    }

    console.log(`📊 Found ${snapshot.size} users to check\n`);

    let updatedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();
    let batchCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Check if user already has membership fields
      if (data.membershipTier !== undefined) {
        console.log(`⏭️  Skipping ${doc.id} - already has membership fields`);
        skippedCount++;
        continue;
      }

      // Add default membership fields
      batch.update(doc.ref, {
        membershipTier: 'free',
        membershipExpiry: null,
        subscriptionId: null,
      });

      batchCount++;
      updatedCount++;
      console.log(`✅ Queued ${doc.id} for update (${data.username || 'Unknown'})`);

      // Commit batch every 500 documents (Firestore limit)
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`\n💾 Committed batch of ${batchCount} updates\n`);
        batchCount = 0;
      }
    }

    // Commit remaining updates
    if (batchCount > 0) {
      await batch.commit();
      console.log(`\n💾 Committed final batch of ${batchCount} updates\n`);
    }

    console.log('✅ Migration completed successfully!');
    console.log(`   - Updated: ${updatedCount} users`);
    console.log(`   - Skipped: ${skippedCount} users (already migrated)`);
    console.log(`   - Total: ${snapshot.size} users`);

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }

  process.exit(0);
}

// Run migration
migrateMembershipFields();
