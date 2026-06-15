<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateWaterRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'log_date' => ['nullable', 'date_format:Y-m-d'],
            'glasses' => ['required', 'integer', 'min:0', 'max:100'],
        ];
    }
}
