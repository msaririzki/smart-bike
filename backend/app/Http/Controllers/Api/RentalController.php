<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\Rental;
use App\Services\RentalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RentalController extends Controller
{
    public function __construct(private readonly RentalService $rentals) {}

    public function start(Request $request): JsonResponse
    {
        $data = $request->validate([
            'bike_id' => ['required', 'exists:bikes,id'],
        ]);

        $rental = $this->rentals->start($request->user(), Bike::query()->findOrFail($data['bike_id']));

        return response()->json(['data' => $rental], 201);
    }

    public function active(Request $request): JsonResponse
    {
        $rental = Rental::query()
            ->with(['bike', 'latestLocationPoint'])
            ->where('user_id', $request->user()->id)
            ->whereIn('status', [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])
            ->latest('started_at')
            ->first();

        return response()->json(['data' => $rental]);
    }

    public function history(Request $request): JsonResponse
    {
        return response()->json([
            'data' => Rental::query()
                ->with('bike')
                ->where('user_id', $request->user()->id)
                ->latest('started_at')
                ->paginate(20),
        ]);
    }

    public function finish(Request $request, Rental $rental): JsonResponse
    {
        return response()->json([
            'data' => $this->rentals->finish($request->user(), $rental),
        ]);
    }

    public function continueIdle(Request $request, Rental $rental): JsonResponse
    {
        return response()->json([
            'data' => $this->rentals->continueIdle($request->user(), $rental),
        ]);
    }

    public function locationPoints(Request $request, Rental $rental): JsonResponse
    {
        return response()->json([
            'data' => $rental->locationPoints()
                ->where('is_valid_movement', true)
                ->orderBy('recorded_at')
                ->get(['id', 'latitude', 'longitude', 'speed_kmh', 'accuracy_meters', 'recorded_at']),
        ]);
    }
}
