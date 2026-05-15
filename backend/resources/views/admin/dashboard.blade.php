@extends('layouts.admin', ['title' => 'Dasbor'])

@section('content')
    <style>
        .dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(14rem, 1fr)); gap: 1rem; margin-bottom: 2rem; }
        .dash-card { background: #ffffff; border-radius: 0.75rem; padding: 1rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); display: flex; flex-direction: column; position: relative; overflow: hidden; border: 1px solid #f1f5f9; transition: transform 0.2s, box-shadow 0.2s; }
        .dashboard-grid.collapsed .dash-card:nth-child(n+5) { display: none; }
        .dash-card:hover { transform: translateY(-0.25rem); box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.04); }
        .dash-card::before { content: ''; position: absolute; top: 0; left: 0; width: 0.35rem; height: 100%; background: #0f766e; }
        .dash-card.accent-blue::before { background: #3b82f6; }
        .dash-card.accent-red::before { background: #ef4444; }
        .dash-card.accent-amber::before { background: #f59e0b; }
        .dash-card.accent-green::before { background: #10b981; }
        .dash-card.accent-purple::before { background: #8b5cf6; }

        .dash-card-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.75rem; }
        .dash-card-title { color: #64748b; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; margin: 0; }
        .dash-card-icon { width: 2.25rem; height: 2.25rem; border-radius: 0.5rem; display: flex; align-items: center; justify-content: center; color: #0f766e; background: #ccfbf1; }
        .dash-card-icon svg { width: 1.25rem; height: 1.25rem; }
        .dash-card.accent-blue .dash-card-icon { color: #3b82f6; background: #dbeafe; }
        .dash-card.accent-red .dash-card-icon { color: #ef4444; background: #fee2e2; }
        .dash-card.accent-amber .dash-card-icon { color: #d97706; background: #fef3c7; }
        .dash-card.accent-green .dash-card-icon { color: #10b981; background: #d1fae5; }
        .dash-card.accent-purple .dash-card-icon { color: #8b5cf6; background: #ede9fe; }
        .dash-card-value { font-size: 1.5rem; font-weight: 700; color: #0f172a; margin: 0; line-height: 1; }

        .dash-map-panel { background: white; border-radius: 1.5rem; border: 1px solid #e2e8f0; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.05), 0 8px 10px -6px rgba(0, 0, 0, 0.01); overflow: hidden; display: flex; flex-direction: column; }
        .dash-map-header { padding: 1.75rem 2rem; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem; border-bottom: 1px solid #e2e8f0; background: linear-gradient(to bottom, #ffffff, #f8fafc); }
        .dash-map-title { margin: 0; color: #0f172a; font-size: 1.5rem; font-weight: 700; display: flex; align-items: center; gap: 0.75rem; }
        .dash-map-title svg { stroke: #0f766e; background: #ccfbf1; border-radius: 0.5rem; padding: 0.25rem; width: 2rem; height: 2rem; }
        .dash-map-subtitle { margin: 0.5rem 0 0 0; color: #64748b; font-size: 0.95rem; }
        .dash-map-canvas { height: 70vh; min-height: 550px; width: 100%; background: #eef2f6; z-index: 1; position: relative; }
        .map-actions { display: flex; align-items: center; gap: 1.25rem; }
        .leaflet-popup-content-wrapper { border-radius: 1rem; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.05); overflow: hidden; padding: 0; }
        .leaflet-popup-content { margin: 0; width: 320px !important; }
        .map-popup { padding: 0; font-family: inherit; }
        .map-popup-header { display: flex; justify-content: space-between; align-items: flex-start; padding: 1.25rem; background: linear-gradient(135deg, #0f766e, #14b8a6); color: white; }
        .map-popup-title { margin: 0; font-size: 1.25rem; font-weight: 700; letter-spacing: 0.025em; }
        .map-popup-subtitle { margin: 0.25rem 0 0 0; font-size: 0.875rem; opacity: 0.9; }
        .map-popup-header .badge { background: rgba(255, 255, 255, 0.2); color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; border: 1px solid rgba(255, 255, 255, 0.3); backdrop-filter: blur(4px); }
        .map-popup-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; padding: 1.25rem; background: #f8fafc; border-bottom: 1px solid #e2e8f0; }
        .map-popup-item { display: flex; flex-direction: column; gap: 0.25rem; }
        .map-popup-label { font-size: 0.7rem; color: #64748b; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; }
        .map-popup-value { font-size: 0.95rem; color: #0f172a; font-weight: 600; }
        .map-popup-battery { height: 6px; background: #e2e8f0; border-radius: 9999px; overflow: hidden; margin-top: 0.25rem; width: 100%; }
        .map-popup-battery span { display: block; height: 100%; background: #10b981; border-radius: 9999px; }
        .map-popup-battery.low span { background: #ef4444; }
        .map-popup-details { padding: 1.25rem; font-size: 0.875rem; color: #475569; }
        .map-popup-details p { margin: 0 0 0.5rem 0; }
        .map-popup-details p:last-child { margin: 0; }
        .map-popup-details strong { color: #0f172a; }
        .map-popup-footer { display: flex; justify-content: space-between; padding: 1rem 1.25rem; background: white; border-top: 1px solid #f1f5f9; }
        .map-popup-footer a { color: #0f766e; font-weight: 600; font-size: 0.875rem; text-decoration: none; display: inline-flex; align-items: center; gap: 0.25rem; transition: color 0.2s; }
        .map-popup-footer a:hover { color: #0f172a; text-decoration: underline; }


        @media (max-width: 768px) {
            .dashboard-grid { grid-template-columns: repeat(2, 1fr); gap: 0.75rem; }
            .dash-card { padding: 0.75rem; }
            .dash-card-icon { width: 1.75rem; height: 1.75rem; border-radius: 0.375rem; }
            .dash-card-icon svg { width: 1rem; height: 1rem; }
            .dash-card-title { font-size: 0.65rem; }
            .dash-card-value { font-size: 1.25rem; }
            .dash-card-header { margin-bottom: 0.25rem; }
        }
        @media (max-width: 480px) {
            .dashboard-grid { gap: 0.5rem; }
            .dash-card { padding: 0.625rem; }
            .dash-card-value { font-size: 1.125rem; }
        }

        .trend { font-size: 0.75rem; font-weight: 600; display: flex; align-items: center; gap: 0.25rem; margin-top: 0.25rem; }
        .trend.up { color: #10b981; }
        .trend.down { color: #ef4444; }

        .main-content-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 1.5rem; margin-bottom: 2.5rem; }
        @media (max-width: 900px) { .main-content-grid { grid-template-columns: 1fr; } }

        .activity-list { margin: 0; padding: 0; list-style: none; display: flex; flex-direction: column; gap: 1rem; }
        .activity-item { display: flex; gap: 1rem; align-items: flex-start; padding-bottom: 1rem; border-bottom: 1px solid #f1f5f9; }
        body.dark-mode .activity-item { border-bottom-color: #334155; }
        .activity-item:last-child { border: none; padding: 0; }
        .activity-icon { width: 2rem; height: 2rem; border-radius: 50%; background: #dbeafe; color: #3b82f6; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        body.dark-mode .activity-icon { background: rgba(59, 130, 246, 0.2); }
        .activity-details { flex-grow: 1; font-size: 0.875rem; }
        .activity-time { color: #64748b; font-size: 0.75rem; margin-top: 0.25rem; }

        .weather-widget { background: linear-gradient(135deg, #0ea5e9, #2563eb); color: white; border-radius: 1rem; padding: 1.5rem; display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.5rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        .weather-info h3 { margin: 0; font-size: 1.5rem; }
        .weather-info p { margin: 0.25rem 0 0; opacity: 0.9; font-size: 0.875rem; }
        /* Popup Animation */
        .animated-popup .leaflet-popup-content-wrapper,
        .animated-popup .leaflet-popup-tip {
            animation: popupScaleFade 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards;
            transform-origin: bottom center;
        }
        @keyframes popupScaleFade {
            0% { opacity: 0; transform: scale(0.85) translateY(10px); }
            100% { opacity: 1; transform: scale(1) translateY(0); }
        }
    </style>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;">
        <h1 style="margin: 0; color: #0f172a; font-size: 1.75rem;">Dasbor</h1>
        <button id="toggleCardsBtn" type="button" style="background: white; border: 1px solid #e2e8f0; color: #475569; padding: 0.5rem 1rem; border-radius: 0.5rem; font-size: 0.875rem; cursor: pointer; display: flex; align-items: center; gap: 0.5rem; font-weight: 500; transition: all 0.2s; box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
            <span id="toggleCardsText">Lihat Lainnya</span>
            <svg id="toggleCardsIcon" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M6 9l6 6 6-6"/></svg>
        </button>
    </div>

    <div class="dashboard-grid collapsed" id="dashboardGrid">
        <div class="dash-card">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Total Sepeda</h3>
                <div class="dash-card-icon"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 18c-.5 0-.9-.2-1.2-.5C3.5 17.2 3.4 16.8 3.5 16.4l2.2-9.9C5.9 5.6 6.7 5 7.6 5h8.8c.9 0 1.7.6 1.9 1.5l2.2 9.9c.1.4 0 .8-.3 1.1-.3.3-.7.5-1.2.5H5z"></path><circle cx="8" cy="18" r="2"></circle><circle cx="16" cy="18" r="2"></circle></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $totalBikes }}</p>
            </div>
        </div>
        <div class="dash-card accent-green">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Sepeda Tersedia</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="M22 4L12 14.01l-3-3"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $availableBikes }}</p>
            </div>
        </div>
        <div class="dash-card accent-blue">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Sepeda Dipakai</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $inUseBikes }}</p>
            </div>
        </div>
        <div class="dash-card accent-red">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Sepeda Offline</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="1" y1="1" x2="23" y2="23"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><line x1="12" y1="20" x2="12.01" y2="20"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $offlineBikes }}</p>
            </div>
        </div>
        <div class="dash-card accent-amber">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Rental Aktif</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $activeRentals }}</p>
            </div>
        </div>
        <div class="dash-card accent-purple">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Rental Selesai</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><path d="M9 12l2 2 4-4"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $completedRentalsToday }}</p>
            </div>
        </div>
        <div class="dash-card accent-green">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Estimasi Pendapatan</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">Rp{{ number_format($totalRevenue, 0, ',', '.') }}</p>
            </div>
        </div>
        <div class="dash-card accent-blue">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Total Jarak</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ number_format($totalDistanceMeters / 1000, 2) }} <span style="font-size: 1rem; font-weight: 500; color: #64748b;">km</span></p>
            </div>
        </div>
        <div class="dash-card">
            <div class="dash-card-header">
                <h3 class="dash-card-title">Pengguna</h3>
                <div class="dash-card-icon"><svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg></div>
            </div>
            <div>
                <p class="dash-card-value">{{ $users }}</p>
            </div>
        </div>
    </div>

    <div class="dash-map-panel" style="margin-bottom: 2.5rem;">
        <div class="dash-map-header">
            <div>
                <h2 class="dash-map-title">
                    <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                    Peta Lokasi Sepeda
                </h2>
                <p class="dash-map-subtitle">Peta otomatis diperbarui. Klik penanda untuk melihat ringkasan sepeda dan membuka halaman detail.</p>
            </div>
            <div class="map-actions">
                <span style="font-size: 0.875rem; color: #0f766e; background: #ccfbf1; padding: 0.5rem 1rem; border-radius: 9999px; font-weight: 600;" id="bike-map-count">{{ $mapBikes->count() }} sepeda memiliki data lokasi</span>
                <button class="button secondary" style="padding: 0.5rem 1rem; border-radius: 0.5rem; background: white; border: 1px solid #cbd5e1; color: #334155; font-weight: 600; box-shadow: 0 1px 2px 0 rgba(0,0,0,0.05); transition: all 0.2s;" type="button" id="bike-map-center" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">Pusatkan Peta</button>
            </div>
        </div>

        <div id="bike-map-empty" class="map-empty" @if($mapBikes->isNotEmpty()) hidden @endif>
            Belum ada sepeda yang memiliki data lokasi.
        </div>
        <div id="bike-map" class="dash-map-canvas" @if($mapBikes->isEmpty()) hidden @endif></div>
    </div>

    <div class="main-content-grid">
        <div class="analytic-panel" style="margin-bottom: 0;">
            <div class="analytic-header">
                <h2 class="dash-map-title">Analisis Rental</h2>
                <p class="dash-map-subtitle">Tren pendapatan harian selama 7 hari terakhir.</p>
            </div>
            <div class="analytic-canvas-wrapper" style="display: flex; align-items: center; justify-content: center;">
                <p class="muted">Data historis pendapatan belum tersedia.</p>
                <canvas id="revenueChart" style="display: none;"></canvas>
            </div>
        </div>

        <div class="analytic-panel" style="margin-bottom: 0;">
            <div class="analytic-header">
                <h2 class="dash-map-title">Aktivitas Terbaru</h2>
            </div>
            <div style="display: flex; height: 100%; align-items: center; justify-content: center; padding-bottom: 2rem;">
                <p class="muted" style="text-align: center;">Tidak ada aktivitas terbaru yang dapat ditampilkan.</p>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js" crossorigin=""></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
            const map = L.map(mapElement).setView([-8.5830, 116.1160], 14);
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

                        <div class="map-popup-details">
                            <p><strong>Perangkat:</strong> ${escapeHtml(bike.device ?? '-')}</p>
                            <p><strong>Rental aktif:</strong> ${escapeHtml(rentalText)}</p>
                        </div>

                        <div class="map-popup-footer">
                            <a href="${escapeHtml(bike.detail_url)}">Detail Sepeda &rarr;</a>
                            ${rentalLink}
                        </div>
                    </div>
                `;
            };

            const renderBikes = (nextBikes, fitMap = false) => {
                const visibleCodes = new Set();
                const bounds = [];

                let warnedAboutOffline = false;
                let warnedAboutBattery = false;

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
                            L.marker(position, { icon: bikeIcon(bike) }).addTo(map).bindPopup(popupHtml(bike), { autoPan: false, className: 'animated-popup' }),
                        );
                    }

                    // Toast logic
                    if (!bike.is_online && !warnedAboutOffline && window.showToast) {
                        window.showToast('Sepeda Offline', `Sepeda ${bike.code} terdeteksi offline.`, 'warning');
                        warnedAboutOffline = true;
                    }
                    if (bike.battery_percent !== null && bike.battery_percent < 20 && !warnedAboutBattery && window.showToast) {
                        window.showToast('Baterai Lemah', `Baterai ${bike.code} tersisa ${bike.battery_percent}%.`, 'error');
                        warnedAboutBattery = true;
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
            
            // Fix: Gunakan setTimeout 200ms setelah DOM siap untuk mencegah kotak abu-abu
            const applyMapFix = () => {
                setTimeout(() => {
                    map.invalidateSize();
                    if (currentBounds.length > 0) {
                        fitMapToBounds();
                    }
                }, 200);
            };

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', applyMapFix);
            } else {
                applyMapFix();
            }

            mapCenterButton?.addEventListener('click', fitMapToBounds);
            setInterval(refreshBikes, 10000);
        } else if (mapElement) {
            mapElement.innerHTML = '<div class="map-empty">Peta belum bisa dimuat. Periksa koneksi internet untuk membuka peta.</div>';
        }

        const toggleCardsBtn = document.getElementById('toggleCardsBtn');
        const dashboardGrid = document.getElementById('dashboardGrid');
        const toggleCardsText = document.getElementById('toggleCardsText');
        const toggleCardsIcon = document.getElementById('toggleCardsIcon');

        if (toggleCardsBtn && dashboardGrid) {
            toggleCardsBtn.addEventListener('click', () => {
                dashboardGrid.classList.toggle('collapsed');
                if (dashboardGrid.classList.contains('collapsed')) {
                    toggleCardsText.textContent = 'Lihat Lainnya';
                    toggleCardsIcon.innerHTML = '<path d="M6 9l6 6 6-6"/>';
                } else {
                    toggleCardsText.textContent = 'Lebih Sedikit';
                    toggleCardsIcon.innerHTML = '<path d="M18 15l-6-6-6 6"/>';
                }
                
                // Panggil invalidateSize saat ukuran kontainer berubah
                setTimeout(() => {
                    if (window.L) {
                        const mapElem = document.getElementById('bike-map');
                        if (mapElem && mapElem._leaflet_id) {
                             // Minimal fix: dispatch resize event to trigger Leaflet's internal invalidateSize
                            window.dispatchEvent(new Event('resize'));
                        }
                    }
                }, 200);
            });
        }

        // Charts Logic
        const revCtx = document.getElementById('revenueChart');
        // Currently no backend data is provided for the chart, rendering disabled.
    </script>
@endsection
