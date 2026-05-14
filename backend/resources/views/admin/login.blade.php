@extends('layouts.admin', ['title' => 'Masuk Admin'])

@section('content')
    <style>
        body {
            background-color: #f8fafc;
            background-image: url("data:image/svg+xml,%3Csvg width='100' height='100' viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M30,70 A15,15 0 1,0 60,70 A15,15 0 1,0 30,70 M45,70 L55,45 L70,45 M55,45 L40,45 L30,70' fill='none' stroke='%23cbd5e1' stroke-width='1.5' stroke-opacity='0.4'/%3E%3C/svg%3E");
            background-size: 200px;
            display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0;
        }
        main { margin: 0; padding: 20px; width: 100%; display: flex; justify-content: center; align-items: center; }
        .login-card { background: white; border: none; border-radius: 1rem; padding: 2.5rem 2.5rem; width: 100%; max-width: 400px; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); position: relative; z-index: 10; }
        .login-header { text-align: center; margin-bottom: 2rem; }
        .login-logo { display: inline-flex; align-items: center; justify-content: center; color: #0f766e; margin-bottom: 1rem; }
        .login-title { font-size: 1.5rem; font-weight: 700; color: #0f172a; margin: 0 0 0.5rem; }
        .login-subtitle { color: #64748b; font-size: 0.875rem; margin: 0; }
        .login-card label { display: block; margin-bottom: 0.5rem; font-weight: 500; font-size: 0.875rem; color: #334155; margin-top: 1.25rem; }
        .login-card input[type="email"], .login-card input[type="password"] { width: 100%; padding: 0.75rem 1rem; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 0.875rem; transition: all 0.2s; background: #f8fafc; box-sizing: border-box; }
        .login-card input[type="email"]:focus, .login-card input[type="password"]:focus { border-color: #0f766e; background: white; box-shadow: 0 0 0 3px rgba(15, 118, 110, 0.1); outline: none; }
        .checkbox-wrapper { display: flex; align-items: center; gap: 0.5rem; }
        .checkbox-wrapper input[type="checkbox"] { width: 1rem; height: 1rem; border-radius: 0.25rem; border: 1px solid #cbd5e1; accent-color: #0f766e; cursor: pointer; margin: 0; }
        .checkbox-wrapper label { margin: 0; font-weight: 400; cursor: pointer; color: #475569; }
        .btn-login { width: 100%; background: #0f766e; color: white; padding: 0.875rem; border: none; border-radius: 8px; font-weight: 600; font-size: 0.875rem; margin-top: 1.5rem; cursor: pointer; transition: background 0.2s; box-shadow: 0 4px 6px -1px rgba(15, 118, 110, 0.2); }
        .btn-login:hover { background: #115e59; box-shadow: 0 6px 8px -1px rgba(15, 118, 110, 0.3); }
        .form-footer { display: flex; justify-content: space-between; align-items: center; margin-top: 1.25rem; }
        .forgot-link { font-size: 0.875rem; color: #0f766e; text-decoration: none; font-weight: 500; transition: color 0.2s; }
        .forgot-link:hover { color: #115e59; text-decoration: underline; }
    </style>

    <div class="login-card">
        <div class="login-header">
            <div class="login-logo" style="width: 100%;">
                <img src="{{ asset('images/flowbike-logo-landscape.png') }}" alt="FlowBike" style="max-width: 80%; height: auto;">
            </div>
            <h1 class="login-title">Masuk ke Akun</h1>
            <p class="login-subtitle">Masukkan email dan kata sandi Anda untuk melanjutkan</p>
        </div>

        <form method="post" action="{{ route('admin.login.store') }}">
            @csrf
            <div>
                <label for="email">Alamat Email</label>
                <input id="email" name="email" type="email" value="{{ old('email') }}" placeholder="admin@example.com" required>
                @error('email') <p class="error" style="margin: 0.25rem 0 0; font-size: 0.75rem;">{{ $message }}</p> @enderror
            </div>

            <div>
                <label for="password">Kata Sandi</label>
                <input id="password" name="password" type="password" placeholder="Masukkan kata sandi" required>
                @error('password') <p class="error" style="margin: 0.25rem 0 0; font-size: 0.75rem;">{{ $message }}</p> @enderror
            </div>

            <div class="form-footer">
                <div class="checkbox-wrapper">
                    <input type="checkbox" id="remember" name="remember" value="1">
                    <label for="remember">Ingat Saya</label>
                </div>
                <a href="#" class="forgot-link">Lupa Kata Sandi?</a>
            </div>

            <button class="btn-login" type="submit">Masuk</button>
        </form>
    </div>
@endsection
