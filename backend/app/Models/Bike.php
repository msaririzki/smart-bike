<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable([
    'code',
    'name',
    'status',
    'current_latitude',
    'current_longitude',
    'last_accuracy',
    'is_online',
    'battery_percent',
    'assigned_device_user_id',
    'last_seen_at',
])]
class Bike extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'current_latitude' => 'decimal:7',
            'current_longitude' => 'decimal:7',
            'last_accuracy' => 'decimal:2',
            'is_online' => 'boolean',
            'last_seen_at' => 'datetime',
        ];
    }

    public function assignedDevice(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_device_user_id');
    }

    public function rentals(): HasMany
    {
        return $this->hasMany(Rental::class);
    }

    public function activeRental(): HasOne
    {
        return $this->hasOne(Rental::class)
            ->whereIn('status', [
                Rental::STATUS_ACTIVE,
                Rental::STATUS_IDLE_WARNING,
                Rental::STATUS_IDLE_BILLING,
            ])
            ->latestOfMany('started_at');
    }

    public function locationPoints(): HasMany
    {
        return $this->hasMany(RentalLocationPoint::class);
    }

    public function latestLocationPoint(): HasOne
    {
        return $this->hasOne(RentalLocationPoint::class)->latestOfMany('recorded_at');
    }

    public function deviceHeartbeats(): HasMany
    {
        return $this->hasMany(DeviceHeartbeat::class);
    }

    public function cellObservations(): HasMany
    {
        return $this->hasMany(CellObservation::class);
    }

    public function latestHeartbeat(): HasOne
    {
        return $this->hasOne(DeviceHeartbeat::class)->latestOfMany('last_seen_at');
    }
}
