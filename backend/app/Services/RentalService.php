<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RentalService
{
    public function __construct(private readonly PricingConfigService $pricing) {}

    public function start(User $user, Bike $bike): Rental
    {
        if (! $this->pricing->get('allow_multiple_active_rentals')) {
            $hasActive = $user->rentals()
                ->whereIn('status', [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])
                ->exists();

            if ($hasActive) {
                throw ValidationException::withMessages([
                    'rental' => 'User masih memiliki rental aktif.',
                ]);
            }
        }

        if ($bike->status !== 'available') {
            throw ValidationException::withMessages([
                'bike_id' => 'Bike tidak tersedia untuk disewa.',
            ]);
        }

        if (! $bike->is_online) {
            throw ValidationException::withMessages([
                'bike_id' => 'Bike sedang offline dan tidak bisa disewa.',
            ]);
        }

        return DB::transaction(function () use ($user, $bike) {
            $rental = Rental::query()->create([
                'user_id' => $user->id,
                'bike_id' => $bike->id,
                'status' => Rental::STATUS_ACTIVE,
                'started_at' => now(),
                'last_movement_at' => now(),
            ]);

            $bike->update(['status' => 'in_use']);

            return $rental->load('bike');
        });
    }

    public function finish(User $user, Rental $rental): Rental
    {
        if ($user->role === 'user' && $rental->user_id !== $user->id) {
            abort(403, 'Rental ini bukan milik user.');
        }

        if (in_array($rental->status, [Rental::STATUS_COMPLETED, Rental::STATUS_CANCELLED], true)) {
            return $rental->load('bike', 'billingLogs');
        }

        return DB::transaction(function () use ($rental) {
            $rental->update([
                'status' => Rental::STATUS_COMPLETED,
                'ended_at' => now(),
                'total_cost' => (int) $rental->distance_cost + (int) $rental->idle_cost,
            ]);

            $rental->bike()->update(['status' => 'available']);

            return $rental->refresh()->load('bike', 'billingLogs');
        });
    }

    public function continueIdle(User $user, Rental $rental): Rental
    {
        if ($rental->user_id !== $user->id) {
            abort(403, 'Rental ini bukan milik user.');
        }

        if ($rental->status !== Rental::STATUS_IDLE_WARNING) {
            return $rental;
        }

        $rental->update([
            'idle_warning_at' => now(),
        ]);

        $rental->idleEvents()->create([
            'event_type' => 'warning_acknowledged',
            'description' => 'User memilih lanjut sewa saat idle warning. Grace period idle diulang.',
            'event_at' => now(),
        ]);

        return $rental->refresh();
    }
}
