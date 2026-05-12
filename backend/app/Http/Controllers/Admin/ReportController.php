<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\Rental;
use App\Models\RentalIdleEvent;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class ReportController extends Controller
{
    public function index(): View
    {
        return view('admin.reports.index', [
            'dailyRentals' => Rental::query()
                ->selectRaw('DATE(started_at) as report_date, COUNT(*) as rental_count, SUM(total_cost) as revenue, SUM(total_distance_meters) as distance_meters')
                ->where('started_at', '>=', now()->subDays(14)->startOfDay())
                ->groupBy(DB::raw('DATE(started_at)'))
                ->orderByDesc('report_date')
                ->get(),
            'topBikes' => Bike::query()
                ->withCount('rentals')
                ->withSum('rentals', 'total_distance_meters')
                ->orderByDesc('rentals_count')
                ->limit(10)
                ->get(),
            'totalRevenue' => Rental::query()->sum('total_cost'),
            'totalDistanceMeters' => Rental::query()->sum('total_distance_meters'),
            'idleEventCount' => RentalIdleEvent::query()->count(),
            'frequentIdleRentals' => Rental::query()
                ->with('user', 'bike')
                ->withCount('idleEvents')
                ->has('idleEvents')
                ->orderByDesc('idle_events_count')
                ->limit(10)
                ->get(),
        ]);
    }
}
