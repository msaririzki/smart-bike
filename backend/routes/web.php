<?php

use App\Http\Controllers\Admin\AlertController;
use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\BikeController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\MonitoringController;
use App\Http\Controllers\Admin\RentalController;
use App\Http\Controllers\Admin\ReportController;
use App\Http\Controllers\Admin\SearchController;
use App\Http\Controllers\Admin\SettingController;
use App\Http\Controllers\Admin\UserController;
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
        Route::get('search', [SearchController::class, 'index'])->name('search');
        Route::get('dashboard/map-data', [DashboardController::class, 'mapData'])->name('dashboard.map-data');
        Route::post('dashboard/cell-survey/clear', [DashboardController::class, 'clearCellSurvey'])->name('dashboard.cell-survey.clear');
        Route::get('monitoring-bikes', [MonitoringController::class, 'index'])->name('monitoring.index');
        Route::get('monitoring-bikes/{bike}', [MonitoringController::class, 'show'])->name('monitoring.show');
        Route::resource('bikes', BikeController::class)->except(['show', 'destroy']);
        Route::get('rentals', [RentalController::class, 'index'])->name('rentals.index');
        Route::get('rentals/{rental}', [RentalController::class, 'show'])->name('rentals.show');
        Route::get('rentals/{rental}/route-map-data', [RentalController::class, 'routeMapData'])->name('rentals.route-map-data');
        Route::get('users', [UserController::class, 'index'])->name('users.index');
        Route::post('users', [UserController::class, 'store'])->name('users.store');
        Route::get('users/{user}', [UserController::class, 'show'])->name('users.show');
        Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
        Route::get('alerts', [AlertController::class, 'index'])->name('alerts.index');
        Route::resource('notifications', \App\Http\Controllers\Admin\NotificationController::class);
    });

    Route::middleware(['auth', 'role:superadmin'])->group(function (): void {
        Route::get('settings', [SettingController::class, 'edit'])->name('settings.edit');
        Route::put('settings', [SettingController::class, 'update'])->name('settings.update');
        Route::put('users/{user}/role', [UserController::class, 'updateRole'])->name('users.role.update');
    });
});
