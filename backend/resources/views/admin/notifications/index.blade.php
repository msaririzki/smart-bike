@extends('layouts.admin')

@section('title', 'Daftar Pengumuman')
@section('header', 'Pengumuman & Notifikasi')

@section('content')
<div class="card">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px;">
        <h2 style="margin: 0; color: var(--teal-800);">Daftar Pengumuman</h2>
        <a href="{{ route('admin.notifications.create') }}" class="button">
            <svg style="width: 18px; height: 18px; margin-right: 8px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Buat Baru
        </a>
    </div>

    @if(session('success'))
        <div class="alert-card" style="border-left-color: #10b981; background: #ecfdf5; margin-bottom: 24px;">
            <p style="color: #065f46; margin: 0;">{{ session('success') }}</p>
        </div>
    @endif

    <div class="table-responsive">
        <table>
            <thead>
                <tr>
                    <th>Waktu</th>
                    <th>Judul</th>
                    <th>Tipe</th>
                    <th>Target</th>
                    <th style="text-align: right;">Aksi</th>
                </tr>
            </thead>
            <tbody>
                @forelse($notifications as $notif)
                    <tr>
                        <td data-label="Waktu" style="color: #667085; font-size: 13px;">{{ $notif->created_at->format('d M Y, H:i') }}</td>
                        <td data-label="Judul">
                            <strong style="color: #111827; display: block; margin-bottom: 4px;">{{ $notif->title }}</strong>
                        </td>
                        <td data-label="Tipe">
                            @if($notif->type === 'sewa')
                                <span class="badge" style="background: #e0e7ff; color: #4f46e5;">Sewa</span>
                            @elseif($notif->type === 'promosi')
                                <span class="badge" style="background: #fce7f3; color: #be185d;">Promosi</span>
                            @else
                                <span class="badge" style="background: #fef3c7; color: #d97706;">Pengumuman</span>
                            @endif
                        </td>
                        <td data-label="Target">
                            @if($notif->user_id)
                                <span style="color: #374151; display:flex; align-items:center; gap: 4px;">
                                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
                                    {{ $notif->user->name }}
                                </span>
                            @else
                                <span style="color: var(--teal-700); font-weight: 600; display:flex; align-items:center; gap: 4px;">
                                    <svg width="14" height="14" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                                    Semua Pengguna
                                </span>
                            @endif
                        </td>
                        <td data-label="Aksi" style="text-align: right;">
                            <a href="{{ route('admin.notifications.show', $notif) }}" class="button secondary" style="padding: 6px 10px; font-size: 13px;">Lihat Detail</a>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="5" style="text-align: center; padding: 40px; color: #6b7280;">Belum ada pengumuman yang dikirim.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($notifications->hasPages())
        {{ $notifications->links() }}
    @endif
</div>
@endsection
