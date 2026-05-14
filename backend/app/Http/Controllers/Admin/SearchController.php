<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\User;
use App\Models\Rental;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('search');

        $bikes = collect();
        $users = collect();
        $rentals = collect();

        if ($search) {
            $bikes = Bike::query()
                ->where('code', 'like', "%{$search}%")
                ->orWhere('name', 'like', "%{$search}%")
                ->limit(10)
                ->get();

            $users = User::query()
                ->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%")
                ->limit(10)
                ->get();

            if (is_numeric($search)) {
                $rentals = Rental::query()
                    ->where('id', $search)
                    ->with(['user', 'bike'])
                    ->limit(5)
                    ->get();
            }
        }

        return view('admin.search.index', [
            'search' => $search,
            'bikes' => $bikes,
            'users' => $users,
            'rentals' => $rentals,
        ]);
    }
}
