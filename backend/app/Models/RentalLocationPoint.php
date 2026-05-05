<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'rental_id',
    'bike_id',
    'latitude',
    'longitude',
    'speed_kmh',
    'accuracy_meters',
    'network_type',
    'movement_distance_meters',
    'is_valid_movement',
    'is_anomaly',
    'ignored_reason',
    'recorded_at',
])]
class RentalLocationPoint extends Model
{
    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'speed_kmh' => 'decimal:2',
            'accuracy_meters' => 'decimal:2',
            'movement_distance_meters' => 'decimal:2',
            'is_valid_movement' => 'boolean',
            'is_anomaly' => 'boolean',
            'recorded_at' => 'datetime',
        ];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }

    public function bike(): BelongsTo
    {
        return $this->belongsTo(Bike::class);
    }
}
