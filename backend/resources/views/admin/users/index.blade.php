@extends('layouts.admin', ['title' => 'Manajemen Pengguna'])

@section('content')
    <h1>Manajemen Pengguna</h1>

    <form class="card toolbar" method="get" action="{{ route('admin.users.index') }}">
        <label>
            Hak Akses
            <select name="role">
                @foreach(['all', 'user', 'admin', 'superadmin', 'device'] as $option)
                    <option value="{{ $option }}" @selected($role === $option)>{{ $option === 'all' ? 'semua' : ($adminRoleLabels[$option] ?? $option) }}</option>
                @endforeach
            </select>
        </label>
        <label>
            Cari
            <input type="search" name="search" value="{{ $search }}" placeholder="Nama, email, telepon">
        </label>
        <div>
            <div class="actions">
                <button class="button" type="submit">Filter</button>
                <a class="button secondary" href="{{ route('admin.users.index', request()->only(['role', 'search'])) }}">Muat Ulang</a>
                <a class="button secondary" href="{{ route('admin.users.index') }}">Hapus Filter</a>
            </div>
        </div>
    </form>

    <table>
        <thead>
            <tr>
                <th>Nama</th>
                <th>Email</th>
                <th>Telepon</th>
                <th>Hak Akses</th>
                <th>Total Rental</th>
                <th>Dibuat</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @forelse($users as $user)
                <tr>
                    <td>{{ $user->name }}</td>
                    <td>{{ $user->email }}</td>
                    <td>{{ $user->phone ?? '-' }}</td>
                    <td><span class="badge {{ $user->role }}">{{ $adminRoleLabels[$user->role] ?? $user->role }}</span></td>
                    <td>{{ $user->rentals_count }}</td>
                    <td>{{ $user->created_at }}</td>
                    <td><a href="{{ route('admin.users.show', $user) }}">Lihat Detail</a></td>
                </tr>
            @empty
                <tr><td colspan="7" class="muted">Tidak ada user yang cocok.</td></tr>
            @endforelse
        </tbody>
    </table>

    {{ $users->links() }}
@endsection
