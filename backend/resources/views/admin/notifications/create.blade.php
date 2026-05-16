@extends('layouts.admin')

@section('title', 'Kirim Pengumuman')
@section('header', 'Kirim Pengumuman Global')

@section('content')
<div class="card" style="max-width: 600px; margin: 0 auto;">
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
            <label for="title">Judul Pengumuman</label>
            <input type="text" id="title" name="title" required placeholder="Contoh: Maintenance Server Rutin" 
                   value="{{ old('title') }}">
            @error('title')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <div style="margin-bottom: 24px;">
            <label for="message">Isi Pesan</label>
            <textarea id="message" name="message" rows="5" required 
                      placeholder="Masukkan detail pengumuman di sini...">{{ old('message') }}</textarea>
            @error('message')
                <span style="color: #dc2626; font-size: 12px; margin-top: 4px; display: block;">{{ $message }}</span>
            @enderror
        </div>

        <button type="submit" class="button" style="width: 100%;">
            <svg style="width: 18px; height: 18px; margin-right: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z"></path>
            </svg>
            Kirim Broadcast
        </button>
    </form>
</div>
@endsection
