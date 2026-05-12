@extends('layouts.admin', ['title' => 'Sepeda'])

@section('content')
    <h1>Sepeda</h1>
    @if(session('device_credentials'))
        @php($credentials = session('device_credentials'))
        <div class="card" style="border-color: #0f766e; background: #f0fdfa;">
            <h2 style="margin-top: 0; color: #134e4a;">Kredensial Login Mobile Bike</h2>
            <p class="muted" style="margin-top: 0;">Gunakan akun ini untuk login di aplikasi <strong>mobile_bike</strong>. Password hanya ditampilkan setelah akun dibuat.</p>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px;">
                <div>
                    <span class="muted">Kode sepeda</span>
                    <p style="margin: 4px 0 0; font-weight: 800;">{{ $credentials['bike_code'] }}</p>
                </div>
                <div>
                    <span class="muted">Email device</span>
                    <p style="margin: 4px 0 0; font-weight: 800;">{{ $credentials['email'] }}</p>
                </div>
                <div>
                    <span class="muted">Password</span>
                    <p style="margin: 4px 0 0; font-weight: 800;">{{ $credentials['password'] }}</p>
                </div>
            </div>
        </div>
    @endif
    <p><a class="button" href="{{ route('admin.bikes.create') }}">Tambah Sepeda</a></p>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Kode</th>
                    <th>Nama</th>
                    <th>Status</th>
                    <th>Status Online</th>
                    <th>Baterai</th>
                    <th>Perangkat Sepeda</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @foreach($bikes as $bike)
                    @php($statusBadge = $bike->is_online ? $bike->status : 'offline')
                    <tr>
                        <td><strong>{{ $bike->code }}</strong></td>
                        <td>{{ $bike->name }}</td>
                        <td><span class="badge {{ $statusBadge }}">{{ $adminStatusLabels[$statusBadge] ?? $statusBadge }}</span></td>
                        <td><span class="badge {{ $bike->is_online ? 'available' : 'maintenance' }}">{{ $bike->is_online ? 'Online' : 'Offline' }}</span></td>
                        <td>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <span style="min-width: 32px;">{{ $bike->battery_percent !== null ? $bike->battery_percent.'%' : '-' }}</span>
                                @if($bike->battery_percent !== null)
                                    @php($batteryClass = $bike->battery_percent <= 20 ? 'background: #dc2626;' : 'background: #0f766e;')
                                    <div style="width: 40px; height: 6px; border-radius: 4px; background: #e2e8f0; overflow: hidden;"><div style="height: 100%; width: {{ max(0, min(100, $bike->battery_percent)) }}%; {{ $batteryClass }}"></div></div>
                                @endif
                            </div>
                        </td>
                        <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                        <td><a href="{{ route('admin.bikes.edit', $bike) }}" class="button" style="padding: 6px 12px; font-size: 13px;">Ubah</a></td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    <div style="margin-top: 16px;">
        {{ $bikes->links() }}
    </div>
@endsection
