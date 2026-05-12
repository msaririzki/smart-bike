@extends('layouts.admin', ['title' => 'Rental'])

@section('content')
    <h1>Rental</h1>

    <form class="card toolbar" method="get" action="{{ route('admin.rentals.index') }}">
        <label>
            Filter Status
            <select name="status">
                @foreach($filters as $option)
                    <option value="{{ $option }}" @selected($filter === $option)>
                        @if($option === 'all')
                            semua
                        @elseif($option === 'running')
                            rental berjalan
                        @else
                            {{ $adminStatusLabels[$option] ?? $option }}
                        @endif
                    </option>
                @endforeach
            </select>
        </label>
        <div>
            <div class="actions">
                <button class="button" type="submit">Filter</button>
                <a class="button secondary" href="{{ route('admin.rentals.index', ['status' => $filter]) }}">Muat Ulang</a>
                <a class="button secondary" href="{{ route('admin.rentals.index') }}">Hapus Filter</a>
            </div>
        </div>
    </form>

    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>No. Rental</th>
                    <th>Pengguna</th>
                    <th>Sepeda</th>
                    <th>Status</th>
                    <th>Durasi</th>
                    <th>Jarak</th>
                    <th>Biaya Sepeda Diam</th>
                    <th>Total Biaya</th>
                    <th>Lokasi Terakhir</th>
                    <th>Mulai</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                @forelse($rentals as $rental)
                    <tr>
                        <td><strong>#{{ $rental->id }}</strong></td>
                        <td>{{ $rental->user->name }}</td>
                        <td>{{ $rental->bike->code }}</td>
                        <td><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></td>
                        <td>{{ $rental->started_at?->diffForHumans($rental->ended_at ?? now(), true) ?? '-' }}</td>
                        <td>{{ number_format($rental->total_distance_meters, 2) }} m</td>
                        <td>Rp{{ number_format($rental->idle_cost, 0, ',', '.') }}</td>
                        <td>Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</td>
                        <td>
                            @if($rental->latestLocationPoint)
                                {{ $rental->latestLocationPoint->latitude }}, {{ $rental->latestLocationPoint->longitude }}
                            @else
                                -
                            @endif
                        </td>
                        <td>{{ $rental->started_at }}</td>
                        <td><a href="{{ route('admin.rentals.show', $rental) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="11" class="muted">Tidak ada rental yang cocok.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
    <div style="margin-top: 16px;">
        {{ $rentals->links() }}
    </div>
@endsection
