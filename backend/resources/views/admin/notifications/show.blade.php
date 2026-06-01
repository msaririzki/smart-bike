@extends('layouts.admin')

@section('title', 'Detail Pengumuman')
@section('header', 'Pengumuman & Notifikasi')

@section('content')
<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; flex-wrap: wrap; gap: 16px;">
    <div style="display: flex; gap: 12px; align-items: center;">
        <a href="{{ route('admin.notifications.index') }}" class="button secondary" style="padding: 8px;">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"></path></svg>
        </a>
        <h2 style="margin: 0; color: var(--teal-800);">Detail Pengumuman</h2>
    </div>
    <div style="display: flex; gap: 8px;">
        <a href="{{ route('admin.notifications.edit', $notification) }}" class="button">
            <svg style="width: 16px; height: 16px; margin-right: 6px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
            Edit
        </a>
        <form action="{{ route('admin.notifications.destroy', $notification) }}" method="POST" onsubmit="return confirm('Yakin ingin menghapus pengumuman ini?');" style="margin: 0;">
            @csrf
            @method('DELETE')
            <button type="submit" class="button" style="background: #fee2e2; color: #dc2626; border-color: #fca5a5;">
                <svg style="width: 16px; height: 16px; margin-right: 6px;" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                Hapus
            </button>
        </form>
    </div>
</div>

<div class="card" style="padding: 32px;">
<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 24px; margin-bottom: 24px;">
    <div style="padding: 24px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px;">
        <div style="font-size: 12px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 16px;">Target Penerima</div>
        @if($notification->user_id)
            <div style="display: flex; align-items: center; gap: 12px;">
                <div style="width: 48px; height: 48px; border-radius: 50%; background: #ccfbf1; color: var(--teal-700); display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 18px;">
                    {{ substr($notification->user->name, 0, 1) }}
                </div>
                <div>
                    <div style="font-weight: 600; color: #1e293b; font-size: 16px;">{{ $notification->user->name }}</div>
                    <div style="font-size: 14px; color: #64748b; margin-top: 2px;">{{ $notification->user->email }}</div>
                </div>
            </div>
        @else
            <div style="display: inline-flex; align-items: center; gap: 8px; padding: 10px 16px; background: #ecfdf5; border: 1px solid #10b981; border-radius: 8px; color: #047857; font-weight: 600; font-size: 15px;">
                <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                Semua Pengguna
            </div>
        @endif
    </div>
    
    <div style="padding: 24px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px;">
        <div style="font-size: 12px; font-weight: 600; color: #64748b; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 12px;">Waktu Pengiriman</div>
        <div style="font-weight: 600; color: #1e293b; font-size: 18px;">{{ $notification->created_at->format('d M Y') }}</div>
        <div style="font-size: 15px; color: #64748b; margin-top: 4px;">{{ $notification->created_at->format('H:i T') }}</div>
    </div>
</div>

<hr style="border: 0; border-top: 1px solid #e2e8f0; margin: 32px 0;">

    <div style="margin-bottom: 24px;">
        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 16px; flex-wrap: wrap;">
            <h3 style="margin: 0; font-size: 24px; color: var(--teal-800); word-break: break-word;">{{ $notification->title }}</h3>
            @if($notification->type === 'sewa')
                <span class="badge" style="background: #e0e7ff; color: #4f46e5; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">Sewa</span>
            @elseif($notification->type === 'promosi')
                <span class="badge" style="background: #fce7f3; color: #be185d; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">Promosi</span>
            @else
                <span class="badge" style="background: #fef3c7; color: #d97706; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 600;">Pengumuman</span>
            @endif
        </div>
        <div style="padding: 24px; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; color: #334155; font-size: 15px; line-height: 1.6; white-space: pre-wrap;">{{ $notification->message }}</div>
    </div>
</div>
@endsection
