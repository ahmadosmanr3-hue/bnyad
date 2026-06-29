<?php

namespace App\Http\Requests\Auth;

use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone' => ['required', 'string', 'regex:/^\+?[0-9]{7,15}$/'],
            'code' => ['required', 'string', 'digits:6'],
            'password' => ['nullable', 'string', 'min:6'],
            // Provided on first sign-in (registration); optional on later logins.
            'name' => ['nullable', 'string', 'max:120'],
        ];
    }

    public function messages(): array
    {
        return [
            'code.digits' => 'The verification code must be 6 digits.',
            'password.min' => 'Password must be at least 6 characters.',
        ];
    }
}
