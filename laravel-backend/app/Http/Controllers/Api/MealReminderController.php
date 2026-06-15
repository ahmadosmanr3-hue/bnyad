<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateMealReminderRequest;
use App\Http\Resources\MealReminderResource;
use Illuminate\Http\Request;

class MealReminderController extends Controller
{
    public function index(Request $request)
    {
        return MealReminderResource::collection(
            $request->user()->mealReminders()->get()
        );
    }

    /**
     * Upsert a meal reminder (one per meal_type per user).
     */
    public function update(UpdateMealReminderRequest $request): MealReminderResource
    {
        $data = $request->validated();

        $reminder = $request->user()->mealReminders()->updateOrCreate(
            ['meal_type' => $data['meal_type']],
            ['enabled' => $data['enabled'], 'reminder_time' => $data['reminder_time']],
        );

        return new MealReminderResource($reminder);
    }
}
