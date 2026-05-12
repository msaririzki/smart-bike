@extends('layouts.admin', ['title' => 'Monitoring Sepeda'])

@section('content')
    <h1>Monitoring Sepeda</h1>

    <form class="card toolbar" method="get" action="{{ route('admin.monitoring.index') }}">
        <label>
            Filter Status
            <select name="status">
                @foreach($filters as $option)
                    <option value="{{ $option }}" @selected($filter === $option)>
                        {{ $option === 'all' ? 'semua' : ($adminStatusLabels[$option] ?? $option) }}
                    </option>
                @endforeach
            </select>
        </label>
        <label>
            Cari Kode/Nama
            <input type="search" name="search" value="{{ $search }}" placeholder="Contoh: BK-001">
        </label>
        <div>
            <div class="actions">
                <button class="button" type="submit">Filter</button>
                <a class="button secondary" href="{{ route('admin.monitoring.index', request()->only(['status', 'search'])) }}">Muat Ulang</a>
                <a class="button secondary" href="{{ route('admin.monitoring.index') }}">Hapus Filter</a>
            </div>
        </div>
    </form>

    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Kode</th>
                    <th>Nama</th>
                    <th>Status</th>
                    <th>Status Online</th>
                    <th>Baterai</th>
                    <th>Lintang</th>
                    <th>Bujur</th>
                    <th>Terakhir Aktif</th>
                    <th>Jenis Jaringan</th>
                    <th>Perangkat Sepeda</th>
                    <th>Rental Aktif</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse($bikes as $bike)
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
                        <td>{{ $bike->current_latitude ?? '-' }}</td>
                        <td>{{ $bike->current_longitude ?? '-' }}</td>
                        <td>{{ $bike->last_seen_at ?? '-' }}</td>
                        <td>{{ $bike->latestHeartbeat?->network_type ?? $bike->latestLocationPoint?->network_type ?? '-' }}</td>
                        <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                        <td>
                            @if($bike->activeRental)
                                <a href="{{ route('admin.rentals.show', $bike->activeRental) }}">
                                    #{{ $bike->activeRental->id }} - {{ $bike->activeRental->user?->name ?? 'Pengguna' }}
                                </a>
                            @else
                                -
                            @endif
                        </td>
                        <td><a href="{{ route('admin.monitoring.show', $bike) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="12" class="muted">Tidak ada sepeda yang cocok.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{ $bikes->links() }}
@endsection
