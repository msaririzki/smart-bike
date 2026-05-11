@extends('layouts.admin', ['title' => $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda'])

@section('content')
    <h1>{{ $bike->exists ? 'Ubah Sepeda' : 'Tambah Sepeda' }}</h1>
    <div class="card">
        <form method="post" action="{{ $bike->exists ? route('admin.bikes.update', $bike) : route('admin.bikes.store') }}">
            @csrf
            @if($bike->exists) @method('put') @endif

            <label>Kode</label>
            <input name="code" value="{{ old('code', $bike->code) }}" required>
            @error('code') <p class="error">{{ $message }}</p> @enderror

            <label>Nama</label>
            <input name="name" value="{{ old('name', $bike->name) }}" required>

            <label>Status</label>
            <select name="status">
                @foreach(['available','reserved','in_use','idle','offline','maintenance'] as $status)
                    <option value="{{ $status }}" @selected(old('status', $bike->status) === $status)>{{ $adminStatusLabels[$status] ?? $status }}</option>
                @endforeach
            </select>

            <label>Lintang</label>
            <input name="current_latitude" value="{{ old('current_latitude', $bike->current_latitude) }}">

            <label>Bujur</label>
            <input name="current_longitude" value="{{ old('current_longitude', $bike->current_longitude) }}">

            <label>Persentase Baterai</label>
            <input name="battery_percent" type="number" min="0" max="100" value="{{ old('battery_percent', $bike->battery_percent) }}">

            <label>Perangkat Sepeda</label>
            <select name="assigned_device_user_id">
                <option value="">-</option>
                @foreach($devices as $device)
                    <option value="{{ $device->id }}" @selected((int) old('assigned_device_user_id', $bike->assigned_device_user_id) === $device->id)>{{ $device->name }} - {{ $device->email }}</option>
                @endforeach
            </select>

            <p><button class="button" type="submit">Simpan</button></p>
        </form>
    </div>
@endsection
