<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreFavoriteRequest;
use App\Http\Resources\FavoriteTemplateResource;
use App\Models\FavoriteTemplate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FavoriteTemplateController extends Controller
{
    public function index(Request $request)
    {
        return FavoriteTemplateResource::collection(
            $request->user()->favoriteTemplates()->latest()->get()
        );
    }

    public function store(StoreFavoriteRequest $request): FavoriteTemplateResource
    {
        $favorite = $request->user()->favoriteTemplates()->create($request->validated());

        return new FavoriteTemplateResource($favorite);
    }

    public function destroy(Request $request, FavoriteTemplate $favorite): JsonResponse
    {
        abort_unless($favorite->user_id === $request->user()->id, 403);
        $favorite->delete();

        return response()->json(['message' => 'Deleted.']);
    }
}
