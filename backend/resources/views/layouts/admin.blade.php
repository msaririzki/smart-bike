<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin FlowBike' }}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="icon" type="image/png" href="{{ asset('images/flowbike-logo-square.png') }}">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        integrity="sha256-p4NxAoJBhIINfQouMjQkGOpJnIubd9F3PNP6EGGoB1Q=" crossorigin="">
    <style>
        body { margin: 0; font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f6f7f9; color: #1e293b; line-height: 1.5; }
        header { background: #0f766e; color: white; padding: 12px 32px; display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 16px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); width: 100%; box-sizing: border-box; }
        header .brand { font-size: 20px; font-weight: 700; letter-spacing: -0.5px; margin-right: 24px; display: flex; align-items: center; gap: 8px; white-space: nowrap; }
        header .header-left { display: flex; align-items: center; flex-wrap: wrap; gap: 16px; }
        nav { display: flex; flex-wrap: wrap; gap: 16px; align-items: center; }
        .nav-item { display: flex; align-items: center; gap: 8px; color: #ccfbf1; padding: 8px 12px; border-radius: 6px; text-decoration: none; font-weight: 500; font-size: 14px; transition: all 0.2s ease; cursor: pointer; }
        .nav-item:hover, .nav-item.active { background: #115e59; color: white; box-shadow: inset 0 2px 4px 0 rgba(0, 0, 0, 0.06); }
        .nav-dropdown { position: relative; }
        .dropdown-menu { display: none; position: absolute; top: 100%; right: 0; background: white; min-width: 220px; border-radius: 8px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -2px rgba(0,0,0,0.05); padding: 8px; z-index: 50; flex-direction: column; gap: 4px; margin-top: 8px; }
        .nav-dropdown:hover .dropdown-menu { display: flex; }
        .dropdown-menu a { color: #334155; padding: 10px 12px; border-radius: 6px; font-weight: 500; font-size: 14px; display: flex; align-items: center; gap: 10px; text-decoration: none; transition: background 0.2s; }
        .dropdown-menu a:hover, .dropdown-menu a.active { background: #f1f5f9; color: #0f766e; box-shadow: none; }

        header input::placeholder { color: rgba(255,255,255,0.6); }
        header input:focus { border-bottom-color: white; box-shadow: none; background: transparent; }
        main { max-width: 100%; margin: 32px auto; padding: 0 32px; box-sizing: border-box; }

        /* Toasts */
        #toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; display: flex; flex-direction: column; gap: 12px; }
        .toast { background: white; border-radius: 8px; padding: 16px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); border-left: 4px solid #0f766e; min-width: 250px; transform: translateX(150%); transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
        .toast.show { transform: translateX(0); }
        .toast.error { border-left-color: #ef4444; }
        .toast.warning { border-left-color: #f59e0b; }
        .toast-title { font-weight: 600; font-size: 14px; margin: 0 0 4px; color: #0f172a; }
        .toast-message { font-size: 13px; color: #64748b; margin: 0; }
        /* Navbar Responsif & Glassmorphism */
        .menu-toggle { display: none; background: transparent; border: none; color: white; cursor: pointer; padding: 6px; border-radius: 4px; box-shadow: none; margin-left: auto; }
        .menu-toggle:hover { background: #115e59; }
        .nav-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 40; opacity: 0; transition: opacity 0.3s ease; }
        .nav-overlay.open { display: block; opacity: 1; }
        .nav-close { display: none; background: transparent; border: none; color: #64748b; font-size: 28px; line-height: 1; cursor: pointer; align-self: flex-end; margin-bottom: 16px; padding: 4px; transition: color 0.2s; }
        .nav-close:hover { color: #0f172a; }

        .nav-logout-btn { background: transparent; border: 1px solid rgba(255,255,255,0.4); color: white; padding: 8px; border-radius: 6px; display: flex; align-items: center; justify-content: center; gap: 6px; cursor: pointer; transition: all 0.2s; font: inherit; font-size: 14px; font-weight: 500; }
        .nav-logout-btn:hover { background: rgba(255,255,255,0.1); border-color: white; }

        @media (min-width: 901px) {
            .logout-text { display: none; }
            nav { align-items: center; }
            header .brand { margin-right: auto; }
        }

        @media (max-width: 900px) {
            .menu-toggle { display: block; }
            nav { display: flex; flex-direction: column; position: fixed; top: 0; right: 0; left: auto; width: 300px; height: 100%; background: rgba(255, 255, 255, 0.95); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); z-index: 50; padding: 24px; gap: 8px; box-shadow: -4px 0 16px rgba(0,0,0,0.1); transform: translateX(100%); transition: transform 0.3s ease, visibility 0.3s; visibility: hidden; align-items: stretch; overflow-y: auto; }
            nav.open { transform: translateX(0); visibility: visible; }
            .nav-item { color: #334155; padding: 12px 16px; border-radius: 6px; font-size: 15px; }
            .nav-item.active { background: #0f766e; color: white; box-shadow: 0 2px 4px rgba(15,118,110,0.2); }
            .nav-item:hover:not(.active) { background: rgba(15,118,110,0.08); color: #0f766e; box-shadow: none; }
            .nav-close { display: block; }

            .nav-dropdown:hover .dropdown-menu { display: none; }
            .dropdown-menu { position: static; box-shadow: none; background: transparent; padding: 0 0 0 16px; margin-top: 4px; display: none; border-left: 2px solid #e2e8f0; margin-left: 16px; border-radius: 0; }
            .dropdown-menu.open { display: flex; }
            .dropdown-menu a { color: #475569; padding: 10px 12px; }
            .dropdown-menu a:hover, .dropdown-menu a.active { background: rgba(15,118,110,0.08); color: #0f766e; }

            .nav-logout-btn { background: #fef2f2; border: 1px solid #fecaca; color: #dc2626; padding: 12px 16px; margin-top: 16px; width: 100%; }
            .nav-logout-btn:hover { background: #fee2e2; border-color: #fca5a5; }
            .logout-text { display: inline; }
        }
        @media (max-width: 768px) {
            .table-responsive { margin: 0; padding: 0; overflow-x: visible; }
            .table-responsive table { border: 0; width: 100%; display: block; }
            .table-responsive table thead { border: none; clip: rect(0 0 0 0); height: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute; width: 1px; }
            .table-responsive table tbody { display: block; width: 100%; }
            .table-responsive table tr { border: 1px solid #e2e8f0; display: block; margin-bottom: 16px; background: white; border-radius: 8px; padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
            .table-responsive table tr:hover td { background-color: transparent; }
            .table-responsive table td { border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; padding: 10px 4px; font-size: 13px; text-align: right; gap: 12px; word-break: break-word; }
            .table-responsive table td::before { content: attr(data-label); font-weight: 600; color: #64748b; text-transform: uppercase; font-size: 10px; text-align: left; max-width: 40%; line-height: 1.2; }
            .table-responsive table td:last-child { border-bottom: 0; }
        }
        .card { background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 24px; margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); transition: transform 0.2s ease, box-shadow 0.2s ease; }
        .card:hover { box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.025); transform: translateY(-2px); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; margin: 0 -24px; padding: 0 24px; max-height: 70vh; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th { position: sticky; top: 0; background: #ffffff; z-index: 10; padding: 14px 16px; border-bottom: 2px solid #e2e8f0; text-align: left; font-size: 13px; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 2px 2px -1px rgba(0,0,0,0.05); }
        td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left; font-size: 14px; color: #334155; vertical-align: middle; }
        tr:hover td { background-color: #f8fafc; }
        label { display: block; margin-top: 16px; font-weight: 600; font-size: 14px; color: #334155; }
        input, select, textarea { width: 100%; box-sizing: border-box; padding: 10px 14px; border: 1px solid #cbd5e1; border-radius: 6px; margin-top: 6px; font-family: inherit; font-size: 14px; transition: border-color 0.2s, box-shadow 0.2s; }
        input:focus, select:focus, textarea:focus { outline: none; border-color: #0f766e; box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.1); }
        .button { display: inline-flex; align-items: center; justify-content: center; gap: 8px; background: #0f766e; color: white; padding: 10px 16px; border-radius: 6px; border: none; font-weight: 500; font-size: 14px; text-decoration: none; cursor: pointer; transition: all 0.2s; box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }
        .button:hover { background: #0d9488; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); transform: translateY(-1px); }
        .button.secondary { background: #f1f5f9; color: #334155; border: 1px solid #cbd5e1; box-shadow: none; }
        .button.secondary:hover { background: #e2e8f0; color: #0f172a; }
        .button:disabled { opacity: .55; cursor: not-allowed; transform: none; box-shadow: none; }
        .toolbar { display: flex; gap: 10px; align-items: end; flex-wrap: wrap; margin-bottom: 16px; }
        .toolbar label { margin-top: 0; min-width: 180px; }
        .toolbar .actions { display: flex; gap: 8px; margin-top: 5px; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 999px; font-size: 12px; font-weight: 700; line-height: 1; }
        .badge.available { color: #047857; background: #d1fae5; }
        .badge.in_use, .badge.idle { color: #1d4ed8; background: #dbeafe; }
        .badge.active, .badge.idle_warning, .badge.idle_billing { color: #1d4ed8; background: #dbeafe; }
        .badge.completed { color: #047857; background: #d1fae5; }
        .badge.cancelled { color: #b91c1c; background: #fee2e2; }
        .badge.user { color: #0f766e; background: #ccfbf1; }
        .badge.device { color: #475569; background: #f1f5f9; }
        .badge.admin { color: #4338ca; background: #e0e7ff; }
        .badge.superadmin { color: #991b1b; background: #fee2e2; }
        .badge.offline { color: #475569; background: #f1f5f9; }
        .badge.maintenance { color: #b91c1c; background: #fee2e2; }
        .badge.reserved { color: #b45309; background: #fef3c7; }

        .stat-card { position: relative; overflow: hidden; border-left: 4px solid #0f766e; }
        .stat-card h2 { margin: 8px 0 0; color: #0f766e; font-size: 28px; }
        .stat-card .muted { font-weight: 500; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }

        .alert-card { border-left: 4px solid #dc2626; background: #fef2f2; padding: 24px; border-radius: 8px; position: relative; overflow: hidden; }
        .alert-card.warning { border-left-color: #f59e0b; background: #fffbeb; }
        .alert-card h2 { margin: 8px 0 0; color: #991b1b; font-size: 28px; }
        .alert-card.warning h2 { color: #b45309; }
        .alert-card .muted { font-weight: 600; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; color: #b91c1c; display: block; }
        .alert-card.warning .muted { color: #d97706; }
        .map-header { display: flex; justify-content: space-between; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; }
        .map-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .map-canvas { width: 100%; height: 360px; min-height: 360px; border-radius: 8px; border: 1px solid #dde3ea; background: #eef2f6; position: relative; overflow: hidden; box-sizing: border-box; }
        .map-canvas[hidden] { display: none; }
        .map-canvas.compact { height: 340px; min-height: 340px; }
        .map-canvas .leaflet-container, .leaflet-container.map-canvas { width: 100%; height: 100%; }
        .leaflet-container { font: inherit; }
        .leaflet-control-container a { color: #20242a; }
        .leaflet-container { overflow: hidden; position: relative; z-index: 0; }
        .leaflet-pane,
        .leaflet-tile,
        .leaflet-marker-icon,
        .leaflet-marker-shadow,
        .leaflet-tile-container,
        .leaflet-pane > svg,
        .leaflet-pane > canvas,
        .leaflet-zoom-box,
        .leaflet-image-layer,
        .leaflet-layer { position: absolute; left: 0; top: 0; }
        .leaflet-tile { border: 0; user-select: none; }
        .leaflet-marker-icon,
        .leaflet-marker-shadow { display: block; }
        .leaflet-tile-pane { z-index: 200; }
        .leaflet-overlay-pane { z-index: 400; }
        .leaflet-shadow-pane { z-index: 500; }
        .leaflet-marker-pane { z-index: 600; }
        .leaflet-tooltip-pane { z-index: 650; }
        .leaflet-popup-pane { z-index: 700; }
        .leaflet-popup { position: absolute; text-align: center; margin-bottom: 20px; }
        .leaflet-popup-content-wrapper { padding: 1px; text-align: left; border-radius: 8px; background: white; box-shadow: 0 8px 24px rgba(15, 23, 42, .18); }
        .leaflet-popup-content { margin: 12px; line-height: 1.35; }
        .leaflet-popup-tip-container { width: 40px; height: 20px; position: absolute; left: 50%; margin-left: -20px; overflow: hidden; pointer-events: none; }
        .leaflet-popup-tip { width: 17px; height: 17px; padding: 1px; margin: -10px auto 0; transform: rotate(45deg); background: white; box-shadow: 0 8px 24px rgba(15, 23, 42, .12); }
        .leaflet-container a.leaflet-popup-close-button { position: absolute; top: 4px; right: 6px; width: 24px; height: 24px; border: 0; text-align: center; text-decoration: none; color: #667085; font: 18px/24px Arial, sans-serif; background: transparent; z-index: 1; }
        .leaflet-container a.leaflet-popup-close-button:hover { color: #20242a; }
        .map-empty { padding: 36px; text-align: center; border: 1px dashed #cfd8e3; border-radius: 8px; background: #f8fafc; }
        .map-empty[hidden] { display: none; }
        .map-popup { min-width: 260px; }
        .map-popup p { margin: 4px 0; }
        .map-popup a { display: inline-block; margin-top: 8px; color: #0f766e; font-weight: 700; }
        .bike-map-marker { width: 36px; height: 36px; border-radius: 999px; display: grid; place-items: center; color: white; background: #475467; border: 3px solid white; box-shadow: 0 8px 18px rgba(15, 23, 42, .28); }
        .bike-map-marker.available { background: #0f766e; }
        .bike-map-marker.in_use, .bike-map-marker.idle { background: #2563eb; }
        .bike-map-marker.offline { background: #475467; }
        .bike-map-marker.maintenance { background: #dc2626; }
        .bike-map-marker-symbol { font-size: 19px; line-height: 1; transform: translateY(-1px); }
        .map-popup-header { display: flex; justify-content: space-between; gap: 10px; align-items: flex-start; margin-bottom: 10px; }
        .map-popup-title { margin: 0; font-size: 16px; line-height: 1.25; }
        .map-popup-subtitle { margin-top: 2px; color: #667085; font-size: 12px; }
        .map-popup-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin: 10px 0; }
        .map-popup-item { border: 1px solid #e6ebf0; border-radius: 6px; padding: 8px; background: #f8fafc; }
        .map-popup-label { display: block; color: #667085; font-size: 11px; margin-bottom: 3px; }
        .map-popup-value { display: block; color: #20242a; font-weight: 700; font-size: 13px; }
        .map-popup-battery { height: 7px; border-radius: 999px; background: #e6ebf0; overflow: hidden; margin-top: 5px; }
        .map-popup-battery span { display: block; height: 100%; background: #0f766e; }
        .map-popup-battery.low span { background: #dc2626; }
        .map-popup-footer { display: flex; justify-content: space-between; gap: 8px; align-items: center; border-top: 1px solid #e6ebf0; padding-top: 9px; margin-top: 9px; }
        .map-popup-footer a { margin-top: 0; }
        @media (max-width: 640px) {
            .map-canvas, .map-canvas.compact { height: 300px; min-height: 300px; }
            .map-popup-grid { grid-template-columns: 1fr; }
        }
        .muted { color: #667085; }
        .error { color: #b42318; }
        .success { color: #027a48; }
    </style>
</head>
<body>
@unless(request()->routeIs('admin.login'))
<header>
    <div style="display: flex; align-items: center; gap: 16px; flex: 1;">
        <a href="{{ route('admin.dashboard') }}" class="brand" style="text-decoration: none; color: inherit;">
            <img src="{{ asset('images/flowbike-logo-landscape.png') }}" alt="FlowBike" style="height: 32px; width: auto; filter: brightness(0) invert(1);">
        </a>

        @auth
        <form action="{{ route('admin.monitoring.index') }}" method="get" style="display: flex; align-items: center; position: relative; max-width: 320px; width: 100%;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="position: absolute; left: 0; top: 11px; opacity: 0.6;"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            <input type="search" name="search" placeholder="Cari..." style="margin: 0; padding-left: 28px; background: transparent; border: none; border-bottom: 1px solid rgba(255,255,255,0.4); border-radius: 0; color: white; height: 38px; width: 100%; box-shadow: none; font-size: 14px;">
        </form>
        @endauth
    </div>

    @auth
        <button class="menu-toggle" id="menu-btn" aria-label="Buka Menu">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"></path></svg>
        </button>

        <div class="nav-overlay" id="nav-overlay"></div>
        <nav id="nav-menu">
            <button class="nav-close" id="nav-close" aria-label="Tutup Menu">&times;</button>

            <a href="{{ route('admin.dashboard') }}" class="nav-item {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg> Dasbor
            </a>

            <a href="{{ route('admin.monitoring.index') }}" class="nav-item {{ request()->routeIs('admin.monitoring.*') ? 'active' : '' }}">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path><circle cx="12" cy="10" r="3"></circle></svg> Monitoring
            </a>

            <a href="{{ route('admin.rentals.index') }}" class="nav-item {{ request()->routeIs('admin.rentals.*') && !request()->has('status') ? 'active' : '' }}">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg> Rental
            </a>

            <!-- Dropdown Analitik -->
            @php
                $isAnalyticActive = request()->routeIs('admin.reports.*') || request()->routeIs('admin.alerts.*');
            @endphp
            <div class="nav-dropdown">
                <button class="nav-item {{ $isAnalyticActive ? 'active' : '' }}" id="analytic-btn" style="background:transparent; border:none; width:100%; text-align:left;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line></svg> Analitik
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-left:auto;"><polyline points="6 9 12 15 18 9"></polyline></svg>
                </button>
                <div class="dropdown-menu" id="analytic-menu">
                    <a href="{{ route('admin.reports.index') }}" class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><path d="M21 12H3"></path><path d="M12 21V3"></path></svg> Laporan
                    </a>
                    <a href="{{ route('admin.alerts.index') }}" class="{{ request()->routeIs('admin.alerts.*') ? 'active' : '' }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg> Peringatan
                    </a>
                </div>
            </div>

            <!-- Dropdown Manajemen -->
            @php
                $isManagementActive = request()->routeIs('admin.bikes.*') || request()->routeIs('admin.users.*') || request()->routeIs('admin.settings.*');
            @endphp
            <div class="nav-dropdown">
                <button class="nav-item {{ $isManagementActive ? 'active' : '' }}" id="management-btn" style="background:transparent; border:none; width:100%; text-align:left;">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg> Manajemen
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-left:auto;"><polyline points="6 9 12 15 18 9"></polyline></svg>
                </button>
                <div class="dropdown-menu" id="management-menu">
                    <a href="{{ route('admin.bikes.index') }}" class="{{ request()->routeIs('admin.bikes.*') ? 'active' : '' }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><circle cx="12" cy="12" r="3"></circle></svg> Data Sepeda
                    </a>
                    <a href="{{ route('admin.users.index') }}" class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg> Pengguna
                    </a>
                    @if(auth()->user()->role === 'superadmin')
                    <a href="{{ route('admin.settings.edit') }}" class="{{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg> Pengaturan Sistem
                    </a>
                    @endif
                </div>
            </div>

            <form method="post" action="{{ route('admin.logout') }}" style="margin: 0; display: flex; align-items: center;" class="logout-form">
                @csrf
                <button type="submit" class="nav-logout-btn" title="Keluar">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    <span class="logout-text">Keluar</span>
                </button>
            </form>
        </nav>
    @endauth
</header>
@endunless

<div id="logout-modal" class="nav-overlay" style="z-index: 1000; display: none; align-items: center; justify-content: center;">
    <div style="background: white; padding: 24px; border-radius: 12px; max-width: 320px; width: 90%; text-align: center; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1);">
        <div style="width: 48px; height: 48px; border-radius: 50%; background: #fee2e2; color: #dc2626; display: flex; align-items: center; justify-content: center; margin: 0 auto 16px;">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
        </div>
        <h3 style="margin: 0 0 8px; font-size: 18px; color: #0f172a;">Yakin ingin keluar?</h3>
        <p style="margin: 0 0 24px; color: #64748b; font-size: 14px;">Sesi Anda akan diakhiri dan Anda harus masuk kembali untuk mengakses Dasbor.</p>
        <div style="display: flex; gap: 12px;">
            <button type="button" id="btn-cancel-logout" class="button secondary" style="flex: 1; justify-content: center; padding: 10px;">Batal</button>
            <button type="button" id="btn-confirm-logout" class="button" style="flex: 1; justify-content: center; background: #dc2626; padding: 10px;">Ya, Keluar</button>
        </div>
    </div>
</div>

<script>
    document.addEventListener('DOMContentLoaded', () => {
        const menuBtn = document.getElementById('menu-btn');
        const closeBtn = document.getElementById('nav-close');
        const overlay = document.getElementById('nav-overlay');
        const nav = document.getElementById('nav-menu');

        if (menuBtn && nav && overlay) {
            const openMenu = () => {
                nav.classList.add('open');
                overlay.classList.add('open');
                document.body.style.overflow = 'hidden';
            };

            const closeMenu = () => {
                nav.classList.remove('open');
                overlay.classList.remove('open');
                document.body.style.overflow = '';
            };

            menuBtn.addEventListener('click', openMenu);
            closeBtn.addEventListener('click', closeMenu);
            overlay.addEventListener('click', closeMenu);
        }

        // Mobile dropdown logic
        const mgtBtn = document.getElementById('management-btn');
        const mgtMenu = document.getElementById('management-menu');
        const anBtn = document.getElementById('analytic-btn');
        const anMenu = document.getElementById('analytic-menu');

        if (mgtBtn && mgtMenu) {
            mgtBtn.addEventListener('click', (e) => {
                if(window.innerWidth <= 900) { e.preventDefault(); mgtMenu.classList.toggle('open'); }
            });
        }
        if (anBtn && anMenu) {
            anBtn.addEventListener('click', (e) => {
                if(window.innerWidth <= 900) { e.preventDefault(); anMenu.classList.toggle('open'); }
            });
        }

        // Auto-inject data-label for responsive tables
        document.querySelectorAll('.table-responsive table').forEach(table => {
            const headers = Array.from(table.querySelectorAll('thead th')).map(th => th.innerText.trim());
            table.querySelectorAll('tbody tr').forEach(tr => {
                Array.from(tr.querySelectorAll('td')).forEach((td, i) => {
                    if (headers[i]) {
                        td.setAttribute('data-label', headers[i]);
                    }
                });
            });
        });

        // Logout Confirmation Logic
        const logoutForms = document.querySelectorAll('.logout-form');
        const logoutModal = document.getElementById('logout-modal');
        const btnCancelLogout = document.getElementById('btn-cancel-logout');
        const btnConfirmLogout = document.getElementById('btn-confirm-logout');
        let currentLogoutForm = null;

        if (logoutModal && btnCancelLogout && btnConfirmLogout) {
            logoutForms.forEach(form => {
                form.addEventListener('submit', (e) => {
                    e.preventDefault();
                    currentLogoutForm = form;
                    logoutModal.style.display = 'flex';
                    requestAnimationFrame(() => logoutModal.classList.add('open'));
                });
            });

            const closeLogoutModal = () => {
                logoutModal.classList.remove('open');
                setTimeout(() => { logoutModal.style.display = 'none'; }, 300);
                currentLogoutForm = null;
            };

            btnCancelLogout.addEventListener('click', closeLogoutModal);
            logoutModal.addEventListener('click', (e) => {
                if (e.target === logoutModal) closeLogoutModal();
            });

            btnConfirmLogout.addEventListener('click', () => {
                if (currentLogoutForm) {
                    currentLogoutForm.submit();
                }
            });
        }
    });

    // Global Toast Function
    window.showToast = function(title, message, type = 'info') {
        const container = document.getElementById('toast-container');
        if (!container) return;
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `<h4 class="toast-title">${title}</h4><p class="toast-message">${message}</p>`;
        container.appendChild(toast);
        // Animate in
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                toast.classList.add('show');
            });
        });
        // Remove after 5s
        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => toast.remove(), 300);
        }, 5000);
    }
</script>
<main>
    <div id="toast-container"></div>
    @if(session('status'))
        <p class="success">{{ session('status') }}</p>
    @endif
    @yield('content')
</main>
</body>
</html>
