@extends('layouts.admin', ['title' => 'Peringatan'])

@section('content')
    <h1>Notifikasi / Peringatan</h1>

    <div class="grid">
        <div class="card"><span class="muted">Sepeda Offline</span><h2>{{ $offlineBikes->count() }}</h2></div>
        <div class="card"><span class="muted">Baterai Rendah</span><h2>{{ $lowBatteryBikes->count() }}</h2></div>
        <div class="card"><span class="muted">Sepeda Diam Terlalu Lama</span><h2>{{ $idleRentals->count() }}</h2></div>
        <div class="card"><span class="muted">Lokasi Belum Diperbarui</span><h2>{{ $staleGpsBikes->count() }}</h2></div>
        <div class="card"><span class="muted">Perangkat Tidak Mengirim Sinyal</span><h2>{{ $staleHeartbeatBikes->count() }}</h2></div>
    </div>

    <h2>Sepeda Offline</h2>
    @include('admin.alerts.partials.bike-table', ['bikes' => $offlineBikes, 'empty' => 'Tidak ada sepeda offline.'])

    <h2>Baterai Rendah</h2>
    @include('admin.alerts.partials.bike-table', ['bikes' => $lowBatteryBikes, 'empty' => 'Tidak ada baterai rendah.'])

    <h2>Sepeda Diam Terlalu Lama</h2>
    <table>
        <thead><tr><th>Rental</th><th>Pengguna</th><th>Sepeda</th><th>Status</th><th>Mulai Diam</th><th></th></tr></thead>
        <tbody>
            @forelse($idleRentals as $rental)
                <tr>
                    <td>#{{ $rental->id }}</td>
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

    <h2>Lokasi Belum Diperbarui</h2>
    <p class="muted">Batas waktu: {{ $gpsTimeout }} detik sejak lokasi terakhir diterima.</p>
    @include('admin.alerts.partials.bike-table', ['bikes' => $staleGpsBikes, 'empty' => 'Semua lokasi sepeda masih terbaru.'])

    <h2>Perangkat Tidak Mengirim Sinyal</h2>
    <p class="muted">Batas waktu: {{ $offlineTimeout }} detik sejak sinyal perangkat terakhir diterima.</p>
    @include('admin.alerts.partials.bike-table', ['bikes' => $staleHeartbeatBikes, 'empty' => 'Semua perangkat sepeda masih mengirim sinyal.'])
@endsection
