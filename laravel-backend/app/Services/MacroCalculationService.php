<?php

namespace App\Services;

/**
 * Isolated, testable service for all physical / nutritional calculations.
 *
 * Mirrors the Flutter `lib/utils/nutrition_calculator.dart` logic 1-to-1 so
 * mobile and server always agree on the numbers.
 */
class MacroCalculationService
{
    // ─── Activity multipliers ────────────────────────────

    private const ACTIVITY_MULTIPLIERS = [
        'sedentary'       => 1.2,
        'lightlyActive'   => 1.375,
        'moderatelyActive'=> 1.55,
        'veryActive'      => 1.725,
        'extraActive'     => 1.9,
    ];

    // ─── Workout kcal burned per session (avg estimates) ─

    private const WORKOUT_KCAL_PER_SESSION = [
        'workoutCardio'   => 350,
        'workoutStrength'  => 250,
        'workoutBoth'      => 400,
        'workoutSport'     => 400,
    ];

    // ─── Goal → calorie delta (kcal / day) ───────────────

    private const GOAL_DELTAS = [
        'loseWeight'   => -500,
        'loseFat'      => -400,
        'gainWeight'   =>  400,
        'buildMuscle'  =>  300,
        'stayHealthy'  =>    0,
    ];

    // ─── Pace multipliers ────────────────────────────────

    private const PACE_FACTORS = [
        'relaxed'    => 0.6,
        'moderate'   => 1.0,
        'aggressive' => 1.4,
    ];

    // ──────────────────────────────────────────────────────
    //  BMI
    // ──────────────────────────────────────────────────────

    /** Standard BMI (kg / m²) — matches WHO / CDC calculators. */
    public function bmi(float $weightKg, float $heightCm): float
    {
        if ($weightKg <= 0 || $heightCm <= 0) {
            return 0;
        }

        $heightM = $heightCm / 100;

        return $weightKg / ($heightM * $heightM);
    }

    // ──────────────────────────────────────────────────────
    //  BMR  (Mifflin–St Jeor 1990)
    // ──────────────────────────────────────────────────────

    /**
     * Male:   (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
     * Female: (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
     */
    public function bmr(float $weightKg, float $heightCm, int $age, string $gender): float
    {
        $base = (10 * $weightKg) + (6.25 * $heightCm) - (5 * $age);

        return $this->isFemale($gender)
            ? $base - 161
            : $base + 5;
    }

    // ──────────────────────────────────────────────────────
    //  TDEE  (maintenance calories)
    // ──────────────────────────────────────────────────────

    /**
     * TDEE = BMR × activity multiplier, with optional workout and pregnancy
     * adjustments that match the Flutter companion logic exactly.
     */
    public function tdee(
        float  $weightKg,
        float  $heightCm,
        int    $age,
        string $gender,
        string $activityLevel,
        int    $workoutDaysPerWeek = 0,
        string $workoutType = 'none',
        string $pregnancyStatus = 'none',
    ): float {
        $multiplier = self::ACTIVITY_MULTIPLIERS[$activityLevel] ?? 1.55;
        $tdee = $this->bmr($weightKg, $heightCm, $age, $gender) * $multiplier;

        // Only add explicit workout kcal when the activity level is low —
        // higher multipliers already account for regular exercise.
        $lowActivity = in_array($activityLevel, ['sedentary', 'lightlyActive'], true);

        if ($lowActivity
            && $workoutDaysPerWeek > 0
            && ! in_array($workoutType, ['none', 'workoutNone'], true)
        ) {
            $perSession = self::WORKOUT_KCAL_PER_SESSION[$workoutType] ?? 0;
            $tdee += ($perSession * $workoutDaysPerWeek) / 7;
        }

        if ($this->isFemale($gender)) {
            if ($pregnancyStatus === 'pregnant') {
                $tdee += 300;
            }
            if ($pregnancyStatus === 'breastfeeding') {
                $tdee += 450;
            }
        }

        return $tdee;
    }

    // ──────────────────────────────────────────────────────
    //  Daily calorie target (TDEE ± goal adjustment)
    // ──────────────────────────────────────────────────────

    /**
     * Returns the daily calorie target after applying the goal delta,
     * pace scaling, and optional target-weight override.
     *
     * Clamped to [1200, 5000] (1800 min for pregnant/breastfeeding).
     */
    public function dailyCalories(
        float   $weightKg,
        float   $heightCm,
        int     $age,
        string  $gender,
        string  $activityLevel,
        string  $goal,
        string  $pace = 'moderate',
        ?float  $targetWeightKg = null,
        int     $workoutDaysPerWeek = 0,
        string  $workoutType = 'none',
        string  $pregnancyStatus = 'none',
    ): int {
        $goal = $this->normalizeGoal($goal);

        $tdee = $this->tdee(
            $weightKg, $heightCm, $age, $gender, $activityLevel,
            $workoutDaysPerWeek, $workoutType, $pregnancyStatus,
        );

        $delta = (float) (self::GOAL_DELTAS[$goal] ?? 0);
        $paceFactor = self::PACE_FACTORS[$pace] ?? 1.0;
        $delta *= $paceFactor;

        // Override direction when target weight contradicts the chosen goal.
        if ($targetWeightKg !== null && $targetWeightKg > 0) {
            $diff = $targetWeightKg - $weightKg;
            if ($diff < -1 && $delta >= 0) {
                $delta = -400 * $paceFactor;
            }
            if ($diff > 1 && $delta <= 0) {
                $delta = 300 * $paceFactor;
            }
        }

        $tdee += $delta;

        $lowerBound = 1200;
        if ($this->isFemale($gender)
            && in_array($pregnancyStatus, ['pregnant', 'breastfeeding'], true)
        ) {
            $lowerBound = 1800;
        }

        return (int) max($lowerBound, min(5000, round($tdee)));
    }

    // ──────────────────────────────────────────────────────
    //  Macro split (protein / carbs / fat in grams)
    // ──────────────────────────────────────────────────────

    /**
     * Returns an associative array:
     *
     *     ['calories' => int, 'protein' => int, 'carbs' => int, 'fat' => int]
     *
     * Macro grams are reconciled so that (protein×4 + carbs×4 + fat×9) matches
     * the calorie target as closely as possible.
     *
     * @return array{calories: int, protein: int, carbs: int, fat: int}
     */
    public function macros(
        int    $calories,
        float  $weightKg,
        string $goal,
        string $activityLevel,
        string $dietaryPattern = 'omnivore',
        int    $workoutDaysPerWeek = 0,
        string $workoutType = 'none',
    ): array {
        $goal = $this->normalizeGoal($goal);

        // ── Base percentage split by goal ────────────────
        [$proteinPct, $carbsPct, $fatPct] = match ($goal) {
            'buildMuscle' => [0.30, 0.45, 0.25],
            'loseFat',
            'loseWeight'  => [0.35, 0.35, 0.30],
            'gainWeight'  => [0.20, 0.55, 0.25],
            default       => [0.25, 0.50, 0.25],
        };

        // ── Dietary-pattern overrides ────────────────────
        if ($dietaryPattern === 'keto') {
            $proteinPct = 0.25;
            $carbsPct   = 0.07;
            $fatPct     = 0.68;
        } elseif ($dietaryPattern === 'lowCarb') {
            $proteinPct = 0.30;
            $carbsPct   = 0.25;
            $fatPct     = 0.45;
        } elseif ($dietaryPattern === 'mediterranean') {
            $proteinPct = 0.20;
            $carbsPct   = 0.50;
            $fatPct     = 0.30;
        }

        // ── Minimum protein floor (g per kg body weight) ─
        $hasTraining = $workoutDaysPerWeek >= 2
            && ! in_array($workoutType, ['none', 'workoutNone'], true);

        $proteinPerKg = $hasTraining
            ? 1.6
            : ($activityLevel === 'sedentary' ? 0.8 : 1.2);

        $minProtein = (int) round($weightKg * $proteinPerKg);

        $protein = (int) round(($calories * $proteinPct) / 4);
        if ($protein < $minProtein) {
            $protein = $minProtein;
        }

        $proteinCal = $protein * 4;
        if ($proteinCal > $calories) {
            $protein    = (int) floor($calories / 4);
            $proteinCal = $protein * 4;
        }

        // ── Split remaining calories between carbs & fat ─
        $remainingCal = $calories - $proteinCal;
        $nonProteinShare = $carbsPct + $fatPct;
        $carbShare = $nonProteinShare > 0
            ? $carbsPct / $nonProteinShare
            : 0.5;

        $carbs = (int) round($remainingCal * $carbShare / 4);
        $fat   = (int) round(($remainingCal - $carbs * 4) / 9);

        if ($fat < 0) {
            $fat   = 0;
            $carbs = (int) round($remainingCal / 4);
        }

        // ── Reconcile rounding so macro kcal == target ───
        $totalMacroCal = $protein * 4 + $carbs * 4 + $fat * 9;
        $diff = $calories - $totalMacroCal;

        if ($diff !== 0) {
            $carbAdjust = (int) round($diff / 4);
            $carbs = max(0, min(999, $carbs + $carbAdjust));

            $totalMacroCal = $protein * 4 + $carbs * 4 + $fat * 9;
            $diff = $calories - $totalMacroCal;

            if ($diff !== 0) {
                $fat = max(0, min(999, $fat + (int) round($diff / 9)));
            }
        }

        return [
            'calories' => $calories,
            'protein'  => $protein,
            'carbs'    => $carbs,
            'fat'      => $fat,
        ];
    }

    // ──────────────────────────────────────────────────────
    //  All-in-one convenience method
    // ──────────────────────────────────────────────────────

    /**
     * Compute daily calories + macro split in a single call.
     *
     * @return array{calories: int, protein: int, carbs: int, fat: int, bmr: float, tdee: float, bmi: float}
     */
    public function computeAll(
        float   $weightKg,
        float   $heightCm,
        int     $age,
        string  $gender,
        string  $activityLevel,
        string  $goal,
        string  $pace = 'moderate',
        ?float  $targetWeightKg = null,
        string  $pregnancyStatus = 'none',
        string  $dietaryPattern = 'omnivore',
        int     $workoutDaysPerWeek = 0,
        string  $workoutType = 'none',
    ): array {
        $bmrVal  = $this->bmr($weightKg, $heightCm, $age, $gender);
        $tdeeVal = $this->tdee(
            $weightKg, $heightCm, $age, $gender, $activityLevel,
            $workoutDaysPerWeek, $workoutType, $pregnancyStatus,
        );
        $bmiVal = $this->bmi($weightKg, $heightCm);

        $calories = $this->dailyCalories(
            $weightKg, $heightCm, $age, $gender, $activityLevel, $goal,
            $pace, $targetWeightKg, $workoutDaysPerWeek, $workoutType,
            $pregnancyStatus,
        );

        $macros = $this->macros(
            $calories, $weightKg, $goal, $activityLevel,
            $dietaryPattern, $workoutDaysPerWeek, $workoutType,
        );

        return [
            ...$macros,
            'bmr'  => round($bmrVal, 1),
            'tdee' => round($tdeeVal, 1),
            'bmi'  => round($bmiVal, 1),
        ];
    }

    // ──────────────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────────────

    private function isFemale(string $gender): bool
    {
        return in_array(strtolower($gender), ['female', 'f', 'woman'], true);
    }

    private function normalizeGoal(string $goal): string
    {
        return match ($goal) {
            'gainMuscle', 'athletic' => 'buildMuscle',
            'manageCondition'        => 'stayHealthy',
            default                  => $goal,
        };
    }
}
