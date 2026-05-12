@extends('layouts.admin', ['title' => 'Laporan'])

@section('content')
    <h1>Laporan</h1>

    <div class="grid" style="margin-bottom: 32px;">
        <div class="card stat-card"><span class="muted">Total Pendapatan</span><h2>Rp{{ number_format($totalRevenue, 0, ',', '.') }}</h2></div>
        <div class="card stat-card"><span class="muted">Total Jarak</span><h2>{{ number_format($totalDistanceMeters / 1000, 2) }} km</h2></div>
        <div class="card stat-card"><span class="muted">Jumlah Catatan Sepeda Diam</span><h2>{{ $idleEventCount }}</h2></div>
    </div>

    <h2>Total Rental per Hari</h2>
    <div class="table-responsive">
        <table style="margin-bottom: 24px;">
            <thead><tr><th>Tanggal</th><th>Total Rental</th><th>Pendapatan</th><th>Jarak</th></tr></thead>
            <tbody>
                @forelse($dailyRentals as $daily)
                    <tr>
                        <td><strong>{{ $daily->report_date }}</strong></td>
                        <td>{{ $daily->rental_count }}</td>
                        <td>Rp{{ number_format($daily->revenue, 0, ',', '.') }}</td>
                        <td>{{ number_format($daily->distance_meters / 1000, 2) }} km</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="muted">Belum ada data rental.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Sepeda Paling Sering Dipakai</h2>
    <div class="table-responsive">
        <table style="margin-bottom: 24px;">
            <thead><tr><th>Kode</th><th>Nama</th><th>Total Rental</th><th>Total Jarak</th><th></th></tr></thead>
            <tbody>
                @forelse($topBikes as $bike)
                    <tr>
                        <td><strong>{{ $bike->code }}</strong></td>
                        <td>{{ $bike->name }}</td>
                        <td>{{ $bike->rentals_count }}</td>
                        <td>{{ number_format(($bike->rentals_sum_total_distance_meters ?? 0) / 1000, 2) }} km</td>
                        <td><a href="{{ route('admin.monitoring.show', $bike) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="muted">Belum ada data sepeda.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Rental dengan Sepeda Sering Diam</h2>
    <div class="table-responsive">
        <table>
            <thead><tr><th>Rental</th><th>Pengguna</th><th>Sepeda</th><th>Catatan Sepeda Diam</th><th>Status</th><th></th></tr></thead>
            <tbody>
                @forelse($frequentIdleRentals as $rental)
                    <tr>
                        <td><strong>#{{ $rental->id }}</strong></td>
                        <td>{{ $rental->user?->name ?? '-' }}</td>
                        <td>{{ $rental->bike?->code ?? '-' }}</td>
                        <td>{{ $rental->idle_events_count }}</td>
                        <td><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></td>
                        <td><a href="{{ route('admin.rentals.show', $rental) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="muted">Belum ada rental dengan catatan sepeda diam.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
