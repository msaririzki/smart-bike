<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin Smart Bike' }}</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        integrity="sha256-p4NxAoJBhIINfQouMjQkGOpJnIubd9F3PNP6EGGoB1Q=" crossorigin="">
    <style>
        body { margin: 0; font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #f6f7f9; color: #1e293b; line-height: 1.5; }
        header { background: #0f766e; color: white; padding: 16px 24px; display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 16px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
        header .brand { font-size: 20px; font-weight: 700; letter-spacing: -0.5px; margin-right: 24px; display: flex; align-items: center; gap: 8px; }
        header .header-left { display: flex; align-items: center; flex-wrap: wrap; gap: 16px; }
        nav { display: flex; flex-wrap: wrap; gap: 6px; }
        nav a { color: #ccfbf1; padding: 8px 12px; border-radius: 6px; text-decoration: none; font-weight: 500; font-size: 14px; transition: all 0.2s ease; }
        nav a:hover, nav a.active { background: #115e59; color: white; box-shadow: inset 0 2px 4px 0 rgba(0, 0, 0, 0.06); }
        header button.btn-outline { color: white; padding: 8px 16px; background: #115e59; border: 1px solid #134e4a; border-radius: 6px; cursor: pointer; font: inherit; font-size: 14px; font-weight: 500; transition: all 0.2s ease; display: flex; align-items: center; gap: 6px; }
        header button.btn-outline:hover { background: #0d9488; border-color: #ccfbf1; }
        header input::placeholder { color: rgba(255,255,255,0.6); }
        header input:focus { background: rgba(255,255,255,0.2); border-color: rgba(255,255,255,0.4); box-shadow: none; }
        main { max-width: 1200px; margin: 32px auto; padding: 0 20px; width: 100%; box-sizing: border-box; }

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
            nav { display: flex; flex-direction: column; position: fixed; top: 0; right: 0; left: auto; width: 280px; height: 100%; background: rgba(255, 255, 255, 0.9); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px); z-index: 50; padding: 24px; gap: 8px; box-shadow: -4px 0 16px rgba(0,0,0,0.1); transform: translateX(100%); transition: transform 0.3s ease, visibility 0.3s; visibility: hidden; align-items: stretch; overflow-y: auto; }
            nav.open { transform: translateX(0); visibility: visible; }
            nav a { color: #334155; padding: 12px 16px; border-radius: 6px; font-size: 15px; }
            nav a.active { background: #0f766e; color: white; box-shadow: 0 2px 4px rgba(15,118,110,0.2); }
            nav a:hover:not(.active) { background: rgba(15,118,110,0.08); color: #0f766e; }
            .nav-close { display: block; }

            .nav-logout-btn { background: #fef2f2; border: 1px solid #fecaca; color: #dc2626; padding: 12px 16px; margin-top: 16px; }
            .nav-logout-btn:hover { background: #fee2e2; border-color: #fca5a5; }
            .logout-text { display: inline; }
        }
        .card { background: white; border: 1px solid #e2e8f0; border-radius: 8px; padding: 24px; margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03); transition: transform 0.2s ease, box-shadow 0.2s ease; }
        .card:hover { box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.05), 0 4px 6px -2px rgba(0, 0, 0, 0.025); transform: translateY(-2px); }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; }
        .table-responsive { overflow-x: auto; -webkit-overflow-scrolling: touch; margin: 0 -24px; padding: 0 24px; }
        table { width: 100%; border-collapse: collapse; background: white; white-space: nowrap; }
        th { padding: 12px 16px; border-bottom: 2px solid #e2e8f0; text-align: left; font-size: 13px; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; }
        td { padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left; font-size: 14px; color: #334155; }
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
<header>
    <div class="brand">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 18c-.5 0-.9-.2-1.2-.5C3.5 17.2 3.4 16.8 3.5 16.4l2.2-9.9C5.9 5.6 6.7 5 7.6 5h8.8c.9 0 1.7.6 1.9 1.5l2.2 9.9c.1.4 0 .8-.3 1.1-.3.3-.7.5-1.2.5H5z"></path><circle cx="8" cy="18" r="2"></circle><circle cx="16" cy="18" r="2"></circle></svg>
        Smart Bike
    </div>

    @auth
        <div class="header-left" style="flex: 1; margin: 0 24px; max-width: 400px; display: flex;">
            <form action="{{ route('admin.monitoring.index') }}" method="get" style="display: flex; width: 100%; position: relative;">
                <input type="search" name="search" placeholder="Cari sepeda atau pengguna..." style="margin: 0; padding-left: 36px; border-radius: 999px; background: rgba(255,255,255,0.1); border: 1px solid rgba(255,255,255,0.2); color: white; height: 38px;">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="position: absolute; left: 12px; top: 11px; opacity: 0.6;"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            </form>
        </div>

        <button class="menu-toggle" id="menu-btn" aria-label="Buka Menu">
            <svg width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M4 12h16M4 18h16"></path></svg>
        </button>

        <div class="nav-overlay" id="nav-overlay"></div>
        <nav id="nav-menu">
            <button class="nav-close" id="nav-close" aria-label="Tutup Menu">&times;</button>

            <a href="{{ route('admin.dashboard') }}" class="{{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">Dasbor</a>
            <a href="{{ route('admin.monitoring.index') }}" class="{{ request()->routeIs('admin.monitoring.*') ? 'active' : '' }}">Monitoring Sepeda</a>
            <a href="{{ route('admin.bikes.index') }}" class="{{ request()->routeIs('admin.bikes.*') ? 'active' : '' }}">Sepeda</a>
            <a href="{{ route('admin.rentals.index') }}" class="{{ request()->routeIs('admin.rentals.*') && !request()->has('status') ? 'active' : '' }}">Rental</a>
            <a href="{{ route('admin.rentals.index', ['status' => 'running']) }}" class="{{ request()->fullUrlIs('*status=running*') ? 'active' : '' }}">Rental Aktif</a>
            <a href="{{ route('admin.users.index') }}" class="{{ request()->routeIs('admin.users.*') ? 'active' : '' }}">Pengguna</a>
            <a href="{{ route('admin.reports.index') }}" class="{{ request()->routeIs('admin.reports.*') ? 'active' : '' }}">Laporan</a>
            <a href="{{ route('admin.alerts.index') }}" class="{{ request()->routeIs('admin.alerts.*') ? 'active' : '' }}">Peringatan</a>
            @if(auth()->user()->role === 'superadmin')
                <a href="{{ route('admin.settings.edit') }}" class="{{ request()->routeIs('admin.settings.*') ? 'active' : '' }}">Pengaturan</a>
            @endif

            <form method="post" action="{{ route('admin.logout') }}" style="margin: 0; display: contents;">
                @csrf
                <button type="submit" class="nav-logout-btn" title="Keluar">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                    <span class="logout-text">Keluar</span>
                </button>
            </form>
        </nav>
    @endauth
</header>
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
