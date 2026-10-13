-- Additive only. Run explicitly against a backed-up development database first.
-- Never executed by npm install or a Vercel build.
CREATE TABLE IF NOT EXISTS auth_rate_limits (
  key TEXT PRIMARY KEY,
  bucket INTEGER NOT NULL,
  count INTEGER NOT NULL DEFAULT 0
);
