@extends('layouts.admin', ['title' => 'Settings'])

@section('content')
    <h1>Pricing & Rules</h1>
    <form method="post" action="{{ route('admin.settings.update') }}">
        @csrf
        @method('put')
        @foreach($settings as $group => $items)
            <div class="card">
                <h2>{{ $group }}</h2>
                @foreach($items as $setting)
                    <label>{{ $setting->key }}</label>
                    <input name="settings[{{ $setting->key }}]" value="{{ old('settings.'.$setting->key, $setting->value) }}">
                    <p class="muted">{{ $setting->description }}</p>
                @endforeach
            </div>
        @endforeach
        <button class="button" type="submit">Simpan Settings</button>
    </form>
@endsection
