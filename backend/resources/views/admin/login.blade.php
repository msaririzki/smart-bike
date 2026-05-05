@extends('layouts.admin', ['title' => 'Login Admin'])

@section('content')
    <div class="card" style="max-width:420px;margin:48px auto;">
        <h1>Login Admin</h1>
        <p class="muted">Demo: superadmin@smartbike.test / password</p>
        <form method="post" action="{{ route('admin.login.store') }}">
            @csrf
            <label>Email</label>
            <input name="email" type="email" value="{{ old('email') }}" required>
            @error('email') <p class="error">{{ $message }}</p> @enderror

            <label>Password</label>
            <input name="password" type="password" required>
            @error('password') <p class="error">{{ $message }}</p> @enderror

            <p><button class="button" type="submit">Login</button></p>
        </form>
    </div>
@endsection
