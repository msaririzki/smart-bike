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
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class DashboardController extends Controller
{
    private const LOMBOK_LATITUDE_RANGE = [-8.95, -8.20];

    private const LOMBOK_LONGITUDE_RANGE = [115.75, 116.75];

    public function __invoke(Request $request): View
    {
        $activeRentalStatuses = [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING];
        $selectedCellDeviceId = $this->selectedCellDeviceId($request);

        return view('admin.dashboard', [
            'totalBikes' => Bike::query()->count(),
            'availableBikes' => Bike::query()->where('status', 'available')->count(),
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
            'mapCells' => $this->cellMapData($selectedCellDeviceId),
            'cellDeviceOptions' => $this->cellDeviceOptions(),
            'selectedCellDeviceId' => $selectedCellDeviceId,
        ]);
    }

    public function mapData(Request $request): JsonResponse
    {
        $selectedCellDeviceId = $this->selectedCellDeviceId($request);

        return response()->json([
            'data' => $this->bikeMapData(),
            'cells' => $this->cellMapData($selectedCellDeviceId),
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
        CellHandoverEvent::query()->where('device_user_id', $deviceUserId)->delete();
        $deleted = CellObservation::query()->where('device_user_id', $deviceUserId)->delete();
        CellTower::query()->doesntHave('observations')->delete();

        return redirect()
            ->route('admin.dashboard', ['cell_device_id' => $deviceUserId])
            ->with('status', "{$deleted} rekaman BTS akun device berhasil dibersihkan.");
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

    private function cellMapData(?int $deviceUserId): Collection
    {
        if ($deviceUserId === null) {
            return collect();
        }

        return CellObservation::query()
            ->with(['cellTower', 'bike:id,code,name'])
            ->where('device_user_id', $deviceUserId)
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

    private function cellDeviceOptions(): Collection
    {
        return User::query()
            ->where('role', 'device')
            ->orderBy('name')
            ->get(['id', 'name', 'email']);
    }

    private function average(Collection $observations, string $field): ?float
    {
        $values = $observations
            ->map(fn (CellObservation $observation): mixed => $observation->{$field})
            ->filter(fn (mixed $value): bool => $value !== null);

        return $values->isEmpty() ? null : round((float) $values->avg(), 2);
    }
}
