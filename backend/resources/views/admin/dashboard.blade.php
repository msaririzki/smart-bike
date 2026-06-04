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

        .dash-map-panel { background: #ffffff; border-radius: 1.25rem; border: 1px solid #e2e8f0; box-shadow: 0 18px 28px -18px rgba(15, 23, 42, 0.3); overflow: hidden; display: flex; flex-direction: column; position: relative; }
        .dash-map-header { padding: 1.5rem; display: flex; flex-direction: column; gap: 1rem; border-bottom: 1px solid #e2e8f0; background: #ffffff; position: relative; z-index: 10; }
        .dash-map-heading { display: flex; flex-direction: column; gap: 0.45rem; min-width: 0; }
        .dash-map-title-row { display: flex; align-items: center; justify-content: space-between; gap: 1rem; flex-wrap: wrap; }
        .dash-map-title { margin: 0; color: #0f172a; font-size: 1.55rem; font-weight: 800; display: flex; align-items: center; gap: 0.7rem; letter-spacing: 0; }
        .dash-map-title svg { stroke: #ffffff; background: #0f766e; border-radius: 0.7rem; padding: 0.38rem; width: 2.1rem; height: 2.1rem; box-shadow: 0 8px 18px -10px rgba(15, 118, 110, 0.75); flex-shrink: 0; }
        .dash-map-subtitle { margin: 0; color: #64748b; font-size: 0.95rem; font-weight: 500; }
        .dash-map-canvas { height: 70vh; min-height: 550px; width: 100%; background: #eef2f6; z-index: 1; position: relative; }

        .map-live-badge { display: inline-flex; align-items: center; gap: 0.45rem; min-height: 34px; padding: 0 0.8rem; border: 1px solid #ccfbf1; border-radius: 999px; background: #f0fdfa; color: #0f766e; font-size: 0.8rem; font-weight: 800; white-space: nowrap; }
        .map-live-badge svg { width: 1rem; height: 1rem; stroke-width: 2.4; }
        .map-actions { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 0.75rem; width: 100%; align-items: start; }
        .map-filter-shell { min-width: 0; }
        
        .cell-filter-form { display: grid; grid-template-columns: repeat(2, minmax(220px, 1fr)); gap: 0.75rem; min-width: 0; }
        .cell-filter-form .premium-select-field { flex: 1; min-width: 220px; min-height: 56px; padding: 0.5rem 0.75rem; border-radius: 0.8rem; box-sizing: border-box; }
        .cell-filter-form .premium-select-icon { width: 34px; height: 34px; border-radius: 0.65rem; }
        .cell-filter-form .premium-select-hint { display: none; }
        
        .map-actions-primary { display: flex; gap: 0.65rem; align-items: flex-start; justify-content: flex-end; flex-wrap: nowrap; }
        .map-actions-secondary { display: flex; justify-content: flex-end; min-width: max-content; }

        .dash-map-action-button, .cell-clear-button { display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem; padding: 0 0.9rem !important; border-radius: 0.75rem !important; font-size: 0.86rem !important; font-weight: 800 !important; cursor: pointer; transition: all 0.2s ease !important; min-height: 44px; white-space: nowrap; }
        .dash-map-action-button svg, .cell-clear-button svg { width: 1rem; height: 1rem; stroke-width: 2.4; flex-shrink: 0; }

        .dash-map-action-button { background: #ffffff !important; border: 1px solid #e2e8f0 !important; color: #334155 !important; box-shadow: 0 1px 3px rgba(0,0,0,0.05) !important; }
        .dash-map-action-button:hover { background: #f8fafc !important; border-color: #cbd5e1 !important; color: #0f172a !important; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05) !important; transform: translateY(-1px); }

        .cell-layer-button.active { background: #0f766e !important; border-color: #0f766e !important; color: #ffffff !important; box-shadow: 0 4px 6px -1px rgba(15, 118, 110, 0.2) !important; }
        .cell-layer-button.active:hover { background: #0d9488 !important; border-color: #0d9488 !important; }

        .cell-clear-button { background: #fff7f8; border: 1px solid #ffe4e6; color: #e11d48; width: auto; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
        .cell-clear-button:hover:not(:disabled) { background: #ffe4e6; border-color: #fecdd3; color: #be123c; transform: translateY(-1px); box-shadow: 0 4px 6px -1px rgba(225, 29, 72, 0.1); }
        .cell-clear-button:disabled { background: #f8fafc; border-color: #e2e8f0; color: #94a3b8; cursor: not-allowed; transform: none; box-shadow: none; }
        .leaflet-popup-content-wrapper { border-radius: 1rem; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.05); overflow: hidden; padding: 0; }
        .leaflet-popup-content { margin: 0; width: 320px !important; }
        .map-popup { padding: 0; font-family: inherit; }
        .map-popup-header { display: flex; justify-content: space-between; align-items: flex-start; padding: 1.25rem 2.5rem 1.25rem 1.25rem; background: linear-gradient(135deg, #0f766e, #14b8a6); color: white; }
        .map-popup-title { margin: 0; font-size: 1.25rem; font-weight: 700; letter-spacing: 0.025em; }
        .map-popup-subtitle { margin: 0.25rem 0 0 0; font-size: 0.875rem; color: rgba(255, 255, 255, 0.9); }
        .map-popup-header .badge { background: rgba(255, 255, 255, 0.2); color: white; padding: 0.25rem 0.75rem; border-radius: 9999px; font-size: 0.75rem; font-weight: 600; text-transform: uppercase; border: 1px solid rgba(255, 255, 255, 0.3); backdrop-filter: blur(4px); }
        .leaflet-popup-close-button { color: rgba(255, 255, 255, 0.8) !important; right: 12px !important; top: 12px !important; font-size: 18px !important; width: 24px !important; height: 24px !important; line-height: 24px !important; text-align: center !important; }
        .leaflet-popup-close-button:hover { color: white !important; background: transparent !important; }
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
        .cell-map-marker { width: 30px; height: 30px; border-radius: 999px; display: grid; place-items: center; color: #7c2d12; background: #fed7aa; border: 3px solid #fff7ed; box-shadow: 0 8px 18px rgba(124, 45, 18, .26); font-size: 16px; }
        .cell-handover-marker { width: 30px; height: 30px; border-radius: 999px; display: grid; place-items: center; color: #ffffff; background: #2563eb; border: 3px solid #dbeafe; box-shadow: 0 10px 20px rgba(37, 99, 235, .32); font-size: 15px; font-weight: 900; }
        .cell-route-line { filter: drop-shadow(0 4px 8px rgba(37, 99, 235, .22)); }
        .cell-layer-button.active { background: #0f766e !important; border-color: #0f766e !important; color: white !important; }


        @media (max-width: 1180px) {
            .map-actions { grid-template-columns: 1fr; }
            .map-actions-primary { justify-content: flex-start; flex-wrap: wrap; }
        }
        @media (max-width: 768px) {
            .dashboard-grid { grid-template-columns: repeat(2, 1fr); gap: 0.75rem; }
            .dash-map-header { padding: 1.25rem; }
            .dash-map-title { font-size: 1.25rem; }
            .dash-map-subtitle { font-size: 0.88rem; }
            .cell-filter-form { grid-template-columns: 1fr; }
            .dash-map-action-button, .cell-clear-button, #cell-clear-form { width: 100%; }
            .map-actions-primary { display: grid; grid-template-columns: 1fr; }
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
        <h2 style="margin: 0; color: var(--teal-800); font-size: 1.75rem;">Dasbor</h2>
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
            <div class="dash-map-heading">
                <div class="dash-map-title-row">
                    <h2 class="dash-map-title">
                        <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                        Peta Lokasi Sepeda
                    </h2>
                    <span class="map-live-badge">
                        <svg width="18" height="18" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M21 12a9 9 0 0 0-9-9 9.8 9.8 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.8 9.8 0 0 0 6.74-2.74L21 16"/><path d="M16 16h5v5"/></svg>
                        Auto 10 dtk
                    </span>
                </div>
                <p class="dash-map-subtitle">Peta otomatis diperbarui. Klik penanda untuk melihat ringkasan sepeda dan membuka halaman detail.</p>
            </div>
            <div class="map-actions">
                @php
                    $cellDeviceSelectOptions = $cellDeviceOptions
                        ->map(fn ($device) => [
                            'value' => $device->id,
                            'label' => "{$device->name} - {$device->email}",
                        ])
                        ->values();
                    $cellRentalSelectOptions = collect($cellRentalOptions)
                        ->map(fn ($rentalOption) => [
                            'value' => $rentalOption['id'],
                            'label' => $rentalOption['label'],
                            'meta' => "{$rentalOption['observation_count']} data",
                        ])
                        ->values();
                @endphp
                <div class="map-filter-shell">
                    <form method="get" action="{{ route('admin.dashboard') }}" class="cell-filter-form">
                        <x-admin.premium-select
                            name="cell_device_id"
                            id="cell-device-filter"
                            label="Akun Perekam"
                            icon="bike"
                            placeholder="Pilih akun device"
                            hint="Sumber rekaman BTS"
                            :options="$cellDeviceSelectOptions"
                            :selected="$selectedCellDeviceId"
                        />
                        <x-admin.premium-select
                            name="cell_rental_id"
                            id="cell-rental-filter"
                            label="Perjalanan"
                            icon="route"
                            placeholder="Semua perjalanan akun"
                            hint="Sesi pengujian"
                            :options="$cellRentalSelectOptions"
                            :selected="$selectedCellRentalId"
                            :disabled="$selectedCellDeviceId === null"
                        />
                    </form>
                </div>
                <div class="map-actions-primary">
                    <button class="button secondary cell-layer-button dash-map-action-button" type="button" id="cell-layer-toggle">
                        <svg width="18" height="18" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M12 20h.01"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M5 13a10 10 0 0 1 14 0"/><path d="M2 9.5a15 15 0 0 1 20 0"/></svg>
                        <span id="cell-layer-label">BTS ({{ $mapCells->count() }})</span>
                    </button>
                    <form method="post" action="{{ route('admin.dashboard.cell-survey.clear') }}" id="cell-clear-form">
                        @csrf
                        <input type="hidden" name="device_user_id" value="{{ $selectedCellDeviceId }}">
                        <input type="hidden" name="cell_rental_id" value="{{ $selectedCellRentalId }}">
                        <button class="cell-clear-button" type="submit" @disabled($selectedCellDeviceId === null)>
                            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M3 6h18"/><path d="M8 6V4h8v2"/><path d="m19 6-1 14H6L5 6"/><path d="M10 11v5"/><path d="M14 11v5"/></svg>
                            Bersihkan
                        </button>
                    </form>
                    <div class="map-actions-secondary">
                        <button class="button secondary dash-map-action-button" type="button" id="bike-map-center">
                            <svg width="18" height="18" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" viewBox="0 0 24 24"><path d="M12 2v3"/><path d="M12 19v3"/><path d="M2 12h3"/><path d="M19 12h3"/><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/></svg>
                            Pusatkan
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <div id="bike-map-empty" class="map-empty" @if($mapBikes->isNotEmpty() || $mapCells->isNotEmpty()) hidden @endif>
            Belum ada sepeda atau rekaman BTS untuk filter yang dipilih.
        </div>
        <div id="bike-map" class="dash-map-canvas" @if($mapBikes->isEmpty() && $mapCells->isEmpty()) hidden @endif></div>
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
        const cells = @json($mapCells);
        const cellRoute = @json($cellRoute);
        const cellHandovers = @json($cellHandovers);
        const statusLabels = @json($adminStatusLabels);
        const mapElement = document.getElementById('bike-map');
        const mapEmptyElement = document.getElementById('bike-map-empty');
        const mapCenterButton = document.getElementById('bike-map-center');
        const cellLayerToggle = document.getElementById('cell-layer-toggle');
        const cellLayerLabel = document.getElementById('cell-layer-label');
        const cellDeviceFilter = document.getElementById('cell-device-filter');
        const cellRentalFilter = document.getElementById('cell-rental-filter');
        const cellClearForm = document.getElementById('cell-clear-form');
        const cellClearDeviceInput = cellClearForm?.querySelector('input[name="device_user_id"]');
        const cellClearRentalInput = cellClearForm?.querySelector('input[name="cell_rental_id"]');
        const cellClearButton = cellClearForm?.querySelector('.cell-clear-button');
        let selectedCellDeviceId = @json($selectedCellDeviceId);
        let selectedCellRentalId = @json($selectedCellRentalId);
        const mapDataUrl = @json(route('admin.dashboard.map-data'));
        const mapDataRequestUrl = () => {
            const url = new URL(mapDataUrl, window.location.origin);
            if (selectedCellDeviceId) {
                url.searchParams.set('cell_device_id', selectedCellDeviceId);
            }
            if (selectedCellRentalId) {
                url.searchParams.set('cell_rental_id', selectedCellRentalId);
            }

            return url.toString();
        };
        const escapeHtml = (value) => String(value ?? '-')
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#039;');

        if (mapElement && window.L) {
            const map = L.map(mapElement).setView([-8.5830, 116.1160], 14);
            const markers = new Map();
            const cellMarkers = new Map();
            const handoverMarkers = new Map();
            let cellRouteLine = null;
            let cellsVisible = true;
            let hasFittedMap = false;
            let currentBounds = [];
            let latestCells = cells;
            let latestCellRoute = cellRoute;
            let latestCellHandovers = cellHandovers;

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
                    : '<span style="color: #64748b;">Belum ada rental aktif</span>';

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

            const cellIcon = () => L.divIcon({
                className: 'cell-map-marker',
                html: '&#128246;',
                iconSize: [30, 30],
                iconAnchor: [15, 15],
                popupAnchor: [0, -15],
            });

            const handoverIcon = () => L.divIcon({
                className: 'cell-handover-marker',
                html: '&#8644;',
                iconSize: [30, 30],
                iconAnchor: [15, 15],
                popupAnchor: [0, -15],
            });

            const cellPopupHtml = (cell) => {
                const signal = cell.average_signal_dbm === null ? '-' : `${cell.average_signal_dbm} dBm`;
                const rsrp = cell.average_rsrp_dbm === null ? '-' : `${cell.average_rsrp_dbm} dBm`;

                const operatorLabel = cell.operator_label ?? cell.operator_name ?? 'Cell Terdeteksi';

                return `
                    <div class="map-popup">
                        <div class="map-popup-header" style="background: linear-gradient(135deg, #c2410c, #f97316);">
                            <div>
                                <h3 class="map-popup-title">${escapeHtml(operatorLabel)}</h3>
                                <div class="map-popup-subtitle">${escapeHtml(cell.radio_type)} - Cell ${escapeHtml(cell.cell_id)}</div>
                            </div>
                            <span class="badge">Estimasi</span>
                        </div>
                        <div class="map-popup-grid">
                            <div class="map-popup-item">
                                <span class="map-popup-label">MCC/MNC</span>
                                <span class="map-popup-value">${escapeHtml(cell.mcc ?? '-')}/${escapeHtml(cell.mnc ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">SIM Data Aktif</span>
                                <span class="map-popup-value">${escapeHtml(cell.active_data_subscription_id ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Kode Operator</span>
                                <span class="map-popup-value">${escapeHtml(cell.network_operator_code ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">TAC/LAC</span>
                                <span class="map-popup-value">${escapeHtml(cell.tac_or_lac ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">PCI/PSC</span>
                                <span class="map-popup-value">${escapeHtml(cell.pci_or_psc ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Sinyal Rata-rata</span>
                                <span class="map-popup-value">${escapeHtml(signal)}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">RSRP Rata-rata</span>
                                <span class="map-popup-value">${escapeHtml(rsrp)}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Observasi</span>
                                <span class="map-popup-value">${escapeHtml(cell.observation_count)} data</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Sepeda</span>
                                <span class="map-popup-value">${escapeHtml(cell.bike ?? '-')}</span>
                            </div>
                        </div>
                        <div class="map-popup-details">
                            <p><strong>Catatan:</strong> Marker ini hanya dari akun perekam yang dipilih dan merupakan estimasi observasi perangkat, bukan koordinat tower resmi operator.</p>
                            <p><strong>Terakhir terlihat:</strong> ${escapeHtml(cell.last_seen_at ?? '-')}</p>
                        </div>
                    </div>
                `;
            };

            const handoverPopupHtml = (event) => {
                const fromOperator = event.from_operator_label ?? 'Cell awal';
                const toOperator = event.to_operator_label ?? 'Cell baru';
                const signal = event.signal_dbm === null ? '-' : `${event.signal_dbm} dBm`;

                return `
                    <div class="map-popup">
                        <div class="map-popup-header" style="background: linear-gradient(135deg, #1d4ed8, #38bdf8);">
                            <div>
                                <h3 class="map-popup-title">Pindah BTS/Cell</h3>
                                <div class="map-popup-subtitle">${escapeHtml(fromOperator)} &rarr; ${escapeHtml(toOperator)}</div>
                            </div>
                            <span class="badge">Handover</span>
                        </div>
                        <div class="map-popup-grid">
                            <div class="map-popup-item">
                                <span class="map-popup-label">Dari Cell</span>
                                <span class="map-popup-value">${escapeHtml(event.from_radio_type ?? '-')} ${escapeHtml(event.from_cell_id ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Ke Cell</span>
                                <span class="map-popup-value">${escapeHtml(event.to_radio_type ?? '-')} ${escapeHtml(event.to_cell_id ?? '-')}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Sinyal saat pindah</span>
                                <span class="map-popup-value">${escapeHtml(signal)}</span>
                            </div>
                            <div class="map-popup-item">
                                <span class="map-popup-label">Waktu</span>
                                <span class="map-popup-value">${escapeHtml(event.observed_at ?? '-')}</span>
                            </div>
                        </div>
                        <div class="map-popup-details">
                            <p><strong>Catatan:</strong> Titik ini adalah lokasi GPS saat perangkat terdeteksi berpindah dari satu cell ke cell lain dalam perjalanan yang dipilih.</p>
                        </div>
                    </div>
                `;
            };

            const renderCellRoute = (routePoints) => {
                if (cellRouteLine) {
                    map.removeLayer(cellRouteLine);
                    cellRouteLine = null;
                }

                if (routePoints.length < 2) {
                    return;
                }

                const positions = routePoints.map((point) => [point.latitude, point.longitude]);
                cellRouteLine = L.polyline(positions, {
                    color: '#2563eb',
                    weight: 5,
                    opacity: 0.9,
                    lineCap: 'round',
                    lineJoin: 'round',
                    className: 'cell-route-line',
                }).bindPopup(
                    `<div class="map-popup-details"><p><strong>Jalur observasi BTS:</strong> ${escapeHtml(routePoints.length)} titik GPS pada perjalanan yang dipilih.</p></div>`,
                    { autoPan: false, className: 'animated-popup' },
                );

                if (cellsVisible) {
                    cellRouteLine.addTo(map);
                }
            };

            const renderHandovers = (events) => {
                const visibleIds = new Set();

                events.forEach((event) => {
                    const id = String(event.id);
                    const position = [event.latitude, event.longitude];
                    visibleIds.add(id);

                    if (handoverMarkers.has(id)) {
                        handoverMarkers.get(id)
                            .setLatLng(position)
                            .setPopupContent(handoverPopupHtml(event));
                    } else {
                        const marker = L.marker(position, { icon: handoverIcon(), zIndexOffset: 650 }).bindPopup(handoverPopupHtml(event), { autoPan: false, className: 'animated-popup' });
                        handoverMarkers.set(id, marker);
                    }

                    if (cellsVisible && ! map.hasLayer(handoverMarkers.get(id))) {
                        handoverMarkers.get(id).addTo(map);
                    }
                    if (! cellsVisible && map.hasLayer(handoverMarkers.get(id))) {
                        map.removeLayer(handoverMarkers.get(id));
                    }
                });

                handoverMarkers.forEach((marker, id) => {
                    if (! visibleIds.has(id)) {
                        map.removeLayer(marker);
                        handoverMarkers.delete(id);
                    }
                });
            };

            const renderCells = (nextCells) => {
                const visibleIds = new Set();

                nextCells.forEach((cell) => {
                    const id = String(cell.id);
                    const position = [cell.latitude, cell.longitude];
                    visibleIds.add(id);

                    if (cellMarkers.has(id)) {
                        cellMarkers.get(id)
                            .setLatLng(position)
                            .setPopupContent(cellPopupHtml(cell));
                    } else {
                        const marker = L.marker(position, { icon: cellIcon() }).bindPopup(cellPopupHtml(cell), { autoPan: false, className: 'animated-popup' });
                        cellMarkers.set(id, marker);
                    }

                    if (cellsVisible && ! map.hasLayer(cellMarkers.get(id))) {
                        cellMarkers.get(id).addTo(map);
                    }
                    if (! cellsVisible && map.hasLayer(cellMarkers.get(id))) {
                        map.removeLayer(cellMarkers.get(id));
                    }
                });

                cellMarkers.forEach((marker, id) => {
                    if (! visibleIds.has(id)) {
                        map.removeLayer(marker);
                        cellMarkers.delete(id);
                    }
                });

                if (cellLayerLabel) {
                    const handoverCount = latestCellHandovers.length;
                    cellLayerLabel.textContent = handoverCount > 0
                        ? `BTS (${nextCells.length}) / Pindah (${handoverCount})`
                        : `BTS (${nextCells.length})`;
                }
                cellLayerToggle.classList.toggle('active', Boolean(selectedCellDeviceId) && cellsVisible);
                cellLayerToggle.disabled = ! selectedCellDeviceId;
            };

            const renderMapData = (nextBikes, nextCells, nextCellRoute = [], nextCellHandovers = [], fitMap = false) => {
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

                latestCells = nextCells;
                latestCellRoute = nextCellRoute;
                latestCellHandovers = nextCellHandovers;
                renderCellRoute(nextCellRoute);
                renderHandovers(nextCellHandovers);
                renderCells(nextCells);

                nextCellRoute.forEach((point) => bounds.push([point.latitude, point.longitude]));
                nextCells.forEach((cell) => bounds.push([cell.latitude, cell.longitude]));
                nextCellHandovers.forEach((event) => bounds.push([event.latitude, event.longitude]));

                if (nextBikes.length === 0 && bounds.length === 0 && nextCells.length > 0) {
                    nextCells.forEach((cell) => bounds.push([cell.latitude, cell.longitude]));
                }

                const hasMapData = nextBikes.length > 0 || nextCells.length > 0 || nextCellRoute.length > 0 || nextCellHandovers.length > 0;
                mapEmptyElement.hidden = hasMapData;
                mapElement.hidden = ! hasMapData;
                mapCenterButton.disabled = ! hasMapData;
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

            const optionMeta = (option) => option.meta ?? (option.observation_count ? `${option.observation_count} data` : '');

            const setPremiumSelectDisabled = (selectElement, disabled) => {
                const field = selectElement?.closest('[data-premium-select]');
                const trigger = field?.querySelector('.premium-select-trigger');

                if (! selectElement || ! field || ! trigger) {
                    return;
                }

                selectElement.disabled = disabled;
                trigger.disabled = disabled;
                field.classList.toggle('is-disabled', disabled);

                if (disabled && window.closePremiumSelect) {
                    window.closePremiumSelect(field);
                }
            };

            const rebuildPremiumSelectOptions = (selectElement, options, selectedValue = '') => {
                const field = selectElement?.closest('[data-premium-select]');
                const menu = field?.querySelector('.premium-select-menu');

                if (! selectElement || ! field || ! menu) {
                    return;
                }

                selectElement.innerHTML = '';
                menu.innerHTML = '';

                options.forEach((option) => {
                    const value = String(option.value ?? '');
                    const title = String(option.title ?? option.label ?? value);
                    const meta = String(optionMeta(option) ?? '');
                    const label = String(option.label ?? title);
                    const selected = String(selectedValue ?? '') === value;

                    const nativeOption = document.createElement('option');
                    nativeOption.value = value;
                    nativeOption.textContent = meta && ! label.includes(meta) ? `${label} - ${meta}` : label;
                    nativeOption.selected = selected;
                    selectElement.appendChild(nativeOption);

                    const button = document.createElement('button');
                    button.className = 'premium-select-option';
                    button.type = 'button';
                    button.setAttribute('role', 'option');
                    button.setAttribute('aria-selected', selected ? 'true' : 'false');
                    button.dataset.value = value;
                    button.dataset.title = title;
                    button.dataset.meta = meta;

                    const check = document.createElement('span');
                    check.className = 'premium-select-option-check';
                    check.setAttribute('aria-hidden', 'true');
                    check.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="m20 6-11 11-5-5"/></svg>';

                    const copy = document.createElement('span');
                    copy.className = 'premium-select-option-copy';

                    const titleElement = document.createElement('span');
                    titleElement.className = 'premium-select-option-title';
                    titleElement.textContent = title;
                    copy.appendChild(titleElement);

                    if (meta) {
                        const metaElement = document.createElement('span');
                        metaElement.className = 'premium-select-option-meta';
                        metaElement.textContent = meta;
                        copy.appendChild(metaElement);
                    }

                    button.append(check, copy);
                    menu.appendChild(button);
                });

                selectElement.value = String(selectedValue ?? '');
                window.syncPremiumSelect?.(field);
            };

            const updateFilterUrl = () => {
                const url = new URL(window.location.href);
                if (selectedCellDeviceId) {
                    url.searchParams.set('cell_device_id', selectedCellDeviceId);
                } else {
                    url.searchParams.delete('cell_device_id');
                }

                if (selectedCellRentalId) {
                    url.searchParams.set('cell_rental_id', selectedCellRentalId);
                } else {
                    url.searchParams.delete('cell_rental_id');
                }

                window.history.replaceState({}, '', url);
            };

            const updateCellClearState = () => {
                if (cellClearDeviceInput) {
                    cellClearDeviceInput.value = selectedCellDeviceId ?? '';
                }
                if (cellClearRentalInput) {
                    cellClearRentalInput.value = selectedCellRentalId ?? '';
                }
                if (cellClearButton) {
                    cellClearButton.disabled = ! selectedCellDeviceId;
                }
            };

            const updateRentalFilterOptions = (rentalOptions) => {
                const options = [
                    { value: '', label: 'Semua perjalanan akun', title: 'Semua perjalanan akun', meta: '' },
                    ...rentalOptions.map((option) => ({
                        value: option.id,
                        label: option.label,
                        title: option.label,
                        meta: `${option.observation_count ?? 0} data`,
                    })),
                ];

                rebuildPremiumSelectOptions(cellRentalFilter, options, selectedCellRentalId ?? '');
                setPremiumSelectDisabled(cellRentalFilter, ! selectedCellDeviceId);
            };

            const applyDashboardFilters = async ({ updateRentals = false, fitMap = true } = {}) => {
                updateFilterUrl();
                updateCellClearState();

                try {
                    const response = await fetch(mapDataRequestUrl(), { headers: { Accept: 'application/json' } });
                    const payload = await response.json();
                    selectedCellDeviceId = payload.selected_cell_device_id;
                    selectedCellRentalId = payload.selected_cell_rental_id;

                    if (updateRentals) {
                        updateRentalFilterOptions(payload.cell_rental_options ?? []);
                    }

                    renderMapData(payload.data ?? [], payload.cells ?? [], payload.cell_route ?? [], payload.cell_handovers ?? [], fitMap);
                    updateFilterUrl();
                    updateCellClearState();
                } catch (_error) {
                    window.showToast?.('Filter peta gagal', 'Data peta belum bisa diperbarui. Coba lagi sebentar.', 'error');
                }
            };

            const refreshBikes = async () => {
                try {
                    const response = await fetch(mapDataRequestUrl(), { headers: { Accept: 'application/json' } });
                    const payload = await response.json();
                    renderMapData(payload.data ?? [], payload.cells ?? [], payload.cell_route ?? [], payload.cell_handovers ?? []);
                } catch (_error) {
                    return;
                }
            };

            renderMapData(bikes, cells, cellRoute, cellHandovers);

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
            cellLayerToggle?.addEventListener('click', () => {
                cellsVisible = ! cellsVisible;
                renderCellRoute(latestCellRoute);
                renderHandovers(latestCellHandovers);
                renderCells(latestCells);
            });
            cellDeviceFilter?.addEventListener('change', () => {
                selectedCellDeviceId = cellDeviceFilter.value ? Number(cellDeviceFilter.value) : null;
                selectedCellRentalId = null;
                if (cellRentalFilter) {
                    cellRentalFilter.value = '';
                }
                applyDashboardFilters({ updateRentals: true });
            });
            cellRentalFilter?.addEventListener('change', () => {
                selectedCellRentalId = cellRentalFilter.value ? Number(cellRentalFilter.value) : null;
                applyDashboardFilters({ updateRentals: false });
            });
            cellDeviceFilter?.form?.addEventListener('submit', (event) => {
                event.preventDefault();
                selectedCellDeviceId = cellDeviceFilter.value ? Number(cellDeviceFilter.value) : null;
                selectedCellRentalId = cellRentalFilter?.value ? Number(cellRentalFilter.value) : null;
                applyDashboardFilters({ updateRentals: true });
            });
            cellClearForm?.addEventListener('submit', (event) => {
                const scope = selectedCellRentalId ? 'perjalanan yang dipilih' : 'akun device yang dipilih';
                if (! confirm(`Bersihkan rekaman BTS untuk ${scope}? Data lain tidak ikut dihapus.`)) {
                    event.preventDefault();
                }
            });
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
