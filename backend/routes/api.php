<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BikeController;
use App\Http\Controllers\Api\DeviceController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\RentalController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/password-reset/request', [AuthController::class, 'requestPasswordReset']);
    Route::post('/password-reset/confirm', [AuthController::class, 'confirmPasswordReset']);
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::patch('/me', [AuthController::class, 'updateMe']);
    });
});

Route::middleware(['auth:sanctum', 'role:user,admin,superadmin'])->group(function (): void {
    Route::get('/bikes', [BikeController::class, 'index']);
    Route::get('/bikes/{bike}', [BikeController::class, 'show']);
    
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/{id}/unread', [NotificationController::class, 'markAsUnread']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
});

Route::middleware(['auth:sanctum', 'role:user'])->group(function (): void {
    Route::post('/rentals/start', [RentalController::class, 'start']);
    Route::post('/rentals/start-from-qr', [RentalController::class, 'startFromQr']);
    Route::get('/rentals/active', [RentalController::class, 'active']);
    Route::get('/rentals/history', [RentalController::class, 'history']);
    Route::get('/rentals/idle-settings', [RentalController::class, 'idleSettings']);
    Route::get('/rentals/{rental}/location-points', [RentalController::class, 'locationPoints']);
    Route::get('/rentals/{rental}', [RentalController::class, 'show']);
    Route::post('/rentals/{rental}/finish', [RentalController::class, 'finish']);
    Route::post('/rentals/{rental}/idle/continue', [RentalController::class, 'continueIdle']);
    Route::delete('/rentals/{rental}', [RentalController::class, 'destroy']);
});

Route::middleware(['auth:sanctum', 'role:device'])->prefix('device')->group(function (): void {
    Route::get('/current-assignment', [DeviceController::class, 'currentAssignment']);
    Route::get('/active-rental-summary', [DeviceController::class, 'activeRentalSummary']);
    Route::post('/location-update', [DeviceController::class, 'locationUpdate']);
    Route::post('/heartbeat', [DeviceController::class, 'heartbeat']);
    Route::post('/rental-qr', [DeviceController::class, 'generateRentalQr']);
});
