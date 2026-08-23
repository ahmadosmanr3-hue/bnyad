<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\RequestOtpRequest;
use App\Http\Requests\Auth\VerifyOtpRequest;
use App\Http\Resources\UserResource;
use App\Models\PhoneOtp;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Step 1 — generate and "send" a 6-digit OTP for the phone number.
     *
     * In production, dispatch the code via an SMS provider (Twilio, etc.).
     * In local/testing the demo code 123456 is always accepted (see verify()).
     */
    public function requestOtp(RequestOtpRequest $request): JsonResponse
    {
        $phone = $request->input('phone');

        // Basic throttle: one active code per phone.
        PhoneOtp::where('phone', $phone)->whereNull('consumed_at')->delete();

        $code = app()->environment('production')
            ? (string) random_int(100000, 999999)
            : '123456';

        PhoneOtp::create([
            'phone' => $phone,
            'code_hash' => Hash::make($code),
            'expires_at' => now()->addMinutes(5),
        ]);

        // TODO(sms): send $code to $phone via your SMS gateway.

        return response()->json([
            'message' => 'OTP sent.',
            // Never expose the code outside local/dev.
            'demo_code' => app()->environment('production') ? null : $code,
        ]);
    }

    /**
     * Check whether a phone number already has an account.
     */
    public function checkPhone(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'regex:/^\+?[0-9]{7,15}$/'],
        ]);

        $registered = User::where('phone', $request->input('phone'))->exists();

        return response()->json(['registered' => $registered]);
    }

    /**
     * Step 2 — verify the OTP + password. Registers the user on first sign-in,
     * otherwise logs them in. Returns a Sanctum token.
     */
    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $phone = $request->input('phone');

        $otp = PhoneOtp::where('phone', $phone)
            ->whereNull('consumed_at')
            ->latest()
            ->first();

        if (! $otp || $otp->isExpired()) {
            throw ValidationException::withMessages([
                'code' => ['The verification code is invalid or has expired.'],
            ]);
        }

        if ($otp->attempts >= 5) {
            throw ValidationException::withMessages([
                'code' => ['Too many attempts. Request a new code.'],
            ]);
        }

        if (! Hash::check($request->input('code'), $otp->code_hash)) {
            $otp->increment('attempts');
            throw ValidationException::withMessages([
                'code' => ['The verification code is incorrect.'],
            ]);
        }

        $otp->update(['consumed_at' => now()]);

        $user = User::where('phone', $phone)->first();

        if ($user) {
            // Returning user — OTP only (no password re-entry).
        } else {
            $password = $request->input('password');
            if (! is_string($password) || strlen($password) < 6) {
                throw ValidationException::withMessages([
                    'password' => ['Password must be at least 6 characters.'],
                ]);
            }

            // First sign-in → register.
            $user = User::create([
                'name' => $request->input('name') ?: 'BNYAD user',
                'phone' => $phone,
                'email' => $phone.'@phone.bnyad.app', // placeholder unique email
                'password' => $password,
                'phone_verified_at' => now(),
            ]);

            UserProfile::create([
                'user_id' => $user->id,
                'display_name' => $request->input('name') ?: '',
            ]);
        }

        if ($user->phone_verified_at === null) {
            $user->update(['phone_verified_at' => now()]);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => new UserResource($user->load('profile')),
        ]);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('profile'));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    /**
     * Permanently delete user account and all personal data.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'message' => 'Your account and all associated personal data have been permanently deleted.',
        ]);
    }
}
