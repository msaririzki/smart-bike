@extends('layouts.admin', ['title' => 'Detail Pengguna'])

@section('content')
    <div style="display: flex; gap: 12px; align-items: center; margin-bottom: 24px;">
        <a href="{{ route('admin.users.index') }}" class="button secondary" style="padding: 8px;" title="Kembali">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"></path></svg>
        </a>
        <h1 style="margin: 0;">{{ $targetUser->name }}</h1>
    </div>

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
    <div class="table-responsive">
        <table>
            <thead>
                <tr><th>ID</th><th>Sepeda</th><th>Status</th><th>Mulai</th><th>Selesai</th><th>Jarak</th><th>Total Biaya</th><th></th></tr>
            </thead>
            <tbody>
                @forelse($targetUser->rentals as $rental)
                    <tr>
                        <td><strong>#{{ $rental->id }}</strong></td>
                        <td>{{ $rental->bike?->code ?? '-' }}</td>
                        <td><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></td>
                        <td>{{ $rental->started_at }}</td>
                        <td>{{ $rental->ended_at ?? '-' }}</td>
                        <td>{{ number_format($rental->total_distance_meters, 2) }} m</td>
                        <td>Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</td>
                        <td><a href="{{ route('admin.rentals.show', $rental) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr><td colspan="8" class="muted">Belum ada histori rental.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
@endsection
