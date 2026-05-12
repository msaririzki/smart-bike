<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use Illuminate\Http\Request;
use Illuminate\View\View;

class MonitoringController extends Controller
{
    private const FILTERS = ['all', 'available', 'in_use', 'offline', 'maintenance'];

    public function index(Request $request): View
    {
        $filter = in_array($request->query('status'), self::FILTERS, true)
            ? $request->query('status')
            : 'all';
        $search = trim((string) $request->query('search', ''));

        $bikes = Bike::query()
            ->with([
                'assignedDevice:id,name,email',
                'latestHeartbeat',
                'latestLocationPoint',
                'activeRental.user:id,name,email',
            ])
            ->when($filter === 'offline', function ($query): void {
                $query->where(function ($query): void {
                    $query->where('status', 'offline')
                        ->orWhere('is_online', false);
                });
            })
            ->when($filter !== 'all' && $filter !== 'offline', function ($query) use ($filter): void {
                $query->where('status', $filter);
            })
            ->when($search !== '', function ($query) use ($search): void {
                $query->where(function ($query) use ($search): void {
                    $query->where('code', 'like', '%'.$search.'%')
                        ->orWhere('name', 'like', '%'.$search.'%');
                });
            })
            ->orderBy('code')
            ->paginate(20)
            ->withQueryString();

        return view('admin.monitoring.index', [
            'bikes' => $bikes,
            'filter' => $filter,
            'filters' => self::FILTERS,
            'search' => $search,
        ]);
    }

    public function show(Bike $bike): View
    {
        $bike->load([
            'assignedDevice:id,name,email',
            'latestHeartbeat',
            'latestLocationPoint',
            'activeRental.user:id,name,email',
        ]);

        return view('admin.monitoring.show', [
            'bike' => $bike,
            'heartbeats' => $bike->deviceHeartbeats()
                ->with('deviceUser:id,name,email')
                ->latest('last_seen_at')
                ->limit(10)
                ->get(),
            'locationPoints' => $bike->locationPoints()
                ->with('rental.user:id,name,email')
                ->latest('recorded_at')
                ->limit(10)
                ->get(),
        ]);
    }
}
