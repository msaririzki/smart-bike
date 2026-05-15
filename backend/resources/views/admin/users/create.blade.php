@extends('layouts.admin', ['title' => 'Tambah User Baru'])

@section('content')
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h1 style="margin: 0;">Tambah User Baru</h1>
        <a href="{{ route('admin.users.index') }}" class="button secondary">Kembali</a>
    </div>

    <form method="post" action="{{ route('admin.users.store') }}" class="card" style="max-width: 600px;">
        @csrf
        
        <div style="margin-bottom: 16px;">
            <label for="name">Nama Lengkap <span style="color: #dc2626;">*</span></label>
            <input type="text" id="name" name="name" value="{{ old('name') }}" required autofocus placeholder="Contoh: Budi Santoso">
            @error('name')
                <div style="color: #dc2626; font-size: 13px; margin-top: 4px;">{{ $message }}</div>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="email">Email <span style="color: #dc2626;">*</span></label>
            <input type="email" id="email" name="email" value="{{ old('email') }}" required placeholder="Contoh: budi@example.com">
            @error('email')
                <div style="color: #dc2626; font-size: 13px; margin-top: 4px;">{{ $message }}</div>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="phone">Nomor Telepon <span style="color: #dc2626;">*</span></label>
            <input type="text" id="phone" name="phone" value="{{ old('phone') }}" required placeholder="Contoh: 08123456789">
            @error('phone')
                <div style="color: #dc2626; font-size: 13px; margin-top: 4px;">{{ $message }}</div>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="role">Hak Akses <span style="color: #dc2626;">*</span></label>
            <select id="role" name="role" required>
                <option value="user" @selected(old('role') == 'user')>Member (Aplikasi Mobile)</option>
                <option value="admin" @selected(old('role') == 'admin')>Admin</option>
                <option value="superadmin" @selected(old('role') == 'superadmin')>Super Admin</option>
            </select>
            @error('role')
                <div style="color: #dc2626; font-size: 13px; margin-top: 4px;">{{ $message }}</div>
            @enderror
        </div>

        <div style="margin-bottom: 24px;">
            <label for="password">Password <span style="color: #dc2626;">*</span></label>
            <input type="password" id="password" name="password" required placeholder="Minimal 8 karakter">
            @error('password')
                <div style="color: #dc2626; font-size: 13px; margin-top: 4px;">{{ $message }}</div>
            @enderror
        </div>

        <button type="submit" class="button" style="width: 100%; justify-content: center;">Simpan User Baru</button>
    </form>
@endsection
