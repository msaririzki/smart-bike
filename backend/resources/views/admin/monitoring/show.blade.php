@extends('layouts.admin', ['title' => 'Detail Monitoring Sepeda'])

@section('content')
    @php($statusBadge = $bike->is_online ? $bike->status : 'offline')

    <p><a href="{{ route('admin.monitoring.index') }}">Kembali ke Monitoring Sepeda</a></p>
    <h1>{{ $bike->code }} - {{ $bike->name }}</h1>

    <div class="grid">
        <div class="card">
            <span class="muted" style="display: block; margin-bottom: 8px;">Status Sepeda</span>
            <div style="display: flex; gap: 8px; margin-bottom: 16px;">
                <span class="badge {{ $statusBadge }}" style="font-size: 14px;">{{ $adminStatusLabels[$statusBadge] ?? $statusBadge }}</span>
                <span class="badge {{ $bike->is_online ? 'available' : 'maintenance' }}" style="font-size: 14px;">{{ $bike->is_online ? 'Online' : 'Offline' }}</span>
            </div>
            
            <p style="margin-bottom: 4px;"><strong>Baterai:</strong></p>
            <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 12px;">
                <span style="font-weight: 600;">{{ $bike->battery_percent !== null ? $bike->battery_percent.'%' : '-' }}</span>
                @if($bike->battery_percent !== null)
                    @php($batteryClass = $bike->battery_percent <= 20 ? 'background: #dc2626;' : 'background: #0f766e;')
                    <div style="width: 100px; height: 8px; border-radius: 4px; background: #e2e8f0; overflow: hidden;"><div style="height: 100%; width: {{ max(0, min(100, $bike->battery_percent)) }}%; {{ $batteryClass }}"></div></div>
                @endif
            </div>
            <p><strong>Perangkat Sepeda:</strong> <br> {{ $bike->assignedDevice?->email ?? '-' }}</p>
        </div>
        <div class="card">
            <span class="muted">Lokasi Terakhir</span>
            <h2>{{ $bike->current_latitude ?? '-' }}, {{ $bike->current_longitude ?? '-' }}</h2>
            <p><strong>Akurasi:</strong> {{ $bike->last_accuracy !== null ? $bike->last_accuracy.' m' : '-' }}</p>
            <p><strong>Lokasi Terakhir Diterima:</strong> {{ $bike->latestLocationPoint?->recorded_at ?? '-' }}</p>
            <p><strong>Akurasi Lokasi Terakhir:</strong> {{ $bike->latestLocationPoint?->accuracy_meters !== null ? $bike->latestLocationPoint->accuracy_meters.' m' : '-' }}</p>
            <p><strong>Terakhir Aktif:</strong> {{ $bike->last_seen_at ?? '-' }}</p>
        </div>
        <div class="card">
            <span class="muted">Sinyal Perangkat Terakhir</span>
            <h2>{{ $bike->latestHeartbeat?->last_seen_at ?? '-' }}</h2>
            <p><strong>Jenis Jaringan:</strong> {{ $bike->latestHeartbeat?->network_type ?? '-' }}</p>
            <p><strong>Catatan Sinyal:</strong> {{ $bike->latestHeartbeat?->signal_note ?? '-' }}</p>
        </div>
    </div>

    <h2>Rental Aktif</h2>
    <div class="card">
        @if($bike->activeRental)
            <p><strong>ID:</strong> <a href="{{ route('admin.rentals.show', $bike->activeRental) }}">#{{ $bike->activeRental->id }}</a></p>
            <p><strong>Pengguna:</strong> {{ $bike->activeRental->user?->name ?? '-' }}</p>
            <p><strong>Status:</strong> {{ $adminStatusLabels[$bike->activeRental->status] ?? $bike->activeRental->status }}</p>
            <p><strong>Mulai:</strong> {{ $bike->activeRental->started_at }}</p>
            <p><strong>Jarak:</strong> {{ number_format($bike->activeRental->total_distance_meters, 2) }} m</p>
            <p><strong>Total Biaya:</strong> Rp{{ number_format($bike->activeRental->total_cost, 0, ',', '.') }}</p>
        @else
            <p class="muted">Tidak ada rental aktif.</p>
        @endif
    </div>

    <h2>10 Sinyal Perangkat Terakhir</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Perangkat Sepeda</th>
                    <th>Jenis Jaringan</th>
                    <th>Catatan Sinyal</th>
                    <th>Terakhir Aktif</th>
                    <th>Data Diperbarui</th>
                </tr>
            </thead>
            <tbody>
                @forelse($heartbeats as $heartbeat)
                    <tr>
                        <td>{{ $heartbeat->deviceUser?->email ?? '-' }}</td>
                        <td>{{ $heartbeat->network_type ?? '-' }}</td>
                        <td>{{ $heartbeat->signal_note ?? '-' }}</td>
                        <td>{{ $heartbeat->last_seen_at }}</td>
                        <td>{{ $heartbeat->updated_at }}</td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="muted">Belum ada sinyal perangkat.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>10 Lokasi Rental Terakhir</h2>
    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Rental</th>
                    <th>Pengguna</th>
                    <th>Lintang</th>
                    <th>Bujur</th>
                    <th>Kecepatan</th>
                    <th>Jenis Jaringan</th>
                    <th>Waktu Diterima</th>
                </tr>
            </thead>
            <tbody>
                @forelse($locationPoints as $point)
                    <tr>
                        <td>
                            @if($point->rental)
                                <a href="{{ route('admin.rentals.show', $point->rental) }}"><strong>#{{ $point->rental->id }}</strong></a>
                            @else
                                -
                            @endif
                        </td>
                        <td>{{ $point->rental?->user?->name ?? '-' }}</td>
                        <td>{{ $point->latitude }}</td>
                        <td>{{ $point->longitude }}</td>
                        <td>{{ $point->speed_kmh !== null ? $point->speed_kmh.' km/h' : '-' }}</td>
                        <td>{{ $point->network_type ?? '-' }}</td>
                        <td>{{ $point->recorded_at }}</td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="muted">Belum ada lokasi rental.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
