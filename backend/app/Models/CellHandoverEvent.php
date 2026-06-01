<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'bike_id',
    'device_user_id',
    'from_cell_tower_id',
    'to_cell_tower_id',
    'latitude',
    'longitude',
    'observed_at',
])]
class CellHandoverEvent extends Model
{
    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'observed_at' => 'datetime',
        ];
    }

    public function fromCellTower(): BelongsTo
    {
        return $this->belongsTo(CellTower::class, 'from_cell_tower_id');
    }

    public function toCellTower(): BelongsTo
    {
        return $this->belongsTo(CellTower::class, 'to_cell_tower_id');
    }
}
