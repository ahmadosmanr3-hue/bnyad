<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserProfileResource;
use App\Services\MacroCalculationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function __construct(
        private readonly MacroCalculationService $calculator,
    ) {}

    public function show(Request $request): UserProfileResource
    {
        $profile = $request->user()->profile()->firstOrCreate([]);

        return new UserProfileResource($profile);
    }

    public function update(UpdateProfileRequest $request): UserProfileResource
    {
        $profile = $request->user()->profile()->firstOrCreate([]);
        $profile->update($request->validated());

        return new UserProfileResource($profile);
    }

    /**
     * POST /api/profile/calculate-macros
     *
     * Accepts body stats and returns computed BMR, TDEE, BMI, calories, and
     * macro split without persisting anything. Useful for the onboarding
     * results screen or a "recalculate" button.
     */
    public function calculateMacros(Request $request): JsonResponse
    {
        $data = $request->validate([
            'weight'               => 'required|numeric|min:20|max:400',
            'height'               => 'required|numeric|min:50|max:300',
            'age'                  => 'required|integer|min:10|max:120',
            'gender'               => 'required|string|in:male,female',
            'activity_level'       => 'required|string',
            'goal'                 => 'required|string',
            'pace'                 => 'sometimes|string|in:relaxed,moderate,aggressive',
            'target_weight'        => 'sometimes|nullable|numeric|min:20|max:400',
            'pregnancy_status'     => 'sometimes|string',
            'dietary_pattern'      => 'sometimes|string',
            'workout_days_per_week'=> 'sometimes|integer|min:0|max:7',
            'workout_type'         => 'sometimes|string',
        ]);

        $result = $this->calculator->computeAll(
            weightKg:           $data['weight'],
            heightCm:           $data['height'],
            age:                $data['age'],
            gender:             $data['gender'],
            activityLevel:      $data['activity_level'],
            goal:               $data['goal'],
            pace:               $data['pace'] ?? 'moderate',
            targetWeightKg:     $data['target_weight'] ?? null,
            pregnancyStatus:    $data['pregnancy_status'] ?? 'none',
            dietaryPattern:     $data['dietary_pattern'] ?? 'omnivore',
            workoutDaysPerWeek: $data['workout_days_per_week'] ?? 0,
            workoutType:        $data['workout_type'] ?? 'none',
        );

        return response()->json(['data' => $result]);
    }
}
