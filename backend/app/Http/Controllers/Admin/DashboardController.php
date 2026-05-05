<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __invoke(): View
    {
        return view('admin.dashboard', [
            'totalBikes' => Bike::query()->count(),
            'activeRentals' => Rental::query()->whereIn('status', [Rental::STATUS_ACTIVE, Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING])->count(),
            'completedRentals' => Rental::query()->where('status', Rental::STATUS_COMPLETED)->count(),
            'offlineBikes' => Bike::query()->where('is_online', false)->count(),
            'totalRevenue' => Rental::query()->sum('total_cost'),
            'users' => User::query()->where('role', 'user')->count(),
        ]);
    }
}
