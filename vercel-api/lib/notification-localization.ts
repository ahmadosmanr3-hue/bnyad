import { RequestError } from './http';

export type NotificationText = { title: string; body: string };
export type NotificationTranslations = Record<'en' | 'ar' | 'ckb', NotificationText>;

/** Optional authored translations; never machine-translate private messages. */
export function parseNotificationTranslations(raw: unknown): NotificationTranslations | undefined {
  if (raw === undefined) return undefined;
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) throw new RequestError('Invalid notification translations.');
  const source = raw as Record<string, unknown>;
  if (Object.keys(source).some(k => !['en', 'ar', 'ckb', 'ku'].includes(k)) || (source.ckb && source.ku)) {
    throw new RequestError('Use en, ar and ckb notification translations (ku is a legacy alias).');
  }
  const result = {} as NotificationTranslations;
  for (const lang of ['en','ar','ckb'] as const) {
    const item = source[lang] ?? (lang === 'ckb' ? source.ku : undefined);
    if (!item || typeof item !== 'object' || Array.isArray(item)) throw new RequestError('Provide all three notification languages.');
    const text = item as Record<string, unknown>;
    if (Object.keys(text).some(k => !['title','body'].includes(k))) throw new RequestError('Invalid translated notification fields.');
    for (const [key, max] of [['title', 120], ['body', 4000]] as const) {
      if (typeof text[key] !== 'string' || !text[key].trim() || text[key].length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(text[key])) {
        throw new RequestError('Invalid translated notification text.');
      }
    }
    result[lang] = { title: (text.title as string).trim(), body: (text.body as string).trim() };
  }
  return result;
}

export function localizedNotification(note: NotificationText & { translations?: unknown }, language?: string | null): NotificationText {
  const lang = language === 'ku' ? 'ckb' : language ?? 'en';
  const map = note.translations as Record<string, NotificationText> | null | undefined;
  const text = map?.[lang];
  return text && typeof text.title === 'string' && typeof text.body === 'string'
    ? { title: text.title, body: text.body } : { title: note.title, body: note.body };
}
