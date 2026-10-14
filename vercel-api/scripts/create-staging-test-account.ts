// MANUAL after migration/test-data approval, never part of install/build/deploy.
import { assertStagingDatabase } from '../lib/staging';
import { prisma } from '../lib/db';
import { hashPassword } from '../lib/auth';

async function main() {
  if (process.env.APP_ENV !== 'staging' ||
      process.env.STAGING_TEST_DATA_APPROVED !== 'true') {
    throw new Error('Explicit staging test-data approval is required.');
  }
  assertStagingDatabase();
  const password = process.env.STAGING_TEST_PASSWORD ?? '';
  if (password.length < 16) throw new Error('Set a private staging test password of at least 16 characters.');
  // No OTP provider or phone call is used. This synthetic account still uses
  // normal bcrypt password verification and normal bearer session creation.
  await prisma.user.create({
    data: {
      name: 'BNYAD QA',
      email: 'bnyad-qa@example.test',
      phone: '+9647000000000',
      passwordHash: await hashPassword(password),
      phoneVerifiedAt: new Date(),
      profile: { create: { displayName: 'BNYAD QA' } },
    },
  });
  console.log('Synthetic staging test account created. Existing accounts were not modified.');
}

main().catch(() => {
  // Prisma errors may contain parameters; do not dump exception details.
  console.error('Staging account creation failed. Verify approval/configuration, migrations and that the fixture account does not already exist.');
  process.exitCode = 1;
}).finally(() => prisma.$disconnect());
