'use client';

import React, { useState } from 'react';

export default function DeleteAccountPage() {
  const [phone, setPhone] = useState('');
  const [authMethod, setAuthMethod] = useState<'password' | 'otp'>('password');
  const [password, setPassword] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [otpRequested, setOtpRequested] = useState(false);
  const [confirmed, setConfirmed] = useState(false);

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [deleted, setDeleted] = useState(false);

  async function handleRequestOtp() {
    if (!phone.trim()) {
      setMessage({ type: 'error', text: 'Please enter your registered phone number first.' });
      return;
    }
    setLoading(true);
    setMessage(null);
    try {
      const res = await fetch('/api/auth/request-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: phone.trim() }),
      });
      const data = await res.json();
      if (res.ok) {
        setOtpRequested(true);
        setMessage({ type: 'success', text: 'Verification code sent to your phone via SMS.' });
      } else {
        setMessage({ type: 'error', text: data.message || 'Failed to send verification code.' });
      }
    } catch {
      setMessage({ type: 'error', text: 'Network error. Please try again.' });
    } finally {
      setLoading(false);
    }
  }

  async function handleDeleteAccount(e: React.FormEvent) {
    e.preventDefault();
    if (!phone.trim()) {
      setMessage({ type: 'error', text: 'Please enter your registered phone number.' });
      return;
    }
    if (!confirmed) {
      setMessage({ type: 'error', text: 'Please check the box confirming you understand this action is permanent.' });
      return;
    }

    setLoading(true);
    setMessage(null);
    try {
      const payload: Record<string, string> = { phone: phone.trim() };
      if (authMethod === 'password') {
        if (!password) {
          setMessage({ type: 'error', text: 'Please enter your password.' });
          setLoading(false);
          return;
        }
        payload.password = password;
      } else {
        if (!otpCode) {
          setMessage({ type: 'error', text: 'Please enter the 6-digit SMS code.' });
          setLoading(false);
          return;
        }
        payload.otpCode = otpCode;
      }

      const res = await fetch('/api/auth/web-delete-account', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const data = await res.json();

      if (res.ok) {
        setDeleted(true);
        setMessage({
          type: 'success',
          text: 'Your BNYAD account and all associated personal data have been permanently deleted.',
        });
      } else {
        setMessage({ type: 'error', text: data.message || 'Account deletion failed.' });
      }
    } catch {
      setMessage({ type: 'error', text: 'Network error occurred. Please try again.' });
    } finally {
      setLoading(false);
    }
  }

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
        {/* Header */}
        <div style={{ borderBottom: '1px solid #334155', paddingBottom: '20px', marginBottom: '30px' }}>
          <h1 style={{ fontSize: '28px', fontWeight: '800', color: '#F8FAFC', margin: '0 0 10px 0' }}>
            Account Deletion — BNYAD (Nutrify)
          </h1>
          <p style={{ color: '#94A3B8', fontSize: '14px', margin: 0 }}>
            App Store Guideline 5.1.1(v) Self-Service Data Deletion Portal
          </p>
        </div>

        {/* Section 1: In-App Instructions */}
        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>
            How to Delete Your Account
          </h2>
          <p>
            You can permanently delete your account and all associated personal health data at any time using either method below:
          </p>
          <div style={{
            backgroundColor: '#0F172A',
            border: '1px solid #334155',
            borderRadius: '12px',
            padding: '20px',
            marginTop: '16px',
            marginBottom: '20px'
          }}>
            <h3 style={{ fontSize: '16px', color: '#F8FAFC', margin: '0 0 8px 0', fontWeight: '700' }}>
              Option 1: Directly inside the BNYAD Mobile App (Recommended)
            </h3>
            <ol style={{ paddingLeft: '20px', margin: 0 }}>
              <li style={{ marginBottom: '6px' }}>Open the <strong>BNYAD (Nutrify)</strong> app.</li>
              <li style={{ marginBottom: '6px' }}>Navigate to the <strong>Settings</strong> tab.</li>
              <li style={{ marginBottom: '6px' }}>Under the <strong>Account</strong> section, tap <strong>Delete Account</strong>.</li>
              <li style={{ marginBottom: '6px' }}>Confirm the deletion prompt to immediately wipe all your data.</li>
            </ol>
          </div>

          <div style={{
            backgroundColor: '#0F172A',
            border: '1px solid #334155',
            borderRadius: '12px',
            padding: '20px'
          }}>
            <h3 style={{ fontSize: '16px', color: '#F8FAFC', margin: '0 0 8px 0', fontWeight: '700' }}>
              Option 2: Self-Service Deletion via this Web Page
            </h3>
            <p style={{ margin: 0, fontSize: '14px', color: '#CBD5E1' }}>
              If you have uninstalled the app or prefer to delete your account online, verify your account below to immediately process permanent deletion.
            </p>
          </div>
        </section>

        {/* Section 2: What Data is Deleted */}
        <section style={{ marginBottom: '28px' }}>
          <h2 style={{ fontSize: '20px', color: '#38BDF8', marginBottom: '12px' }}>
            What Happens When You Delete Your Account
          </h2>
          <div style={{
            backgroundColor: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid rgba(239, 68, 68, 0.3)',
            borderRadius: '12px',
            padding: '16px',
            marginBottom: '16px'
          }}>
            <p style={{ margin: 0, color: '#FCA5A5', fontSize: '14px', fontWeight: '600' }}>
              ⚠️ Warning: Account deletion is immediate, permanent, and irreversible.
            </p>
          </div>
          <p>The following data will be permanently and immediately removed from our database:</p>
          <ul style={{ paddingLeft: '20px', marginTop: '8px' }}>
            <li style={{ marginBottom: '6px' }}><strong>User Profile & Credentials:</strong> Name, phone number, password hash, and push notification tokens.</li>
            <li style={{ marginBottom: '6px' }}><strong>Health & Body Composition:</strong> Age, gender, height, weight entries, target goals, and body fat estimates.</li>
            <li style={{ marginBottom: '6px' }}><strong>Nutrition & Daily Logs:</strong> All logged foods, water intake records, micronutrients, and custom recipes.</li>
            <li style={{ marginBottom: '6px' }}><strong>Meal Plans & Preferences:</strong> Generated meal plans, dietary preferences, dislikes, and schedules.</li>
            <li style={{ marginBottom: '6px' }}><strong>Active Tokens & Sessions:</strong> All authentication sessions and API access tokens are instantly invalidated.</li>
          </ul>
        </section>

        {/* Section 3: Web Self-Service Deletion Form */}
        <section style={{
          backgroundColor: '#0F172A',
          border: '1px solid #475569',
          borderRadius: '16px',
          padding: '24px',
          marginBottom: '28px'
        }}>
          <h2 style={{ fontSize: '20px', color: '#F8FAFC', marginBottom: '16px' }}>
            Permanent Account Deletion Form
          </h2>

          {deleted ? (
            <div style={{
              backgroundColor: 'rgba(34, 197, 94, 0.15)',
              border: '1px solid rgba(34, 197, 94, 0.4)',
              borderRadius: '12px',
              padding: '24px',
              textAlign: 'center'
            }}>
              <div style={{ fontSize: '40px', marginBottom: '12px' }}>✅</div>
              <h3 style={{ color: '#4ADE80', margin: '0 0 8px 0', fontSize: '18px' }}>
                Account Successfully Deleted
              </h3>
              <p style={{ margin: 0, color: '#E2E8F0', fontSize: '14px' }}>
                Your account and all associated health records, nutrition logs, and personal data have been permanently wiped from our servers.
              </p>
            </div>
          ) : (
            <form onSubmit={handleDeleteAccount}>
              {message && (
                <div style={{
                  backgroundColor: message.type === 'error' ? 'rgba(239, 68, 68, 0.2)' : 'rgba(34, 197, 94, 0.2)',
                  border: `1px solid ${message.type === 'error' ? '#EF4444' : '#22C55E'}`,
                  borderRadius: '8px',
                  padding: '12px 16px',
                  marginBottom: '16px',
                  color: message.type === 'error' ? '#FCA5A5' : '#86EFAC',
                  fontSize: '14px'
                }}>
                  {message.text}
                </div>
              )}

              {/* Phone number */}
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#94A3B8', marginBottom: '6px' }}>
                  Registered Phone Number (e.g. +9647501234567)
                </label>
                <input
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+9647501234567"
                  required
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    borderRadius: '8px',
                    border: '1px solid #334155',
                    backgroundColor: '#1E293B',
                    color: '#F8FAFC',
                    fontSize: '15px',
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              {/* Auth method selection */}
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#94A3B8', marginBottom: '8px' }}>
                  Verification Method
                </label>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button
                    type="button"
                    onClick={() => { setAuthMethod('password'); setMessage(null); }}
                    style={{
                      flex: 1,
                      padding: '10px',
                      borderRadius: '8px',
                      border: authMethod === 'password' ? '2px solid #38BDF8' : '1px solid #334155',
                      backgroundColor: authMethod === 'password' ? '#1E293B' : '#0F172A',
                      color: authMethod === 'password' ? '#38BDF8' : '#94A3B8',
                      fontWeight: '600',
                      cursor: 'pointer'
                    }}
                  >
                    Account Password
                  </button>
                  <button
                    type="button"
                    onClick={() => { setAuthMethod('otp'); setMessage(null); }}
                    style={{
                      flex: 1,
                      padding: '10px',
                      borderRadius: '8px',
                      border: authMethod === 'otp' ? '2px solid #38BDF8' : '1px solid #334155',
                      backgroundColor: authMethod === 'otp' ? '#1E293B' : '#0F172A',
                      color: authMethod === 'otp' ? '#38BDF8' : '#94A3B8',
                      fontWeight: '600',
                      cursor: 'pointer'
                    }}
                  >
                    SMS Verification Code
                  </button>
                </div>
              </div>

              {/* Password or OTP input */}
              {authMethod === 'password' ? (
                <div style={{ marginBottom: '20px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#94A3B8', marginBottom: '6px' }}>
                    Password
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your account password"
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      borderRadius: '8px',
                      border: '1px solid #334155',
                      backgroundColor: '#1E293B',
                      color: '#F8FAFC',
                      fontSize: '15px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
              ) : (
                <div style={{ marginBottom: '20px' }}>
                  <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#94A3B8', marginBottom: '6px' }}>
                    SMS Verification Code
                  </label>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <input
                      type="text"
                      maxLength={6}
                      value={otpCode}
                      onChange={(e) => setOtpCode(e.target.value)}
                      placeholder="6-digit code"
                      style={{
                        flex: 1,
                        padding: '12px 16px',
                        borderRadius: '8px',
                        border: '1px solid #334155',
                        backgroundColor: '#1E293B',
                        color: '#F8FAFC',
                        fontSize: '15px',
                        boxSizing: 'border-box'
                      }}
                    />
                    <button
                      type="button"
                      disabled={loading}
                      onClick={handleRequestOtp}
                      style={{
                        padding: '12px 20px',
                        backgroundColor: '#334155',
                        color: '#F8FAFC',
                        border: 'none',
                        borderRadius: '8px',
                        fontWeight: '600',
                        cursor: 'pointer',
                        whiteSpace: 'nowrap'
                      }}
                    >
                      {otpRequested ? 'Resend Code' : 'Send Code'}
                    </button>
                  </div>
                </div>
              )}

              {/* Confirmation checkbox */}
              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'flex', alignItems: 'flex-start', gap: '10px', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={confirmed}
                    onChange={(e) => setConfirmed(e.target.checked)}
                    style={{ marginTop: '4px' }}
                  />
                  <span style={{ fontSize: '13px', color: '#CBD5E1' }}>
                    I understand and confirm that deleting my account will permanently and irreversibly wipe all my profile information, food logs, meal plans, and health tracking records.
                  </span>
                </label>
              </div>

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                style={{
                  width: '100%',
                  padding: '14px',
                  borderRadius: '10px',
                  border: 'none',
                  backgroundColor: '#EF4444',
                  color: '#FFFFFF',
                  fontWeight: '700',
                  fontSize: '16px',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  opacity: loading ? 0.7 : 1,
                  boxShadow: '0 4px 12px rgba(239, 68, 68, 0.4)'
                }}
              >
                {loading ? 'Processing Deletion...' : 'Permanently Delete My Account'}
              </button>
            </form>
          )}
        </section>

        {/* Footer links */}
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
          <span>&copy; 2026 BNYAD (Nutrify)</span>
        </div>
      </div>
    </div>
  );
}
