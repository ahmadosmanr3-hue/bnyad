<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreWeightRequest;
use App\Http\Resources\WeightEntryResource;
use Illuminate\Http\Request;

class WeightEntryController extends Controller
{
    public function index(Request $request)
    {
        return WeightEntryResource::collection(
            $request->user()->weightEntries()->orderBy('log_date')->get()
        );
    }

    public function store(StoreWeightRequest $request): WeightEntryResource
    {
        $data = $request->validated();
        $date = $data['log_date'] ?? now()->toDateString();

        $entry = $request->user()->weightEntries()->updateOrCreate(
            ['log_date' => $date],
            ['weight' => $data['weight']],
        );

        return new WeightEntryResource($entry);
    }
}
