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
          <p>We only collect information necessary to provide tailored nutrition tracking, meal planning, and health metrics estimation:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}>
              <strong>Account Information:</strong> Phone number and optional profile name for authentication via secure OTP verification.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Health & Physical Metrics:</strong> Age, gender, height, weight, target weight, activity level, and circumference measurements (waist, neck, hip) used exclusively for calculating daily calorie/macronutrient needs and body fat estimates.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Nutrition & Food Logs:</strong> Daily logged foods, water intake, meal photos, and custom recipes saved to track your progress over time.
            </li>
            <li style={{ marginBottom: '8px' }}>
              <strong>Device & Usage Information:</strong> Push notification tokens (FCM) to deliver meal and supplement reminders configured by you.
            </li>
          </ul>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>3. How We Use Your Information</h2>
          <p>Your data is used strictly to deliver and improve core app features:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}>Compute personalized daily calorie targets, macronutrient distributions, and body fat estimates based on established scientific formulas.</li>
            <li style={{ marginBottom: '8px' }}>Store and sync your food logs, weight entries, and meal plans securely.</li>
            <li style={{ marginBottom: '8px' }}>Send user-requested notifications for meal and supplement reminders.</li>
            <li style={{ marginBottom: '8px' }}>Verify subscription purchase status via RevenueCat and Apple App Store in-app purchases.</li>
          </ul>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>4. Data Sharing & Third Parties</h2>
          <p>
            <strong>We do NOT sell, rent, or trade your personal health data to third parties or advertisers.</strong>
          </p>
          <p style={{ marginTop: '8px' }}>We utilize reliable service providers strictly to process data for core app functionality:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '8px' }}><strong>Apple App Store / RevenueCat:</strong> To manage in-app subscriptions and purchase receipts securely.</li>
            <li style={{ marginBottom: '8px' }}><strong>Firebase Cloud Messaging (FCM):</strong> To dispatch opt-in push reminders.</li>
            <li style={{ marginBottom: '8px' }}><strong>Open Food Facts / USDA API:</strong> To fetch public nutritional facts when scanning barcodes or searching food items.</li>
          </ul>
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
