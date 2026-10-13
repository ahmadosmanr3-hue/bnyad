-- MANUAL additive migration; test on staging and back up before approved deployment.
-- No changes to existing profiles, tokens, plans or subscriptions.
CREATE TABLE IF NOT EXISTS ai_consents (
 user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
 version TEXT NOT NULL, enabled BOOLEAN NOT NULL DEFAULT FALSE,
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS ai_usage (
 id TEXT PRIMARY KEY, user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
 operation TEXT NOT NULL, model TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 budget_period TEXT NOT NULL, reserved_micros BIGINT NOT NULL, charged_micros BIGINT NOT NULL,
 input_tokens INTEGER NOT NULL DEFAULT 0, output_tokens INTEGER NOT NULL DEFAULT 0,
 status TEXT NOT NULL DEFAULT 'reserved', cache_key TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS ai_usage_user_time ON ai_usage(user_id, created_at);
CREATE INDEX IF NOT EXISTS ai_usage_budget ON ai_usage(budget_period);
CREATE TABLE IF NOT EXISTS ai_cache (
 user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 key TEXT NOT NULL, response JSONB NOT NULL, expires_at TIMESTAMPTZ NOT NULL,
 PRIMARY KEY(user_id, key)
);
