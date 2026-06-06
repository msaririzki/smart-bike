<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\CellHandoverEvent;
use App\Models\CellObservation;
use App\Models\CellTower;
use App\Models\Rental;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class DashboardController extends Controller
{
    private const LOMBOK_LATITUDE_RANGE = [-8.95, -8.20];

    private const LOMBOK_LONGITUDE_RANGE = [115.75, 116.75];

    private const CONFIRMED_HANDOVER_DISTANCE_METERS = 25.0;

    private const PING_PONG_DISTANCE_METERS = 35.0;

    private const PING_PONG_SECONDS = 120;

    private const CONFIRMED_HANDOVER_SAMPLE_COUNT = 2;

    public function __invoke(Request $request): View
    {
        $activeRentalStatuses = [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING];
        $selectedCellDeviceId = $this->selectedCellDeviceId($request);
        $selectedCellRentalId = $this->selectedCellRentalId($request, $selectedCellDeviceId);

        return view('admin.dashboard', [
            'totalBikes' => Bike::query()->count(),
            'availableBikes' => Bike::query()
                ->where('status', 'available')
                ->where('is_online', true)
                ->count(),
            'inUseBikes' => Bike::query()->whereIn('status', ['in_use', 'idle'])->count(),
            'offlineBikes' => Bike::query()->where('is_online', false)->count(),
            'activeRentals' => Rental::query()->whereIn('status', $activeRentalStatuses)->count(),
            'completedRentalsToday' => Rental::query()
                ->where('status', Rental::STATUS_COMPLETED)
                ->whereDate('ended_at', today())
                ->count(),
            'totalRevenue' => Rental::query()->sum('total_cost'),
            'totalDistanceMeters' => Rental::query()->sum('total_distance_meters'),
            'users' => User::query()->where('role', 'user')->count(),
            'mapBikes' => $this->bikeMapData(),
            'mapCells' => $this->cellMapData($selectedCellDeviceId, $selectedCellRentalId),
            'cellRoute' => $this->cellRouteData($selectedCellDeviceId, $selectedCellRentalId),
            'cellHandovers' => $this->cellHandoverData($selectedCellDeviceId, $selectedCellRentalId),
            'cellDeviceOptions' => $this->cellDeviceOptions(),
            'cellRentalOptions' => $this->cellRentalOptions($selectedCellDeviceId),
            'selectedCellDeviceId' => $selectedCellDeviceId,
            'selectedCellRentalId' => $selectedCellRentalId,
        ]);
    }

    public function mapData(Request $request): JsonResponse
    {
        $selectedCellDeviceId = $this->selectedCellDeviceId($request);
        $selectedCellRentalId = $this->selectedCellRentalId($request, $selectedCellDeviceId);

        return response()->json([
            'data' => $this->bikeMapData(),
            'cells' => $this->cellMapData($selectedCellDeviceId, $selectedCellRentalId),
            'cell_route' => $this->cellRouteData($selectedCellDeviceId, $selectedCellRentalId),
            'cell_handovers' => $this->cellHandoverData($selectedCellDeviceId, $selectedCellRentalId),
            'cell_rental_options' => $this->cellRentalOptions($selectedCellDeviceId),
            'selected_cell_device_id' => $selectedCellDeviceId,
            'selected_cell_rental_id' => $selectedCellRentalId,
            'updated_at' => now()->format('Y-m-d H:i:s'),
        ]);
    }

    public function clearCellSurvey(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'device_user_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where('role', 'device'),
            ],
        ]);

        $deviceUserId = (int) $data['device_user_id'];
        $rentalId = $request->integer('cell_rental_id');
        if ($rentalId > 0 && ! CellObservation::query()
            ->where('device_user_id', $deviceUserId)
            ->where('rental_id', $rentalId)
            ->exists()) {
            throw ValidationException::withMessages([
                'cell_rental_id' => 'Perjalanan tidak valid untuk akun device yang dipilih.',
            ]);
        }

        $query = CellObservation::query()->where('device_user_id', $deviceUserId);
        if ($rentalId > 0) {
            $query->where('rental_id', $rentalId);
        } else {
            CellHandoverEvent::query()->where('device_user_id', $deviceUserId)->delete();
        }

        $deleted = $query->delete();
        CellTower::query()->doesntHave('observations')->delete();

        $scopeLabel = $rentalId > 0 ? 'perjalanan terpilih' : 'akun device';

        return redirect()
            ->route('admin.dashboard', ['cell_device_id' => $deviceUserId])
            ->with('status', "{$deleted} rekaman BTS {$scopeLabel} berhasil dibersihkan.");
    }

    private function bikeMapData(): Collection
    {
        return Bike::query()
            ->with(['assignedDevice:id,name,email', 'activeRental.user:id,name,email', 'latestHeartbeat'])
            ->whereNotNull('current_latitude')
            ->whereNotNull('current_longitude')
            ->whereBetween('current_latitude', self::LOMBOK_LATITUDE_RANGE)
            ->whereBetween('current_longitude', self::LOMBOK_LONGITUDE_RANGE)
            ->orderBy('code')
            ->get()
            ->map(fn (Bike $bike): array => [
                'code' => $bike->code,
                'name' => $bike->name,
                'status' => $bike->status,
                'is_online' => $bike->is_online,
                'battery_percent' => $bike->battery_percent,
                'network_type' => $bike->latestHeartbeat?->network_type,
                'latitude' => (float) $bike->current_latitude,
                'longitude' => (float) $bike->current_longitude,
                'last_seen_at' => $bike->last_seen_at?->format('Y-m-d H:i:s'),
                'device' => $bike->assignedDevice?->email,
                'active_rental' => $bike->activeRental ? [
                    'id' => $bike->activeRental->id,
                    'user' => $bike->activeRental->user?->name,
                    'detail_url' => route('admin.rentals.show', $bike->activeRental),
                ] : null,
                'detail_url' => route('admin.monitoring.show', $bike),
            ])
            ->values();
    }

    private function cellMapData(?int $deviceUserId, ?int $rentalId): Collection
    {
        if ($deviceUserId === null) {
            return collect();
        }

        return CellObservation::query()
            ->with(['cellTower', 'bike:id,code,name'])
            ->where('device_user_id', $deviceUserId)
            ->when($rentalId !== null, fn ($query) => $query->where('rental_id', $rentalId))
            ->whereBetween('latitude', self::LOMBOK_LATITUDE_RANGE)
            ->whereBetween('longitude', self::LOMBOK_LONGITUDE_RANGE)
            ->latest('observed_at')
            ->latest('id')
            ->limit(5000)
            ->get()
            ->groupBy('cell_tower_id')
            ->map(function (Collection $observations): ?array {
                /** @var CellObservation|null $latest */
                $latest = $observations->first();
                $cell = $latest?->cellTower;

                if (! $latest || ! $cell) {
                    return null;
                }

                $positionObservations = $observations
                    ->filter(fn (CellObservation $observation): bool => $observation->accuracy_meters !== null && (float) $observation->accuracy_meters <= 50.0);

                $centroidObservations = $positionObservations->isNotEmpty() ? $positionObservations : $observations;
                $earliest = $observations->last();

                return [
                    'id' => $cell->id,
                    'radio_type' => $cell->radio_type,
                    'operator_name' => $cell->operator_name,
                    'operator_label' => $latest->operator_label ?? $cell->operator_label,
                    'network_operator_code' => $latest->network_operator_code ?? $cell->network_operator_code,
                    'active_data_subscription_id' => $latest->active_data_subscription_id ?? $cell->active_data_subscription_id,
                    'mcc' => $cell->mcc,
                    'mnc' => $cell->mnc,
                    'cell_id' => $cell->cell_id,
                    'tac_or_lac' => $cell->tac_or_lac,
                    'pci_or_psc' => $cell->pci_or_psc,
                    'bike' => $latest->bike?->code,
                    'latitude' => round($this->average($centroidObservations, 'latitude') ?? (float) $latest->latitude, 7),
                    'longitude' => round($this->average($centroidObservations, 'longitude') ?? (float) $latest->longitude, 7),
                    'observation_count' => $observations->count(),
                    'position_observation_count' => $positionObservations->count(),
                    'average_signal_dbm' => $this->average($observations, 'signal_dbm'),
                    'average_rsrp_dbm' => $this->average($observations, 'rsrp_dbm'),
                    'average_rsrq_db' => $this->average($observations, 'rsrq_db'),
                    'average_sinr_db' => $this->average($observations, 'sinr_db'),
                    'first_seen_at' => $earliest?->observed_at?->format('Y-m-d H:i:s'),
                    'last_seen_at' => $latest->observed_at?->format('Y-m-d H:i:s'),
                ];
            })
            ->filter()
            ->sortByDesc('last_seen_at')
            ->take(500)
            ->values();
    }

    private function cellRouteData(?int $deviceUserId, ?int $rentalId): Collection
    {
        if ($deviceUserId === null || $rentalId === null) {
            return collect();
        }

        return $this->cellObservationSequence($deviceUserId, $rentalId)
            ->map(fn (CellObservation $observation): array => [
                'id' => $observation->id,
                'cell_tower_id' => $observation->cell_tower_id,
                'operator_label' => $observation->operator_label ?? $observation->cellTower?->operator_label,
                'radio_type' => $observation->cellTower?->radio_type,
                'cell_id' => $observation->cellTower?->cell_id,
                'latitude' => (float) $observation->latitude,
                'longitude' => (float) $observation->longitude,
                'accuracy_meters' => $observation->accuracy_meters !== null ? (float) $observation->accuracy_meters : null,
                'signal_dbm' => $observation->signal_dbm,
                'observed_at' => $observation->observed_at?->format('Y-m-d H:i:s'),
            ])
            ->values();
    }

    private function cellHandoverData(?int $deviceUserId, ?int $rentalId): Collection
    {
        if ($deviceUserId === null || $rentalId === null) {
            return collect();
        }

        $observations = $this->cellObservationSequence($deviceUserId, $rentalId)->values();
        $events = collect();

        for ($index = 1; $index < $observations->count(); $index++) {
            /** @var CellObservation $from */
            $from = $observations->get($index - 1);
            /** @var CellObservation $current */
            $current = $observations->get($index);

            if ((int) $from->cell_tower_id === (int) $current->cell_tower_id) {
                continue;
            }

            $classification = $this->classifyHandover($observations, $index);

            $events->push([
                'id' => "{$from->id}-{$current->id}",
                'from_cell_tower_id' => $from->cell_tower_id,
                'to_cell_tower_id' => $current->cell_tower_id,
                'from_operator_label' => $from->operator_label ?? $from->cellTower?->operator_label,
                'to_operator_label' => $current->operator_label ?? $current->cellTower?->operator_label,
                'from_radio_type' => $from->cellTower?->radio_type,
                'to_radio_type' => $current->cellTower?->radio_type,
                'from_cell_id' => $from->cellTower?->cell_id,
                'to_cell_id' => $current->cellTower?->cell_id,
                'latitude' => (float) $current->latitude,
                'longitude' => (float) $current->longitude,
                'signal_dbm' => $current->signal_dbm,
                'distance_from_previous_meters' => $this->distanceMeters($from, $current),
                'classification' => $classification['classification'],
                'classification_label' => $classification['label'],
                'classification_reason' => $classification['reason'],
                'observed_at' => $current->observed_at?->format('Y-m-d H:i:s'),
            ]);
        }

        return $events->values();
    }

    /**
     * @param Collection<int, CellObservation> $observations
     * @return array{classification: string, label: string, reason: string}
     */
    private function classifyHandover(Collection $observations, int $index): array
    {
        /** @var CellObservation $from */
        $from = $observations->get($index - 1);
        /** @var CellObservation $current */
        $current = $observations->get($index);
        /** @var CellObservation|null $beforeFrom */
        $beforeFrom = $observations->get($index - 2);
        $distanceMeters = $this->distanceMeters($from, $current);
        $newCellRunLength = $this->sameCellRunLength($observations, $index);
        $isShortPingPong = $beforeFrom
            && (int) $beforeFrom->cell_tower_id === (int) $current->cell_tower_id
            && $this->distanceMeters($beforeFrom, $current) <= self::PING_PONG_DISTANCE_METERS
            && $this->secondsBetween($beforeFrom, $current) <= self::PING_PONG_SECONDS;

        if ($isShortPingPong) {
            return [
                'classification' => 'fluctuation',
                'label' => 'Fluktuasi',
                'reason' => 'Pola ping-pong cell saat posisi relatif dekat.',
            ];
        }

        if ($distanceMeters >= self::CONFIRMED_HANDOVER_DISTANCE_METERS) {
            return [
                'classification' => 'confirmed',
                'label' => 'Pindah valid',
                'reason' => 'Cell berubah bersamaan dengan perpindahan GPS yang cukup jauh.',
            ];
        }

        if ($newCellRunLength >= self::CONFIRMED_HANDOVER_SAMPLE_COUNT) {
            return [
                'classification' => 'confirmed',
                'label' => 'Pindah valid',
                'reason' => 'Cell baru bertahan pada beberapa observasi berikutnya.',
            ];
        }

        return [
            'classification' => 'fluctuation',
            'label' => 'Fluktuasi',
            'reason' => 'Cell berubah singkat saat perpindahan GPS kecil.',
        ];
    }

    /**
     * @param Collection<int, CellObservation> $observations
     */
    private function sameCellRunLength(Collection $observations, int $startIndex): int
    {
        /** @var CellObservation $start */
        $start = $observations->get($startIndex);
        $count = 0;

        for ($index = $startIndex; $index < $observations->count(); $index++) {
            /** @var CellObservation $observation */
            $observation = $observations->get($index);
            if ((int) $observation->cell_tower_id !== (int) $start->cell_tower_id) {
                break;
            }

            $count++;
        }

        return $count;
    }

    private function distanceMeters(CellObservation $from, CellObservation $to): float
    {
        $earthRadiusMeters = 6371000;
        $fromLatitude = deg2rad((float) $from->latitude);
        $toLatitude = deg2rad((float) $to->latitude);
        $latitudeDelta = deg2rad((float) $to->latitude - (float) $from->latitude);
        $longitudeDelta = deg2rad((float) $to->longitude - (float) $from->longitude);

        $angle = sin($latitudeDelta / 2) ** 2
            + cos($fromLatitude) * cos($toLatitude) * sin($longitudeDelta / 2) ** 2;

        return round($earthRadiusMeters * 2 * atan2(sqrt($angle), sqrt(1 - $angle)), 2);
    }

    private function secondsBetween(CellObservation $from, CellObservation $to): int
    {
        if (! $from->observed_at || ! $to->observed_at) {
            return PHP_INT_MAX;
        }

        return (int) abs($to->observed_at->diffInSeconds($from->observed_at));
    }

    private function cellObservationSequence(int $deviceUserId, int $rentalId): Collection
    {
        return CellObservation::query()
            ->with('cellTower')
            ->where('device_user_id', $deviceUserId)
            ->where('rental_id', $rentalId)
            ->whereBetween('latitude', self::LOMBOK_LATITUDE_RANGE)
            ->whereBetween('longitude', self::LOMBOK_LONGITUDE_RANGE)
            ->orderBy('observed_at')
            ->orderBy('id')
            ->limit(5000)
            ->get();
    }

    private function selectedCellDeviceId(Request $request): ?int
    {
        $deviceUserId = $request->integer('cell_device_id');

        if ($deviceUserId <= 0) {
            return null;
        }

        return User::query()
            ->whereKey($deviceUserId)
            ->where('role', 'device')
            ->exists()
                ? $deviceUserId
                : null;
    }

    private function selectedCellRentalId(Request $request, ?int $deviceUserId): ?int
    {
        if ($deviceUserId === null) {
            return null;
        }

        $rentalId = $request->integer('cell_rental_id');
        if ($rentalId <= 0) {
            return null;
        }

        return CellObservation::query()
            ->where('device_user_id', $deviceUserId)
            ->where('rental_id', $rentalId)
            ->exists()
                ? $rentalId
                : null;
    }

    private function cellDeviceOptions(): Collection
    {
        return User::query()
            ->where('role', 'device')
            ->orderBy('name')
            ->get(['id', 'name', 'email']);
    }

    private function cellRentalOptions(?int $deviceUserId): Collection
    {
        if ($deviceUserId === null) {
            return collect();
        }

        $groups = CellObservation::query()
            ->where('device_user_id', $deviceUserId)
            ->whereNotNull('rental_id')
            ->selectRaw('rental_id, COUNT(*) as observation_count, MIN(observed_at) as first_observed_at, MAX(observed_at) as last_observed_at')
            ->groupBy('rental_id')
            ->orderByDesc('last_observed_at')
            ->limit(100)
            ->get();

        $rentals = Rental::query()
            ->with(['bike:id,code,name', 'user:id,name,email'])
            ->whereKey($groups->pluck('rental_id')->filter())
            ->get()
            ->keyBy('id');

        return $groups
            ->map(function (CellObservation $group) use ($rentals): ?array {
                $rentalId = (int) $group->rental_id;
                $rental = $rentals->get($rentalId);
                if (! $rental) {
                    return null;
                }

                return [
                    'id' => $rentalId,
                    'label' => sprintf(
                        '#%d - %s - %s',
                        $rentalId,
                        $rental->bike?->code ?? 'Sepeda',
                        $rental->started_at?->format('d/m H:i') ?? 'tanpa waktu',
                    ),
                    'observation_count' => (int) $group->observation_count,
                    'last_observed_at' => $group->last_observed_at,
                    'user_name' => $rental->user?->name,
                ];
            })
            ->filter()
            ->values();
    }

    private function average(Collection $observations, string $field): ?float
    {
        $values = $observations
            ->map(fn (CellObservation $observation): mixed => $observation->{$field})
            ->filter(fn (mixed $value): bool => $value !== null);

        return $values->isEmpty() ? null : round((float) $values->avg(), 2);
    }
}
