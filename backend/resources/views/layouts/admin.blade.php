<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Admin Smart Bike' }}</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        integrity="sha256-p4NxAoJBhIINfQouMjQkGOpJnIubd9F3PNP6EGGoB1Q=" crossorigin="">
    <style>
        body { margin: 0; font-family: Arial, sans-serif; background: #f6f7f9; color: #20242a; }
        header { background: #164e63; color: white; padding: 14px 24px; display: flex; justify-content: space-between; align-items: center; }
        nav a, header button { color: white; margin-right: 16px; background: transparent; border: 0; cursor: pointer; font: inherit; text-decoration: none; }
        main { max-width: 1120px; margin: 24px auto; padding: 0 16px; }
        .card { background: white; border: 1px solid #dde3ea; border-radius: 8px; padding: 18px; margin-bottom: 16px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 14px; }
        table { width: 100%; border-collapse: collapse; background: white; }
        th, td { padding: 10px; border-bottom: 1px solid #e6ebf0; text-align: left; font-size: 14px; }
        label { display: block; margin-top: 12px; font-weight: 600; }
        input, select { width: 100%; box-sizing: border-box; padding: 9px; border: 1px solid #cfd8e3; border-radius: 6px; margin-top: 5px; }
        .button { display: inline-block; background: #0f766e; color: white; padding: 9px 12px; border-radius: 6px; border: 0; text-decoration: none; cursor: pointer; }
        .button.secondary { background: #475467; }
        .button:disabled { opacity: .55; cursor: not-allowed; }
        .toolbar { display: flex; gap: 10px; align-items: end; flex-wrap: wrap; margin-bottom: 16px; }
        .toolbar label { margin-top: 0; min-width: 180px; }
        .toolbar .actions { display: flex; gap: 8px; margin-top: 5px; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 999px; font-size: 12px; font-weight: 700; line-height: 1; }
        .badge.available { color: #027a48; background: #ecfdf3; }
        .badge.in_use, .badge.idle { color: #175cd3; background: #eff8ff; }
        .badge.active, .badge.idle_warning, .badge.idle_billing { color: #175cd3; background: #eff8ff; }
        .badge.completed { color: #027a48; background: #ecfdf3; }
        .badge.cancelled { color: #b42318; background: #fef3f2; }
        .badge.user, .badge.device { color: #344054; background: #f2f4f7; }
        .badge.admin, .badge.superadmin { color: #175cd3; background: #eff8ff; }
        .badge.offline { color: #344054; background: #f2f4f7; }
        .badge.maintenance { color: #b42318; background: #fef3f2; }
        .badge.reserved { color: #b54708; background: #fffaeb; }
        .map-panel { overflow: hidden; }
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
    <div>
        <strong>Smart Bike Rental</strong>
        @auth
            <nav style="display:inline">
                <a href="{{ route('admin.dashboard') }}">Dasbor</a>
                <a href="{{ route('admin.monitoring.index') }}">Monitoring Sepeda</a>
                <a href="{{ route('admin.bikes.index') }}">Sepeda</a>
                <a href="{{ route('admin.rentals.index') }}">Rental</a>
                <a href="{{ route('admin.rentals.index', ['status' => 'running']) }}">Rental Aktif</a>
                <a href="{{ route('admin.users.index') }}">Pengguna</a>
                <a href="{{ route('admin.reports.index') }}">Laporan</a>
                <a href="{{ route('admin.alerts.index') }}">Peringatan</a>
                @if(auth()->user()->role === 'superadmin')
                    <a href="{{ route('admin.settings.edit') }}">Pengaturan</a>
                @endif
            </nav>
        @endauth
    </div>
    @auth
        <form method="post" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit">Keluar</button>
        </form>
    @endauth
</header>
<main>
    @if(session('status'))
        <p class="success">{{ session('status') }}</p>
    @endif
    @yield('content')
</main>
</body>
</html>
