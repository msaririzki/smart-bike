<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

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

    public function locationPoints(): HasMany
    {
        return $this->hasMany(RentalLocationPoint::class);
    }
}
