<?php

namespace App\Services;

use App\Models\Notification;

class NotificationService
{
    /**
     * Send a notification to a user or globally.
     *
     * @param int|null $userId Null for global announcements.
     * @param string $title
     * @param string $message
     * @param string $type 'sewa' or 'pengumuman'
     * @return Notification
     */
    public static function send(?int $userId, string $title, string $message, string $type = 'pengumuman', ?array $data = null): Notification
    {
        return Notification::create([
            'user_id' => $userId,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'data' => $data,
        ]);
    }
}
