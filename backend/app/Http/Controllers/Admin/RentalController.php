<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Rental;
use Illuminate\View\View;

class RentalController extends Controller
{
    public function index(): View
    {
        return view('admin.rentals.index', [
            'rentals' => Rental::query()->with('user', 'bike')->latest('started_at')->paginate(20),
        ]);
    }

    public function show(Rental $rental): View
    {
        return view('admin.rentals.show', [
            'rental' => $rental->load('user', 'bike', 'billingLogs', 'idleEvents', 'locationPoints'),
        ]);
    }
}
