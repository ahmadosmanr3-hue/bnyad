<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreWeightRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'log_date' => ['nullable', 'date_format:Y-m-d'],
            'weight' => ['required', 'numeric', 'min:0', 'max:600'],
        ];
    }
}
