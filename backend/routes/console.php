<?php

use App\Services\BikeStatusService;
use App\Services\IdleDetectionService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Schedule::call(fn () => app(IdleDetectionService::class)->checkIdleWarnings())
    ->everyMinute()
    ->name('smart-bike-check-idle-rentals');

Schedule::call(fn () => app(IdleDetectionService::class)->moveWarningsToIdleBilling())
    ->everyMinute()
    ->name('smart-bike-start-idle-billing');

Schedule::call(fn () => app(IdleDetectionService::class)->applyIdleBillingDue())
    ->everyMinute()
    ->name('smart-bike-apply-idle-billing');

Schedule::call(fn () => app(BikeStatusService::class)->markOfflineBikes())
    ->everyMinute()
    ->name('smart-bike-mark-offline-bikes');
