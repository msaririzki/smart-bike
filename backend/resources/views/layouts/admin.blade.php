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
        :root {
            --teal-800: #115e59;
            --teal-700: #0f766e;
            --teal-600: #0d9488;
            --teal-400: #2dd4bf;
            --gray-50: #f9fafb;
            --gray-100: #f3f4f6;
            --gray-200: #e5e7eb;
            --gray-800: #1f2937;
        }

        body { margin: 0; font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--gray-50); color: var(--gray-800); line-height: 1.5; }

        /* Sidebar Styles */
        .sidebar { position: fixed; top: 0; left: 0; width: 256px; height: 100vh; background: var(--teal-800); color: white; display: flex; flex-direction: column; z-index: 100; transition: transform 0.3s ease; box-shadow: 2px 0 8px rgba(0,0,0,0.1); }
        .sidebar-header { padding: 24px 20px 16px; display: flex; align-items: center; justify-content: space-between; }
        .sidebar-brand { display: flex; align-items: center; text-decoration: none; color: white; font-weight: 700; font-size: 20px; }
        .sidebar-brand img { height: 32px; filter: brightness(0) invert(1); margin-right: 12px; }

        .sidebar-search { padding: 0 20px 16px; }
        .sidebar-search form { position: relative; }
        .sidebar-search input { width: 100%; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: white; border-radius: 8px; padding: 10px 12px 10px 36px; font-size: 14px; box-sizing: border-box; transition: all 0.2s; }
        .sidebar-search input::placeholder { color: rgba(255,255,255,0.6); }
        .sidebar-search input:focus { background: rgba(255,255,255,0.15); border-color: var(--teal-400); outline: none; }
        .sidebar-search svg { position: absolute; left: 12px; top: 50%; transform: translateY(-50%); opacity: 0.6; color: white; pointer-events: none; }

        .sidebar-nav { flex: 1; overflow-y: auto; padding: 0 12px 24px; display: flex; flex-direction: column; gap: 20px; }
        .sidebar-nav::-webkit-scrollbar { width: 6px; }
        .sidebar-nav::-webkit-scrollbar-track { background: transparent; }
        .sidebar-nav::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 10px; }

        .nav-group { display: flex; flex-direction: column; gap: 4px; }
        .nav-group-title { font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em; color: rgba(255,255,255,0.5); margin: 0 0 4px 12px; font-weight: 600; }

        .nav-item { display: flex; align-items: center; gap: 12px; padding: 10px 12px; color: rgba(255,255,255,0.8); text-decoration: none; font-size: 14px; font-weight: 500; border-radius: 8px; transition: all 0.2s; position: relative; border-left: 4px solid transparent; }
        .nav-item:hover { background: rgba(255,255,255,0.1); color: white; }
        .nav-item.active { background: rgba(255,255,255,0.15); color: white; border-left-color: var(--teal-400); font-weight: 600; }

        .sidebar-footer { padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.1); }
        .nav-logout-btn { width: 100%; display: flex; align-items: center; gap: 12px; padding: 10px 12px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: white; border-radius: 8px; font-size: 14px; font-weight: 500; cursor: pointer; transition: all 0.2s; justify-content: center; }
        .nav-logout-btn:hover { background: rgba(220,38,38,0.8); border-color: transparent; }

        /* Mobile Header */
        .mobile-header { display: none; position: fixed; top: 0; left: 0; right: 0; height: 60px; background: var(--teal-800); color: white; align-items: center; justify-content: space-between; padding: 0 16px; z-index: 90; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .mobile-brand { display: flex; align-items: center; gap: 12px; text-decoration: none; color: white; font-weight: 700; }
        .mobile-brand img { height: 24px; filter: brightness(0) invert(1); }
        .menu-toggle { background: transparent; border: none; color: white; cursor: pointer; padding: 4px; }

        /* Main Content Wrapper */
        .main-wrapper { margin-left: 256px; padding: 32px; min-height: 100vh; box-sizing: border-box; width: calc(100% - 256px); }
        .login-wrapper { padding: 32px; min-height: 100vh; box-sizing: border-box; width: 100%; }

        @media (max-width: 1024px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
            .mobile-header { display: flex; }
            .main-wrapper { margin-left: 0; padding: 80px 16px 32px; width: 100%; }
            .login-wrapper { padding: 16px; }
            .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 95; }
            .sidebar-overlay.open { display: block; }
            .sidebar-close-btn { display: block; }
        }
        @media (min-width: 1025px) {
            .sidebar-close-btn { display: none; }
            .sidebar-overlay { display: none !important; }
        }

        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; }

        /* Base styles */
        .card { background: white; border: 1px solid var(--gray-200); border-radius: 8px; padding: 24px; margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); transition: transform 0.2s ease, box-shadow 0.2s ease; }
        .card:hover { box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.025); transform: translateY(-2px); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        
        .table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; margin: 0 -24px; padding: 0 24px; max-height: 70vh; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th { position: sticky; top: 0; background: #ffffff; z-index: 10; padding: 14px 16px; border-bottom: 2px solid var(--gray-200); text-align: left; font-size: 13px; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; box-shadow: 0 2px 2px -1px rgba(0,0,0,0.05); }
        td { padding: 14px 16px; border-bottom: 1px solid var(--gray-100); text-align: left; font-size: 14px; color: #334155; vertical-align: middle; }
        tr:hover td { background-color: var(--gray-50); }
        label { display: block; margin-top: 16px; font-weight: 600; font-size: 14px; color: #334155; }
        input, select, textarea { width: 100%; box-sizing: border-box; padding: 10px 14px; border: 1px solid #cbd5e1; border-radius: 6px; margin-top: 6px; font-family: inherit; font-size: 14px; transition: border-color 0.2s, box-shadow 0.2s; }
        input:focus, select:focus, textarea:focus { outline: none; border-color: var(--teal-700); box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.1); }
        
        @media (max-width: 768px) {
            .table-responsive { margin: 0; padding: 0; overflow-x: visible; }
            .table-responsive table { border: 0; width: 100%; display: block; }
            .table-responsive table thead { border: none; clip: rect(0 0 0 0); height: 1px; margin: -1px; overflow: hidden; padding: 0; position: absolute; width: 1px; }
            .table-responsive table tbody { display: block; width: 100%; }
            .table-responsive table tr { border: 1px solid var(--gray-200); display: block; margin-bottom: 16px; background: white; border-radius: 8px; padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
            .table-responsive table tr:hover td { background-color: transparent; }
            .table-responsive table td { border-bottom: 1px solid var(--gray-100); display: flex; justify-content: space-between; align-items: center; padding: 10px 4px; font-size: 13px; text-align: right; gap: 12px; word-break: break-word; }
            .table-responsive table td::before { content: attr(data-label); font-weight: 600; color: #64748b; text-transform: uppercase; font-size: 10px; text-align: left; max-width: 40%; line-height: 1.2; }
            .table-responsive table td:last-child { border-bottom: 0; }
        }

        .button { display: inline-flex; align-items: center; justify-content: center; gap: 8px; background: var(--teal-700); color: white; padding: 10px 16px; border-radius: 6px; border: none; font-weight: 500; font-size: 14px; text-decoration: none; cursor: pointer; transition: all 0.2s; box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); }
        .button:hover { background: var(--teal-600); box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); transform: translateY(-1px); }
        .button.secondary { background: #f1f5f9; color: #334155; border: 1px solid #cbd5e1; box-shadow: none; }
        .button.secondary:hover { background: var(--gray-200); color: #0f172a; }
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
        .badge.user { color: var(--teal-700); background: #ccfbf1; }
        .badge.device { color: #475569; background: #f1f5f9; }
        .badge.admin { color: #4338ca; background: #e0e7ff; }
        .badge.superadmin { color: #991b1b; background: #fee2e2; }
        .badge.offline { color: #475569; background: #f1f5f9; }
        .badge.maintenance { color: #b91c1c; background: #fee2e2; }
        .badge.reserved { color: #b45309; background: #fef3c7; }

        .stat-card { position: relative; overflow: hidden; border-left: 4px solid var(--teal-700); }
        .stat-card h2 { margin: 8px 0 0; color: var(--teal-700); font-size: 28px; }
        .stat-card .muted { font-weight: 500; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }

        .alert-card { border-left: 4px solid #dc2626; background: #fef2f2; padding: 24px; border-radius: 8px; position: relative; overflow: hidden; }
        .alert-card.warning { border-left-color: #f59e0b; background: #fffbeb; }
        .alert-card h2 { margin: 8px 0 0; color: #991b1b; font-size: 28px; }
        .alert-card.warning h2 { color: #b45309; }
        .alert-card .muted { font-weight: 600; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; color: #b91c1c; display: block; }
        .alert-card.warning .muted { color: #d97706; }

        /* Map Styles */
        .map-header { display: flex; justify-content: space-between; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; }
        .map-actions { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .map-canvas { width: 100%; height: 360px; min-height: 360px; border-radius: 8px; border: 1px solid #dde3ea; background: #eef2f6; position: relative; overflow: hidden; box-sizing: border-box; z-index: 10; }
        .map-canvas[hidden] { display: none; }
        .map-canvas.compact { height: 340px; min-height: 340px; }
        .map-canvas .leaflet-container, .leaflet-container.map-canvas { width: 100%; height: 100%; }
        .leaflet-container { font: inherit; z-index: 10; }
        .leaflet-control-container a { color: #20242a; }
        
        .leaflet-popup { position: absolute; text-align: center; margin-bottom: 20px; }
        .leaflet-popup-content-wrapper { padding: 1px; text-align: left; border-radius: 8px; background: white; box-shadow: 0 8px 24px rgba(15, 23, 42, .18); }
        .leaflet-popup-content { margin: 12px; line-height: 1.35; }
        .leaflet-popup-tip-container { width: 40px; height: 20px; position: absolute; left: 50%; margin-left: -20px; overflow: hidden; pointer-events: none; }
        .leaflet-popup-tip { width: 17px; height: 17px; padding: 1px; margin: -10px auto 0; transform: rotate(45deg); background: white; box-shadow: 0 8px 24px rgba(15, 23, 42, .12); }
        .leaflet-container a.leaflet-popup-close-button { position: absolute; top: 4px; right: 6px; width: 24px; height: 24px; border: 0; text-align: center; text-decoration: none; color: #667085; font: 18px/24px Arial, sans-serif; background: transparent; z-index: 1; }
        
        .map-empty { padding: 36px; text-align: center; border: 1px dashed #cfd8e3; border-radius: 8px; background: #f8fafc; }
        .map-empty[hidden] { display: none; }
        .map-popup { min-width: 260px; }
        .map-popup p { margin: 4px 0; }
        .map-popup a { display: inline-block; margin-top: 8px; color: var(--teal-700); font-weight: 700; }
        
        .bike-map-marker { width: 36px; height: 36px; border-radius: 999px; display: grid; place-items: center; color: white; background: #475467; border: 3px solid white; box-shadow: 0 8px 18px rgba(15, 23, 42, .28); }
        .bike-map-marker.available { background: var(--teal-700); }
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
        .map-popup-battery span { display: block; height: 100%; background: var(--teal-700); }
        .map-popup-battery.low span { background: #dc2626; }
        .map-popup-footer { display: flex; justify-content: space-between; gap: 8px; align-items: center; border-top: 1px solid #e6ebf0; padding-top: 9px; margin-top: 9px; }
        .map-popup-footer a { margin-top: 0; }
        @media (max-width: 640px) {
            .map-canvas, .map-canvas.compact { height: 300px; min-height: 300px; }
            .map-popup-grid { grid-template-columns: 1fr; }
        }
        .muted { color: #667085; }
        .error { color: #b42318; }

        /* Pagination Styles */
        .pagination { display: flex; padding-left: 0; list-style: none; justify-content: center; margin-top: 1.5rem; margin-bottom: 0; gap: 0.25rem; }
        .page-link { position: relative; display: flex; align-items: center; justify-content: center; padding: 0.5rem 0.75rem; min-width: 36px; height: 36px; color: var(--teal-700); text-decoration: none; background-color: #fff; border: 1px solid #e2e8f0; border-radius: 0.375rem; font-size: 0.875rem; font-weight: 600; transition: all 0.2s; }
        .page-link:hover { z-index: 2; color: #0f172a; background-color: #f8fafc; border-color: #cbd5e1; }
        .page-item.active .page-link { z-index: 3; color: #fff; background-color: var(--teal-700); border-color: var(--teal-700); }
        .page-item.disabled .page-link { color: #94a3b8; pointer-events: none; background-color: #f8fafc; border-color: #e2e8f0; }
        .page-link svg { width: 1.25rem; height: 1.25rem; }
        .d-flex.justify-content-between.flex-fill { display: flex; justify-content: space-between; align-items: center; width: 100%; gap: 1rem; margin-top: 1.5rem; }
        .d-none.flex-sm-fill.d-sm-flex.align-items-sm-center.justify-content-sm-between { display: flex; justify-content: space-between; align-items: center; width: 100%; margin-top: 1.5rem; flex-wrap: wrap; gap: 1rem; }
        p.small.text-muted { margin: 0; font-size: 0.875rem; color: #64748b; }

        /* Toasts */
        #toast-container { position: fixed; bottom: 24px; right: 24px; z-index: 9999; display: flex; flex-direction: column; gap: 12px; }
        .toast { background: white; border-radius: 8px; padding: 16px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); border-left: 4px solid var(--teal-700); min-width: 250px; transform: translateX(150%); transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1); }
        .toast.show { transform: translateX(0); }
        .toast.error { border-left-color: #ef4444; }
        .toast.warning { border-left-color: #f59e0b; }
        .toast-title { font-weight: 600; font-size: 14px; margin: 0 0 4px; color: #0f172a; }
        .toast-message { font-size: 13px; color: #64748b; margin: 0; }
    </style>
</head>
<body>

@unless(request()->routeIs('admin.login'))
    <!-- Mobile Header -->
    <header class="mobile-header">
        <a href="{{ route('admin.dashboard') }}" class="mobile-brand">
            <img src="{{ asset('images/flowbike-logo-landscape.png') }}" alt="FlowBike" style="height: 28px;">
        </a>
        <button class="menu-toggle" id="mobile-menu-btn" aria-label="Buka Menu">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
        </button>
    </header>

    <div class="sidebar-overlay" id="sidebar-overlay"></div>

    <!-- Sidebar -->
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-header">
            <a href="{{ route('admin.dashboard') }}" class="sidebar-brand">
                <img src="{{ asset('images/flowbike-logo-landscape.png') }}" alt="FlowBike">
            </a>
            <button class="sidebar-close-btn menu-toggle" id="sidebar-close-btn" aria-label="Tutup Menu">
                <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
        </div>

        @auth
        <div class="sidebar-search">
            <form action="{{ route('admin.search') }}" method="get">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                <input type="search" name="search" placeholder="Cari..." value="{{ request()->routeIs('admin.search') ? request('search') : '' }}">
            </form>
        </div>

        <nav class="sidebar-nav">
            <!-- Group 1: Dashboard -->
            <div class="nav-group">
                <a href="{{ route('admin.dashboard') }}" class="nav-item {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="9"></rect><rect x="14" y="3" width="7" height="5"></rect><rect x="14" y="12" width="7" height="9"></rect><rect x="3" y="16" width="7" height="5"></rect></svg>
                    Dasbor
                </a>
            </div>

            <!-- Group 2: Operasional Sepeda -->
            <div class="nav-group">
                <div class="nav-group-title">Operasional Sepeda</div>
                <a href="{{ route('admin.monitoring.index') }}" class="nav-item {{ request()->routeIs('admin.monitoring.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="3 6 9 3 15 6 21 3 21 18 15 21 9 18 3 21"></polygon><line x1="9" y1="3" x2="9" y2="21"></line><line x1="15" y1="3" x2="15" y2="21"></line></svg>
                    Monitoring
                </a>
                <a href="{{ route('admin.bikes.index') }}" class="nav-item {{ request()->routeIs('admin.bikes.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="5.5" cy="17.5" r="3.5"></circle><circle cx="18.5" cy="17.5" r="3.5"></circle><path d="M15 6a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-3 11.5V14l-3-3 4-3 2 3h2"></path></svg>
                    Data Sepeda
                </a>
            </div>

            <!-- Group 3: Manajemen Pengguna -->
            <div class="nav-group">
                <div class="nav-group-title">Manajemen Pengguna</div>
                <a href="{{ route('admin.users.index') }}" class="nav-item {{ request()->routeIs('admin.users.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
                    Manajemen User
                </a>
            </div>

            <!-- Group 4: Keamanan & Akses -->
            <div class="nav-group">
                <div class="nav-group-title">Keamanan & Akses</div>
                <a href="{{ Route::has('admin.settings.edit') ? route('admin.settings.edit') : url('/admin/settings') }}" class="nav-item {{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
                    Roles & Permissions
                </a>
            </div>

            <!-- Group 5: Analitik -->
            <div class="nav-group">
                <div class="nav-group-title">Analitik</div>
                <a href="{{ route('admin.rentals.index') }}" class="nav-item {{ request()->routeIs('admin.rentals.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline></svg>
                    Riwayat Rental
                </a>
                <a href="{{ route('admin.reports.index') }}" class="nav-item {{ request()->routeIs('admin.reports.*') || request()->routeIs('admin.alerts.*') ? 'active' : '' }}">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="20" x2="12" y2="10"></line><line x1="18" y1="20" x2="18" y2="4"></line><line x1="6" y1="20" x2="6" y2="16"></line></svg>
                    Pendapatan
                </a>
            </div>
        </nav>

        <div class="sidebar-footer">
            <form method="post" action="{{ route('admin.logout') }}" style="margin: 0;" class="logout-form">
                @csrf
                <button type="submit" class="nav-logout-btn" title="Keluar">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    Keluar Sistem
                </button>
            </form>
        </div>
        @endauth
    </aside>
@endunless

<div id="logout-modal" class="modal-overlay">
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
        const mobileMenuBtn = document.getElementById('mobile-menu-btn');
        const sidebarCloseBtn = document.getElementById('sidebar-close-btn');
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('sidebar-overlay');

        if (mobileMenuBtn && sidebar && overlay) {
            const openSidebar = () => {
                sidebar.classList.add('open');
                overlay.classList.add('open');
                document.body.style.overflow = 'hidden';
            };

            const closeSidebar = () => {
                sidebar.classList.remove('open');
                overlay.classList.remove('open');
                document.body.style.overflow = '';
            };

            mobileMenuBtn.addEventListener('click', openSidebar);
            if (sidebarCloseBtn) sidebarCloseBtn.addEventListener('click', closeSidebar);
            overlay.addEventListener('click', closeSidebar);
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
                });
            });

            const closeLogoutModal = () => {
                logoutModal.style.display = 'none';
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

<main class="{{ request()->routeIs('admin.login') ? 'login-wrapper' : 'main-wrapper' }}">
    <div id="toast-container"></div>
    @if(session('status'))
        <div class="toast show" style="position: static; transform: none; margin-bottom: 24px; border-left-color: var(--teal-700);">
            <h4 class="toast-title">Sukses</h4>
            <p class="toast-message">{{ session('status') }}</p>
        </div>
    @endif
    @yield('content')
</main>
</body>
</html>
