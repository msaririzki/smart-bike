@extends('layouts.admin', ['title' => 'Manajemen Pengguna'])

@section('content')
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h1 style="margin: 0;">Manajemen Pengguna</h1>
        <button type="button" class="button" onclick="document.getElementById('create-user-modal').style.display = 'flex'" style="background: #0d9488;">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            Tambah Pengguna
        </button>
    </div>

    <form class="card toolbar" method="get" action="{{ route('admin.users.index') }}">
        <label>
            Hak Akses
            <select name="role">
                @foreach(['all', 'user', 'admin', 'superadmin'] as $option)
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

    <!-- Modal Tambah User -->
    <div id="create-user-modal" class="modal-overlay" style="{{ $errors->any() ? 'display: flex;' : '' }}">
        <div class="card" style="max-width: 500px; width: 90%; max-height: 90vh; overflow-y: auto;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h2 style="margin: 0; color: #0f766e;">Tambah Pengguna Baru</h2>
                <button type="button" onclick="document.getElementById('create-user-modal').style.display = 'none'" style="background: none; border: none; cursor: pointer; color: #64748b;">
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </button>
            </div>
            
            <form method="post" action="{{ route('admin.users.store') }}">
                @csrf
                <div style="margin-bottom: 16px;">
                    <label for="name">Nama Lengkap <span style="color: #dc2626;">*</span></label>
                    <input type="text" id="name" name="name" value="{{ old('name') }}" required placeholder="Contoh: Budi Santoso">
                    @error('name') <p class="error" style="font-size: 12px; margin-top: 4px;">{{ $message }}</p> @enderror
                </div>

                <div style="margin-bottom: 16px;">
                    <label for="email">Email <span style="color: #dc2626;">*</span></label>
                    <input type="email" id="email" name="email" value="{{ old('email') }}" required placeholder="budi@example.com">
                    @error('email') <p class="error" style="font-size: 12px; margin-top: 4px;">{{ $message }}</p> @enderror
                </div>

                <div style="margin-bottom: 16px;">
                    <label for="phone">Nomor Telepon <span style="color: #dc2626;">*</span></label>
                    <input type="text" id="phone" name="phone" value="{{ old('phone') }}" required placeholder="08123456789">
                    @error('phone') <p class="error" style="font-size: 12px; margin-top: 4px;">{{ $message }}</p> @enderror
                </div>

                <div style="margin-bottom: 16px;">
                    <label for="create_role">Hak Akses <span style="color: #dc2626;">*</span></label>
                    <select id="create_role" name="role" required>
                        <option value="user" @selected(old('role') == 'user')>Member (Aplikasi Mobile)</option>
                        <option value="admin" @selected(old('role') == 'admin')>Admin</option>
                        <option value="superadmin" @selected(old('role') == 'superadmin')>Super Admin</option>
                    </select>
                    @error('role') <p class="error" style="font-size: 12px; margin-top: 4px;">{{ $message }}</p> @enderror
                </div>

                <div style="margin-bottom: 24px;">
                    <label for="password">Password <span style="color: #dc2626;">*</span></label>
                    <input type="password" id="password" name="password" required placeholder="Minimal 8 karakter">
                    @error('password') <p class="error" style="font-size: 12px; margin-top: 4px;">{{ $message }}</p> @enderror
                </div>

                <div style="display: flex; gap: 12px; margin-top: 24px;">
                    <button type="button" class="button secondary" onclick="document.getElementById('create-user-modal').style.display = 'none'" style="flex: 1;">Batal</button>
                    <button type="submit" class="button" style="flex: 2; background: #0d9488;">Simpan User</button>
                </div>
            </form>
        </div>
    </div>

    <div class="table-responsive">
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
                        <td><strong>{{ $user->name }}</strong></td>
                        <td>{{ $user->email }}</td>
                        <td>{{ $user->phone ?? '-' }}</td>
                        <td><span class="badge {{ $user->role }}">{{ $adminRoleLabels[$user->role] ?? $user->role }}</span></td>
                        <td>{{ $user->rentals_count }}</td>
                        <td>{{ $user->created_at }}</td>
                        <td><a href="{{ route('admin.users.show', $user) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                    </tr>
                @empty
                    <tr><td colspan="7" class="muted">Tidak ada user yang cocok.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <div style="margin-top: 16px;">
        {{ $users->links() }}
    </div>
@endsection
