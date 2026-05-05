<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\BikeController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\RentalController;
use App\Http\Controllers\Admin\SettingController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('admin.dashboard');
});

Route::prefix('admin')->name('admin.')->group(function (): void {
    Route::middleware('guest')->group(function (): void {
        Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
        Route::post('/login', [AuthController::class, 'login'])->name('login.store');
    });

    Route::middleware(['auth', 'role:admin,superadmin'])->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('/', DashboardController::class)->name('dashboard');
        Route::resource('bikes', BikeController::class)->except(['show', 'destroy']);
        Route::get('rentals', [RentalController::class, 'index'])->name('rentals.index');
        Route::get('rentals/{rental}', [RentalController::class, 'show'])->name('rentals.show');
    });

    Route::middleware(['auth', 'role:superadmin'])->group(function (): void {
        Route::get('settings', [SettingController::class, 'edit'])->name('settings.edit');
        Route::put('settings', [SettingController::class, 'update'])->name('settings.update');
    });
});
