<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateWaterRequest;
use App\Http\Resources\WaterLogResource;
use Illuminate\Http\Request;

class WaterLogController extends Controller
{
    public function show(Request $request): WaterLogResource
    {
        $date = $request->query('date', now()->toDateString());

        $log = $request->user()->waterLogs()->firstOrCreate(
            ['log_date' => $date],
            ['glasses' => 0],
        );

        return new WaterLogResource($log);
    }

    /**
     * Upsert the glass count for a day (mirrors Firestore set()).
     */
    public function update(UpdateWaterRequest $request): WaterLogResource
    {
        $data = $request->validated();
        $date = $data['log_date'] ?? now()->toDateString();

        $log = $request->user()->waterLogs()->updateOrCreate(
            ['log_date' => $date],
            ['glasses' => $data['glasses']],
        );

        return new WaterLogResource($log);
    }
}
