import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { limitAuth } from '@/lib/security';
import {
  createSession,
  hashPassword,
  userToJson,
  verifyOtp,
} from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

async function handlePOST(req: Request) {
  const body = await readJson<{
    phone?: string;
    code?: string;
    password?: string;
    name?: string;
    fcmToken?: string;
    fcm_token?: string;
  }>(req);

  const phone = body.phone?.trim();
  const limited = await limitAuth(req, phone);
  if (limited) return limited;
  const code = body.code?.trim();
  const password = body.password ?? '';
  const fcmToken = body.fcmToken?.trim() || body.fcm_token?.trim();

  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }
  if (!code || !/^\d{6}$/.test(code)) {
    return error('The verification code must be 6 digits.', 422);
  }

  let user = await prisma.user.findUnique({
    where: { phone },
    include: { profile: true, subscriptions: true },
  });

  if (!user && password.length < 6) return error('Password must be at least 6 characters.', 422);

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
  // Reserve an attempt atomically, including concurrent requests.
  const attempt = await prisma.phoneOtp.updateMany({
    where: { id: otp.id, consumedAt: null, attempts: { lt: 5 }, expiresAt: { gt: new Date() } },
    data: { attempts: { increment: 1 } },
  });
  if (!attempt.count) return error('Too many attempts. Request a new code.', 422);
  if (!(await verifyOtp(code, otp.codeHash))) {
    return error('The verification code is incorrect.', 422);
  }

  const claimed = await prisma.phoneOtp.updateMany({
    where: { id: otp.id, consumedAt: null, expiresAt: { gt: new Date() } },
    data: { consumedAt: new Date() },
  });
  if (!claimed.count) return error('The verification code was already used.', 422);


  if (user) {
    // Returning user — OTP only (no password re-entry). Update FCM token if sent.
    if (fcmToken) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { fcmToken },
        include: { profile: true, subscriptions: true },
      });
    }
  } else {
    if (password.length < 6) {
      return error('Password must be at least 6 characters.', 422);
    }
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
        fcmToken: fcmToken || null,
      },
      include: { profile: true, subscriptions: true },
    });
  }

  if (!user.phoneVerifiedAt) {
    user = await prisma.user.update({
      where: { id: user.id },
      data: { 
        phoneVerifiedAt: new Date(),
        ...(fcmToken ? { fcmToken } : {})
      },
      include: { profile: true, subscriptions: true },
    });
  }

  const token = await createSession(user.id);
  return json({ token, user: userToJson(user) });
}

export const POST = safeRoute(handlePOST);
