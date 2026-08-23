import { prisma } from '@/lib/db';
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
export async function POST(req: Request) {
  const body = await readJson<{
    phone?: string;
    password?: string;
    otpCode?: string;
  }>(req);

  const phone = body.phone?.trim();
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
    const isDemo =
      process.env.NODE_ENV !== 'production' &&
      process.env.APP_ENV !== 'production' &&
      code === DEMO_OTP;

    if (!isDemo) {
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

      const match = await verifyOtp(code, otp.codeHash);
      if (!match) {
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
