import { prisma } from '@/lib/db';
import {
  createSession,
  hashPassword,
  userToJson,
  verifyOtp,
  verifyPassword,
} from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function POST(req: Request) {
  const body = await readJson<{
    phone?: string;
    code?: string;
    password?: string;
    name?: string;
  }>(req);

  const phone = body.phone?.trim();
  const code = body.code?.trim();
  const password = body.password ?? '';

  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }
  if (!code || !/^\d{6}$/.test(code)) {
    return error('The verification code must be 6 digits.', 422);
  }
  if (password.length < 6) {
    return error('Password must be at least 6 characters.', 422);
  }

  const otp = await prisma.phoneOtp.findFirst({
    where: { phone, consumedAt: null },
    orderBy: { id: 'desc' },
  });

  if (!otp || otp.expiresAt < new Date()) {
    return error('The verification code is invalid or has expired.', 422);
  }
  if (otp.attempts >= 5) {
    return error('Too many attempts. Request a new code.', 422);
  }
  if (!(await verifyOtp(code, otp.codeHash))) {
    await prisma.phoneOtp.update({
      where: { id: otp.id },
      data: { attempts: { increment: 1 } },
    });
    return error('The verification code is incorrect.', 422);
  }

  await prisma.phoneOtp.update({
    where: { id: otp.id },
    data: { consumedAt: new Date() },
  });

  let user = await prisma.user.findUnique({
    where: { phone },
    include: { profile: true },
  });

  if (user) {
    if (!(await verifyPassword(password, user.passwordHash))) {
      return error('Incorrect password for this number.', 422);
    }
  } else {
    user = await prisma.user.create({
      data: {
        name: body.name?.trim() || 'BNYAD user',
        phone,
        email: `${phone.replace(/\D/g, '')}@phone.bnyad.app`,
        passwordHash: await hashPassword(password),
        phoneVerifiedAt: new Date(),
        profile: {
          create: { displayName: body.name?.trim() || '' },
        },
      },
      include: { profile: true },
    });
  }

  if (!user.phoneVerifiedAt) {
    user = await prisma.user.update({
      where: { id: user.id },
      data: { phoneVerifiedAt: new Date() },
      include: { profile: true },
    });
  }

  const token = await createSession(user.id);
  return json({ token, user: userToJson(user) });
}
