<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        // Get personal and broadcast notifications
        $notifications = AppNotification::query()
            ->where('user_id', $user->id)
            ->orWhereNull('user_id')
            ->latest()
            ->limit(100)
            ->get();

        // Get broadcast notification IDs read by this user
        $readBroadcastIds = DB::table('notification_reads')
            ->where('user_id', $user->id)
            ->pluck('notification_id')
            ->toArray();

        return response()->json([
            'data' => $notifications
                ->map(function (AppNotification $notification) use ($readBroadcastIds) {
                    $isRead = $notification->user_id !== null
                        ? $notification->is_read
                        : in_array($notification->id, $readBroadcastIds);
                    return $this->serializeNotification($notification, $isRead);
                })
                ->values(),
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $personalUnread = AppNotification::query()
            ->where('user_id', $user->id)
            ->where('is_read', false)
            ->count();

        $readBroadcastIds = DB::table('notification_reads')
            ->where('user_id', $user->id)
            ->pluck('notification_id')
            ->toArray();

        $broadcastUnread = AppNotification::query()
            ->whereNull('user_id')
            ->whereNotIn('id', $readBroadcastIds)
            ->count();

        return response()->json([
            'data' => [
                'count' => $personalUnread + $broadcastUnread,
            ],
        ]);
    }

    public function markAsRead(Request $request, $id): JsonResponse
    {
        $user = $request->user();

        $notification = AppNotification::query()
            ->where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })
            ->where('id', $id)
            ->firstOrFail();

        $isRead = true;

        if ($notification->user_id !== null) {
            $notification->forceFill(['is_read' => true])->save();
        } else {
            DB::table('notification_reads')->updateOrInsert([
                'user_id' => $user->id,
                'notification_id' => $notification->id,
            ], [
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'data' => $this->serializeNotification($notification->refresh(), $isRead),
        ]);
    }

    public function markAsUnread(Request $request, $id): JsonResponse
    {
        $user = $request->user();

        $notification = AppNotification::query()
            ->where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })
            ->where('id', $id)
            ->firstOrFail();

        $isRead = false;

        if ($notification->user_id !== null) {
            $notification->forceFill(['is_read' => false])->save();
        } else {
            DB::table('notification_reads')
                ->where('user_id', $user->id)
                ->where('notification_id', $notification->id)
                ->delete();
        }

        return response()->json([
            'data' => $this->serializeNotification($notification->refresh(), $isRead),
        ]);
    }

    public function destroy(Request $request, $id): JsonResponse
    {
        $user = $request->user();

        $notification = AppNotification::query()
            ->where('user_id', $user->id)
            ->where('id', $id)
            ->firstOrFail();

        $notification->delete();

        return response()->json(['message' => 'Notifikasi berhasil dihapus.']);
    }

    private function serializeNotification(AppNotification $notification, bool $isRead): array
    {
        // Parse time fields which could be carbon objects or strings
        $startTime = null;
        if (isset($notification->start_time)) {
            $startTime = \Carbon\Carbon::parse($notification->start_time)->toJSON();
        }
        $endTime = null;
        if (isset($notification->end_time)) {
            $endTime = \Carbon\Carbon::parse($notification->end_time)->toJSON();
        }

        // Get actual data
        $notificationData = null;
        if (isset($notification->data)) {
            $notificationData = is_string($notification->data) ? json_decode($notification->data, true) : $notification->data;
        }

        return [
            'id' => $notification->id,
            'user_id' => $notification->user_id,
            'rental_id' => $notification->rental_id,
            'title' => $notification->title,
            'message' => $notification->message,
            'type' => $this->mobileType($notification->type),
            'raw_type' => $notification->type,
            'is_read' => $isRead,
            'created_at' => $notification->created_at?->toJSON(),
            'start_time' => $startTime,
            'end_time' => $endTime,
            'data' => $notificationData ?? [
                'raw_type' => $notification->type,
                'rental_id' => $notification->rental_id,
            ],
        ];
    }

    private function mobileType(string $type): string
    {
        return match ($type) {
            'sewa', 'pengumuman', 'promosi' => $type,
            default => 'pengumuman',
        };
    }
}
