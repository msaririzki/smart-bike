<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\DeviceHeartbeat;
use App\Models\Rental;
use App\Models\User;

class BikeStatusService
{
    public function __construct(private readonly PricingConfigService $pricing) {}

    public function recordHeartbeat(User $deviceUser, array $data): Bike
    {
        $bike = Bike::query()
            ->where('assigned_device_user_id', $deviceUser->id)
            ->firstOrFail();

        DeviceHeartbeat::query()->updateOrCreate(
            ['bike_id' => $bike->id, 'device_user_id' => $deviceUser->id],
            [
                'network_type' => $data['network_type'] ?? null,
                'signal_note' => $data['signal_note'] ?? null,
                'last_seen_at' => now(),
            ],
        );

        $updates = [
            'is_online' => true,
            'last_seen_at' => now(),
        ];

        if (isset($data['battery_percent'])) {
            $updates['battery_percent'] = $data['battery_percent'];
        }

        if ($bike->status === 'offline') {
            $updates['status'] = $this->onlineOperationalStatus($bike);
        }

        $bike->update($updates);

        return $bike->refresh();
    }

    public function markOfflineBikes(): int
    {
        $timeout = max(1, (int) $this->pricing->get('offline_timeout_seconds'));

        return Bike::query()
            ->where('is_online', true)
            ->where('last_seen_at', '<', now()->subSeconds($timeout))
            ->update(['is_online' => false]);
    }

    public function onlineOperationalStatus(Bike $bike): string
    {
        $hasActiveRental = Rental::query()
            ->where('bike_id', $bike->id)
            ->whereIn('status', [
                Rental::STATUS_ACTIVE,
                Rental::STATUS_IDLE_WARNING,
                Rental::STATUS_IDLE_BILLING,
            ])
            ->exists();

        return $hasActiveRental ? 'in_use' : 'available';
    }
}
