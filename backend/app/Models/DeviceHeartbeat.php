<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['bike_id', 'device_user_id', 'network_type', 'last_seen_at', 'signal_note'])]
class DeviceHeartbeat extends Model
{
    protected function casts(): array
    {
        return ['last_seen_at' => 'datetime'];
    }

    public function bike(): BelongsTo
    {
        return $this->belongsTo(Bike::class);
    }

    public function deviceUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'device_user_id');
    }
}
