<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreVitaminRequest;
use App\Http\Resources\VitaminResource;
use App\Models\Vitamin;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VitaminController extends Controller
{
    public function index(Request $request)
    {
        return VitaminResource::collection($request->user()->vitamins()->get());
    }

    public function store(StoreVitaminRequest $request): VitaminResource
    {
        $vitamin = $request->user()->vitamins()->create($request->validated());

        return new VitaminResource($vitamin);
    }

    public function update(StoreVitaminRequest $request, Vitamin $vitamin): VitaminResource
    {
        abort_unless($vitamin->user_id === $request->user()->id, 403);
        $vitamin->update($request->validated());

        return new VitaminResource($vitamin);
    }

    public function destroy(Request $request, Vitamin $vitamin): JsonResponse
    {
        abort_unless($vitamin->user_id === $request->user()->id, 403);
        $vitamin->delete();

        return response()->json(['message' => 'Deleted.']);
    }

    /**
     * Reset all `taken` flags (called by the app at the start of a new day).
     */
    public function resetDaily(Request $request): JsonResponse
    {
        $request->user()->vitamins()->update(['taken' => false]);

        return response()->json(['message' => 'Daily vitamins reset.']);
    }
}
