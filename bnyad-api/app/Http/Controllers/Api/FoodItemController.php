<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\FoodItemResource;
use App\Models\FoodItem;
use Illuminate\Http\Request;

class FoodItemController extends Controller
{
    /**
     * Searchable food catalog. ?q= matches translated names in any locale.
     */
    public function index(Request $request)
    {
        $query = FoodItem::query()->with('translations');

        if ($q = trim((string) $request->query('q', ''))) {
            $query->whereHas('translations', function ($sub) use ($q) {
                $sub->where('name', 'like', "%{$q}%");
            });
        }

        if ($category = $request->query('category')) {
            $query->where('category', $category);
        }

        return FoodItemResource::collection($query->paginate(50));
    }

    public function show(FoodItem $foodItem): FoodItemResource
    {
        return new FoodItemResource($foodItem->load('translations'));
    }
}
