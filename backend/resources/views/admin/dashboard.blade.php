@extends('layouts.admin', ['title' => 'Dasbor'])

@section('content')
    <style>
        .stat-card { position: relative; overflow: hidden; border-left: 4px solid #0f766e; }
        .stat-card h2 { margin: 8px 0 0; color: #0f766e; font-size: 28px; }
        .stat-card .muted { font-weight: 500; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }
        .map-panel { padding: 0; overflow: hidden; }
        .map-header { padding: 24px 24px 16px; margin: 0; }
        .map-header h2 { margin: 0 0 4px; color: #0f766e; }
        .map-canvas, .map-empty { border: 0; border-radius: 0; border-top: 1px solid #e2e8f0; }
        .map-canvas { height: 420px; min-height: 420px; }
    </style>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h1 style="margin: 0; color: #0f766e;">Dasbor</h1>
    </div>

    <div class="grid">
        <div class="card stat-card"><span class="muted">Total Sepeda</span><h2>{{ $totalBikes }}</h2></div>
        <div class="card stat-card"><span class="muted">Sepeda Tersedia</span><h2>{{ $availableBikes }}</h2></div>
        <div class="card stat-card"><span class="muted">Sepeda Dipakai</span><h2>{{ $inUseBikes }}</h2></div>
        <div class="card stat-card"><span class="muted">Sepeda Offline</span><h2>{{ $offlineBikes }}</h2></div>
        <div class="card stat-card"><span class="muted">Rental Aktif</span><h2>{{ $activeRentals }}</h2></div>
        <div class="card stat-card"><span class="muted">Rental Selesai Hari Ini</span><h2>{{ $completedRentalsToday }}</h2></div>
        <div class="card stat-card"><span class="muted">Estimasi Pendapatan</span><h2>Rp{{ number_format($totalRevenue, 0, ',', '.') }}</h2></div>
        <div class="card stat-card"><span class="muted">Total Jarak Tempuh</span><h2>{{ number_format($totalDistanceMeters / 1000, 2) }} km</h2></div>
        <div class="card stat-card"><span class="muted">Pengguna</span><h2>{{ $users }}</h2></div>
    </div>

    <div class="card map-panel">
        <div class="map-header">
            <div>
                <h2>Peta Lokasi Sepeda</h2>
                <p class="muted">Peta otomatis diperbarui. Klik penanda untuk melihat ringkasan sepeda dan membuka halaman detail.</p>
            </div>
            <div class="map-actions">
                <span class="muted" id="bike-map-count">{{ $mapBikes->count() }} sepeda memiliki data lokasi</span>
                <button class="button secondary" type="button" id="bike-map-center">Pusatkan Peta</button>
            </div>
        </div>

        <div id="bike-map-empty" class="map-empty" @if($mapBikes->isNotEmpty()) hidden @endif>
            Belum ada sepeda yang memiliki data lokasi.
        </div>
        <div id="bike-map" class="map-canvas" @if($mapBikes->isEmpty()) hidden @endif></div>
    </div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
        integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <script>
        const bikes = @json($mapBikes);
        const statusLabels = @json($adminStatusLabels);
        const mapElement = document.getElementById('bike-map');
        const mapEmptyElement = document.getElementById('bike-map-empty');
        const mapCountElement = document.getElementById('bike-map-count');
        const mapCenterButton = document.getElementById('bike-map-center');
        const mapDataUrl = @json(route('admin.dashboard.map-data'));
        const escapeHtml = (value) => String(value ?? '-')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#039;');

        if (mapElement && window.L) {
            const map = L.map(mapElement).setView([-5.1477, 119.4327], 13);
            const markers = new Map();
            let hasFittedMap = false;
            let currentBounds = [];

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                maxZoom: 19,
                attribution: '&copy; OpenStreetMap contributors',
            }).addTo(map);

            const markerStatus = (bike) => bike.is_online ? bike.status : 'offline';
            const bikeIcon = (bike) => L.divIcon({
                className: `bike-map-marker ${markerStatus(bike)}`,
                html: '<span class="bike-map-marker-symbol">&#128690;</span>',
                iconSize: [36, 36],
                iconAnchor: [18, 18],
                popupAnchor: [0, -18],
            });

            const popupHtml = (bike) => {
                const statusText = statusLabels[bike.status] ?? bike.status;
                const onlineText = bike.is_online ? 'online' : 'offline';
                const batteryText = bike.battery_percent === null ? '-' : `${bike.battery_percent}%`;
                const batteryPercent = Math.max(0, Math.min(100, Number(bike.battery_percent ?? 0)));
                const batteryClass = batteryPercent <= 20 ? 'map-popup-battery low' : 'map-popup-battery';
                const networkText = bike.network_type ?? '-';
                const rentalText = bike.active_rental
                    ? `#${bike.active_rental.id} - ${bike.active_rental.user ?? 'Pengguna'}`
                    : '-';
                const rentalLink = bike.active_rental?.detail_url
                    ? `<a href="${escapeHtml(bike.active_rental.detail_url)}">Lihat Rental</a>`
                    : '<span class="muted">Belum ada rental aktif</span>';

                return `
                    <div class="map-popup">
                        <div class="map-popup-header">
                            <div>
                                <h3 class="map-popup-title">${escapeHtml(bike.code)}</h3>
                                <div class="map-popup-subtitle">${escapeHtml(bike.name)}</div>
                            </div>
                            <span class="badge ${escapeHtml(markerStatus(bike))}">${escapeHtml(bike.is_online ? statusText : 'offline')}</span>
                        </div>

                        <div class="map-popup-grid">
                            <div class="map-popup-item">
                                <span class="map-popup-label">Baterai</span>
                                <span class="map-popup-value">${escapeHtml(batteryText)}</span>
                                <div class="${batteryClass}"><span style="width: ${batteryPercent}%"></span></div>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Jaringan</span>
                                <span class="map-popup-value">${escapeHtml(networkText)}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Status Online</span>
                                <span class="map-popup-value">${escapeHtml(onlineText)}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Terakhir Aktif</span>
                                <span class="map-popup-value">${escapeHtml(bike.last_seen_at ?? '-')}</span>
                            </div>
                        </div>

                        <p><strong>Perangkat:</strong> ${escapeHtml(bike.device ?? '-')}</p>
                        <p><strong>Rental aktif:</strong> ${escapeHtml(rentalText)}</p>

                        <div class="map-popup-footer">
                            <a href="${escapeHtml(bike.detail_url)}">Detail Sepeda</a>
                            ${rentalLink}
                        </div>
                    </div>
                `;
            };

            const renderBikes = (nextBikes, fitMap = false) => {
                const visibleCodes = new Set();
                const bounds = [];

                nextBikes.forEach((bike) => {
                    const position = [bike.latitude, bike.longitude];
                    visibleCodes.add(bike.code);
                    bounds.push(position);

                    if (markers.has(bike.code)) {
                        markers.get(bike.code)
                            .setLatLng(position)
                            .setIcon(bikeIcon(bike))
                            .setPopupContent(popupHtml(bike));
                    } else {
                        markers.set(
                            bike.code,
                            L.marker(position, { icon: bikeIcon(bike) }).addTo(map).bindPopup(popupHtml(bike)),
                        );
                    }
                });

                markers.forEach((marker, code) => {
                    if (! visibleCodes.has(code)) {
                        map.removeLayer(marker);
                        markers.delete(code);
                    }
                });

                mapEmptyElement.hidden = nextBikes.length > 0;
                mapElement.hidden = nextBikes.length === 0;
                mapCenterButton.disabled = nextBikes.length === 0;
                mapCountElement.textContent = `${nextBikes.length} sepeda memiliki data lokasi`;
                currentBounds = bounds;

                if (bounds.length === 0) {
                    return;
                }

                if (bounds.length > 0 && (fitMap || ! hasFittedMap)) {
                    hasFittedMap = true;
                    fitMapToBounds();
                }

                requestAnimationFrame(() => map.invalidateSize());
            };

            const fitMapToBounds = () => {
                map.invalidateSize();

                if (currentBounds.length === 1) {
                    map.setView(currentBounds[0], 16);
                } else if (currentBounds.length > 1) {
                    const center = currentBounds.reduce((carry, point) => [
                        carry[0] + point[0],
                        carry[1] + point[1],
                    ], [0, 0]).map((value) => value / currentBounds.length);
                    map.setView(center, 15);
                }

                L.DomUtil.setPosition(map.getPane('mapPane'), L.point(0, 0));
                requestAnimationFrame(() => map.invalidateSize());
            };

            const refreshBikes = async () => {
                try {
                    const response = await fetch(mapDataUrl, { headers: { Accept: 'application/json' } });
                    const payload = await response.json();
                    renderBikes(payload.data ?? []);
                } catch (_error) {
                    mapCountElement.textContent = 'Peta belum bisa diperbarui otomatis';
                }
            };

            renderBikes(bikes);
            setTimeout(() => map.invalidateSize(), 100);
            setTimeout(() => map.invalidateSize(), 500);
            mapCenterButton?.addEventListener('click', fitMapToBounds);
            setInterval(refreshBikes, 10000);
        } else if (mapElement) {
            mapElement.innerHTML = '<div class="map-empty">Peta belum bisa dimuat. Periksa koneksi internet untuk membuka peta.</div>';
        }
    </script>
@endsection
