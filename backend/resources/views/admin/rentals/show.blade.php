@extends('layouts.admin', ['title' => 'Rental Detail'])

@section('content')
    <h1>Rental #{{ $rental->id }}</h1>
    <div class="card">
        <p><strong>User:</strong> {{ $rental->user->name }} | <strong>Bike:</strong> {{ $rental->bike->code }}</p>
        <p><strong>Status:</strong> {{ $rental->status }}</p>
        <p><strong>Distance:</strong> {{ number_format($rental->total_distance_meters, 2) }} m</p>
        <p><strong>Distance Cost:</strong> Rp{{ number_format($rental->distance_cost, 0, ',', '.') }}</p>
        <p><strong>Idle Cost:</strong> Rp{{ number_format($rental->idle_cost, 0, ',', '.') }}</p>
        <p><strong>Total:</strong> Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</p>
    </div>

    <h2>Billing Logs</h2>
    <table>
        <tbody>
            @foreach($rental->billingLogs as $log)
                <tr><td>{{ $log->billing_type }}</td><td>Rp{{ number_format($log->amount, 0, ',', '.') }}</td><td>{{ $log->notes }}</td><td>{{ $log->created_at }}</td></tr>
            @endforeach
        </tbody>
    </table>

    <h2>Idle Events</h2>
    <table>
        <tbody>
            @foreach($rental->idleEvents as $event)
                <tr><td>{{ $event->event_type }}</td><td>{{ $event->description }}</td><td>{{ $event->event_at }}</td></tr>
            @endforeach
        </tbody>
    </table>

    <h2>Location Points</h2>
    <table>
        <thead><tr><th>Lat</th><th>Lng</th><th>Distance</th><th>Valid</th><th>Ignored</th><th>Recorded</th></tr></thead>
        <tbody>
            @foreach($rental->locationPoints->sortByDesc('recorded_at')->take(30) as $point)
                <tr>
                    <td>{{ $point->latitude }}</td>
                    <td>{{ $point->longitude }}</td>
                    <td>{{ number_format($point->movement_distance_meters, 2) }} m</td>
                    <td>{{ $point->is_valid_movement ? 'yes' : 'no' }}</td>
                    <td>{{ $point->ignored_reason ?? '-' }}</td>
                    <td>{{ $point->recorded_at }}</td>
                </tr>
            @endforeach
        </tbody>
    </table>
@endsection
