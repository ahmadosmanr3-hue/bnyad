type Environment = Record<string, string | undefined>;

/** Additional guard for staging only. Host/name must be approved independently
 * from Neon Console, not copied automatically from an arbitrary DATABASE_URL.
 * Never include connection strings or parser errors in thrown messages.
 */
export function assertStagingDatabase(env: Environment = process.env): void {
  if (env.APP_ENV !== 'staging') return;
  try {
    const db = new URL(env.DATABASE_URL ?? '');
    if (!['postgres:', 'postgresql:'].includes(db.protocol) ||
        !env.STAGING_DATABASE_HOST || !env.STAGING_DATABASE_NAME ||
        !/^[a-zA-Z0-9_-]{8,80}$/.test(env.STAGING_ENVIRONMENT_ID ?? '') ||
        db.hostname !== env.STAGING_DATABASE_HOST.toLowerCase() ||
        !db.hostname.endsWith('.neon.tech') ||
        decodeURIComponent(db.pathname.slice(1)) !== env.STAGING_DATABASE_NAME ||
        !db.username || !db.password ||
        !['require', 'verify-full'].includes(db.searchParams.get('sslmode') ?? '') ||
        env.AI_ENABLED !== 'false') {
      throw new Error();
    }
  } catch {
    throw new Error('Staging configuration rejected. Verify the approved isolated Neon host/database, TLS, environment identity and disabled AI.');
  }
}
