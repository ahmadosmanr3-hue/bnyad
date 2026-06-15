<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreDailyLogRequest;
use App\Http\Resources\DailyLogResource;
use App\Models\DailyLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DailyLogController extends Controller
{
    /**
     * List logs. Supports ?date=Y-m-d (single day) or
     * ?from=Y-m-d&to=Y-m-d (range, e.g. weekly summary).
     */
    public function index(Request $request)
    {
        $query = $request->user()->dailyLogs()->with('foodItem.translations');

        if ($date = $request->query('date')) {
            $query->whereDate('logged_at', $date);
        } elseif (($from = $request->query('from')) && ($to = $request->query('to'))) {
            $query->whereBetween('logged_at', [$from, $to]);
        }

        return DailyLogResource::collection(
            $query->orderByDesc('consumed_at')->orderByDesc('id')->get()
        );
    }

    public function store(StoreDailyLogRequest $request): DailyLogResource
    {
        $data = $request->validated();
        $data['logged_at'] ??= now()->toDateString();
        $data['consumed_at'] ??= now();

        $log = $request->user()->dailyLogs()->create($data);

        return new DailyLogResource($log->load('foodItem.translations'));
    }

    public function destroy(Request $request, DailyLog $dailyLog): JsonResponse
    {
        abort_unless($dailyLog->user_id === $request->user()->id, 403);
        $dailyLog->delete();

        return response()->json(['message' => 'Deleted.']);
    }
}
