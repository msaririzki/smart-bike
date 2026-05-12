<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class BikeController extends Controller
{
    public function index(): View
    {
        return view('admin.bikes.index', [
            'bikes' => Bike::query()->with('assignedDevice')->orderBy('code')->paginate(20),
        ]);
    }

    public function create(): View
    {
        return view('admin.bikes.form', [
            'bike' => new Bike(['status' => 'available']),
            'devices' => User::query()->where('role', 'device')->orderBy('name')->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        Bike::query()->create($this->validated($request));

        return redirect()->route('admin.bikes.index')->with('status', 'Sepeda dibuat.');
    }

    public function edit(Bike $bike): View
    {
        return view('admin.bikes.form', [
            'bike' => $bike,
            'devices' => User::query()->where('role', 'device')->orderBy('name')->get(),
        ]);
    }

    public function update(Request $request, Bike $bike): RedirectResponse
    {
        $bike->update($this->validated($request, $bike->id));

        return redirect()->route('admin.bikes.index')->with('status', 'Sepeda diperbarui.');
    }

    private function validated(Request $request, ?int $bikeId = null): array
    {
        return $request->validate([
            'code' => ['required', 'string', 'max:50', 'unique:bikes,code,'.($bikeId ?? 'NULL').',id'],
            'name' => ['required', 'string', 'max:255'],
            'status' => ['required', 'in:available,reserved,in_use,idle,offline,maintenance'],
            'current_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'current_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'battery_percent' => ['nullable', 'integer', 'min:0', 'max:100'],
            'assigned_device_user_id' => ['nullable', 'exists:users,id'],
        ]);
    }
}
