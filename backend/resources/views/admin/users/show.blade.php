@extends('layouts.admin', ['title' => 'Detail Pengguna'])

@section('content')
    <p><a href="{{ route('admin.users.index') }}">Kembali ke Pengguna</a></p>
    <h1>{{ $targetUser->name }}</h1>

    <div class="grid">
        <div class="card">
            <span class="muted">Data Pengguna</span>
            <h2>{{ $targetUser->email }}</h2>
            <p><strong>Telepon:</strong> {{ $targetUser->phone ?? '-' }}</p>
            <p><strong>Hak Akses:</strong> <span class="badge {{ $targetUser->role }}">{{ $adminRoleLabels[$targetUser->role] ?? $targetUser->role }}</span></p>
            <p><strong>Dibuat:</strong> {{ $targetUser->created_at }}</p>
        </div>
        <div class="card">
            <span class="muted">Rental</span>
            <h2>{{ $targetUser->rentals_count }}</h2>
            <p>Histori rental terakhir yang tersimpan untuk user ini.</p>
        </div>
        <div class="card">
            <span class="muted">Perangkat Sepeda Terhubung</span>
            <h2>{{ $targetUser->assignedBikes->count() }}</h2>
            @foreach($targetUser->assignedBikes as $bike)
                <p><a href="{{ route('admin.monitoring.show', $bike) }}">{{ $bike->code }} - {{ $bike->name }}</a></p>
            @endforeach
        </div>
    </div>

    @if(auth()->user()->role === 'superadmin')
        <div class="card">
            <h2>Ubah Hak Akses</h2>
            <form method="post" action="{{ route('admin.users.role.update', $targetUser) }}">
                @csrf
                @method('put')
                <label>Hak Akses</label>
                <select name="role">
                    @foreach(['user', 'admin', 'superadmin', 'device'] as $role)
                        <option value="{{ $role }}" @selected($targetUser->role === $role)>{{ $adminRoleLabels[$role] ?? $role }}</option>
                    @endforeach
                </select>
                <p><button class="button" type="submit">Simpan Hak Akses</button></p>
            </form>
        </div>
    @endif

    <h2>Histori Rental Pengguna</h2>
    <table>
        <thead>
            <tr><th>ID</th><th>Sepeda</th><th>Status</th><th>Mulai</th><th>Selesai</th><th>Jarak</th><th>Total Biaya</th><th></th></tr>
        </thead>
        <tbody>
            @forelse($targetUser->rentals as $rental)
                <tr>
                    <td>{{ $rental->id }}</td>
                    <td>{{ $rental->bike?->code ?? '-' }}</td>
                    <td><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></td>
                    <td>{{ $rental->started_at }}</td>
                    <td>{{ $rental->ended_at ?? '-' }}</td>
                    <td>{{ number_format($rental->total_distance_meters, 2) }} m</td>
                    <td>Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</td>
                    <td><a href="{{ route('admin.rentals.show', $rental) }}">Lihat Detail</a></td>
                </tr>
            @empty
                <tr><td colspan="8" class="muted">Belum ada histori rental.</td></tr>
            @endforelse
        </tbody>
    </table>
@endsection
