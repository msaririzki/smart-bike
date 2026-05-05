@extends('layouts.admin', ['title' => 'Bikes'])

@section('content')
    <h1>Bikes</h1>
    <p><a class="button" href="{{ route('admin.bikes.create') }}">Tambah Bike</a></p>
    <table>
        <thead>
            <tr>
                <th>Code</th>
                <th>Name</th>
                <th>Status</th>
                <th>Online</th>
                <th>Battery</th>
                <th>Device</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @foreach($bikes as $bike)
                <tr>
                    <td>{{ $bike->code }}</td>
                    <td>{{ $bike->name }}</td>
                    <td>{{ $bike->status }}</td>
                    <td>{{ $bike->is_online ? 'online' : 'offline' }}</td>
                    <td>{{ $bike->battery_percent ?? '-' }}</td>
                    <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                    <td><a href="{{ route('admin.bikes.edit', $bike) }}">Edit</a></td>
                </tr>
            @endforeach
        </tbody>
    </table>
    {{ $bikes->links() }}
@endsection
