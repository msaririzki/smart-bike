<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use App\Services\NotificationService;
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

        return DB::transaction(function () use ($user, $bike) {
            $rental = Rental::query()->create([
                'user_id' => $user->id,
                'bike_id' => $bike->id,
                'status' => Rental::STATUS_ACTIVE,
                'started_at' => now(),
                'last_movement_at' => now(),
            ]);

            $bike->update(['status' => 'in_use']);

            NotificationService::send(
                $user->id,
                'Sewa Dimulai',
                "Sewa sepeda {$bike->code} telah dimulai. Selamat bersepeda!",
                'sewa',
                [
                    'rental_id' => $rental->id,
                    'rental_status' => 'started',
                    'bike_code' => $bike->code,
                    'started_at' => now()->toIso8601String(),
                    'start_location' => 'Shelter Utama',
                    'battery' => ($bike->battery_percent ?? 85) . '% / Baik',
                    'safety_notes' => 'Pastikan standar sepeda sudah dinaikkan. Selalu parkirkan kembali sepeda di shelter resmi terdekat agar terhindar dari denda tambahan.',
                ]
            );

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

        return DB::transaction(function () use ($user, $rental) {
            $rental->update([
                'status' => Rental::STATUS_COMPLETED,
                'ended_at' => now(),
                'total_cost' => (int) $rental->distance_cost + (int) $rental->idle_cost,
            ]);

            $rental->bike()->update(['status' => 'available']);

            $totalCostFormat = number_format($rental->total_cost, 0, ',', '.');
            NotificationService::send(
                $user->id,
                'Sewa Selesai',
                "Sewa sepeda {$rental->bike->code} selesai. Total biaya: Rp {$totalCostFormat}.",
                'sewa',
                [
                    'rental_id' => $rental->id,
                    'rental_status' => 'completed',
                    'bike_code' => $rental->bike->code,
                    'started_at' => $rental->started_at->toIso8601String(),
                    'ended_at' => now()->toIso8601String(),
                    'duration_minutes' => $rental->started_at->diffInMinutes(now()),
                    'distance_meters' => $rental->total_distance_meters ?? 0,
                    'total_cost' => $rental->total_cost,
                    'end_location' => 'Shelter Utama',
                ]
            );

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
