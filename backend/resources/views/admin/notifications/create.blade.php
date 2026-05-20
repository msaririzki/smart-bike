@extends('layouts.admin')

@section('title', 'Kirim Pengumuman')
@section('header', 'Kirim Pengumuman Global')

@section('content')
<div class="card">
    <h2 style="margin-top: 0; color: var(--teal-800); margin-bottom: 24px;">Kirim Pengumuman ke Semua Pengguna</h2>

    @if(session('success'))
        <div class="alert-card" style="border-left-color: #10b981; background: #ecfdf5; margin-bottom: 24px;">
            <h3 style="color: #047857; margin: 0 0 8px;">Sukses!</h3>
            <p style="color: #065f46; margin: 0;">{{ session('success') }}</p>
        </div>
    @endif

    <form action="{{ route('admin.notifications.store') }}" method="POST">
        @csrf
        <div style="margin-bottom: 16px;">
            <label for="type">Tipe</label>
            <select id="type" name="type" required onchange="toggleTypeFields()">
                <option value="pengumuman" {{ old('type') === 'pengumuman' ? 'selected' : '' }}>Pengumuman</option>
                <option value="promosi" {{ old('type') === 'promosi' ? 'selected' : '' }}>Promosi</option>
            </select>
            @error('type')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="target">Target Pengiriman</label>
            <select id="target" name="target" required onchange="toggleUserSelect()">
                <option value="all" {{ old('target') === 'all' ? 'selected' : '' }}>Semua Pengguna</option>
                <option value="specific" {{ old('target') === 'specific' ? 'selected' : '' }}>Spesifik Pengguna</option>
            </select>
            @error('target')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div id="user_select_container" style="margin-bottom: 16px; display: {{ old('target') === 'specific' ? 'block' : 'none' }}; position: relative;">
            <label for="user_search">Pilih Pengguna</label>
            <input type="hidden" id="user_id" name="user_id" value="{{ old('user_id') }}">
            <input type="text" id="user_search" placeholder="Ketik nama atau email..." autocomplete="off" value="{{ old('user_id') ? $users->firstWhere('id', old('user_id'))?->name : '' }}" {{ old('target') === 'specific' ? 'required' : '' }}>
            <div id="user_list" style="display: none; position: absolute; width: 100%; max-height: 220px; overflow-y: auto; background: white; border: 1px solid #cbd5e1; border-radius: 6px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); z-index: 10; margin-top: 4px;">
                @foreach($users as $user)
                    <div class="user-option" data-id="{{ $user->id }}" style="padding: 10px 14px; cursor: pointer; border-bottom: 1px solid #f1f5f9; color: #334155; font-size: 14px; transition: background-color 0.2s;" onmouseover="this.style.backgroundColor='#f8fafc'" onmouseout="this.style.backgroundColor='white'">
                        <strong style="color: #0f172a;">{{ $user->name }}</strong><br>
                        <span style="color: #64748b; font-size: 12px;">{{ $user->email }}</span>
                    </div>
                @endforeach
                <div id="user_list_empty" style="display: none; padding: 16px; color: #64748b; font-size: 14px; text-align: center;">Tidak ada pengguna yang cocok</div>
            </div>
            @error('user_id')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 16px;">
            <label for="title">Judul Pengumuman</label>
            <input type="text" id="title" name="title" required placeholder="Contoh: Maintenance Server Rutin" 
                   value="{{ old('title') }}">
            @error('title')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 24px;">
            <label for="message">Isi Pesan</label>
            <textarea id="message" name="message" rows="10" required 
                      placeholder="Masukkan detail pengumuman di sini..." style="resize: vertical;">{{ old('message') }}</textarea>
            @error('message')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div id="time_fields_container" style="display: flex; gap: 16px; margin-bottom: 24px; flex-wrap: wrap;">
            <div id="start_time_group" style="flex: 1; min-width: 200px;">
                <label for="start_time">Waktu Mulai</label>
                <input type="datetime-local" id="start_time" name="start_time" value="{{ old('start_time') }}">
                @error('start_time')
                    <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
                @enderror
            </div>
            <div id="end_time_group" style="flex: 1; min-width: 200px;">
                <label id="end_time_label" for="end_time">Waktu Selesai</label>
                <input type="datetime-local" id="end_time" name="end_time" value="{{ old('end_time') }}">
                @error('end_time')
                    <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
                @enderror
            </div>
        </div>

        <div style="display: flex; gap: 12px; justify-content: flex-end;">
            <a href="{{ route('admin.notifications.index') }}" class="button secondary">Batal</a>
            <button type="submit" class="button">
                <svg style="width: 18px; height: 18px; margin-right: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"></path>
                </svg>
                Kirim Pengumuman
            </button>
        </div>
    </form>
</div>

<script>
function toggleUserSelect() {
    const target = document.getElementById('target').value;
    const container = document.getElementById('user_select_container');
    const userSearch = document.getElementById('user_search');
    
    if (target === 'specific') {
        container.style.display = 'block';
        userSearch.required = true;
    } else {
        container.style.display = 'none';
        userSearch.required = false;
        document.getElementById('user_id').value = '';
        userSearch.value = '';
    }
}

function toggleTypeFields() {
    const type = document.getElementById('type').value;
    const startTimeGroup = document.getElementById('start_time_group');
    const endTimeLabel = document.getElementById('end_time_label');
    
    if (type === 'promosi') {
        startTimeGroup.style.display = 'none';
        endTimeLabel.innerText = 'Waktu Promosi Berakhir';
    } else {
        startTimeGroup.style.display = 'block';
        endTimeLabel.innerText = 'Waktu Selesai';
    }
}

document.addEventListener('DOMContentLoaded', function() {
    toggleTypeFields();
    const searchInput = document.getElementById('user_search');
    const hiddenInput = document.getElementById('user_id');
    const userList = document.getElementById('user_list');
    const options = document.querySelectorAll('.user-option');
    const emptyState = document.getElementById('user_list_empty');

    searchInput.addEventListener('focus', () => {
        userList.style.display = 'block';
    });

    searchInput.addEventListener('input', function() {
        const filter = this.value.toLowerCase();
        let hasVisible = false;
        
        options.forEach(option => {
            const text = option.innerText.toLowerCase();
            if (text.includes(filter)) {
                option.style.display = 'block';
                hasVisible = true;
            } else {
                option.style.display = 'none';
            }
        });
        
        emptyState.style.display = hasVisible ? 'none' : 'block';
        hiddenInput.value = ''; // Reset actual value when typing so they are forced to click an option
    });

    options.forEach(option => {
        option.addEventListener('click', function() {
            hiddenInput.value = this.dataset.id;
            searchInput.value = this.querySelector('strong').innerText;
            userList.style.display = 'none';
        });
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', function(e) {
        if (!document.getElementById('user_select_container').contains(e.target)) {
            userList.style.display = 'none';
            
            // Validate if an option was truly selected
            if (!hiddenInput.value && searchInput.value) {
                searchInput.value = ''; // Clear invalid search text if not selected
            }
        }
    });
});
</script>
@endsection
