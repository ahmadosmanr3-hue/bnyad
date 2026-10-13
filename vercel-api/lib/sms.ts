/**
 * Sends a verification code via the OTPIQ SMS gateway.
 * API Endpoint: https://api.otpiq.com/api/sms
 */
export async function sendSmsOtp(phone: string, code: string): Promise<boolean> {
  const token = process.env.OTPIQ_API_KEY || '';
  
  // Format phone number by removing any leading '+'
  const formattedPhone = phone.replace('+', '').trim();
  
  try {
    const response = await fetch('https://api.otpiq.com/api/sms', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        phoneNumber: formattedPhone,
        smsType: 'verification',
        provider: 'whatsapp',
        verificationCode: code,
      }),
      signal: AbortSignal.timeout(10000),
    });
    
    if (!response.ok) {
      console.error('Verification delivery failed:', response.status);
      return false;
    }
    
    return true;
  } catch (error) {
    console.error('Verification delivery failed.');
    return false;
  }
}
