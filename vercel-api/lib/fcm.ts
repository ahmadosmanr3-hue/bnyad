import admin from 'firebase-admin';

/** FCM topic every app install subscribes to for admin broadcasts. */
export const ALL_USERS_TOPIC = 'bnyad_all';

let initialized = false;

function ensureFirebase() {
  if (initialized) return true;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return false;
  try {
    const cred = JSON.parse(raw) as admin.ServiceAccount;
    if (!admin.apps.length) {
      admin.initializeApp({ credential: admin.credential.cert(cred) });
    }
    initialized = true;
    return true;
  } catch (e) {
    console.error('Firebase init failed:', e);
    return false;
  }
}

export type PushResult = { sent: boolean; error?: string };

/** Sends a visible push notification (works when the app is closed on Android). */
export async function sendPush(
  target: { token: string } | { topic: string },
  title: string,
  body: string,
): Promise<PushResult> {
  if (!ensureFirebase()) {
    return { sent: false, error: 'FIREBASE_SERVICE_ACCOUNT_JSON is not configured.' };
  }

  try {
    const message: admin.messaging.Message = {
      notification: { title, body },
      data: { title, body },
      android: {
        priority: 'high',
        notification: {
          channelId: 'meal_reminders_v2',
          priority: 'high',
        },
      },
      ...('token' in target ? { token: target.token } : { topic: target.topic }),
    };

    await admin.messaging().send(message);
    return { sent: true };
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'FCM send failed';
    console.error('FCM send error:', msg);
    return { sent: false, error: msg };
  }
}
