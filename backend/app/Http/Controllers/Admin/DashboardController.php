<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\CellTower;
use App\Models\Rental;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Collection;
use Illuminate\View\View;

class DashboardController extends Controller
{
    private const LOMBOK_LATITUDE_RANGE = [-8.95, -8.20];

    private const LOMBOK_LONGITUDE_RANGE = [115.75, 116.75];

    public function __invoke(): View
    {
        $activeRentalStatuses = [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING];

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
            'mapCells' => $this->cellMapData(),
        ]);
    }

    public function mapData(): JsonResponse
    {
        return response()->json([
            'data' => $this->bikeMapData(),
            'cells' => $this->cellMapData(),
            'updated_at' => now()->format('Y-m-d H:i:s'),
        ]);
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

    private function cellMapData(): Collection
    {
        return CellTower::query()
            ->whereNotNull('estimated_latitude')
            ->whereNotNull('estimated_longitude')
            ->whereBetween('estimated_latitude', self::LOMBOK_LATITUDE_RANGE)
            ->whereBetween('estimated_longitude', self::LOMBOK_LONGITUDE_RANGE)
            ->latest('last_seen_at')
            ->limit(500)
            ->get()
            ->map(fn (CellTower $cell): array => [
                'id' => $cell->id,
                'radio_type' => $cell->radio_type,
                'operator_name' => $cell->operator_name,
                'operator_label' => $cell->operator_label,
                'network_operator_code' => $cell->network_operator_code,
                'active_data_subscription_id' => $cell->active_data_subscription_id,
                'mcc' => $cell->mcc,
                'mnc' => $cell->mnc,
                'cell_id' => $cell->cell_id,
                'tac_or_lac' => $cell->tac_or_lac,
                'pci_or_psc' => $cell->pci_or_psc,
                'latitude' => (float) $cell->estimated_latitude,
                'longitude' => (float) $cell->estimated_longitude,
                'observation_count' => $cell->observation_count,
                'position_observation_count' => $cell->position_observation_count,
                'average_signal_dbm' => $cell->average_signal_dbm !== null ? (float) $cell->average_signal_dbm : null,
                'average_rsrp_dbm' => $cell->average_rsrp_dbm !== null ? (float) $cell->average_rsrp_dbm : null,
                'average_rsrq_db' => $cell->average_rsrq_db !== null ? (float) $cell->average_rsrq_db : null,
                'average_sinr_db' => $cell->average_sinr_db !== null ? (float) $cell->average_sinr_db : null,
                'first_seen_at' => $cell->first_seen_at?->format('Y-m-d H:i:s'),
                'last_seen_at' => $cell->last_seen_at?->format('Y-m-d H:i:s'),
            ])
            ->values();
    }
}
