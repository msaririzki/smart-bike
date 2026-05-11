<div class="table-responsive">
    <table style="margin-bottom: 24px;">
        <thead>
            <tr><th>Kode</th><th>Nama</th><th>Status</th><th>Status Online</th><th>Baterai</th><th>Perangkat Sepeda</th><th>Terakhir Aktif</th><th></th></tr>
        </thead>
        <tbody>
            @forelse($bikes as $bike)
                <tr>
                    <td><strong>{{ $bike->code }}</strong></td>
                    <td>{{ $bike->name }}</td>
                    <td><span class="badge {{ $bike->status }}">{{ $adminStatusLabels[$bike->status] ?? $bike->status }}</span></td>
                    <td><span class="badge {{ $bike->is_online ? 'available' : 'maintenance' }}">{{ $bike->is_online ? 'Online' : 'Offline' }}</span></td>
                    <td>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <span style="min-width: 32px;">{{ $bike->battery_percent !== null ? $bike->battery_percent.'%' : '-' }}</span>
                            @if($bike->battery_percent !== null)
                                @php($batteryClass = $bike->battery_percent <= 20 ? 'background: #dc2626;' : 'background: #0f766e;')
                                <div style="width: 40px; height: 6px; border-radius: 4px; background: #e2e8f0; overflow: hidden;"><div style="height: 100%; width: {{ max(0, min(100, $bike->battery_percent)) }}%; {{ $batteryClass }}"></div></div>
                            @endif
                        </div>
                    </td>
                    <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                    <td>{{ $bike->last_seen_at ?? '-' }}</td>
                    <td><a href="{{ route('admin.monitoring.show', $bike) }}" class="button secondary" style="padding: 6px 12px; font-size: 13px;">Lihat Detail</a></td>
                </tr>
            @empty
                <tr><td colspan="8" class="muted">{{ $empty }}</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
