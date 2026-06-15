# BNYAD — Laravel Backend (Firebase migration)

This folder is the Laravel backend that replaces the app's Firebase (Cloud
Firestore + Firebase Auth) backend. It contains the **full data layer + REST
API**: migrations, Eloquent models, controllers, routes, API resources, form
requests, and a seeder. Drop it into a fresh Laravel 11 project.

## What was migrated

The Flutter app previously used **Cloud Firestore** (4 collections) plus several
features kept only in local storage (`SharedPreferences`). Everything that
represents user data now lives in MySQL.

| Source (Firebase / local)        | Laravel table(s)                     | Notes |
| -------------------------------- | ------------------------------------ | ----- |
| `users/{uid}` document           | `users` + `user_profiles`            | Auth fields on `users`; onboarding/body/diet fields on `user_profiles` (1:1). |
| `foodLogs` collection            | `daily_logs`                         | Stores a macro **snapshot** per entry. `mealId`→`meal_type`, `date`→`logged_at`, `timestamp`→`consumed_at`. |
| `waterLogs/{uid}_{date}`         | `water_logs`                         | One row per user/day, `unique(user_id, log_date)`. |
| `mealPlans/{uid}` document       | `meal_plans` + `meal_plan_items`     | 4 slots (breakfast/lunch/dinner/snacks); multilingual content stored as JSON keyed by locale. |
| In-app static food DB (Dart)     | `food_items` + `food_item_translations` | Translation Table Pattern, locales `en` / `ar` / `ckb`. |
| Local weight history             | `weight_entries`                     | `unique(user_id, log_date)`. |
| Local vitamins tracker           | `vitamins`                           | `taken` resets daily via `POST /vitamins/reset`. |
| Local favorites                  | `favorite_templates`                 | |
| Local shopping list              | `shopping_items`                     | |
| Local meal reminders             | `meal_reminders`                     | Per-meal enabled flag + time, syncs across devices. |
| Local premium flag               | `users.is_premium` / `premium_until` | |
| Firebase Phone Auth              | `phone_otps` + Sanctum tokens        | OTP request/verify, password credential, bearer token. |

## API endpoints

All routes are under `/api`. Authenticated routes need
`Authorization: Bearer <token>`.

### Auth (public)
| Method | Path | Body | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/request-otp` | `phone` | Generate + send a 6-digit OTP. In non-prod returns `demo_code` (`123456`). |
| POST | `/auth/verify-otp` | `phone, code, password, name?` | Verify OTP; registers on first sign-in, else logs in. Returns `token` + `user`. |

### Auth (token required)
| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/auth/me` | Current user + profile |
| POST | `/auth/logout` | Revoke current token |

### Data (token required)
| Method | Path | Purpose |
| --- | --- | --- |
| GET / PUT | `/profile` | Read / update onboarding profile |
| GET | `/logs?date=Y-m-d` or `?from=&to=` | Food logs for a day / range |
| POST | `/logs` | Add a food log |
| DELETE | `/logs/{id}` | Remove a food log |
| GET | `/water?date=Y-m-d` | Glasses for a day |
| PUT | `/water` | Set glasses for a day |
| GET / POST | `/weights` | Weight history / add entry |
| GET / PUT / DELETE | `/meal-plan` | Read / replace / clear meal plan |
| GET / POST | `/vitamins` | List / add vitamins |
| PUT / DELETE | `/vitamins/{id}` | Update / delete |
| POST | `/vitamins/reset` | Reset all `taken` flags (new day) |
| GET / POST | `/favorites` | List / add favorite templates |
| DELETE | `/favorites/{id}` | Delete |
| GET / POST | `/shopping` | List / add shopping items |
| PUT / DELETE | `/shopping/{id}` | Update / delete |
| GET / PUT | `/reminders` | List / upsert a meal reminder |
| GET | `/foods?q=&category=` | Search food catalog |
| GET | `/foods/{id}` | Single food item |

## Firestore security rules → Laravel

Firestore rules enforced "a user can only touch their own documents". Here that
is enforced by `auth:sanctum` + scoping every query to
`$request->user()` (and `abort_unless($model->user_id === $request->user()->id, 403)`
on direct model routes).

## Locale note

The Flutter app uses the language code **`ku`** for Kurdish, while the
translation tables use the ISO code **`ckb`** (Sorani).
`FoodItem::translationForLocale()` normalizes `ku → ckb` and falls back through
`en → ar → ckb`. Set the request locale with Laravel's `app()->setLocale()`
(e.g. from an `Accept-Language` header middleware) so `localized_name` resolves
correctly.

## Setup

```bash
composer create-project laravel/laravel bnyad-api
cd bnyad-api
composer require laravel/sanctum
php artisan install:api          # publishes Sanctum + personal_access_tokens

# copy this folder's app/, database/, and routes/api.php into the project, then:
php artisan migrate --seed
```

`.env` (MySQL):

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bnyad
DB_USERNAME=root
DB_PASSWORD=
```

In `bootstrap/app.php` make sure the API routes are registered (Laravel 11):

```php
->withRouting(
    web: __DIR__.'/../routes/web.php',
    api: __DIR__.'/../routes/api.php',
    commands: __DIR__.'/../routes/console.php',
    health: '/up',
)
```

## Importing the full food catalog

The seeder inserts a representative sample. To import the **entire** in-app food
list, export Flutter's `foodDatabase` to `database/data/food_items.json` and run
`php artisan db:seed --class=FoodItemSeeder`. Expected shape:

```json
[
  {
    "external_id": "p8",
    "category": "Protein",
    "calories": 155, "protein": 11, "carbs": 1.1, "fats": 11,
    "serving_size": 100, "serving_unit": "g",
    "micros": { "vitA": 160, "iron": 1.8 },
    "names": { "en": "Whole Egg", "ar": "بيضة كاملة", "ckb": "هێلکە" }
  }
]
```

A quick way to generate that file from the Flutter project (one-off Dart script):

```dart
// tool/export_foods.dart  —  run with: dart run tool/export_foods.dart
import 'dart:convert';
import 'dart:io';
import 'package:nutrify/constants/food_database.dart';

void main() {
  final list = foodDatabase.map((f) => {
    'external_id': f.id,
    'category': f.category,
    'calories': f.calories, 'protein': f.protein,
    'carbs': f.carbs, 'fats': f.fat,
    'serving_size': f.nutritionReferenceG, 'serving_unit': 'g',
    'micros': f.micros,
    'names': {'en': f.name, 'ar': f.nameAr, 'ckb': f.nameKu},
  }).toList();
  File('food_items.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(list));
  stdout.writeln('Wrote ${list.length} foods.');
}
```

## Files

```
laravel-backend/
  app/
    Models/                 13 Eloquent models + PhoneOtp
    Http/
      Controllers/Api/      11 controllers (+ base Controller)
      Requests/             form-request validators
      Resources/            API resources (JSON shaping)
  database/
    migrations/             15 migrations
    seeders/                FoodItemSeeder + DatabaseSeeder
  routes/
    api.php                 all REST endpoints
```
