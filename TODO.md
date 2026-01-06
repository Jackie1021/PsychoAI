# TODO: Social Match Technical Route

## 🎉 Recently Completed

- [x] ✅ **Fixed User Creation Bug** - Users are now automatically created on first login/match
- [x] ✅ **Fixed Post Creation** - Posts can now be created successfully
- [x] ✅ **Improved Match Algorithm** - Handles edge cases (empty traits, no matches)
- [x] ✅ **Seed Script Created** - Automated test data generation with 6 diverse users
- [x] ✅ **GEMINI API Integration** - LLM-powered matching analysis working
- [x] ✅ **Emulator Setup** - All services (Auth, Firestore, Storage, Functions) running

## 0. Environment & Tooling

- [x] Tighten Firebase Emulator coverage (Auth, Firestore, Storage, Functions) and sync `firebase.json` + `firestore.rules` with production defaults.
- [x] Ensure `START_BACKEND.sh` exports project IDs, region, and `GOOGLE_APPLICATION_CREDENTIALS`; document .env handling for teammates.
- [x] Add seed script (`scripts/seed_emulator.ts`) to create demo users/posts/matches for fast QA.

## 1. User Platform

- [x] ✅ Finalise canonical user schema (`lib/models/user_profile.dart`, `backend/functions/src/types/user.ts`) covering privacy, interests, geo, status flags.
- [x] ✅ Cloud Function auto-creates `/users/{uid}` on first interaction with defaults; guards against duplicates.
- [ ] Implement presence tracking (`lastActive`, `isOnline`) via RTDB presence or scheduled heartbeat function.
- [ ] Expose privacy controls (visibility levels, match opt-in) and enforce them in security rules + backend queries.

## 2. Post & Media Pipeline

- [x] ✅ Lock post schema (`lib/models/post.dart`) including media metadata, metrics, moderation flags, and author reference.
- [x] ✅ Wrap create/edit/delete in callable Cloud Functions for validation, storage uploads, and stats fan-out (`userStats.postsCount`).
- [x] ✅ Build transactional like/save toggles via batched writes; mirror counters under `/posts/{id}/metrics`.
- [x] ✅ Enforce soft delete (`softDeleted`, `moderationStatus`) and propagate removal to feeds/search indices.

## 3. Comment System Rebuild

- [x] ✅ Remove placeholder/default comments from UI and Firestore seeding logic.
- [x] ✅ Define comment model (`/posts/{postId}/comments/{commentId}`) with author, body, mentions, timestamps, softDelete.
- [x] ✅ Implement comment create/delete with validation, throttle spam, increment `metrics.commentsCount` atomically.
- [x] ✅ Hook Flutter UI to Firestore streams for real-time multi-user sync; add optimistic UI rollback on failure.
- [ ] Index comments by `createdAt` and configure security rules to block blocked users + enforce visibility.

## 4. Social Graph Integration

- [x] ✅ Model follow/block/save collections under `/users/{uid}/` for scalable pagination.
- [x] ✅ Sync denormalised counters (`followersCount`, `followingCount`, `likesCount`) through Firestore triggers.
- [ ] Update profile pages (`lib/pages/*profile_page*`) to hydrate authored posts, liked/saved posts, followed creators respecting privacy.

## 5. Match Engine

- [x] ✅ Fixed callable `getMatches` - now creates user document on-the-fly if missing
- [x] ✅ Align match candidate schema across backend and frontend with proper data structure
- [x] ✅ LLM integration working with Gemini API for compatibility analysis
- [x] ✅ Persist candidate pools in `/matches/{uid}/candidates` with scores and analysis
- [ ] Implement swipe actions (`like`, `skip`, `rewind`) -> Cloud Function writes to `/matches/{pairId}` with status timeline and reciprocity detection.
- [ ] Build match history/yearly report data provider (aggregations per month, top interests) feeding `lib/pages/yearly_report_page.dart`.
- [ ] Queue background refresh job (Pub/Sub or scheduled function) to replenish candidate pools based on activity & blocks.

## 6. Report & Block Workflows

- [x] ✅ Report submission UI and schema with reasons, evidence Storage refs, reporter metadata.
- [x] ✅ Cloud Function `handleReport` dedupes submissions, increments `reportCount`.
- [x] ✅ Block list writes to `/users/{uid}/blocks` and cascades properly.
- [ ] Trigger moderation queue when threshold exceeded
- [ ] Audit Storage & Firestore rules ensuring only reporters/moderators can access sensitive evidence.

## 7. Moderator Dashboard Backend

- [ ] Provide callable/HTTPS endpoints for queue listing, approve/reject actions, ban/unban, post restoration (only for custom-claim `moderator`).
- [ ] Log every moderation action to `/auditLogs` with before/after snapshots and actor metadata.
- [ ] Support filters (status, type, severity) and export (CSV / BigQuery sync) for analytics.

## 8. Observability & Resilience

- [ ] Instrument Functions with structured logging + trace IDs; route to BigQuery for retention.
- [ ] Add alerting (Error Reporting, Slack webhook) for function failures, moderation backlog, Firestore quota spikes.
- [ ] Define data retention & GDPR-compliant deletion flow (user-initiated wipe cascades posts/matches/comments/storage assets).

## 9. Testing & Delivery

- [ ] Extend backend Jest tests covering match mutual flows, comment spam throttling, report escalation, block enforcement.
- [ ] Add Flutter integration tests using emulators for post creation, comment sync, match swipes, profile hydration.
- [ ] Configure CI (GitHub Actions) to run `firebase emulators:exec` + `flutter test`; publish coverage & lint results.
- [ ] Document release checklist (Firestore indexes, rules deploy, function versioning, feature flags).

## 10. Milestones

- [x] ✅ **MVP Completed**: Auth + profile bootstrap, create/read posts, real comments, basic matching with LLM, report submission, block enforcement.
- [ ] **Phase 2 (Current)**: Advanced matching (scoring refresh, history page), likes/saves/follows integration, moderator tooling v1.
- [ ] **Phase 3**: Analytics & scalability (caching strategy, Pub/Sub pipelines, BigQuery dashboards, chat bootstrap planning).
