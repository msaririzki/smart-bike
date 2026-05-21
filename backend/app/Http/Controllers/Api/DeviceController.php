<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Services\BikeQrRentalService;
use App\Services\BikeStatusService;
use App\Services\LocationProcessingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function __construct(
        private readonly BikeStatusService $bikeStatus,
        private readonly LocationProcessingService $locations,
        private readonly BikeQrRentalService $qrService,
    ) {}

    public function currentAssignment(Request $request): JsonResponse
    {
        $bike = Bike::query()
            ->where('assigned_device_user_id', $request->user()->id)
            ->first();

        return response()->json(['data' => $bike]);
    }

    public function activeRentalSummary(Request $request): JsonResponse
    {
        $bike = Bike::query()
            ->with([
                'latestHeartbeat',
                'activeRental.user:id,name,email',
                'activeRental.latestLocationPoint',
            ])
            ->where('assigned_device_user_id', $request->user()->id)
            ->first();

        if (! $bike) {
            return response()->json([
                'data' => [
                    'bike' => null,
                    'rental' => null,
                ],
            ]);
        }

        $rental = $bike->activeRental;
        $latestPoint = $rental?->latestLocationPoint;

        return response()->json([
            'data' => [
                'bike' => [
                    'id' => $bike->id,
                    'code' => $bike->code,
                    'name' => $bike->name,
                    'status' => $bike->status,
                    'is_online' => $bike->is_online,
                    'battery_percent' => $bike->battery_percent,
                    'current_latitude' => $bike->current_latitude,
                    'current_longitude' => $bike->current_longitude,
                    'last_accuracy' => $bike->last_accuracy,
                    'last_seen_at' => $bike->last_seen_at?->toISOString(),
                    'network_type' => $bike->latestHeartbeat?->network_type,
                ],
                'rental' => $rental ? [
                    'id' => $rental->id,
                    'status' => $rental->status,
                    'started_at' => $rental->started_at?->toISOString(),
                    'total_distance_meters' => (float) $rental->total_distance_meters,
                    'distance_cost' => (int) $rental->distance_cost,
                    'idle_cost' => (int) $rental->idle_cost,
                    'total_cost' => (int) $rental->total_cost,
                    'current_speed_kmh' => $latestPoint?->speed_kmh !== null ? (float) $latestPoint->speed_kmh : null,
                    'user' => $rental->user ? [
                        'id' => $rental->user->id,
                        'name' => $rental->user->name,
                        'email' => $rental->user->email,
                    ] : null,
                    'latest_location_point' => $latestPoint ? [
                        'latitude' => (float) $latestPoint->latitude,
                        'longitude' => (float) $latestPoint->longitude,
                        'speed_kmh' => $latestPoint->speed_kmh !== null ? (float) $latestPoint->speed_kmh : null,
                        'accuracy_meters' => $latestPoint->accuracy_meters !== null ? (float) $latestPoint->accuracy_meters : null,
                        'network_type' => $latestPoint->network_type,
                        'recorded_at' => $latestPoint->recorded_at?->toISOString(),
                    ] : null,
                ] : null,
            ],
        ]);
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $data = $request->validate([
            'network_type' => ['nullable', 'string', 'max:50'],
            'signal_note' => ['nullable', 'string', 'max:255'],
            'battery_percent' => ['nullable', 'integer', 'min:0', 'max:100'],
        ]);

        return response()->json([
            'data' => $this->bikeStatus->recordHeartbeat($request->user(), $data),
        ]);
    }

    public function locationUpdate(Request $request): JsonResponse
    {
        $data = $request->validate([
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'speed_kmh' => ['nullable', 'numeric', 'min:0'],
            'accuracy_meters' => ['nullable', 'numeric', 'min:0'],
            'network_type' => ['nullable', 'string', 'max:50'],
            'recorded_at' => ['nullable', 'date'],
            'cell' => ['nullable', 'array'],
            'cell.radio_type' => ['nullable', 'string', 'in:LTE,NR,WCDMA,GSM,UNKNOWN'],
            'cell.operator_name' => ['nullable', 'string', 'max:100'],
            'cell.mcc' => ['nullable', 'string', 'max:10'],
            'cell.mnc' => ['nullable', 'string', 'max:10'],
            'cell.cell_id' => ['nullable', 'string', 'max:64'],
            'cell.tac_or_lac' => ['nullable', 'string', 'max:64'],
            'cell.pci_or_psc' => ['nullable', 'string', 'max:64'],
            'cell.signal_dbm' => ['nullable', 'integer'],
            'cell.rsrp_dbm' => ['nullable', 'integer'],
            'cell.rsrq_db' => ['nullable', 'numeric'],
            'cell.sinr_db' => ['nullable', 'numeric'],
            'cell.is_registered' => ['nullable', 'boolean'],
        ]);

        return response()->json($this->locations->process($request->user(), $data));
    }

    public function generateRentalQr(Request $request): JsonResponse
    {
        $session = $this->qrService->generateQr($request->user());
        $session->load('bike');

        return response()->json([
            'data' => [
                'token' => $session->token,
                'payload' => 'smartbike://rent?token=' . $session->token,
                'expires_at' => $session->expires_at->toISOString(),
                'bike' => [
                    'id' => $session->bike->id,
                    'code' => $session->bike->code,
                    'name' => $session->bike->name,
                ],
            ],
        ], 201);
    }
}
