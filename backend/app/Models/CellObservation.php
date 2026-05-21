<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'cell_tower_id',
    'bike_id',
    'device_user_id',
    'rental_id',
    'rental_location_point_id',
    'latitude',
    'longitude',
    'accuracy_meters',
    'signal_dbm',
    'rsrp_dbm',
    'rsrq_db',
    'sinr_db',
    'is_registered',
    'observed_at',
])]
class CellObservation extends Model
{
    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'accuracy_meters' => 'decimal:2',
            'rsrq_db' => 'decimal:2',
            'sinr_db' => 'decimal:2',
            'is_registered' => 'boolean',
            'observed_at' => 'datetime',
        ];
    }

    public function cellTower(): BelongsTo
    {
        return $this->belongsTo(CellTower::class);
    }
}
