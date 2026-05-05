@extends('layouts.admin', ['title' => 'Dashboard'])

@section('content')
    <h1>Dashboard</h1>
    <div class="grid">
        <div class="card"><span class="muted">Total Bikes</span><h2>{{ $totalBikes }}</h2></div>
        <div class="card"><span class="muted">Active Rentals</span><h2>{{ $activeRentals }}</h2></div>
        <div class="card"><span class="muted">Completed Rentals</span><h2>{{ $completedRentals }}</h2></div>
        <div class="card"><span class="muted">Offline Bikes</span><h2>{{ $offlineBikes }}</h2></div>
        <div class="card"><span class="muted">Users</span><h2>{{ $users }}</h2></div>
        <div class="card"><span class="muted">Revenue Simulation</span><h2>Rp{{ number_format($totalRevenue, 0, ',', '.') }}</h2></div>
    </div>
@endsection
