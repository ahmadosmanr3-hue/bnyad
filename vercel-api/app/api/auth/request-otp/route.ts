import { prisma } from '@/lib/db';
import { DEMO_OTP, hashOtp, isProduction } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';
import { sendSmsOtp } from '@/lib/sms';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function POST(req: Request) {
  const body = await readJson<{ phone?: string }>(req);
  const phone = body.phone?.trim();
  if (!phone || !/^\+?[0-9]{7,15}$/.test(phone)) {
    return error('Enter a valid phone number.', 422);
  }

  // Check if user is registered
  const user = await prisma.user.findUnique({ where: { phone } });
  const registered = !!user;

  await prisma.phoneOtp.deleteMany({ where: { phone, consumedAt: null } });

  const isRealOtp = isProduction() || !!process.env.OTPIQ_API_KEY;
  const code = isRealOtp ? String(Math.floor(100000 + Math.random() * 900000)) : DEMO_OTP;

  await prisma.phoneOtp.create({
    data: {
      phone,
      codeHash: await hashOtp(code),
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
    },
  });

  if (isRealOtp) {
    await sendSmsOtp(phone, code);
  }

  return json({
    registered,
    message: 'OTP sent.',
    demo_code: isProduction() ? null : code,
  });
}
