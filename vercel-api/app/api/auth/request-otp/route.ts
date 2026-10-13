import { safeRoute } from '@/lib/http';
import { prisma } from '@/lib/db';
import { DEMO_OTP, hashOtp, isProduction } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';
import { sendSmsOtp } from '@/lib/sms';
import crypto from 'node:crypto';
import { limitAuth } from '@/lib/security';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

async function handlePOST(req: Request) {
  const body = await readJson<{ phone?: string }>(req);
  const phone = body.phone?.trim();
  const limited = await limitAuth(req, phone);
  if (limited) return limited;
  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }

  // Check if user is registered
  const user = await prisma.user.findUnique({ where: { phone } });
  const registered = !!user;

  await prisma.phoneOtp.deleteMany({ where: { phone, consumedAt: null } });

  const allowDemo = !isProduction() && process.env.ALLOW_DEMO_OTP === 'true';
  if (!allowDemo && !process.env.OTPIQ_API_KEY) {
    return error('Verification delivery is temporarily unavailable.', 503);
  }
  const code = allowDemo ? DEMO_OTP : String(crypto.randomInt(100000, 1000000));

  const otp = await prisma.phoneOtp.create({
    data: {
      phone,
      codeHash: await hashOtp(code),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    },
  });

  if (!allowDemo && !(await sendSmsOtp(phone, code))) {
    await prisma.phoneOtp.deleteMany({ where: { id: otp.id } });
    return error('Could not send the verification code. Please try again.', 503);
  }

  return json({
    registered,
    message: 'OTP sent.',
    demo_code: allowDemo ? code : null,
  });
}

export const POST = safeRoute(handlePOST);
