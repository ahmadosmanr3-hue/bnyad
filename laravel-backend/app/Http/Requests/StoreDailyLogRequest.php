<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreDailyLogRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'food_item_id' => ['nullable', 'integer', 'exists:food_items,id'],
            'external_food_id' => ['nullable', 'string', 'max:64'],
            'name' => ['required', 'string', 'max:200'],
            'amount' => ['nullable', 'numeric', 'min:0'],
            'calories' => ['required', 'numeric', 'min:0'],
            'protein' => ['nullable', 'numeric', 'min:0'],
            'carbs' => ['nullable', 'numeric', 'min:0'],
            'fat' => ['nullable', 'numeric', 'min:0'],
            'micros' => ['nullable', 'array'],
            'meal_type' => ['nullable', 'string', 'max:40'],
            'logged_at' => ['nullable', 'date_format:Y-m-d'],
            'consumed_at' => ['nullable', 'date'],
        ];
    }
}
