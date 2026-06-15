<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreShoppingItemRequest;
use App\Http\Resources\ShoppingItemResource;
use App\Models\ShoppingItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShoppingItemController extends Controller
{
    public function index(Request $request)
    {
        return ShoppingItemResource::collection(
            $request->user()->shoppingItems()->latest()->get()
        );
    }

    public function store(StoreShoppingItemRequest $request): ShoppingItemResource
    {
        $item = $request->user()->shoppingItems()->create($request->validated());

        return new ShoppingItemResource($item);
    }

    public function update(StoreShoppingItemRequest $request, ShoppingItem $shoppingItem): ShoppingItemResource
    {
        abort_unless($shoppingItem->user_id === $request->user()->id, 403);
        $shoppingItem->update($request->validated());

        return new ShoppingItemResource($shoppingItem);
    }

    public function destroy(Request $request, ShoppingItem $shoppingItem): JsonResponse
    {
        abort_unless($shoppingItem->user_id === $request->user()->id, 403);
        $shoppingItem->delete();

        return response()->json(['message' => 'Deleted.']);
    }
}
