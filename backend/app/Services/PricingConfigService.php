<?php

namespace App\Services;

use App\Models\PricingSetting;
use Illuminate\Support\Collection;

class PricingConfigService
{
    public const DEFAULTS = [
        'distance_unit_meters' => ['100', 'integer', 'Distance Billing', 'Meter per billing unit.'],
        'distance_price_amount' => ['500', 'integer', 'Distance Billing', 'Price per distance unit.'],
        'rounding_mode' => ['floor', 'string', 'Distance Billing', 'floor, ceil, or nearest.'],
        'minimum_billable_distance_meters' => ['0', 'integer', 'Distance Billing', 'Optional minimum billable distance.'],
        'max_reasonable_speed_kmh' => ['40', 'integer', 'Distance Billing', 'Maximum accepted bike speed.'],
        'idle_warning_after_seconds' => ['300', 'integer', 'Idle Rules', 'Seconds without valid movement before warning.'],
        'grace_period_before_idle_billing_seconds' => ['60', 'integer', 'Idle Rules', 'Seconds after warning before auto idle billing.'],
        'idle_billing_interval_seconds' => ['300', 'integer', 'Idle Rules', 'Idle billing interval.'],
        'idle_billing_amount' => ['200', 'integer', 'Idle Rules', 'Amount charged per idle interval.'],
        'gps_update_interval_seconds' => ['5', 'integer', 'GPS Rules', 'Expected simulator update interval.'],
        'minimum_movement_threshold_meters' => ['10', 'integer', 'GPS Rules', 'Minimum movement counted as valid.'],
        'max_gps_accuracy_meters' => ['25', 'integer', 'GPS Rules', 'Worst accepted GPS accuracy for billing.'],
        'offline_timeout_seconds' => ['20', 'integer', 'GPS Rules', 'Seconds before a bike is marked offline.'],
        'allow_multiple_active_rentals' => ['false', 'boolean', 'Bike Rental Rules', 'Whether a user may rent more than one bike.'],
        'maximum_rental_duration_minutes' => ['0', 'integer', 'Bike Rental Rules', 'Zero means unlimited.'],
        'force_finish_when_offline_too_long' => ['false', 'boolean', 'Bike Rental Rules', 'Whether offline bikes force finish rentals.'],
    ];

    public function seedDefaults(): void
    {
        foreach (self::DEFAULTS as $key => [$value, $type, $group, $description]) {
            PricingSetting::query()->firstOrCreate(
                ['key' => $key],
                [
                    'value' => $value,
                    'value_type' => $type,
                    'group_name' => $group,
                    'description' => $description,
                ],
            );
        }
    }

    public function all(): Collection
    {
        return PricingSetting::query()->orderBy('group_name')->orderBy('key')->get();
    }

    public function get(string $key): mixed
    {
        $setting = PricingSetting::query()->where('key', $key)->first();

        if (! $setting && isset(self::DEFAULTS[$key])) {
            [$value, $type] = self::DEFAULTS[$key];

            return $this->cast($value, $type);
        }

        return $setting ? $this->cast($setting->value, $setting->value_type) : null;
    }

    public function update(array $settings, ?int $updatedBy = null): void
    {
        foreach ($settings as $key => $value) {
            if (! array_key_exists($key, self::DEFAULTS)) {
                continue;
            }

            [, $type, $group, $description] = self::DEFAULTS[$key];

            PricingSetting::query()->updateOrCreate(
                ['key' => $key],
                [
                    'value' => (string) $value,
                    'value_type' => $type,
                    'group_name' => $group,
                    'description' => $description,
                    'updated_by' => $updatedBy,
                ],
            );
        }
    }

    private function cast(string $value, string $type): mixed
    {
        return match ($type) {
            'integer' => (int) $value,
            'float' => (float) $value,
            'boolean' => filter_var($value, FILTER_VALIDATE_BOOL),
            default => $value,
        };
    }
}
