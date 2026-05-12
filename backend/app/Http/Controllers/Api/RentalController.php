<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\Rental;
use App\Services\BikeQrRentalService;
use App\Services\PricingConfigService;
use App\Services\RentalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RentalController extends Controller
{
    public function __construct(
        private readonly RentalService $rentals,
        private readonly BikeQrRentalService $qrRentals,
    ) {}

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

        if ($rental) {
            $rental->setAttribute('current_speed_kmh', $rental->latestLocationPoint?->speed_kmh);
        }

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

    public function startFromQr(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
        ]);

        $rental = $this->qrRentals->startFromQr($request->user(), $data['token']);

        return response()->json(['data' => $rental], 201);
    }

    public function locationPoints(Request $request, Rental $rental): JsonResponse
    {
        abort_unless((int) $rental->user_id === (int) $request->user()->id, 404);

        return response()->json([
            'data' => $rental->locationPoints()
                ->where('is_valid_movement', true)
                ->orderBy('recorded_at')
                ->get(['id', 'latitude', 'longitude', 'speed_kmh', 'accuracy_meters', 'recorded_at']),
        ]);
    }

    public function idleSettings(PricingConfigService $pricing): JsonResponse
    {
        return response()->json([
            'data' => [
                'idle_warning_after_seconds' => $pricing->get('idle_warning_after_seconds'),
                'idle_billing_amount' => $pricing->get('idle_billing_amount'),
                'idle_billing_interval_seconds' => $pricing->get('idle_billing_interval_seconds'),
            ],
        ]);
    }
}
