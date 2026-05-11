@extends('layouts.admin', ['title' => 'Peringatan'])

@section('content')
    <h1>Notifikasi / Peringatan</h1>

    <style>
        .alert-card { border-left: 4px solid #dc2626; background: #fef2f2; padding: 24px; border-radius: 8px; position: relative; overflow: hidden; }
        .alert-card.warning { border-left-color: #f59e0b; background: #fffbeb; }
        .alert-card h2 { margin: 8px 0 0; color: #991b1b; font-size: 28px; }
        .alert-card.warning h2 { color: #b45309; }
        .alert-card .muted { font-weight: 600; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; color: #b91c1c; display: block; }
        .alert-card.warning .muted { color: #d97706; }
    </style>
    <div class="grid" style="margin-bottom: 32px;">
        <div class="alert-card"><span class="muted">Sepeda Offline</span><h2>{{ $offlineBikes->count() }}</h2></div>
        <div class="alert-card"><span class="muted">Baterai Rendah</span><h2>{{ $lowBatteryBikes->count() }}</h2></div>
        <div class="alert-card warning"><span class="muted">Sepeda Diam Terlalu Lama</span><h2>{{ $idleRentals->count() }}</h2></div>
        <div class="alert-card warning"><span class="muted">Lokasi Belum Diperbarui</span><h2>{{ $staleGpsBikes->count() }}</h2></div>
        <div class="alert-card warning"><span class="muted">Sinyal Terputus</span><h2>{{ $staleHeartbeatBikes->count() }}</h2></div>
    </div>

    <h2>Sepeda Offline</h2>
    @include('admin.alerts.partials.bike-table', ['bikes' => $offlineBikes, 'empty' => 'Tidak ada sepeda offline.'])

    <h2>Baterai Rendah</h2>
    @include('admin.alerts.partials.bike-table', ['bikes' => $lowBatteryBikes, 'empty' => 'Tidak ada baterai rendah.'])

    <h2>Sepeda Diam Terlalu Lama</h2>
    <div class="table-responsive">
        <table style="margin-bottom: 24px;">
            <thead><tr><th>Rental</th><th>Pengguna</th><th>Sepeda</th><th>Status</th><th>Mulai Diam</th><th></th></tr></thead>
            <tbody>
                @forelse($idleRentals as $rental)
                    <tr>
                        <td><strong>#{{ $rental->id }}</strong></td>
                        <td>{{ $rental->user?->name ?? '-' }}</td>
                        <td>{{ $rental->bike?->code ?? '-' }}</td>
                        <td><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></td>
                        <td>{{ $rental->idle_started_at ?? '-' }}</td>
                        <td><a href="{{ route('admin.rentals.show', $rental) }}">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="muted">Tidak ada sepeda yang diam terlalu lama.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Lokasi Belum Diperbarui</h2>
    <p class="muted">Batas waktu: {{ $gpsTimeout }} detik sejak lokasi terakhir diterima.</p>
    @include('admin.alerts.partials.bike-table', ['bikes' => $staleGpsBikes, 'empty' => 'Semua lokasi sepeda masih terbaru.'])

    <h2>Perangkat Tidak Mengirim Sinyal</h2>
    <p class="muted">Batas waktu: {{ $offlineTimeout }} detik sejak sinyal perangkat terakhir diterima.</p>
    @include('admin.alerts.partials.bike-table', ['bikes' => $staleHeartbeatBikes, 'empty' => 'Semua perangkat sepeda masih mengirim sinyal.'])
@endsection
