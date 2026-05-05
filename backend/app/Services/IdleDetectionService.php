<?php

namespace App\Services;

use App\Models\AppNotification;
use App\Models\Rental;

class IdleDetectionService
{
    public function __construct(
        private readonly PricingConfigService $pricing,
        private readonly BillingService $billing,
    ) {}

    public function checkIdleWarnings(): int
    {
        $count = 0;

        Rental::query()
            ->where('status', Rental::STATUS_ACTIVE)
            ->whereNotNull('last_movement_at')
            ->each(function (Rental $rental) use (&$count): void {
                if ($this->shouldWarn($rental)) {
                    $this->triggerWarning($rental);
                    $count++;
                }
            });

        return $count;
    }

    public function moveWarningsToIdleBilling(): int
    {
        $grace = max(1, (int) $this->pricing->get('grace_period_before_idle_billing_seconds'));
        $count = 0;

        Rental::query()
            ->where('status', Rental::STATUS_IDLE_WARNING)
            ->where('idle_warning_at', '<=', now()->subSeconds($grace))
            ->each(function (Rental $rental) use (&$count): void {
                $rental->update([
                    'status' => Rental::STATUS_IDLE_BILLING,
                    'idle_started_at' => now(),
                    'last_idle_billing_at' => now(),
                ]);

                $rental->idleEvents()->create([
                    'event_type' => 'idle_billing_started',
                    'description' => 'Idle billing otomatis dimulai setelah grace period.',
                    'event_at' => now(),
                ]);

                $count++;
            });

        return $count;
    }

    public function applyIdleBillingDue(): int
    {
        $interval = max(1, (int) $this->pricing->get('idle_billing_interval_seconds'));
        $count = 0;

        Rental::query()
            ->where('status', Rental::STATUS_IDLE_BILLING)
            ->where(function ($query) use ($interval): void {
                $query
                    ->whereNull('last_idle_billing_at')
                    ->orWhere('last_idle_billing_at', '<=', now()->subSeconds($interval));
            })
            ->each(function (Rental $rental) use (&$count): void {
                $this->billing->applyIdleBilling($rental);
                $count++;
            });

        return $count;
    }

    public function resumeIfMoving(Rental $rental): void
    {
        if (! in_array($rental->status, [Rental::STATUS_IDLE_WARNING, Rental::STATUS_IDLE_BILLING], true)) {
            return;
        }

        $rental->update([
            'status' => Rental::STATUS_ACTIVE,
            'idle_warning_at' => null,
            'idle_started_at' => null,
            'last_idle_billing_at' => null,
        ]);

        $rental->idleEvents()->create([
            'event_type' => 'resume_moving',
            'description' => 'Rental kembali active karena ada pergerakan valid.',
            'event_at' => now(),
        ]);
    }

    private function shouldWarn(Rental $rental): bool
    {
        $threshold = max(1, (int) $this->pricing->get('idle_warning_after_seconds'));

        return $rental->last_movement_at->lte(now()->subSeconds($threshold));
    }

    private function triggerWarning(Rental $rental): void
    {
        $rental->update([
            'status' => Rental::STATUS_IDLE_WARNING,
            'idle_warning_at' => now(),
        ]);

        $rental->idleEvents()->create([
            'event_type' => 'warning',
            'description' => 'Sepeda tidak bergerak melewati batas idle warning.',
            'event_at' => now(),
        ]);

        AppNotification::query()->create([
            'user_id' => $rental->user_id,
            'rental_id' => $rental->id,
            'type' => 'idle_warning',
            'title' => 'Sepeda Tidak Bergerak',
            'message' => 'Sepeda tidak bergerak cukup lama. Lanjutkan atau akhiri sewa.',
        ]);
    }
}
