<?php

namespace App\Services;

use App\Models\Rental;

class BillingService
{
    public function __construct(private readonly PricingConfigService $pricing) {}

    public function recalculateDistanceCost(Rental $rental): Rental
    {
        $unitMeters = max(1, (int) $this->pricing->get('distance_unit_meters'));
        $amount = max(0, (int) $this->pricing->get('distance_price_amount'));
        $roundingMode = (string) $this->pricing->get('rounding_mode');
        $minimumDistance = max(0, (int) $this->pricing->get('minimum_billable_distance_meters'));
        $billableDistance = max((float) $rental->total_distance_meters, $minimumDistance);
        $rawUnits = $billableDistance / $unitMeters;

        $units = match ($roundingMode) {
            'ceil' => (int) ceil($rawUnits),
            'nearest' => (int) round($rawUnits),
            default => (int) floor($rawUnits),
        };

        $newCost = max(0, $units * $amount);
        $delta = $newCost - (int) $rental->distance_cost;

        $rental->distance_cost = $newCost;
        $rental->total_cost = $newCost + (int) $rental->idle_cost;
        $rental->save();

        if ($delta > 0) {
            $rental->billingLogs()->create([
                'billing_type' => 'distance',
                'amount' => $delta,
                'quantity' => $units,
                'unit_label' => "{$unitMeters}m",
                'notes' => "Distance cost recalculated using {$roundingMode} rounding.",
            ]);
        }

        return $rental;
    }

    public function applyIdleBilling(Rental $rental): Rental
    {
        $amount = max(0, (int) $this->pricing->get('idle_billing_amount'));

        $rental->idle_cost = (int) $rental->idle_cost + $amount;
        $rental->total_cost = (int) $rental->distance_cost + (int) $rental->idle_cost;
        $rental->last_idle_billing_at = now();
        $rental->save();

        $rental->billingLogs()->create([
            'billing_type' => 'idle',
            'amount' => $amount,
            'quantity' => 1,
            'unit_label' => 'interval',
            'notes' => 'Idle billing applied.',
        ]);

        $rental->idleEvents()->create([
            'event_type' => 'idle_billing_applied',
            'description' => "Idle billing amount {$amount} applied.",
            'event_at' => now(),
        ]);

        return $rental;
    }
}
