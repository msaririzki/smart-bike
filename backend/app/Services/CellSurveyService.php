<?php

namespace App\Services;

use App\Models\Bike;
use App\Models\CellHandoverEvent;
use App\Models\CellObservation;
use App\Models\CellTower;
use App\Models\Rental;
use App\Models\RentalLocationPoint;
use App\Models\User;
use Carbon\Carbon;

class CellSurveyService
{
    private const MAX_CENTROID_ACCURACY_METERS = 50.0;

    public function recordObservation(
        User $deviceUser,
        Bike $bike,
        ?Rental $rental,
        RentalLocationPoint $point,
        ?array $cell,
        Carbon $observedAt,
    ): ?array {
        $normalized = $this->normalizeCell($cell);
        if (! $normalized) {
            return null;
        }

        $tower = CellTower::query()->firstOrCreate(
            ['identity_key' => $normalized['identity_key']],
            [
                'radio_type' => $normalized['radio_type'],
                'operator_name' => $normalized['operator_name'],
                'mcc' => $normalized['mcc'],
                'mnc' => $normalized['mnc'],
                'cell_id' => $normalized['cell_id'],
                'tac_or_lac' => $normalized['tac_or_lac'],
                'pci_or_psc' => $normalized['pci_or_psc'],
                'first_seen_at' => $observedAt,
                'last_seen_at' => $observedAt,
            ],
        );

        $previousObservation = CellObservation::query()
            ->where('bike_id', $bike->id)
            ->latest('observed_at')
            ->latest('id')
            ->first();

        $observation = CellObservation::query()->create([
            'cell_tower_id' => $tower->id,
            'bike_id' => $bike->id,
            'device_user_id' => $deviceUser->id,
            'rental_id' => $rental?->id,
            'rental_location_point_id' => $point->id,
            'latitude' => $point->latitude,
            'longitude' => $point->longitude,
            'accuracy_meters' => $point->accuracy_meters,
            'signal_dbm' => $normalized['signal_dbm'],
            'rsrp_dbm' => $normalized['rsrp_dbm'],
            'rsrq_db' => $normalized['rsrq_db'],
            'sinr_db' => $normalized['sinr_db'],
            'is_registered' => $normalized['is_registered'],
            'observed_at' => $observedAt,
        ]);

        $this->updateTowerEstimate($tower, $normalized, $point, $observedAt);

        $event = null;
        if ($previousObservation && (int) $previousObservation->cell_tower_id !== (int) $tower->id) {
            $event = CellHandoverEvent::query()->create([
                'bike_id' => $bike->id,
                'device_user_id' => $deviceUser->id,
                'from_cell_tower_id' => $previousObservation->cell_tower_id,
                'to_cell_tower_id' => $tower->id,
                'latitude' => $point->latitude,
                'longitude' => $point->longitude,
                'observed_at' => $observedAt,
            ]);
        }

        return ['tower' => $tower->refresh(), 'observation' => $observation, 'handover_event' => $event];
    }

    private function normalizeCell(?array $cell): ?array
    {
        if (! $cell || empty($cell['cell_id'])) {
            return null;
        }

        $radioType = strtoupper((string) ($cell['radio_type'] ?? 'UNKNOWN'));
        if (! in_array($radioType, ['LTE', 'NR', 'WCDMA', 'GSM', 'UNKNOWN'], true)) {
            $radioType = 'UNKNOWN';
        }

        $mcc = $this->stringOrNull($cell['mcc'] ?? null, 10);
        $mnc = $this->stringOrNull($cell['mnc'] ?? null, 10);
        $cellId = $this->stringOrNull($cell['cell_id'] ?? null, 64);
        $tacOrLac = $this->stringOrNull($cell['tac_or_lac'] ?? null, 64);

        if ($cellId === null) {
            return null;
        }

        $identityKey = hash('sha256', implode('|', [
            $mcc ?? '',
            $mnc ?? '',
            $radioType,
            $cellId,
            $tacOrLac ?? '',
        ]));

        return [
            'identity_key' => $identityKey,
            'radio_type' => $radioType,
            'operator_name' => $this->stringOrNull($cell['operator_name'] ?? null, 100),
            'mcc' => $mcc,
            'mnc' => $mnc,
            'cell_id' => $cellId,
            'tac_or_lac' => $tacOrLac,
            'pci_or_psc' => $this->stringOrNull($cell['pci_or_psc'] ?? null, 64),
            'signal_dbm' => $this->intOrNull($cell['signal_dbm'] ?? null),
            'rsrp_dbm' => $this->intOrNull($cell['rsrp_dbm'] ?? null),
            'rsrq_db' => $this->floatOrNull($cell['rsrq_db'] ?? null),
            'sinr_db' => $this->floatOrNull($cell['sinr_db'] ?? null),
            'is_registered' => (bool) ($cell['is_registered'] ?? false),
        ];
    }

    private function updateTowerEstimate(CellTower $tower, array $cell, RentalLocationPoint $point, Carbon $observedAt): void
    {
        $count = (int) $tower->observation_count;
        $positionCount = (int) $tower->position_observation_count;
        $accuracy = $point->accuracy_meters !== null ? (float) $point->accuracy_meters : null;
        $useForPosition = $accuracy !== null && $accuracy <= self::MAX_CENTROID_ACCURACY_METERS;

        $updates = [
            'operator_name' => $cell['operator_name'] ?? $tower->operator_name,
            'pci_or_psc' => $cell['pci_or_psc'] ?? $tower->pci_or_psc,
            'observation_count' => $count + 1,
            'average_signal_dbm' => $this->nextAverage($tower->average_signal_dbm, $count, $cell['signal_dbm']),
            'average_rsrp_dbm' => $this->nextAverage($tower->average_rsrp_dbm, $count, $cell['rsrp_dbm']),
            'average_rsrq_db' => $this->nextAverage($tower->average_rsrq_db, $count, $cell['rsrq_db']),
            'average_sinr_db' => $this->nextAverage($tower->average_sinr_db, $count, $cell['sinr_db']),
            'first_seen_at' => $tower->first_seen_at ?? $observedAt,
            'last_seen_at' => $observedAt,
        ];

        if ($useForPosition) {
            $updates['position_observation_count'] = $positionCount + 1;
            $updates['estimated_latitude'] = $this->nextAverage($tower->estimated_latitude, $positionCount, (float) $point->latitude);
            $updates['estimated_longitude'] = $this->nextAverage($tower->estimated_longitude, $positionCount, (float) $point->longitude);
        }

        $tower->forceFill($updates)->save();
    }

    private function nextAverage(mixed $currentAverage, int $count, mixed $nextValue): mixed
    {
        if ($nextValue === null) {
            return $currentAverage;
        }

        if ($currentAverage === null || $count <= 0) {
            return $nextValue;
        }

        return (((float) $currentAverage * $count) + (float) $nextValue) / ($count + 1);
    }

    private function stringOrNull(mixed $value, int $maxLength): ?string
    {
        if ($value === null) {
            return null;
        }

        $string = trim((string) $value);

        return $string === '' ? null : mb_substr($string, 0, $maxLength);
    }

    private function intOrNull(mixed $value): ?int
    {
        return is_numeric($value) ? (int) $value : null;
    }

    private function floatOrNull(mixed $value): ?float
    {
        return is_numeric($value) ? (float) $value : null;
    }
}
