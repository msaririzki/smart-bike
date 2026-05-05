<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title ?? 'Smart Bike Admin' }}</title>
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
                <a href="{{ route('admin.dashboard') }}">Dashboard</a>
                <a href="{{ route('admin.bikes.index') }}">Bikes</a>
                <a href="{{ route('admin.rentals.index') }}">Rentals</a>
                @if(auth()->user()->role === 'superadmin')
                    <a href="{{ route('admin.settings.edit') }}">Settings</a>
                @endif
            </nav>
        @endauth
    </div>
    @auth
        <form method="post" action="{{ route('admin.logout') }}">
            @csrf
            <button type="submit">Logout</button>
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
