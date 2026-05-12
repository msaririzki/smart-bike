<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable([
    'user_id',
    'bike_id',
    'status',
    'started_at',
    'ended_at',
    'last_movement_at',
    'idle_warning_at',
    'idle_started_at',
    'last_idle_billing_at',
    'total_distance_meters',
    'distance_cost',
    'idle_cost',
    'total_cost',
])]
class Rental extends Model
{
    use HasFactory;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_IDLE_WARNING = 'idle_warning';

    public const STATUS_IDLE_BILLING = 'idle_billing';

    public const STATUS_COMPLETED = 'completed';

    public const STATUS_CANCELLED = 'cancelled';

    protected $appends = ['current_speed_kmh'];

    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
            'last_movement_at' => 'datetime',
            'idle_warning_at' => 'datetime',
            'idle_started_at' => 'datetime',
            'last_idle_billing_at' => 'datetime',
            'total_distance_meters' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function bike(): BelongsTo
    {
        return $this->belongsTo(Bike::class);
    }

    public function locationPoints(): HasMany
    {
        return $this->hasMany(RentalLocationPoint::class);
    }

    public function latestLocationPoint(): HasOne
    {
        return $this->hasOne(RentalLocationPoint::class)->latestOfMany('recorded_at');
    }

    public function idleEvents(): HasMany
    {
        return $this->hasMany(RentalIdleEvent::class);
    }

    public function billingLogs(): HasMany
    {
        return $this->hasMany(RentalBillingLog::class);
    }

    public function getCurrentSpeedKmhAttribute(): float
    {
        return (float) ($this->latestLocationPoint?->speed_kmh ?? 0);
    }
}
