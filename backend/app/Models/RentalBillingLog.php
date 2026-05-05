<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['rental_id', 'billing_type', 'amount', 'quantity', 'unit_label', 'notes'])]
class RentalBillingLog extends Model
{
    protected function casts(): array
    {
        return ['quantity' => 'decimal:2'];
    }

    public function rental(): BelongsTo
    {
        return $this->belongsTo(Rental::class);
    }
}
