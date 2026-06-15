<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'profile_photo_url' => $this->profile_photo_path
                ? asset('storage/'.$this->profile_photo_path)
                : null,
            'is_premium' => $this->isPremiumActive(),
            'premium_until' => $this->premium_until,
            'profile' => new UserProfileResource($this->whenLoaded('profile')),
            'created_at' => $this->created_at,
        ];
    }
}
