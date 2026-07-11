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
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('OTPIQ SMS Error response:', errorText);
      return false;
    }
    
    const data = await response.json();
    console.log('OTPIQ SMS Success response:', data);
    return true;
  } catch (error) {
    console.error('Failed to send OTPIQ SMS:', error);
    return false;
  }
}
