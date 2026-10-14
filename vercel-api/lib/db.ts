import { PrismaClient } from '@prisma/client';
import { assertStagingDatabase } from './staging';

// Runs before a staging Prisma client can issue any query, including auth writes.
// Production behavior/configuration is unchanged.
assertStagingDatabase();

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
