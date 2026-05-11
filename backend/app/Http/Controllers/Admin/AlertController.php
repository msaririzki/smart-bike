<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\Rental;
use App\Services\PricingConfigService;
use Illuminate\View\View;

class AlertController extends Controller
{
    public function __construct(private readonly PricingConfigService $pricing) {}

    public function index(): View
    {
        $offlineTimeout = max(1, (int) $this->pricing->get('offline_timeout_seconds'));
        $gpsTimeout = max(1, (int) $this->pricing->get('gps_update_interval_seconds')) * 3;
        $staleHeartbeatAt = now()->subSeconds($offlineTimeout);
        $staleGpsAt = now()->subSeconds($gpsTimeout);

        return view('admin.alerts.index', [
            'offlineBikes' => Bike::query()
                ->with('assignedDevice')
                ->where(function ($query): void {
                    $query->where('is_online', false)
                        ->orWhere('status', 'offline');
                })
                ->orderBy('code')
                ->get(),
            'lowBatteryBikes' => Bike::query()
                ->with('assignedDevice')
                ->whereNotNull('battery_percent')
                ->where('battery_percent', '<=', 20)
                ->orderBy('battery_percent')
                ->get(),
            'idleRentals' => Rental::query()
                ->with('user', 'bike')
                ->whereIn('status', [Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])
                ->latest('idle_started_at')
                ->get(),
            'staleGpsBikes' => Bike::query()
                ->with('latestLocationPoint', 'assignedDevice')
                ->whereHas('locationPoints', function ($query) use ($staleGpsAt): void {
                    $query->where('recorded_at', '<', $staleGpsAt);
                })
                ->orderBy('code')
                ->get()
                ->filter(fn (Bike $bike) => $bike->latestLocationPoint?->recorded_at?->lt($staleGpsAt)),
            'staleHeartbeatBikes' => Bike::query()
                ->with('latestHeartbeat', 'assignedDevice')
                ->whereNotNull('assigned_device_user_id')
                ->orderBy('code')
                ->get()
                ->filter(fn (Bike $bike) => ! $bike->latestHeartbeat || $bike->latestHeartbeat->last_seen_at->lt($staleHeartbeatAt)),
            'offlineTimeout' => $offlineTimeout,
            'gpsTimeout' => $gpsTimeout,
        ]);
    }
}
