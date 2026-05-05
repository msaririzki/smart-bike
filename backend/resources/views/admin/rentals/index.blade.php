@extends('layouts.admin', ['title' => 'Rentals'])

@section('content')
    <h1>Rentals</h1>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>User</th>
                <th>Bike</th>
                <th>Status</th>
                <th>Distance</th>
                <th>Total</th>
                <th>Started</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @foreach($rentals as $rental)
                <tr>
                    <td>{{ $rental->id }}</td>
                    <td>{{ $rental->user->name }}</td>
                    <td>{{ $rental->bike->code }}</td>
                    <td>{{ $rental->status }}</td>
                    <td>{{ number_format($rental->total_distance_meters, 2) }} m</td>
                    <td>Rp{{ number_format($rental->total_cost, 0, ',', '.') }}</td>
                    <td>{{ $rental->started_at }}</td>
                    <td><a href="{{ route('admin.rentals.show', $rental) }}">Detail</a></td>
                </tr>
            @endforeach
        </tbody>
    </table>
    {{ $rentals->links() }}
@endsection
