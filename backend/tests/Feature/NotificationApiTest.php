<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_list_notifications_and_unread_count(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $otherUser = User::factory()->create(['role' => 'user']);

        $unread = AppNotification::query()->create([
            'user_id' => $user->id,
            'type' => 'idle_warning',
            'title' => 'Sepeda diam terlalu lama',
            'message' => 'Silakan lanjutkan perjalanan.',
            'is_read' => false,
        ]);

        AppNotification::query()->create([
            'user_id' => $user->id,
            'type' => 'pengumuman',
            'title' => 'Info sistem',
            'message' => 'Maintenance selesai.',
            'is_read' => true,
        ]);

        AppNotification::query()->create([
            'user_id' => $otherUser->id,
            'type' => 'pengumuman',
            'title' => 'Milik user lain',
            'message' => 'Tidak boleh terlihat.',
            'is_read' => false,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/notifications')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment([
                'id' => $unread->id,
                'type' => 'pengumuman',
                'raw_type' => 'idle_warning',
                'is_read' => false,
            ])
            ->assertJsonMissing(['title' => 'Milik user lain']);

        $this->getJson('/api/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('data.count', 1);
    }

    public function test_user_can_mark_notification_read_unread_and_delete(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $notification = AppNotification::query()->create([
            'user_id' => $user->id,
            'type' => 'pengumuman',
            'title' => 'Info',
            'message' => 'Pesan',
            'is_read' => false,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/notifications/{$notification->id}/read")
            ->assertOk()
            ->assertJsonPath('data.is_read', true);

        $this->assertDatabaseHas('notifications', [
            'id' => $notification->id,
            'is_read' => true,
        ]);

        $this->postJson("/api/notifications/{$notification->id}/unread")
            ->assertOk()
            ->assertJsonPath('data.is_read', false);

        $this->deleteJson("/api/notifications/{$notification->id}")
            ->assertOk()
            ->assertJsonPath('message', 'Notifikasi berhasil dihapus.');

        $this->assertDatabaseMissing('notifications', [
            'id' => $notification->id,
        ]);
    }

    public function test_user_cannot_manage_other_users_notification(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $otherUser = User::factory()->create(['role' => 'user']);
        $notification = AppNotification::query()->create([
            'user_id' => $otherUser->id,
            'type' => 'pengumuman',
            'title' => 'Rahasia',
            'message' => 'Milik user lain.',
            'is_read' => false,
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/notifications/{$notification->id}/read")->assertNotFound();
        $this->postJson("/api/notifications/{$notification->id}/unread")->assertNotFound();
        $this->deleteJson("/api/notifications/{$notification->id}")->assertNotFound();
    }
}
