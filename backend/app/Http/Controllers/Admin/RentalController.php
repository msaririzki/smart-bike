<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rental;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class RentalController extends Controller
{
    private const FILTERS = ['all', 'running', 'active', 'idle_warning', 'idle_billing', 'completed', 'cancelled'];

    public function index(Request $request): View
    {
        $filter = in_array($request->query('status'), self::FILTERS, true)
            ? $request->query('status')
            : 'all';
        $activeStatuses = [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING];

        return view('admin.rentals.index', [
            'rentals' => Rental::query()
                ->with('user', 'bike', 'latestLocationPoint')
                ->when($filter === 'running', function ($query) use ($activeStatuses): void {
                    $query->whereIn('status', $activeStatuses);
                })
                ->when($filter !== 'all' && $filter !== 'running', function ($query) use ($filter): void {
                    $query->where('status', $filter);
                })
                ->latest('started_at')
                ->paginate(20)
                ->withQueryString(),
            'filter' => $filter,
            'filters' => self::FILTERS,
        ]);
    }

    public function show(Rental $rental): View
    {
        return view('admin.rentals.show', [
            'rental' => $rental->load('user', 'bike.assignedDevice', 'latestLocationPoint', 'billingLogs', 'idleEvents', 'locationPoints'),
            'routePoints' => $this->routePointData($rental),
        ]);
    }

    public function routeMapData(Rental $rental): JsonResponse
    {
        return response()->json([
            'data' => $this->routePointData($rental),
            'updated_at' => now()->format('Y-m-d H:i:s'),
        ]);
    }

    private function routePointData(Rental $rental)
    {
        return $rental->locationPoints()
            ->orderBy('recorded_at')
            ->limit(500)
            ->get()
            ->map(fn ($point): array => [
                'latitude' => (float) $point->latitude,
                'longitude' => (float) $point->longitude,
                'speed_kmh' => $point->speed_kmh !== null ? (float) $point->speed_kmh : null,
                'accuracy_meters' => $point->accuracy_meters !== null ? (float) $point->accuracy_meters : null,
                'network_type' => $point->network_type,
                'is_valid_movement' => $point->is_valid_movement,
                'is_anomaly' => $point->is_anomaly,
                'ignored_reason' => $point->ignored_reason,
                'recorded_at' => $point->recorded_at?->format('Y-m-d H:i:s'),
            ])
            ->values();
    }
}
