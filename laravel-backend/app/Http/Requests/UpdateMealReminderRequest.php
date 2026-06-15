<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMealReminderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'meal_type' => ['required', 'in:breakfast,lunch,dinner,snacks'],
            'enabled' => ['required', 'boolean'],
            'reminder_time' => ['required', 'date_format:H:i'],
        ];
    }
}
