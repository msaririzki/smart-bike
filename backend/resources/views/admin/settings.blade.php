@extends('layouts.admin', ['title' => 'Pengaturan'])

@section('content')
    <h1>Tarif & Aturan</h1>
    <form method="post" action="{{ route('admin.settings.update') }}">
        @csrf
        @method('put')
        @foreach($settings as $group => $items)
            <div class="card">
                <h2>{{ $adminSettingGroupLabels[$group] ?? $group }}</h2>
                @foreach($items as $setting)
                    <label>{{ $adminSettingLabels[$setting->key] ?? $setting->key }}</label>
                    <input name="settings[{{ $setting->key }}]" value="{{ old('settings.'.$setting->key, $setting->value) }}">
                    <p class="muted">{{ $adminSettingDescriptions[$setting->key] ?? $setting->description }}</p>
                @endforeach
            </div>
        @endforeach
        <button class="button" type="submit">Simpan Pengaturan</button>
    </form>
@endsection
