<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\PricingConfigService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class SettingController extends Controller
{
    public function __construct(private readonly PricingConfigService $pricing) {}

    public function edit(): View
    {
        return view('admin.settings', [
            'settings' => $this->pricing->all()->groupBy('group_name'),
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'settings' => ['required', 'array'],
            'settings.*' => ['nullable', 'string', 'max:255'],
        ]);

        $this->pricing->update($data['settings'], $request->user()->id);

        return redirect()->route('admin.settings.edit')->with('status', 'Pengaturan diperbarui.');
    }
}
