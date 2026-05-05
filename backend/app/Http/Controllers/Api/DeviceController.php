<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Services\BikeStatusService;
use App\Services\LocationProcessingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function __construct(
        private readonly BikeStatusService $bikeStatus,
        private readonly LocationProcessingService $locations,
    ) {}

    public function currentAssignment(Request $request): JsonResponse
    {
        $bike = Bike::query()
            ->where('assigned_device_user_id', $request->user()->id)
            ->first();

        return response()->json(['data' => $bike]);
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
        ]);

        return response()->json($this->locations->process($request->user(), $data));
    }
}
