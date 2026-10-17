-- Prepared only. The release developer must approve/backup/apply this to the
-- intended environment BEFORE deploying the new generated Prisma client/API.
-- No existing notification text or production records are rewritten.
ALTER TABLE "notifications" ADD COLUMN IF NOT EXISTS "translations" JSONB;
