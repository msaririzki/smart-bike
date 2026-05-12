<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\BikeQrSession;
use App\Models\Rental;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class BikeQrRentalService
{
    public function __construct(private readonly RentalService $rentals) {}

    /**
     * Generate a new QR rental token for a device's assigned bike.
     */
    public function generateQr(User $deviceUser): BikeQrSession
    {
        $bike = Bike::query()
            ->where('assigned_device_user_id', $deviceUser->id)
            ->first();

        if (! $bike) {
            throw ValidationException::withMessages([
                'device' => 'Akun device belum di-assign ke sepeda.',
            ]);
        }

        // Check if bike has an active rental
        $hasActiveRental = Rental::query()
            ->where('bike_id', $bike->id)
            ->whereIn('status', [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])
            ->exists();

        if ($hasActiveRental) {
            throw ValidationException::withMessages([
                'bike' => 'Sepeda sedang disewa, tidak bisa membuat QR.',
            ]);
        }

        // Expire any previous unused tokens for this bike
        BikeQrSession::query()
            ->where('bike_id', $bike->id)
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->update(['expires_at' => now()]);

        $token = 'qr_' . Str::random(40);

        return BikeQrSession::query()->create([
            'bike_id' => $bike->id,
            'device_user_id' => $deviceUser->id,
            'token' => $token,
            'expires_at' => now()->addSeconds(120),
        ]);
    }

    /**
     * Start a rental from a QR token.
     */
    public function startFromQr(User $user, string $token): Rental
    {
        $session = BikeQrSession::query()
            ->with('bike')
            ->where('token', $token)
            ->first();

        if (! $session) {
            throw ValidationException::withMessages([
                'token' => 'QR tidak valid untuk Smart Bike.',
            ]);
        }

        if ($session->isExpired()) {
            throw ValidationException::withMessages([
                'token' => 'QR sudah kedaluwarsa. Minta QR baru dari perangkat sepeda.',
            ]);
        }

        if ($session->isUsed()) {
            throw ValidationException::withMessages([
                'token' => 'QR sudah pernah digunakan.',
            ]);
        }

        $bike = $session->bike;

        if (! $bike || $bike->status !== 'available') {
            throw ValidationException::withMessages([
                'token' => 'Sepeda belum tersedia untuk disewa.',
            ]);
        }

        return DB::transaction(function () use ($user, $bike, $session) {
            // Mark token as used
            $session->update([
                'used_at' => now(),
                'used_by_user_id' => $user->id,
            ]);

            // Use existing RentalService to start the rental
            return $this->rentals->start($user, $bike);
        });
    }
}
