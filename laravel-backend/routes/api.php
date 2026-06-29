<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DailyLogController;
use App\Http\Controllers\Api\FavoriteTemplateController;
use App\Http\Controllers\Api\FoodItemController;
use App\Http\Controllers\Api\MealPlanController;
use App\Http\Controllers\Api\MealReminderController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ShoppingItemController;
use App\Http\Controllers\Api\VitaminController;
use App\Http\Controllers\Api\WaterLogController;
use App\Http\Controllers\Api\WeightEntryController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public auth endpoints (phone OTP login)
|--------------------------------------------------------------------------
*/
Route::prefix('auth')->group(function () {
    Route::post('request-otp', [AuthController::class, 'requestOtp'])
        ->middleware('throttle:6,1');
    Route::post('check-phone', [AuthController::class, 'checkPhone'])
        ->middleware('throttle:12,1');
    Route::post('verify-otp', [AuthController::class, 'verifyOtp'])
        ->middleware('throttle:10,1');
});

/*
|--------------------------------------------------------------------------
| Authenticated endpoints (Sanctum token)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::get('auth/me', [AuthController::class, 'me']);
    Route::post('auth/logout', [AuthController::class, 'logout']);

    // Profile (onboarding data)
    Route::get('profile', [ProfileController::class, 'show']);
    Route::match(['put', 'patch'], 'profile', [ProfileController::class, 'update']);
    Route::post('profile/calculate-macros', [ProfileController::class, 'calculateMacros']);

    // Food logs
    Route::get('logs', [DailyLogController::class, 'index']);
    Route::post('logs', [DailyLogController::class, 'store']);
    Route::delete('logs/{dailyLog}', [DailyLogController::class, 'destroy']);

    // Water
    Route::get('water', [WaterLogController::class, 'show']);
    Route::put('water', [WaterLogController::class, 'update']);

    // Weight history
    Route::get('weights', [WeightEntryController::class, 'index']);
    Route::post('weights', [WeightEntryController::class, 'store']);

    // Meal plan
    Route::get('meal-plan', [MealPlanController::class, 'show']);
    Route::put('meal-plan', [MealPlanController::class, 'store']);
    Route::delete('meal-plan', [MealPlanController::class, 'destroy']);

    // Vitamins
    Route::get('vitamins', [VitaminController::class, 'index']);
    Route::post('vitamins', [VitaminController::class, 'store']);
    Route::put('vitamins/{vitamin}', [VitaminController::class, 'update']);
    Route::delete('vitamins/{vitamin}', [VitaminController::class, 'destroy']);
    Route::post('vitamins/reset', [VitaminController::class, 'resetDaily']);

    // Favorites
    Route::get('favorites', [FavoriteTemplateController::class, 'index']);
    Route::post('favorites', [FavoriteTemplateController::class, 'store']);
    Route::delete('favorites/{favorite}', [FavoriteTemplateController::class, 'destroy']);

    // Shopping list
    Route::get('shopping', [ShoppingItemController::class, 'index']);
    Route::post('shopping', [ShoppingItemController::class, 'store']);
    Route::put('shopping/{shoppingItem}', [ShoppingItemController::class, 'update']);
    Route::delete('shopping/{shoppingItem}', [ShoppingItemController::class, 'destroy']);

    // Meal reminders
    Route::get('reminders', [MealReminderController::class, 'index']);
    Route::put('reminders', [MealReminderController::class, 'update']);

    // Food catalog (read-only)
    Route::get('foods', [FoodItemController::class, 'index']);
    Route::get('foods/{foodItem}', [FoodItemController::class, 'show']);
});
