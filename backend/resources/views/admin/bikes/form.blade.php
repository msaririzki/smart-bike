@extends('layouts.admin', ['title' => $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda'])

@section('content')
    <h1>{{ $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda' }}</h1>
    <div class="card" style="max-width: 600px;">
        <form method="post" action="{{ $bike->exists ? route('admin.bikes.update', $bike) : route('admin.bikes.store') }}">
            @csrf
            @if($bike->exists) @method('put') @endif

            <div style="display: flex; flex-direction: column; gap: 16px;">
                <div>
                    <label style="margin-top: 0;">Kode</label>
                    <input name="code" value="{{ old('code', $bike->code) }}" required>
                    @error('code') <p class="error" style="margin: 4px 0 0; font-size: 13px;">{{ $message }}</p> @enderror
                </div>

                <div>
                    <label style="margin-top: 0;">Nama</label>
                    <input name="name" value="{{ old('name', $bike->name) }}" required>
                </div>

                <div>
                    <label style="margin-top: 0;">Status</label>
                    <select name="status">
                        @foreach(['available','reserved','in_use','idle','offline','maintenance'] as $status)
                            <option value="{{ $status }}" @selected(old('status', $bike->status) === $status)>{{ $adminStatusLabels[$status] ?? $status }}</option>
                        @endforeach
                    </select>
                </div>

                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    <div>
                        <label style="margin-top: 0;">Lintang</label>
                        <input name="current_latitude" value="{{ old('current_latitude', $bike->current_latitude) }}">
                    </div>
                    <div>
                        <label style="margin-top: 0;">Bujur</label>
                        <input name="current_longitude" value="{{ old('current_longitude', $bike->current_longitude) }}">
                    </div>
                </div>

                <div>
                    <label style="margin-top: 0;">Persentase Baterai</label>
                    <input name="battery_percent" type="number" min="0" max="100" value="{{ old('battery_percent', $bike->battery_percent) }}">
                </div>

                <div>
                    <label style="margin-top: 0;">Perangkat Sepeda</label>
                    <select name="assigned_device_user_id">
                        <option value="">-</option>
                        @foreach($devices as $device)
                            <option value="{{ $device->id }}" @selected((int) old('assigned_device_user_id', $bike->assigned_device_user_id) === $device->id)>{{ $device->name }} - {{ $device->email }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div style="margin-top: 32px; padding-top: 24px; border-top: 1px solid #e2e8f0; display: flex; justify-content: flex-end;">
                <button class="button" type="submit" style="padding: 12px 24px; font-size: 15px; font-weight: 600;">Simpan Data Sepeda</button>
            </div>
        </form>
    </div>
@endsection
