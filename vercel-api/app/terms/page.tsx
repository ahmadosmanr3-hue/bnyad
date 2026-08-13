import React from 'react';

export const metadata = {
  title: 'Terms of Use (EULA) — BNYAD (Nutrify)',
  description: 'Terms of Service, End User License Agreement (EULA), and Subscription Terms for BNYAD.',
};

export default function TermsOfUsePage() {
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
            Terms of Use (EULA) & Subscription Terms
          </h1>
          <p style={{ color: '#94A3B8', fontSize: '14px', margin: 0 }}>
            Application: BNYAD (Nutrify) — Last Updated: August 13, 2026
          </p>
        </div>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>1. Agreement to Terms</h2>
          <p>
            By downloading, accessing, or using the <strong>BNYAD</strong> mobile application (&quot;App&quot;), you agree to be bound by these Terms of Use and End User License Agreement (&quot;EULA&quot;). If you do not agree to these terms, do not install or use the application.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>2. End User License Agreement (EULA)</h2>
          <p>
            BNYAD grants you a personal, revocable, non-exclusive, non-transferable, limited license to download, install, and use the App solely for your personal, non-commercial health and fitness tracking in accordance with Apple’s Standard EULA terms (<a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" target="_blank" rel="noreferrer" style={{ color: '#38BDF8', textDecoration: 'underline' }}>Apple Standard EULA</a>).
          </p>
        </section>

        <section style={{ marginBottom: '28px', backgroundColor: '#0F172A', padding: '20px', borderRadius: '12px', border: '1px solid #0EA5E9' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px', marginTop: 0 }}>
            3. Auto-Renewable Subscription Terms (Guideline 3.1.2c)
          </h2>
          <p style={{ fontWeight: '600', color: '#F8FAFC' }}>
            BNYAD offers auto-renewable Premium subscriptions to unlock advanced features including AI meal planning, barcode scanning, macronutrient custom targets, and detailed nutrition analysis.
          </p>
          <ul style={{ paddingLeft: '20px', marginTop: '12px' }}>
            <li style={{ marginBottom: '10px' }}>
              <strong>Subscription Options & Pricing:</strong>
              <ul style={{ paddingLeft: '20px', marginTop: '4px' }}>
                <li><strong>Monthly Plan (BNYAD_M1):</strong> $4.99 per month, billed monthly.</li>
                <li><strong>Yearly Plan (BNYAD_Y1):</strong> $19.99 per year ($1.66/month equivalent), billed annually.</li>
              </ul>
            </li>
            <li style={{ marginBottom: '10px' }}>
              <strong>Payment & Billing:</strong> Payment will be charged to your Apple ID Account at confirmation of purchase.
            </li>
            <li style={{ marginBottom: '10px' }}>
              <strong>Automatic Renewal:</strong> Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current billing period.
            </li>
            <li style={{ marginBottom: '10px' }}>
              <strong>Renewal Charges:</strong> Your account will be charged for renewal within 24 hours prior to the end of the current period at the initial subscription price unless notified otherwise.
            </li>
            <li style={{ marginBottom: '10px' }}>
              <strong>Managing & Canceling Subscriptions:</strong> You can manage or turn off auto-renewal anytime in your iPhone / iPad <em>Settings &gt; Apple ID &gt; Subscriptions</em> after purchase.
            </li>
            <li style={{ marginBottom: '10px' }}>
              <strong>Free Trial / Promotions:</strong> Any unused portion of a free trial period, if offered, will be forfeited when the user purchases a subscription.
            </li>
          </ul>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>4. Medical & Physical Health Disclaimer</h2>
          <p>
            The BNYAD application provides fitness, body composition estimates, and macronutrient targets based on standard scientific equations (such as Mifflin-St Jeor, WHO BMI, and US Navy Body Fat formulas). <strong>The App is not intended to provide clinical diagnosis, treatment, or medical advice.</strong>
          </p>
          <p style={{ marginTop: '8px' }}>
            Always consult a licensed physician or nutritionist before beginning any meal plan or fitness regimen. Never disregard professional medical advice because of information presented in the App.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>5. User Conduct & Acceptable Use</h2>
          <p>
            You agree not to modify, reverse engineer, decompile, copy, or redistribute any portion of the BNYAD application or API endpoints without prior written authorization.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>6. Privacy Policy & Links</h2>
          <p>
            Your use of BNYAD is also governed by our <a href="/privacy" style={{ color: '#38BDF8', textDecoration: 'underline' }}>Privacy Policy</a>. Please review our Privacy Policy to understand how we process your health metrics and profile information.
          </p>
        </section>

        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>7. Support & Contact</h2>
          <p>
            For questions regarding subscriptions, terms of service, or account management, please contact:
          </p>
          <p style={{ marginTop: '8px', color: '#CBD5E1' }}>
            Email: <a href="mailto:support@bnyad.app" style={{ color: '#38BDF8', textDecoration: 'underline' }}>support@bnyad.app</a><br />
            Support: BNYAD App Legal & Support Team
          </p>
        </section>

        <div style={{ borderTop: '1px solid #334155', paddingTop: '20px', marginTop: '40px', textAlign: 'center', fontSize: '13px', color: '#64748B' }}>
          &copy; 2026 BNYAD (Nutrify). All rights reserved.
        </div>
      </div>
    </div>
  );
}
