/// Public mobile configuration only. Supply values with dart-define.
library;


/// Base URL of the backend API (no trailing slash on host; include `/api`).
/// Production (Vercel): 'https://nutrify-api-lovat.vercel.app/api'
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://nutrify-api-lovat.vercel.app/api');

/// RevenueCat API Keys
const String rcAndroidApiKey = String.fromEnvironment('RC_ANDROID_PUBLIC_KEY');
const String rcIosApiKey = String.fromEnvironment('RC_IOS_PUBLIC_KEY');
