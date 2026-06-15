<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreFavoriteRequest extends FormRequest
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
        ];
    }
}
