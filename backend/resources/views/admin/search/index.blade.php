@extends('layouts.admin', ['title' => 'Pencarian Global'])

@section('content')
    <h1>Hasil Pencarian</h1>

    <div class="card toolbar">
        <form method="get" action="{{ route('admin.search') }}" style="display: flex; gap: 10px; width: 100%; align-items: flex-end;">
            <label style="flex: 1; margin: 0;">
                Kata Kunci
                <input type="search" name="search" value="{{ $search }}" placeholder="Cari sepeda, pengguna, atau rental..." autofocus>
            </label>
            <button class="button" type="submit">Cari</button>
        </form>
    </div>

    @if($search)
        <p>Menampilkan hasil pencarian untuk: <strong>{{ $search }}</strong></p>

        <div class="grid">
            <!-- Hasil Sepeda -->
            <div class="card" style="margin-bottom: 0;">
                <h2>Sepeda ({{ $bikes->count() }})</h2>
                @if($bikes->isNotEmpty())
                    <ul style="padding-left: 20px;">
                        @foreach($bikes as $bike)
                            <li>
                                <a href="{{ route('admin.bikes.edit', $bike) }}" style="color: var(--teal-700); font-weight: 500;">{{ $bike->code }} - {{ $bike->name }}</a>
                                <div class="muted" style="font-size: 12px;">Status: {{ $bike->status }}</div>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <p class="muted">Tidak ditemukan sepeda.</p>
                @endif
            </div>

            <!-- Hasil Pengguna -->
            <div class="card" style="margin-bottom: 0;">
                <h2>Pengguna ({{ $users->count() }})</h2>
                @if($users->isNotEmpty())
                    <ul style="padding-left: 20px;">
                        @foreach($users as $user)
                            <li>
                                <a href="{{ route('admin.users.show', $user) }}" style="color: var(--teal-700); font-weight: 500;">{{ $user->name }}</a>
                                <div class="muted" style="font-size: 12px;">{{ $user->email }}</div>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <p class="muted">Tidak ditemukan pengguna.</p>
                @endif
            </div>

            <!-- Hasil Rental -->
            <div class="card" style="margin-bottom: 0;">
                <h2>Rental ({{ $rentals->count() }})</h2>
                @if($rentals->isNotEmpty())
                    <ul style="padding-left: 20px;">
                        @foreach($rentals as $rental)
                            <li>
                                <a href="{{ route('admin.rentals.show', $rental) }}" style="color: var(--teal-700); font-weight: 500;">Rental #{{ $rental->id }}</a>
                                <div class="muted" style="font-size: 12px;">Oleh: {{ $rental->user->name ?? '-' }}</div>
                            </li>
                        @endforeach
                    </ul>
                @else
                    <p class="muted">Tidak ditemukan rental. (Gunakan ID angka)</p>
                @endif
            </div>
        </div>
    @else
        <div class="card">
            <p class="muted" style="text-align: center; padding: 40px 0;">Silakan masukkan kata kunci untuk memulai pencarian global.</p>
        </div>
    @endif
@endsection
