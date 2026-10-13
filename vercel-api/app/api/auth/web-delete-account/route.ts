import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { limitAuth } from '@/lib/security';
import { DEMO_OTP, verifyOtp, verifyPassword } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

/**
 * Web-based self-service account deletion endpoint.
 * Allows users who may not have the mobile app installed to verify
 * their account via password or SMS OTP and permanently delete it.
 */
async function handlePOST(req: Request) {
  const body = await readJson<{
    phone?: string;
    password?: string;
    otpCode?: string;
  }>(req);

  const phone = body.phone?.trim();
  const limited = await limitAuth(req, phone);
  if (limited) return limited;
  if (!phone) {
    return error('Phone number is required.', 422);
  }

  const user = await prisma.user.findFirst({
    where: {
      OR: [
        { phone },
        { phone: phone.startsWith('+') ? phone.slice(1) : `+${phone}` },
      ],
    },
  });

  if (!user) {
    return error('No account found with this phone number.', 404);
  }

  // Verification method 1: Password
  if (body.password) {
    const valid = await verifyPassword(body.password, user.passwordHash);
    if (!valid) {
      return error('Incorrect password.', 401);
    }
  }
  // Verification method 2: SMS OTP
  else if (body.otpCode) {
    const code = body.otpCode.trim();
    {
      const otp = await prisma.phoneOtp.findFirst({
        where: { phone, consumedAt: null },
        orderBy: { createdAt: 'desc' },
      });

      if (!otp || otp.expiresAt < new Date()) {
        return error('The verification code is invalid or has expired.', 422);
      }
      if (otp.attempts >= 5) {
        return error('Too many attempts. Please request a new code.', 429);
      }

      const attempt = await prisma.phoneOtp.updateMany({
        where: { id: otp.id, consumedAt: null, attempts: { lt: 5 }, expiresAt: { gt: new Date() } },
        data: { attempts: { increment: 1 } },
      });
      if (!attempt.count) return error('Too many attempts. Please request a new code.', 429);

      const match = await verifyOtp(code, otp.codeHash);
      if (!match) {
        return error('The verification code is incorrect.', 422);
      }

      const claimed = await prisma.phoneOtp.updateMany({
        where: { id: otp.id, consumedAt: null, expiresAt: { gt: new Date() } },
        data: { consumedAt: new Date() },
      });
      if (!claimed.count) return error('The verification code was already used.', 422);
    }
  } else {
    return error('Please provide either your password or SMS verification code.', 422);
  }

  // Permanently delete user and all cascading relations
  await prisma.user.delete({
    where: { id: user.id },
  });

  return json({
    ok: true,
    message: 'Your account and all associated personal data have been permanently deleted.',
  });
}

export const POST = safeRoute(handlePOST);
