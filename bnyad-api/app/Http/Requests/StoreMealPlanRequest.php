<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMealPlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'plan' => ['required', 'array'],
            'plan.*.name' => ['required', 'string', 'max:200'],
            'plan.*.names' => ['nullable', 'array'],
            'plan.*.ingredients' => ['nullable', 'array'],
            'plan.*.instructions' => ['nullable', 'array'],
            'plan.*.calories' => ['nullable', 'integer', 'min:0'],
            'plan.*.protein' => ['nullable', 'integer', 'min:0'],
            'plan.*.carbs' => ['nullable', 'integer', 'min:0'],
            'plan.*.fat' => ['nullable', 'integer', 'min:0'],
            'plan.*.micros' => ['nullable', 'array'],
        ];
    }
}
