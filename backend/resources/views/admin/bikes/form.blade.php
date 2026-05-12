@extends('layouts.admin', ['title' => $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda'])

@section('content')
    <h1>{{ $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda' }}</h1>
    <p class="muted" style="max-width: 760px;">
        Tambahkan data sepeda sekaligus akun perangkat untuk login di aplikasi mobile_bike. Jika akun perangkat dibuat otomatis, admin tidak perlu membuat user device secara terpisah.
    </p>
    <div class="card" style="max-width: 760px;">
        <form method="post" action="{{ $bike->exists ? route('admin.bikes.update', $bike) : route('admin.bikes.store') }}">
            @csrf
            @if($bike->exists) @method('put') @endif

            <div style="display: flex; flex-direction: column; gap: 16px;">
                <div>
                    <label style="margin-top: 0;">Kode</label>
                    <input name="code" value="{{ old('code', $bike->code) }}" required>
                    <p class="muted" style="margin: 4px 0 0; font-size: 13px;">Contoh: BIKE-001. Kode ini juga dipakai untuk membuat email perangkat otomatis.</p>
                    @error('code') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                </div>

                <div>
                    <label style="margin-top: 0;">Nama</label>
                    <input name="name" value="{{ old('name', $bike->name) }}" required>
                    @error('name') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                </div>

                <div>
                    <label style="margin-top: 0;">Status</label>
                    <select name="status">
                        @foreach(['available','reserved','in_use','idle','offline','maintenance'] as $status)
                            <option value="{{ $status }}" @selected(old('status', $bike->status) === $status)>{{ $adminStatusLabels[$status] ?? $status }}</option>
                        @endforeach
                    </select>
                    @error('status') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    <div>
                        <label style="margin-top: 0;">Lintang</label>
                        <input name="current_latitude" value="{{ old('current_latitude', $bike->current_latitude) }}">
                        @error('current_latitude') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                    </div>
                    <div>
                        <label style="margin-top: 0;">Bujur</label>
                        <input name="current_longitude" value="{{ old('current_longitude', $bike->current_longitude) }}">
                        @error('current_longitude') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                    </div>
                </div>

                <div>
                    <label style="margin-top: 0;">Persentase Baterai</label>
                    <input name="battery_percent" type="number" min="0" max="100" value="{{ old('battery_percent', $bike->battery_percent) }}">
                    @error('battery_percent') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                </div>

                <div class="card" style="margin: 0; background: #f8fafc; border-style: dashed;">
                    <h2 style="margin: 0 0 12px; font-size: 18px;">Akun Perangkat Mobile Bike</h2>
                    <p class="muted" style="margin-top: 0;">
                        Aplikasi mobile_bike login memakai akun role <strong>device</strong>. Pilih akun yang belum dipakai, atau buat otomatis dari form ini.
                    </p>

                    <label style="display: flex; align-items: center; gap: 8px; margin-top: 0;">
                        <input type="checkbox" name="create_device_account" value="1" @checked(old('create_device_account', $bike->exists ? false : true))>
                        Buat akun device baru otomatis
                    </label>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 12px;">
                        <div>
                            <label>Nama device baru</label>
                            <input name="device_name" value="{{ old('device_name') }}" placeholder="{{ $bike->code ?: 'BIKE-001' }} Device">
                            @error('device_name') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                        </div>
                        <div>
                            <label>Email device baru</label>
                            <input name="device_email" type="email" value="{{ old('device_email') }}" placeholder="Kosongkan untuk otomatis">
                            @error('device_email') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                        </div>
                    </div>

                    <div style="margin-top: 12px;">
                        <label>Password device baru</label>
                        <input name="device_password" value="{{ old('device_password') }}" placeholder="Kosongkan untuk password otomatis">
                        <p class="muted" style="margin: 4px 0 0; font-size: 13px;">Jika dikosongkan, sistem membuat password aman dan menampilkannya setelah data disimpan.</p>
                        @error('device_password') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                    </div>

                    <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #e2e8f0;">
                        <label style="margin-top: 0;">Atau pakai akun device yang sudah ada</label>
                        <select name="assigned_device_user_id">
                            <option value="">Tidak memilih akun lama</option>
                            @foreach($devices as $device)
                                <option value="{{ $device->id }}" @selected((int) old('assigned_device_user_id', $bike->assigned_device_user_id) === $device->id)>{{ $device->name }} - {{ $device->email }}</option>
                            @endforeach
                        </select>
                        @error('assigned_device_user_id') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                    </div>
                </div>
            </div>

            <div style="margin-top: 32px; padding-top: 24px; border-top: 1px solid #e2e8f0; display: flex; justify-content: flex-end;">
                <button class="button" type="submit" style="padding: 12px 24px; font-size: 15px; font-weight: 600;">Simpan Data Sepeda</button>
            </div>
        </form>
    </div>
@endsection
