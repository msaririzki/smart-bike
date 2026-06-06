@extends('layouts.admin', ['title' => 'Detail Rental'])

@section('content')
    <div style="display: flex; gap: 12px; align-items: center; margin-bottom: 24px;">
        <a href="{{ route('admin.rentals.index') }}" class="button secondary" style="padding: 8px;" title="Kembali">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"></path></svg>
        </a>
        <h1 style="margin: 0;">Rental #{{ $rental->id }}</h1>
    </div>

    <div class="grid">
        <div class="card">
            <span class="muted">Data Pengguna</span>
            <h2>{{ $rental->user->name }}</h2>
            <p><strong>Email:</strong> {{ $rental->user->email }}</p>
            <p><strong>Telepon:</strong> {{ $rental->user->phone ?? '-' }}</p>
        </div>
        <div class="card">
            <span class="muted">Data Sepeda</span>
            <h2>{{ $rental->bike->code }} - {{ $rental->bike->name }}</h2>
            <p><strong>Status:</strong> <span class="badge {{ $rental->bike->status }}">{{ $adminStatusLabels[$rental->bike->status] ?? $rental->bike->status }}</span></p>
            <p><strong>Perangkat Sepeda:</strong> {{ $rental->bike->assignedDevice?->email ?? '-' }}</p>
        </div>
        <div class="card">
            <span class="muted">Ringkasan Rental</span>
            <h2><span class="badge {{ $rental->status }}">{{ $adminStatusLabels[$rental->status] ?? $rental->status }}</span></h2>
            <p><strong>Waktu Mulai:</strong> {{ $rental->started_at }}</p>
            <p><strong>Waktu Selesai:</strong> {{ $rental->ended_at ?? '-' }}</p>
            <p><strong>Durasi:</strong> {{ $rental->started_at?->diffForHumans($rental->ended_at ?? now(), true) ?? '-' }}</p>
        </div>
    </div>

    <div class="grid">
        <div class="card stat-card"><span class="muted">Biaya Jarak</span><h2>Rp{{ number_format($rental->distance_cost, 0, ',', '.') }}</h2></div>
        <div class="card stat-card"><span class="muted">Biaya Sepeda Diam</span><h2>Rp{{ number_format($rental->idle_cost, 0, ',', '.') }}</h2></div>
        <div class="card stat-card"><span class="muted">Total Biaya</span><h2>Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</h2></div>
        <div class="card stat-card"><span class="muted">Total Jarak</span><h2>{{ number_format($rental->total_distance_meters, 2) }} m</h2></div>
    </div>

    <div class="card map-panel" style="padding: 0;">
        <div class="map-header" style="padding: 24px 24px 16px; margin: 0;">
            <div>
                <h2 style="margin: 0 0 8px 0; color: #0f766e;">Peta Rute Rental</h2>
                <p class="muted" style="margin: 0;">Rute diperbarui otomatis dari lokasi yang dikirim perangkat sepeda.</p>
            </div>
            <div class="map-actions">
                <span class="muted" id="route-map-count">{{ $routePoints->count() }} titik lokasi</span>
                <button class="button secondary" type="button" id="route-map-center">Pusatkan Rute</button>
            </div>
        </div>
        <div id="route-map-empty" class="map-empty" style="border: 0; border-radius: 0; background: #f8fafc;" @if($routePoints->isNotEmpty()) hidden @endif>
            Belum ada titik lokasi untuk rental ini.
        </div>
        <div id="route-map" class="map-canvas compact" style="border: 0; border-radius: 0; border-top: 1px solid #e2e8f0; height: 400px; min-height: 400px;" @if($routePoints->isEmpty()) hidden @endif></div>
    </div>

    <div class="card">
        <h2>Lokasi Terakhir</h2>
        @if($rental->latestLocationPoint)
            <p><strong>Lintang:</strong> {{ $rental->latestLocationPoint->latitude }}</p>
            <p><strong>Bujur:</strong> {{ $rental->latestLocationPoint->longitude }}</p>
            <p><strong>Kecepatan:</strong> {{ $rental->latestLocationPoint->speed_kmh !== null ? $rental->latestLocationPoint->speed_kmh.' km/h' : '-' }}</p>
            <p><strong>Akurasi:</strong> {{ $rental->latestLocationPoint->accuracy_meters !== null ? $rental->latestLocationPoint->accuracy_meters.' m' : '-' }}</p>
            <p><strong>Jenis Jaringan:</strong> {{ $rental->latestLocationPoint->network_type ?? '-' }}</p>
            <p><strong>Waktu Diterima:</strong> {{ $rental->latestLocationPoint->recorded_at }}</p>
        @else
            <p class="muted">Belum ada lokasi rental.</p>
        @endif
    </div>

    <h2>Riwayat Tagihan</h2>
    <div class="table-responsive">
        <table>
            <thead><tr><th>Jenis Biaya</th><th>Nominal</th><th>Jumlah</th><th>Satuan</th><th>Catatan</th><th>Waktu Dibuat</th></tr></thead>
            <tbody>
                @forelse($rental->billingLogs as $log)
                    <tr>
                        <td>{{ $log->billing_type }}</td>
                        <td>Rp{{ number_format($log->amount, 0, ',', '.') }}</td>
                        <td>{{ $log->quantity }}</td>
                        <td>{{ $log->unit_label ?? '-' }}</td>
                        <td>{{ $log->notes ?? '-' }}</td>
                        <td>{{ $log->created_at }}</td>
                    </tr>
                @empty
                    <tr><td colspan="6" class="muted">Belum ada riwayat tagihan.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Catatan Sepeda Diam</h2>
    <div class="table-responsive">
        <table>
            <thead><tr><th>Jenis Catatan</th><th>Deskripsi</th><th>Waktu Kejadian</th></tr></thead>
            <tbody>
                @forelse($rental->idleEvents as $event)
                    <tr><td>{{ $event->event_type }}</td><td>{{ $event->description }}</td><td>{{ $event->event_at }}</td></tr>
                @empty
                    <tr><td colspan="3" class="muted">Belum ada catatan sepeda diam.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <h2>Riwayat Rute / Lokasi</h2>
    <div class="table-responsive">
        <table>
            <thead><tr><th>Lintang</th><th>Bujur</th><th>Kecepatan</th><th>Akurasi</th><th>Jenis Jaringan</th><th>Jarak</th><th>Valid</th><th>Alasan Diabaikan</th><th>Waktu Diterima</th></tr></thead>
            <tbody>
                @forelse($rental->locationPoints->sortByDesc('recorded_at')->take(30) as $point)
                    <tr>
                        <td>{{ $point->latitude }}</td>
                        <td>{{ $point->longitude }}</td>
                        <td>{{ $point->speed_kmh !== null ? $point->speed_kmh.' km/h' : '-' }}</td>
                        <td>{{ $point->accuracy_meters !== null ? $point->accuracy_meters.' m' : '-' }}</td>
                        <td>{{ $point->network_type ?? '-' }}</td>
                        <td>{{ number_format($point->movement_distance_meters, 2) }} m</td>
                        <td>{{ $point->is_valid_movement ? 'ya' : 'tidak' }}</td>
                        <td>{{ $point->ignored_reason ?? '-' }}</td>
                        <td>{{ $point->recorded_at }}</td>
                    </tr>
                @empty
                    <tr><td colspan="9" class="muted">Belum ada riwayat lokasi.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js" crossorigin=""></script>
    <script>
        const routePoints = @json($routePoints);
        const routeDataUrl = @json(route('admin.rentals.route-map-data', $rental));
        const routeMapElement = document.getElementById('route-map');
        const routeMapEmptyElement = document.getElementById('route-map-empty');
        const routeMapCountElement = document.getElementById('route-map-count');
        const routeMapCenterButton = document.getElementById('route-map-center');
        const initialRouteCenter = @json([
            'latitude' => $rental->latestLocationPoint?->latitude ?? $rental->bike->current_latitude ?? -8.5830,
            'longitude' => $rental->latestLocationPoint?->longitude ?? $rental->bike->current_longitude ?? 116.1160,
        ]);
        const routeEscapeHtml = (value) => String(value ?? '-')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#039;');

        if (routeMapElement && window.L) {
            const routeMap = L.map(routeMapElement).setView([
                Number(initialRouteCenter.latitude),
                Number(initialRouteCenter.longitude),
            ], 15);
            const routeLayer = L.layerGroup().addTo(routeMap);
            const pointLayer = L.layerGroup().addTo(routeMap);
            let hasFittedRoute = false;
            let currentRouteCoordinates = [];
            const normalRouteStyle = { color: '#0f766e', weight: 5, opacity: 0.85, lineCap: 'round', lineJoin: 'round' };
            const speedAnomalyRouteStyle = { color: '#ef4444', weight: 6, opacity: 0.92, lineCap: 'round', lineJoin: 'round' };

            const startIcon = L.divIcon({
                className: 'badge available',
                html: 'Mulai',
                iconSize: [46, 22],
                iconAnchor: [23, 11],
            });
            const finishIcon = L.divIcon({
                className: 'badge in_use',
                html: 'Terbaru',
                iconSize: [58, 22],
                iconAnchor: [29, 11],
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap contributors',
            }).addTo(routeMap);

            const pointPopup = (point, label) => `
                <div class="map-popup">
                    <h3>${routeEscapeHtml(label)}</h3>
                    <p><strong>Waktu Diterima:</strong> ${routeEscapeHtml(point.recorded_at)}</p>
                    <p><strong>Kecepatan:</strong> ${routeEscapeHtml(point.speed_kmh === null ? '-' : `${point.speed_kmh} km/h`)}</p>
                    <p><strong>Akurasi:</strong> ${routeEscapeHtml(point.accuracy_meters === null ? '-' : `${point.accuracy_meters} m`)}</p>
                    <p><strong>Jenis Jaringan:</strong> ${routeEscapeHtml(point.network_type)}</p>
                    <p><strong>Status Lokasi:</strong> ${point.is_valid_movement ? 'valid' : 'tidak dipakai'}</p>
                    <p><strong>Catatan:</strong> ${routeEscapeHtml(point.ignored_reason)}</p>
                </div>
            `;
            const isSpeedAnomalyPoint = (point) => point?.ignored_reason === 'speed_anomaly';

            const drawRouteSegments = (points) => {
                routeLayer.clearLayers();

                for (let index = 1; index < points.length; index += 1) {
                    const previous = points[index - 1];
                    const current = points[index];
                    const style = isSpeedAnomalyPoint(current) ? speedAnomalyRouteStyle : normalRouteStyle;

                    L.polyline([
                        [previous.latitude, previous.longitude],
                        [current.latitude, current.longitude],
                    ], style).addTo(routeLayer);
                }
            };

            const renderRoute = (points, fitRoute = false) => {
                const coordinates = points.map((point) => [point.latitude, point.longitude]);
                drawRouteSegments(points);
                pointLayer.clearLayers();
                const speedAnomalyCount = points.filter(isSpeedAnomalyPoint).length;

                points.forEach((point, index) => {
                    if (isSpeedAnomalyPoint(point)) {
                        L.circleMarker([point.latitude, point.longitude], {
                            radius: 5,
                            color: '#dc2626',
                            weight: 2,
                            fillColor: '#fee2e2',
                            fillOpacity: 0.95,
                        }).addTo(pointLayer).bindPopup(pointPopup(point, 'Overspeed'));
                    }

                    if (index === 0 || index === points.length - 1) {
                        L.marker([point.latitude, point.longitude], {
                            icon: index === 0 ? startIcon : finishIcon,
                        }).addTo(pointLayer).bindPopup(pointPopup(point, index === 0 ? 'Titik Mulai' : 'Lokasi Terbaru'));
                    }
                });

                routeMapEmptyElement.hidden = points.length > 0;
                routeMapElement.hidden = points.length === 0;
                routeMapCenterButton.disabled = points.length === 0;
                routeMapCountElement.textContent = speedAnomalyCount > 0
                    ? `${points.length} titik lokasi · ${speedAnomalyCount} overspeed`
                    : `${points.length} titik lokasi`;
                currentRouteCoordinates = coordinates;

                if (coordinates.length === 0) {
                    return;
                }

                if (coordinates.length > 0 && (fitRoute || ! hasFittedRoute)) {
                    hasFittedRoute = true;
                    fitRouteToBounds();
                }

                requestAnimationFrame(() => routeMap.invalidateSize());
            };

            const fitRouteToBounds = () => {
                routeMap.invalidateSize();

                if (currentRouteCoordinates.length === 1) {
                    routeMap.setView(currentRouteCoordinates[0], 16);
                } else if (currentRouteCoordinates.length > 1) {
                    const center = currentRouteCoordinates.reduce((carry, point) => [
                        carry[0] + point[0],
                        carry[1] + point[1],
                    ], [0, 0]).map((value) => value / currentRouteCoordinates.length);
                    routeMap.setView(center, 15);
                }

                L.DomUtil.setPosition(routeMap.getPane('mapPane'), L.point(0, 0));
                requestAnimationFrame(() => routeMap.invalidateSize());
            };

            const refreshRoute = async () => {
                try {
                    const response = await fetch(routeDataUrl, { headers: { Accept: 'application/json' } });
                    const payload = await response.json();
                    renderRoute(payload.data ?? []);
                } catch (_error) {
                    routeMapCountElement.textContent = 'Peta rute belum bisa diperbarui otomatis';
                }
            };

            renderRoute(routePoints);

            // Fix: Gunakan setTimeout 200ms setelah DOM siap untuk mencegah kotak abu-abu
            const applyMapFix = () => {
                setTimeout(() => {
                    routeMap.invalidateSize();
                    if (currentRouteCoordinates.length > 0) {
                        fitRouteToBounds();
                    }
                }, 200);
            };

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', applyMapFix);
            } else {
                applyMapFix();
            }

            routeMapCenterButton?.addEventListener('click', fitRouteToBounds);
            setInterval(refreshRoute, 10000);
        } else if (routeMapElement) {
            routeMapElement.innerHTML = '<div class="map-empty">Peta rute belum bisa dimuat. Periksa koneksi internet untuk membuka peta.</div>';
        }
    </script>
@endsection
