<table>
    <thead>
        <tr><th>Kode</th><th>Nama</th><th>Status</th><th>Status Online</th><th>Baterai</th><th>Perangkat Sepeda</th><th>Terakhir Aktif</th><th></th></tr>
    </thead>
    <tbody>
        @forelse($bikes as $bike)
            <tr>
                <td>{{ $bike->code }}</td>
                <td>{{ $bike->name }}</td>
                <td><span class="badge {{ $bike->status }}">{{ $adminStatusLabels[$bike->status] ?? $bike->status }}</span></td>
                <td>{{ $bike->is_online ? 'online' : 'offline' }}</td>
                <td>{{ $bike->battery_percent !== null ? $bike->battery_percent.'%' : '-' }}</td>
                <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                <td>{{ $bike->last_seen_at ?? '-' }}</td>
                <td><a href="{{ route('admin.monitoring.show', $bike) }}">Lihat Detail</a></td>
            </tr>
        @empty
            <tr><td colspan="8" class="muted">{{ $empty }}</td></tr>
        @endforelse
    </tbody>
</table>
