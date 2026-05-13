@extends('layouts.admin', ['title' => 'Detail Monitoring Sepeda'])

@section('content')
    @php($statusBadge = $bike->is_online ? $bike->status : 'offline')
    @php($isAvailable = $bike->status === 'available' && $bike->is_online)

    <div style="margin-bottom: 1.5rem; display: flex; align-items: center; justify-content: space-between;">
        <a href="{{ route('admin.monitoring.index') }}" style="color: #0f766e; text-decoration: none; font-weight: 600; display: flex; align-items: center; gap: 0.5rem;">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M19 12H5M12 19l-7-7 7-7"/></svg>
            Kembali ke Monitoring Sepeda
        </a>
    </div>

    <!-- Main Hero Card -->
    <div style="background: white; border-radius: 1rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); margin-bottom: 2.5rem; overflow: hidden; border: 1px solid #e2e8f0;">
        <!-- Header -->
        <div style="background: #0f766e; color: white; padding: 1.5rem 2rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;">
            <div>
                <h1 style="margin: 0; font-size: 1.75rem; font-weight: 700; line-height: 1.2;">{{ $bike->code }}</h1>
                <p style="margin: 0.25rem 0 0 0; font-size: 1rem; opacity: 0.9;">{{ $bike->name }}</p>
            </div>
            <span style="background: rgba(255, 255, 255, 0.2); border: 1px solid rgba(255, 255, 255, 0.3); padding: 0.5rem 1rem; border-radius: 9999px; font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">
                {{ strtoupper($adminStatusLabels[$statusBadge] ?? $statusBadge) }}
            </span>
        </div>

        <!-- Content -->
        <div style="padding: 2rem;">
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 2rem;">
                <!-- Baterai -->
                <div style="background: #f8fafc; padding: 1.5rem; border-radius: 0.75rem; border: 1px solid #f1f5f9;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem; color: #64748b;">
                        <svg width="18" height="18" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><rect x="2" y="7" width="16" height="10" rx="2" ry="2"/><line x1="22" y1="11" x2="22" y2="13"/></svg>
                        <span style="font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">Baterai</span>
                    </div>
                    <div style="font-size: 1.5rem; font-weight: 700; color: #0f172a; margin-bottom: 0.75rem;">
                        {{ $bike->battery_percent !== null ? $bike->battery_percent.'%' : '-' }}
                    </div>
                    @if($bike->battery_percent !== null)
                        @php($batteryClass = $bike->battery_percent <= 20 ? 'background: #ef4444;' : 'background: #14b8a6;')
                        <div style="width: 100%; height: 8px; border-radius: 9999px; background: #e2e8f0; overflow: hidden;">
                            <div style="height: 100%; width: {{ max(0, min(100, $bike->battery_percent)) }}%; {{ $batteryClass }}"></div>
                        </div>
                    @endif
                </div>

                <!-- Online Status -->
                <div style="background: #f8fafc; padding: 1.5rem; border-radius: 0.75rem; border: 1px solid #f1f5f9;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem; color: #64748b;">
                        <svg width="18" height="18" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
                        <span style="font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">Status Sistem</span>
                    </div>
                    <div style="display: flex; align-items: center; gap: 0.75rem;">
                        <div style="width: 12px; height: 12px; border-radius: 50%; background: {{ $bike->is_online ? '#10b981' : '#ef4444' }};"></div>
                        <span style="font-size: 1.25rem; font-weight: 600; color: #0f172a;">{{ $bike->is_online ? 'Online' : 'Offline' }}</span>
                    </div>
                </div>

                <!-- Jaringan -->
                <div style="background: #f8fafc; padding: 1.5rem; border-radius: 0.75rem; border: 1px solid #f1f5f9;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem; color: #64748b;">
                        <svg width="18" height="18" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/></svg>
                        <span style="font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">Jaringan</span>
                    </div>
                    <div style="font-size: 1.25rem; font-weight: 600; color: #0f172a;">
                        {{ $bike->latestHeartbeat?->network_type ?? '-' }}
                    </div>
                </div>

                <!-- Terakhir Aktif -->
                <div style="background: #f8fafc; padding: 1.5rem; border-radius: 0.75rem; border: 1px solid #f1f5f9;">
                    <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.75rem; color: #64748b;">
                        <svg width="18" height="18" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M2 12h4l2-9 4 18 2-9h4"/></svg>
                        <span style="font-size: 0.875rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;">Aktivitas</span>
                    </div>
                    <div style="font-size: 1.125rem; font-weight: 600; color: #0f172a;">
                        {{ $bike->last_seen_at ? \Carbon\Carbon::parse($bike->last_seen_at)->diffForHumans() : '-' }}
                    </div>
                </div>
            </div>
        </div>
        
        <div style="background: #f1f5f9; padding: 1rem 2rem; border-top: 1px solid #e2e8f0; font-size: 0.875rem; color: #475569;">
            <strong>Perangkat GPS yang Ditugaskan:</strong> {{ $bike->assignedDevice?->email ?? 'Belum terhubung' }}
        </div>
    </div>

    <!-- Additional Information Section -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; margin-bottom: 2.5rem;">
        
        <!-- Active Rental -->
        <div style="background: white; border-radius: 1rem; padding: 1.5rem; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
            <h2 style="margin: 0 0 1.25rem 0; font-size: 1.25rem; color: #0f172a; display: flex; align-items: center; gap: 0.5rem;">
                <svg width="20" height="20" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                Rental Aktif
            </h2>
            
            @if($bike->activeRental)
                <div style="display: flex; flex-direction: column; gap: 1rem;">
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                        <span style="color: #64748b; font-size: 0.875rem;">ID Rental</span>
                        <a href="{{ route('admin.rentals.show', $bike->activeRental) }}" style="font-weight: 600; color: #0f766e; text-decoration: none;">#{{ $bike->activeRental->id }}</a>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                        <span style="color: #64748b; font-size: 0.875rem;">Pengguna</span>
                        <span style="font-weight: 600; color: #0f172a;">{{ $bike->activeRental->user?->name ?? '-' }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                        <span style="color: #64748b; font-size: 0.875rem;">Mulai</span>
                        <span style="font-weight: 600; color: #0f172a;">{{ $bike->activeRental->started_at }}</span>
                    </div>
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="color: #64748b; font-size: 0.875rem;">Jarak / Biaya</span>
                        <span style="font-weight: 600; color: #0f172a;">{{ number_format($bike->activeRental->total_distance_meters, 2) }} m / Rp{{ number_format($bike->activeRental->total_cost, 0, ',', '.') }}</span>
                    </div>
                </div>
            @else
                <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 2rem 0; color: #94a3b8; text-align: center;">
                    <svg width="48" height="48" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24" style="margin-bottom: 1rem; opacity: 0.5;"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                    <span>Tidak ada rental aktif saat ini.</span>
                </div>
            @endif
        </div>

        <!-- Location Info -->
        <div style="background: white; border-radius: 1rem; padding: 1.5rem; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);">
            <h2 style="margin: 0 0 1.25rem 0; font-size: 1.25rem; color: #0f172a; display: flex; align-items: center; gap: 0.5rem;">
                <svg width="20" height="20" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                Detail Lokasi Terakhir
            </h2>
            
            <div style="display: flex; flex-direction: column; gap: 1rem;">
                <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                    <span style="color: #64748b; font-size: 0.875rem;">Koordinat GPS</span>
                    <span style="font-weight: 600; color: #0f172a; font-family: monospace;">{{ $bike->current_latitude ?? '-' }}, {{ $bike->current_longitude ?? '-' }}</span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                    <span style="color: #64748b; font-size: 0.875rem;">Akurasi GPS</span>
                    <span style="font-weight: 600; color: #0f172a;">{{ $bike->last_accuracy !== null ? $bike->last_accuracy.' meter' : '-' }}</span>
                </div>
                <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9;">
                    <span style="color: #64748b; font-size: 0.875rem;">Terakhir Diperbarui</span>
                    <span style="font-weight: 600; color: #0f172a;">{{ $bike->latestLocationPoint?->recorded_at ?? '-' }}</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Table 10 Sinyal Perangkat Terakhir -->
    <div style="background: white; border-radius: 1rem; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); margin-bottom: 2.5rem; overflow: hidden;">
        <div style="padding: 1.5rem; border-bottom: 1px solid #f1f5f9;">
            <h2 style="margin: 0; font-size: 1.25rem; color: #0f172a; display: flex; align-items: center; gap: 0.5rem;">
                <svg width="20" height="20" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M2 12h4l2-9 4 18 2-9h4"/></svg>
                10 Sinyal Perangkat Terakhir
            </h2>
        </div>
        <div class="table-responsive" style="margin: 0;">
            <table style="width: 100%; border-collapse: collapse; text-align: left;">
                <thead style="background: #f8fafc; border-bottom: 2px solid #e2e8f0;">
                    <tr>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Perangkat Sepeda</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Jenis Jaringan</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Catatan Sinyal</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Terakhir Aktif</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($heartbeats as $heartbeat)
                        <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.2s;">
                            <td style="padding: 1rem 1.5rem; color: #0f172a; font-weight: 500;">{{ $heartbeat->deviceUser?->email ?? '-' }}</td>
                            <td style="padding: 1rem 1.5rem;">
                                <span style="background: #f1f5f9; color: #475569; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600;">
                                    {{ $heartbeat->network_type ?? '-' }}
                                </span>
                            </td>
                            <td style="padding: 1rem 1.5rem; color: #64748b;">{{ $heartbeat->signal_note ?? '-' }}</td>
                            <td style="padding: 1rem 1.5rem; color: #64748b;">{{ $heartbeat->last_seen_at }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="4" style="padding: 2rem; text-align: center; color: #94a3b8;">Belum ada sinyal perangkat.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Table 10 Lokasi Rental Terakhir (Keeping existing but styled) -->
    <div style="background: white; border-radius: 1rem; border: 1px solid #e2e8f0; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05); margin-bottom: 2.5rem; overflow: hidden;">
        <div style="padding: 1.5rem; border-bottom: 1px solid #f1f5f9;">
            <h2 style="margin: 0; font-size: 1.25rem; color: #0f172a; display: flex; align-items: center; gap: 0.5rem;">
                <svg width="20" height="20" fill="none" stroke="#0f766e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                10 Lokasi Rental Terakhir
            </h2>
        </div>
        <div class="table-responsive" style="margin: 0;">
            <table style="width: 100%; border-collapse: collapse; text-align: left;">
                <thead style="background: #f8fafc; border-bottom: 2px solid #e2e8f0;">
                    <tr>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Rental</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Pengguna</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Lokasi</th>
                        <th style="padding: 1rem 1.5rem; font-size: 0.875rem; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.05em;">Waktu Diterima</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($locationPoints as $point)
                        <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.2s;">
                            <td style="padding: 1rem 1.5rem;">
                                @if($point->rental)
                                    <a href="{{ route('admin.rentals.show', $point->rental) }}" style="font-weight: 600; color: #0f766e; text-decoration: none;">#{{ $point->rental->id }}</a>
                                @else
                                    <span style="color: #94a3b8;">-</span>
                                @endif
                            </td>
                            <td style="padding: 1rem 1.5rem; color: #0f172a;">{{ $point->rental?->user?->name ?? '-' }}</td>
                            <td style="padding: 1rem 1.5rem; color: #64748b; font-family: monospace;">{{ $point->latitude }}, {{ $point->longitude }}</td>
                            <td style="padding: 1rem 1.5rem; color: #64748b;">{{ $point->recorded_at }}</td>
                        </tr>
                    @empty
                        <tr><td colspan="4" style="padding: 2rem; text-align: center; color: #94a3b8;">Belum ada lokasi rental.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            // Override background of main to be gray
            const mainEl = document.querySelector('main');
            if (mainEl) mainEl.style.backgroundColor = '#f8fafc';
            document.body.style.backgroundColor = '#f8fafc';
        });
    </script>
@endsection
