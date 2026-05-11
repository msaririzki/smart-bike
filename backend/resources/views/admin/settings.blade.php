@extends('layouts.admin', ['title' => 'Pengaturan'])

@section('content')
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px;">
        <h1 style="margin: 0; color: #0f766e;">Pengaturan Sistem</h1>
    </div>
    
    <form method="post" action="{{ route('admin.settings.update') }}">
        @csrf
        @method('put')
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px;">
            @foreach($settings as $group => $items)
                <div class="card" style="margin-bottom: 0;">
                    <h2 style="margin-top: 0; border-bottom: 1px solid #e2e8f0; padding-bottom: 12px; color: #0f766e; font-size: 18px;">{{ $adminSettingGroupLabels[$group] ?? $group }}</h2>
                    <div style="display: flex; flex-direction: column; gap: 16px; margin-top: 16px;">
                        @foreach($items as $setting)
                            <div>
                                <label style="margin-top: 0; color: #334155; font-weight: 600;">{{ $adminSettingLabels[$setting->key] ?? $setting->key }}</label>
                                <input name="settings[{{ $setting->key }}]" value="{{ old('settings.'.$setting->key, $setting->value) }}">
                                <p class="muted" style="margin: 6px 0 0; font-size: 13px;">{{ $adminSettingDescriptions[$setting->key] ?? $setting->description }}</p>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endforeach
        </div>
        
        <div class="card" style="margin-top: 24px; display: flex; justify-content: flex-end; background: #f8fafc; border: 1px dashed #cbd5e1;">
            <button class="button" type="submit" style="padding: 12px 24px; font-size: 15px; font-weight: 600;">Simpan Pengaturan</button>
        </div>
    </form>
@endsection
