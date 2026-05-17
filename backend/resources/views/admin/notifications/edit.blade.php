@extends('layouts.admin')

@section('title', 'Edit Pengumuman')
@section('header', 'Edit Pengumuman')

@section('content')
<div class="card" style="max-width: 600px; margin: 0 auto;">
    <h2 style="margin-top: 0; color: var(--teal-800); margin-bottom: 24px;">Edit Pengumuman</h2>

    <form action="{{ route('admin.notifications.update', $notification) }}" method="POST">
        @csrf
        @method('PUT')
        
        <div style="margin-bottom: 16px;">
            <label for="target">Target Pengiriman</label>
            <select id="target" name="target" required onchange="toggleUserSelect()">
                <option value="all" {{ old('target', $notification->user_id ? 'specific' : 'all') === 'all' ? 'selected' : '' }}>Semua Pengguna (Broadcast)</option>
                <option value="specific" {{ old('target', $notification->user_id ? 'specific' : 'all') === 'specific' ? 'selected' : '' }}>Spesifik Pengguna</option>
            </select>
            @error('target')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div id="user_select_container" style="margin-bottom: 16px; display: {{ old('target', $notification->user_id ? 'specific' : 'all') === 'specific' ? 'block' : 'none' }};">
            <label for="user_id">Pilih Pengguna</label>
            <select id="user_id" name="user_id">
                <option value="">-- Pilih Pengguna --</option>
                @foreach($users as $user)
                    <option value="{{ $user->id }}" {{ old('user_id', $notification->user_id) == $user->id ? 'selected' : '' }}>
                        {{ $user->name }} ({{ $user->email }})
                    </option>
                @endforeach
            </select>
            @error('user_id')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="title">Judul Pengumuman</label>
            <input type="text" id="title" name="title" required placeholder="Contoh: Maintenance Server Rutin" 
                   value="{{ old('title', $notification->title) }}">
            @error('title')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 24px;">
            <label for="message">Isi Pesan</label>
            <textarea id="message" name="message" rows="5" required 
                      placeholder="Masukkan detail pengumuman di sini...">{{ old('message', $notification->message) }}</textarea>
            @error('message')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="display: flex; gap: 12px; justify-content: flex-end;">
            <a href="{{ route('admin.notifications.index') }}" class="button button-outline">Batal</a>
            <button type="submit" class="button">
                <svg style="width: 18px; height: 18px; margin-right: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                Simpan Perubahan
            </button>
        </div>
    </form>
</div>

<script>
function toggleUserSelect() {
    const target = document.getElementById('target').value;
    const container = document.getElementById('user_select_container');
    const userSelect = document.getElementById('user_id');
    
    if (target === 'specific') {
        container.style.display = 'block';
        userSelect.required = true;
    } else {
        container.style.display = 'none';
        userSelect.required = false;
        userSelect.value = '';
    }
}
</script>
@endsection
