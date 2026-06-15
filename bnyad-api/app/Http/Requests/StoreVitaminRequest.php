<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreVitaminRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:120'],
            'dosage' => ['nullable', 'string', 'max:80'],
            'taken' => ['sometimes', 'boolean'],
        ];
    }
}
