import React from 'react';

export const metadata = {
  title: 'Privacy Policy — BNYAD (Nutrify)',
  description: 'Privacy Policy and data protection terms for the BNYAD (Nutrify) application.',
};

export default function PrivacyPolicyPage() {
  return (
    <div style={{
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      backgroundColor: '#0F172A',
      color: '#E2E8F0',
      minHeight: '100vh',
      padding: '40px 20px',
      lineHeight: '1.6'
    }}>
      <div style={{
        maxWidth: '800px',
        margin: '0 auto',
        backgroundColor: '#1E293B',
        padding: '40px',
        borderRadius: '16px',
        border: '1px solid #334155',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3)'
      }}>
        <div style={{ borderBottom: '1px solid #334155', paddingBottom: '20px', marginBottom: '30px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: '800', color: '#F8FAFC', margin: '0 0 10px 0' }}>
            Privacy Policy — BNYAD (Nutrify)
          </h1>
          <p style={{ color: '#94A3B8', fontSize: '14px', margin: 0 }}>
            Last Updated: August 13, 2026
          </p>
        </div>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>1. Introduction</h2>
          <p>
            Welcome to <strong>BNYAD</strong> (also referred to as &quot;Nutrify&quot;). We prioritize the privacy and security of your personal health, fitness, and nutrition data. This Privacy Policy explains how we collect, use, store, and protect your information when you use our mobile application and backend services.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>2. Information We Collect</h2>
          <p>In full compliance with App Store Guidelines, we explicitly disclose what data is collected and how it is gathered:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}>
              <strong>Account Information:</strong> Phone number and optional profile name collected directly from you during sign-up for secure OTP authentication.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Health & Physical Metrics:</strong> Age, gender, height, current weight, target weight, activity level, and body circumference measurements (waist, neck, hip) submitted directly by you to compute daily caloric goals and body fat estimations.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Nutrition & Food Logs:</strong> Logged food entries, water consumption, custom recipes, meal photos, and text inputs logged in-app to track nutritional progress.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Device & Technical Telemetry:</strong> Firebase Cloud Messaging (FCM) device tokens collected automatically upon granting notification permissions to deliver opt-in meal reminders.
            </li>
          </ul>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>3. How We Use Your Information</h2>
          <p>All collected information is used strictly for the following purposes:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}>Calculate personalized daily caloric targets, macronutrient splits, and body fat metrics using peer-reviewed mathematical formulas (e.g., Mifflin-St Jeor).</li>
            <li style={{ marginBottom: '8px' }}>Sync, organize, and present your historical food logs, weight entries, and meal schedules across your authorized devices.</li>
            <li style={{ marginBottom: '8px' }}>Dispatch requested push notifications for meal and supplement schedules configured by you.</li>
            <li style={{ marginBottom: '8px' }}>Verify subscription entitlements and receipt validity via Apple In-App Purchases and RevenueCat.</li>
            <li style={{ marginBottom: '8px' }}>Provide optional AI-assisted meal analysis, barcode resolution, or nutrition advice (subject to explicit in-app user permission as detailed below).</li>
          </ul>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>4. Data Sharing & Third Parties</h2>
          <p>
            <strong>We do NOT sell, rent, or trade your personal health data to third parties, data brokers, or advertisers.</strong>
          </p>
          <p style={{ marginTop: '8px' }}>We share data only with essential service providers necessary for operating core app functions:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}><strong>Apple App Store / RevenueCat:</strong> To manage in-app subscriptions and purchase receipts securely.</li>
            <li style={{ marginBottom: '8px' }}><strong>Firebase Cloud Messaging (FCM):</strong> To dispatch opt-in push notifications.</li>
            <li style={{ marginBottom: '8px' }}><strong>Open Food Facts / UPC Item DB:</strong> To look up public packaged-food information. The bundled food catalog works without these services.</li>
          </ul>

          <div style={{
            marginTop: '20px',
            backgroundColor: '#0F172A',
            padding: '20px',
            borderRadius: '12px',
            border: '1px solid #0EA5E9'
          }}>
            <h3 style={{ fontSize: '18px', color: '#38BDF8', margin: '0 0 10px 0' }}>
              4.1 Third-Party Artificial Intelligence (AI) Services & Data Sharing
            </h3>
            <p style={{ marginBottom: '10px' }}>
              Optional AI features use Google Gemini through BNYAD’s authenticated backend for food-photo estimates and recipe suggestions. Basic tracking and local nutrition calculations do not require AI permission.
            </p>
            <p style={{ marginBottom: '10px' }}>
              <strong>Before transmitting any personal data or photos to a third-party AI service, the app will:</strong>
            </p>
            <ul style={{ paddingLeft: '20px', marginBottom: '10px' }}>
              <li style={{ marginBottom: '6px' }}><strong>Disclose data categories:</strong> The selected photo or ingredient/meal text, nutrition targets and cooking preferences are sent to Google Gemini. An optional body-photo estimate also sends the measurement-derived body-fat anchor. Name, phone, account ID, medications and detailed medical history are not sent. Saved restrictions filter the allowed ingredient catalog on BNYAD’s server.</li>
              <li style={{ marginBottom: '6px' }}><strong>Specify recipient:</strong> Google receives optional AI inputs over HTTPS. BNYAD does not retain uploaded photos or log raw AI prompts.</li>
              <li style={{ marginBottom: '6px' }}><strong>Obtain explicit permission:</strong> Require your affirmative in-app consent (Opt-In Permission) before any request is sent. You may decline or revoke permission at any time in App Settings.</li>
            </ul>
            <p style={{ margin: 0, color: '#CBD5E1' }}>
              Validated AI results may be cached privately per account for up to 24 hours; revoking permission removes server-side reusable results. Saved meal plans and recipes remain user data. Minimal usage metadata (account reference, operation, model, token counts and estimated cost) supports quotas and spending controls. Google’s retention and data-use terms depend on the service tier selected by the operator; no unsupported no-training guarantee is made. AI is disabled until the operator reviews those terms and enables it. Estimates may be wrong, including ingredient recognition and allergens; review ingredients, portions, package labels and cooking safety before use. These features are not medical advice.
            </p>
          </div>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>5. Medical & Health Information Disclaimer</h2>
          <p>
            All health recommendations, body fat estimates, and nutritional calculations generated by BNYAD are provided for informational and educational purposes only. They do not constitute clinical or medical advice. Always seek the advice of a physician or qualified healthcare provider with any questions regarding a medical condition or diet program.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>6. Data Security & Retention</h2>
          <p>
            We enforce industry-standard security measures including HTTPS encryption in transit and secure database storage to safeguard your profile and logged health metrics against unauthorized access, alteration, or disclosure.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>7. User Rights & Account Deletion</h2>
          <p>
            In accordance with applicable privacy standards and App Store guidelines (Guideline 5.1.1(v)), you have the right to access, export, or permanently delete your account and all associated personal data at any time.
          </p>
          <p style={{ marginTop: '8px' }}>
            <strong>How to delete your account:</strong>
          </p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '6px' }}>
              <strong>In-App:</strong> Open the BNYAD (Nutrify) app &rarr; go to <strong>Settings</strong> &rarr; tap <strong>Delete Account</strong> &rarr; confirm deletion.
            </li>
            <li style={{ marginBottom: '6px' }}>
              <strong>On the Web:</strong> Visit our dedicated self-service <a href="/delete-account" style={{ color: '#38BDF8', textDecoration: 'underline' }}>Account Deletion Portal</a> to immediately and permanently delete your account.
            </li>
          </ul>
          <p style={{ marginTop: '8px' }}>
            Upon account deletion, all personal profile data, daily food and water logs, weight tracking history, custom recipes, meal plans, and authentication tokens are immediately, permanently, and irreversibly wiped from our production database.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>8. Contact Us</h2>
          <p>
            If you have questions, concerns, or inquiries regarding this Privacy Policy, please contact us:
          </p>
          <p style={{ marginTop: '8px', color: '#CBD5E1' }}>
            Email: <a href="mailto:support@bnyad.app" style={{ color: '#38BDF8', textDecoration: 'underline' }}>support@bnyad.app</a><br />
            App Support: BNYAD Application Team
          </p>
        </section>

        <div style={{
          borderTop: '1px solid #334155',
          paddingTop: '20px',
          marginTop: '40px',
          textAlign: 'center',
          fontSize: '13px',
          color: '#64748B',
          display: 'flex',
          justifyContent: 'center',
          gap: '20px'
        }}>
          <a href="/privacy" style={{ color: '#38BDF8', textDecoration: 'none' }}>Privacy Policy</a>
          <span>•</span>
          <a href="/terms" style={{ color: '#38BDF8', textDecoration: 'none' }}>Terms of Service</a>
          <span>•</span>
          <a href="/delete-account" style={{ color: '#38BDF8', textDecoration: 'none' }}>Delete Account</a>
          <span>•</span>
          <span>&copy; 2026 BNYAD (Nutrify)</span>
        </div>
      </div>
    </div>
  );
}
