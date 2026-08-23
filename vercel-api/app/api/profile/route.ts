import { prisma } from '@/lib/db';
import { mapProfileUpdate, profileToJson, userFromAuthHeader } from '@/lib/auth';
import { error, json, options, readJson } from '@/lib/http';

export const runtime = 'nodejs';

export function OPTIONS() {
  return options();
}

export async function GET(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  let profile = user.profile;
  if (!profile) {
    profile = await prisma.userProfile.create({ data: { userId: user.id } });
  }

  return json({ data: profileToJson(profile) });
}

export async function PUT(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  const body = await readJson<Record<string, unknown>>(req);
  const data = mapProfileUpdate(body);

  const profile = await prisma.userProfile.upsert({
    where: { userId: user.id },
    create: { userId: user.id, ...data },
    update: data,
  });

  return json({ data: profileToJson(profile) });
}

export async function PATCH(req: Request) {
  return PUT(req);
}

export async function DELETE(req: Request) {
  const user = await userFromAuthHeader(req.headers.get('authorization'));
  if (!user) return error('Unauthenticated.', 401);

  await prisma.user.delete({ where: { id: user.id } });

  return json({
    ok: true,
    message: 'Profile and account deleted successfully.',
  });
}

