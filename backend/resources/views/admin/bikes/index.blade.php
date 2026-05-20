@extends('layouts.admin', ['title' => 'Sepeda'])

@section('content')
    <h2 style="margin: 0; color: var(--teal-800); margin-bottom: 24px;">Data Sepeda & Akun Perangkat</h2>

    <div style="display: flex; gap: 12px; margin-bottom: 24px; border-bottom: 1px solid #e2e8f0; padding-bottom: 12px;">
        <a href="{{ route('admin.bikes.index') }}" style="text-decoration: none; padding: 8px 16px; border-radius: 6px; font-weight: 600; color: {{ $tab === 'bikes' ? '#0f766e' : '#64748b' }}; background: {{ $tab === 'bikes' ? '#ccfbf1' : 'transparent' }};">Daftar Sepeda</a>
        <a href="{{ url('/admin/bikes?tab=devices') }}" style="text-decoration: none; padding: 8px 16px; border-radius: 6px; font-weight: 600; color: {{ $tab === 'devices' ? '#0f766e' : '#64748b' }}; background: {{ $tab === 'devices' ? '#ccfbf1' : 'transparent' }};">Akun Perangkat</a>
    </div>

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

    @if($tab === 'bikes')
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
    @elseif($tab === 'devices')
        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>Nama Akun</th>
                        <th>Email Device</th>
                        <th>Terhubung ke Sepeda</th>
                        <th>Dibuat Pada</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($devices as $device)
                        <tr>
                            <td><strong>{{ $device->name }}</strong></td>
                            <td>{{ $device->email }}</td>
                            <td>
                                @if($device->assignedBikes->isNotEmpty())
                                    @foreach($device->assignedBikes as $b)
                                        <span class="badge available">{{ $b->code }}</span>
                                    @endforeach
                                @else
                                    <span class="muted">-</span>
                                @endif
                            </td>
                            <td>{{ $device->created_at->format('d M Y H:i') }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="4" class="muted text-center">Belum ada akun perangkat.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
        <div style="margin-top: 16px;">
            {{ $devices->links() }}
        </div>
    @endif
@endsection
