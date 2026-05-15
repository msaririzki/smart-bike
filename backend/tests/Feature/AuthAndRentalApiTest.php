<?php

namespace Tests\Feature;

use App\Mail\PasswordResetCodeMail;
use App\Models\Bike;
use App\Models\Rental;
use App\Models\User;
use App\Services\PricingConfigService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthAndRentalApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(PricingConfigService::class)->seedDefaults();
    }

    public function test_user_can_register_login_and_device_role_is_blocked_from_bike_list(): void
    {
        $this->postJson('/api/auth/register', [
            'name' => 'New User',
            'email' => 'new-user@example.test',
            'password' => 'password',
        ])->assertCreated()
            ->assertJsonStructure(['user' => ['id', 'email', 'role'], 'token']);

        $this->postJson('/api/auth/login', [
            'email' => 'new-user@example.test',
            'password' => 'password',
        ])->assertOk()
            ->assertJsonStructure(['user', 'token']);

        $device = User::query()->create([
            'name' => 'Device',
            'email' => 'device@example.test',
            'password' => 'password',
            'role' => 'device',
        ]);

        Sanctum::actingAs($device);

        $this->getJson('/api/bikes')->assertForbidden();
    }

    public function test_user_can_reset_password_with_email_code(): void
    {
        Mail::fake();

        User::query()->create([
            'name' => 'Reset User',
            'email' => 'reset-user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);

        $this->postJson('/api/auth/password-reset/request', [
            'email' => 'reset-user@example.test',
        ])->assertOk()
            ->assertJsonPath('message', 'Kode reset password sudah dikirim ke email akun.');

        $resetCode = null;
        Mail::assertSent(PasswordResetCodeMail::class, function (PasswordResetCodeMail $mail) use (&$resetCode): bool {
            $resetCode = $mail->code;

            return $mail->hasTo('reset-user@example.test');
        });

        $this->postJson('/api/auth/password-reset/confirm', [
            'email' => 'reset-user@example.test',
            'token' => $resetCode,
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])->assertOk()
            ->assertJsonPath('message', 'Password berhasil diubah. Silakan login kembali.');

        $user = User::query()->where('email', 'reset-user@example.test')->firstOrFail();
        $this->assertTrue(Hash::check('new-password', $user->password));

        $this->postJson('/api/auth/login', [
            'email' => 'reset-user@example.test',
            'password' => 'new-password',
        ])->assertOk()
            ->assertJsonStructure(['user', 'token']);
    }

    public function test_user_can_update_profile(): void
    {
        $user = User::query()->create([
            'name' => 'Old Name',
            'email' => 'old-user@example.test',
            'password' => 'password',
            'phone' => '080000000000',
            'role' => 'user',
        ]);

        Sanctum::actingAs($user);

        $this->patchJson('/api/auth/me', [
            'name' => 'Updated User',
            'email' => 'updated-user@example.test',
            'phone' => '081234567890',
        ])->assertOk()
            ->assertJsonPath('message', 'Profil berhasil diperbarui.')
            ->assertJsonPath('user.name', 'Updated User')
            ->assertJsonPath('user.email', 'updated-user@example.test')
            ->assertJsonPath('user.phone', '081234567890');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated User',
            'email' => 'updated-user@example.test',
            'phone' => '081234567890',
        ]);
    }

    public function test_user_can_start_only_one_active_rental_and_finish_it(): void
    {
        $user = User::query()->create([
            'name' => 'User',
            'email' => 'user@example.test',
            'password' => 'password',
            'role' => 'user',
        ]);
        $bike = Bike::query()->create(['code' => 'BIKE-T1', 'name' => 'Bike Test', 'status' => 'available']);
        $secondBike = Bike::query()->create(['code' => 'BIKE-T2', 'name' => 'Bike Test 2', 'status' => 'available']);

        Sanctum::actingAs($user);

        $rentalId = $this->postJson('/api/rentals/start', ['bike_id' => $bike->id])
            ->assertCreated()
            ->json('data.id');

        $this->assertDatabaseHas('bikes', ['id' => $bike->id, 'status' => 'in_use']);

        $this->postJson('/api/rentals/start', ['bike_id' => $secondBike->id])
            ->assertUnprocessable();

        $this->postJson("/api/rentals/{$rentalId}/finish")
            ->assertOk()
            ->assertJsonPath('data.status', Rental::STATUS_COMPLETED);

        $this->assertDatabaseHas('bikes', ['id' => $bike->id, 'status' => 'available']);
    }
}
