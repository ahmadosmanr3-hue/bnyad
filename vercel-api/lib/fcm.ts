import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';

/** FCM topic every app install subscribes to for admin broadcasts. */
export const ALL_USERS_TOPIC = 'bnyad_all';

let initialized = false;

function ensureFirebase() {
  if (initialized) return true;
  let cred: admin.ServiceAccount | null = null;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (raw) {
    try {
      cred = JSON.parse(raw) as admin.ServiceAccount;
    } catch (e) {
      console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT_JSON env var:', e);
    }
  }

  if (!cred) {
    const paths = [
      path.join(process.cwd(), 'service_account.json'),
      path.join(process.cwd(), '..', 'service_account.json'),
    ];
    for (const p of paths) {
      if (fs.existsSync(p)) {
        try {
          cred = JSON.parse(fs.readFileSync(p, 'utf8')) as admin.ServiceAccount;
          console.log(`[Firebase] Loaded credentials from file: ${p}`);
          break;
        } catch (e) {
          console.error(`Failed to parse ${p}:`, e);
        }
      }
    }
  }

  if (!cred) {
    console.error('Firebase init failed: No service account credentials found in environment variables or service_account.json file.');
    return false;
  }

  try {
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
  const targetDesc = 'token' in target ? `token (${target.token.slice(0, 10)}...)` : `topic (${target.topic})`;

  if (!ensureFirebase()) {
    console.warn(`[FCM Push Skipped] Firebase not initialized. Target: ${targetDesc}`);
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
          sound: 'default',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            sound: 'default',
            badge: 1,
            'content-available': 1,
          },
        },
      },
      ...('token' in target ? { token: target.token } : { topic: target.topic }),
    };

    await admin.messaging().send(message);
    console.log(`[FCM Push Sent] Target: ${targetDesc}, Title: "${title}", Body: "${body}"`);
    return { sent: true };
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'FCM send failed';
    console.error(`[FCM Push Failed] Target: ${targetDesc}, Error:`, msg);
    return { sent: false, error: msg };
  }
}
