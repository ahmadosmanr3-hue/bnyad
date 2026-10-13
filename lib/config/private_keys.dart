/// Build-time configuration. Never put server credentials in a mobile binary.
library;

const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://nutrify-api-lovat.vercel.app/api',
);
// RevenueCat PUBLIC SDK keys only; secret REST API keys belong on the server.
const String rcAndroidApiKey = String.fromEnvironment('RC_ANDROID_PUBLIC_KEY');
const String rcIosApiKey = String.fromEnvironment('RC_IOS_PUBLIC_KEY');
