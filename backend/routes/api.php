<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BikeController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\RentalController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
    });
});

Route::middleware(['auth:sanctum', 'role:user,admin,superadmin'])->group(function (): void {
    Route::get('/bikes', [BikeController::class, 'index']);
    Route::get('/bikes/{bike}', [BikeController::class, 'show']);
});

Route::middleware(['auth:sanctum', 'role:user'])->group(function (): void {
    Route::post('/rentals/start', [RentalController::class, 'start']);
    Route::get('/rentals/active', [RentalController::class, 'active']);
    Route::get('/rentals/history', [RentalController::class, 'history']);
    Route::post('/rentals/{rental}/finish', [RentalController::class, 'finish']);
    Route::post('/rentals/{rental}/idle/continue', [RentalController::class, 'continueIdle']);
});

Route::middleware(['auth:sanctum', 'role:device'])->prefix('device')->group(function (): void {
    Route::get('/current-assignment', [DeviceController::class, 'currentAssignment']);
    Route::get('/active-rental-summary', [DeviceController::class, 'activeRentalSummary']);
    Route::post('/location-update', [DeviceController::class, 'locationUpdate']);
    Route::post('/heartbeat', [DeviceController::class, 'heartbeat']);
});
