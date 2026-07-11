<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $isPremium = $this->isPremiumActive();
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'profile_photo_url' => $this->profile_photo_path
                ? asset('storage/'.$this->profile_photo_path)
                : null,
            'is_premium' => $isPremium,
            'premium_until' => $this->premium_until,
            'subscription' => [
                'isPremium' => $isPremium,
                'plan' => $isPremium ? 'custom' : null,
                'expiresAt' => $this->premium_until ? $this->premium_until->toIso8601String() : null,
                'active' => $isPremium,
            ],
            'profile' => new UserProfileResource($this->whenLoaded('profile')),
            'created_at' => $this->created_at,
        ];
    }
}
