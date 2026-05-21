<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'identity_key',
    'radio_type',
    'operator_name',
    'mcc',
    'mnc',
    'cell_id',
    'tac_or_lac',
    'pci_or_psc',
    'estimated_latitude',
    'estimated_longitude',
    'observation_count',
    'position_observation_count',
    'average_signal_dbm',
    'average_rsrp_dbm',
    'average_rsrq_db',
    'average_sinr_db',
    'first_seen_at',
    'last_seen_at',
])]
class CellTower extends Model
{
    protected function casts(): array
    {
        return [
            'estimated_latitude' => 'decimal:7',
            'estimated_longitude' => 'decimal:7',
            'average_signal_dbm' => 'decimal:2',
            'average_rsrp_dbm' => 'decimal:2',
            'average_rsrq_db' => 'decimal:2',
            'average_sinr_db' => 'decimal:2',
            'first_seen_at' => 'datetime',
            'last_seen_at' => 'datetime',
        ];
    }

    public function observations(): HasMany
    {
        return $this->hasMany(CellObservation::class);
    }
}
