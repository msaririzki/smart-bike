<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['rental_id', 'event_type', 'description', 'event_at'])]
class RentalIdleEvent extends Model
{
    protected function casts(): array
    {
        return ['event_at' => 'datetime'];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }
}
