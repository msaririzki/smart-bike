@extends('layouts.admin', ['title' => 'Sepeda'])

@section('content')
    <h1>Sepeda</h1>
    <p><a class="button" href="{{ route('admin.bikes.create') }}">Tambah Sepeda</a></p>
    <table>
        <thead>
            <tr>
                <th>Kode</th>
                <th>Nama</th>
                <th>Status</th>
                <th>Status Online</th>
                <th>Baterai</th>
                <th>Perangkat Sepeda</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            @foreach($bikes as $bike)
                <tr>
                    <td>{{ $bike->code }}</td>
                    <td>{{ $bike->name }}</td>
                    <td>{{ $adminStatusLabels[$bike->status] ?? $bike->status }}</td>
                    <td>{{ $bike->is_online ? 'online' : 'offline' }}</td>
                    <td>{{ $bike->battery_percent ?? '-' }}</td>
                    <td>{{ $bike->assignedDevice?->email ?? '-' }}</td>
                    <td><a href="{{ route('admin.bikes.edit', $bike) }}">Ubah</a></td>
                </tr>
            @endforeach
        </tbody>
    </table>
    {{ $bikes->links() }}
@endsection
