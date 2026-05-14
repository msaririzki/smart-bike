<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Illuminate\View\View;

class BikeController extends Controller
{
    private const DEFAULT_LATITUDE = -8.583000;
    private const DEFAULT_LONGITUDE = 116.116000;
    private const DEFAULT_BATTERY_PERCENT = 100;

    public function index(): View
    {
        return view('admin.bikes.index', [
            'bikes' => Bike::query()->with('assignedDevice')->orderBy('code')->paginate(20),
        ]);
    }

    public function create(): View
    {
        $nextNumber = $this->nextBikeNumber();

        return view('admin.bikes.form', [
            'bike' => new Bike([
                'code' => sprintf('BIKE-%03d', $nextNumber),
                'name' => sprintf('Sepeda Kampus %d', $nextNumber),
                'status' => 'available',
                'current_latitude' => self::DEFAULT_LATITUDE,
                'current_longitude' => self::DEFAULT_LONGITUDE,
                'battery_percent' => self::DEFAULT_BATTERY_PERCENT,
            ]),
            'devices' => $this->availableDeviceUsers()->get(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $credentials = null;
        DB::transaction(function () use ($request, &$credentials): void {
            [$data, $credentials] = $this->prepareBikeData($request);
            Bike::query()->create($data);
        });

        $redirect = redirect()->route('admin.bikes.index')->with('status', 'Sepeda dan akun perangkat siap dipakai.');

        return $credentials ? $redirect->with('device_credentials', $credentials) : $redirect;
    }

    public function edit(Bike $bike): View
    {
        return view('admin.bikes.form', [
            'bike' => $bike,
            'devices' => $this->availableDeviceUsers($bike)->get(),
        ]);
    }

    public function update(Request $request, Bike $bike): RedirectResponse
    {
        $credentials = null;
        DB::transaction(function () use ($request, $bike, &$credentials): void {
            [$data, $credentials] = $this->prepareBikeData($request, $bike);
            $bike->update($data);
        });

        $redirect = redirect()->route('admin.bikes.index')->with('status', 'Sepeda diperbarui.');

        return $credentials ? $redirect->with('device_credentials', $credentials) : $redirect;
    }

    /**
     * @return array{0: array<string, mixed>, 1: array<string, string>|null}
     */
    private function prepareBikeData(Request $request, ?Bike $bike = null): array
    {
        $data = $request->validate([
            'code' => ['required', 'string', 'max:50', 'unique:bikes,code,'.($bike?->id ?? 'NULL').',id'],
            'name' => ['required', 'string', 'max:255'],
            'status' => ['required', 'in:available,reserved,in_use,idle,offline,maintenance'],
            'current_latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'current_longitude' => ['nullable', 'numeric', 'between:-180,180'],
            'battery_percent' => ['nullable', 'integer', 'min:0', 'max:100'],
            'assigned_device_user_id' => ['nullable', Rule::exists('users', 'id')->where('role', 'device')],
            'create_device_account' => ['nullable', 'boolean'],
            'device_name' => ['nullable', 'string', 'max:255'],
            'device_email' => ['nullable', 'email', 'max:255', 'unique:users,email'],
            'device_password' => ['nullable', 'string', 'min:8', 'max:255'],
        ]);

        $createDevice = (bool) ($data['create_device_account'] ?? false);
        $credentials = null;

        if (! $bike?->exists) {
            $data['current_latitude'] = $data['current_latitude'] ?? self::DEFAULT_LATITUDE;
            $data['current_longitude'] = $data['current_longitude'] ?? self::DEFAULT_LONGITUDE;
            $data['battery_percent'] = $data['battery_percent'] ?? self::DEFAULT_BATTERY_PERCENT;
        }

        if ($createDevice) {
            $password = ($data['device_password'] ?? null) ?: 'Bike-'.Str::upper(Str::random(8));
            $device = User::query()->create([
                'name' => ($data['device_name'] ?? null) ?: $data['code'].' Device',
                'email' => ($data['device_email'] ?? null) ?: $this->nextDeviceEmail($data['code']),
                'password' => $password,
                'role' => 'device',
            ]);

            $data['assigned_device_user_id'] = $device->id;
            $credentials = [
                'bike_code' => $data['code'],
                'email' => $device->email,
                'password' => $password,
            ];
        } elseif (! empty($data['assigned_device_user_id'])) {
            $this->ensureDeviceCanBeAssigned((int) $data['assigned_device_user_id'], $bike);
        }

        unset(
            $data['create_device_account'],
            $data['device_name'],
            $data['device_email'],
            $data['device_password'],
        );

        return [$data, $credentials];
    }

    private function availableDeviceUsers(?Bike $bike = null): Builder
    {
        return User::query()
            ->where('role', 'device')
            ->where(function (Builder $query) use ($bike): void {
                $query->whereDoesntHave('assignedBikes');

                if ($bike?->assigned_device_user_id) {
                    $query->orWhere('id', $bike->assigned_device_user_id);
                }
            })
            ->orderBy('name');
    }

    private function ensureDeviceCanBeAssigned(int $deviceUserId, ?Bike $bike = null): void
    {
        $alreadyAssigned = Bike::query()
            ->where('assigned_device_user_id', $deviceUserId)
            ->when($bike, fn (Builder $query) => $query->whereKeyNot($bike->id))
            ->exists();

        if ($alreadyAssigned) {
            throw ValidationException::withMessages([
                'assigned_device_user_id' => 'Perangkat ini sudah terhubung ke sepeda lain.',
            ]);
        }
    }

    private function nextBikeNumber(): int
    {
        return ((int) Bike::query()->count()) + 1;
    }

    private function nextDeviceEmail(string $bikeCode): string
    {
        $base = 'device-'.Str::slug($bikeCode);
        $email = $base.'@smartbike.local';
        $counter = 2;

        while (User::query()->where('email', $email)->exists()) {
            $email = $base.'-'.$counter.'@smartbike.local';
            $counter++;
        }

        return $email;
    }
}
