<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class LocationProcessingService
{
    private const MIN_RELIABLE_REPORTED_SPEED_KMH = 2.0;

    private const MAX_DYNAMIC_MOVEMENT_THRESHOLD_METERS = 35.0;

    private const MAX_STATIONARY_JITTER_METERS = 120.0;

    public function __construct(
        private readonly PricingConfigService $pricing,
        private readonly BillingService $billing,
        private readonly IdleDetectionService $idleDetection,
        private readonly BikeStatusService $bikeStatus,
    ) {}

    public function process(User $deviceUser, array $data): array
    {
        $bike = Bike::query()
            ->where('assigned_device_user_id', $deviceUser->id)
            ->firstOrFail();

        return DB::transaction(function () use ($bike, $data): array {
            $recordedAt = (isset($data['recorded_at']) ? Carbon::parse($data['recorded_at']) : now())->setTimezone(config('app.timezone'));
            $rental = Rental::query()
                ->where('bike_id', $bike->id)
                ->whereIn('status', [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])
                ->latest('started_at')
                ->first();

            $bikeUpdates = [
                'current_latitude' => $data['latitude'],
                'current_longitude' => $data['longitude'],
                'last_accuracy' => $data['accuracy_meters'] ?? null,
                'is_online' => true,
                'last_seen_at' => now(),
            ];

            if ($bike->status === 'offline') {
                $bikeUpdates['status'] = $rental ? 'in_use' : 'available';
            }

            $bike->update($bikeUpdates);

            if (! $rental) {
                $point = $this->storePoint($bike, null, $data, $recordedAt, 'no_active_rental');

                return ['bike' => $bike->refresh(), 'rental' => null, 'point' => $point, 'message' => 'Location stored for monitoring only.'];
            }

            $accuracy = isset($data['accuracy_meters']) ? (float) $data['accuracy_meters'] : null;
            $maxAccuracy = (float) $this->pricing->get('max_gps_accuracy_meters');

            if ($accuracy !== null && $accuracy > $maxAccuracy) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt, 'bad_accuracy');
                $this->idleDetection->checkIdleWarnings();

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'GPS accuracy too low for billing.'];
            }

            $previous = RentalLocationPoint::query()
                ->where('rental_id', $rental->id)
                ->whereNull('ignored_reason')
                ->where('is_anomaly', false)
                ->latest('recorded_at')
                ->first();

            if (! $previous) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt);

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Baseline GPS point stored.'];
            }

            if ($recordedAt->lte($previous->recorded_at)) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt, 'timestamp_not_forward');

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Timestamp ignored because it is not newer than previous point.'];
            }

            $distance = $this->haversineMeters(
                (float) $previous->latitude,
                (float) $previous->longitude,
                (float) $data['latitude'],
                (float) $data['longitude'],
            );

            $threshold = $this->movementThresholdMeters($data, $previous);
            if ($distance < $threshold) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt, 'below_threshold', $distance);
                $this->idleDetection->checkIdleWarnings();

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Movement below threshold; not billed.'];
            }

            $seconds = max(1, abs($recordedAt->diffInSeconds($previous->recorded_at)));
            $speedKmh = ($distance / $seconds) * 3.6;
            $maxSpeed = (float) $this->pricing->get('max_reasonable_speed_kmh');
            $reportedSpeedKmh = isset($data['speed_kmh']) ? (float) $data['speed_kmh'] : null;

            if ($this->looksLikeStationaryJitter($reportedSpeedKmh, $distance, $threshold)) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt, 'stationary_jitter', $distance);
                $this->idleDetection->checkIdleWarnings();

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Stationary GPS jitter ignored; not billed.'];
            }

            if ($speedKmh > $maxSpeed) {
                $point = $this->storePoint($bike, $rental, $data, $recordedAt, 'speed_anomaly', $distance, true);

                return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Movement ignored as GPS anomaly.'];
            }

            $point = $this->storePoint($bike, $rental, $data, $recordedAt, null, $distance, false, true);
            $rental->total_distance_meters = (float) $rental->total_distance_meters + $distance;
            $rental->last_movement_at = $recordedAt;
            $rental->save();

            $this->billing->recalculateDistanceCost($rental);
            $this->idleDetection->resumeIfMoving($rental->refresh());

            return ['bike' => $bike->refresh(), 'rental' => $rental->refresh(), 'point' => $point, 'message' => 'Valid movement processed.'];
        });
    }

    private function movementThresholdMeters(array $data, RentalLocationPoint $previous): float
    {
        $configuredThreshold = max(1.0, (float) $this->pricing->get('minimum_movement_threshold_meters'));
        $currentAccuracy = isset($data['accuracy_meters']) ? (float) $data['accuracy_meters'] : 0.0;
        $previousAccuracy = $previous->accuracy_meters !== null ? (float) $previous->accuracy_meters : 0.0;
        $dynamicThreshold = min(
            self::MAX_DYNAMIC_MOVEMENT_THRESHOLD_METERS,
            max($currentAccuracy, $previousAccuracy) * 1.5,
        );

        return max($configuredThreshold, $dynamicThreshold);
    }

    private function looksLikeStationaryJitter(?float $reportedSpeedKmh, float $distance, float $threshold): bool
    {
        if ($reportedSpeedKmh === null || $reportedSpeedKmh >= self::MIN_RELIABLE_REPORTED_SPEED_KMH) {
            return false;
        }

        return $distance < max(self::MAX_STATIONARY_JITTER_METERS, $threshold);
    }

    public function haversineMeters(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000;
        $latFrom = deg2rad($lat1);
        $latTo = deg2rad($lat2);
        $latDelta = deg2rad($lat2 - $lat1);
        $lonDelta = deg2rad($lon2 - $lon1);

        $a = sin($latDelta / 2) ** 2
            + cos($latFrom) * cos($latTo) * sin($lonDelta / 2) ** 2;

        return $earthRadius * (2 * atan2(sqrt($a), sqrt(1 - $a)));
    }

    private function storePoint(
        Bike $bike,
        ?Rental $rental,
        array $data,
        Carbon $recordedAt,
        ?string $ignoredReason = null,
        float $distance = 0,
        bool $isAnomaly = false,
        bool $isValidMovement = false,
    ): RentalLocationPoint {
        return RentalLocationPoint::query()->create([
            'rental_id' => $rental?->id,
            'bike_id' => $bike->id,
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'speed_kmh' => $data['speed_kmh'] ?? null,
            'accuracy_meters' => $data['accuracy_meters'] ?? null,
            'network_type' => $data['network_type'] ?? null,
            'movement_distance_meters' => $distance,
            'is_valid_movement' => $isValidMovement,
            'is_anomaly' => $isAnomaly,
            'ignored_reason' => $ignoredReason,
            'recorded_at' => $recordedAt,
        ]);
    }
}
