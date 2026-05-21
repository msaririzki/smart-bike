<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = AppNotification::query()
            ->where('user_id', $request->user()->id)
            ->latest()
            ->limit(100)
            ->get();

        return response()->json([
            'data' => $notifications
                ->map(fn (AppNotification $notification): array => $this->serializeNotification($notification))
                ->values(),
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        return response()->json([
            'data' => [
                'count' => AppNotification::query()
                    ->where('user_id', $request->user()->id)
                    ->where('is_read', false)
                    ->count(),
            ],
        ]);
    }

    public function markAsRead(Request $request, AppNotification $notification): JsonResponse
    {
        $this->authorizeNotification($request, $notification);

        $notification->forceFill(['is_read' => true])->save();

        return response()->json([
            'data' => $this->serializeNotification($notification->refresh()),
        ]);
    }

    public function markAsUnread(Request $request, AppNotification $notification): JsonResponse
    {
        $this->authorizeNotification($request, $notification);

        $notification->forceFill(['is_read' => false])->save();

        return response()->json([
            'data' => $this->serializeNotification($notification->refresh()),
        ]);
    }

    public function destroy(Request $request, AppNotification $notification): JsonResponse
    {
        $this->authorizeNotification($request, $notification);

        $notification->delete();

        return response()->json(['message' => 'Notifikasi berhasil dihapus.']);
    }

    private function authorizeNotification(Request $request, AppNotification $notification): void
    {
        abort_unless((int) $notification->user_id === (int) $request->user()->id, 404);
    }

    private function serializeNotification(AppNotification $notification): array
    {
        return [
            'id' => $notification->id,
            'user_id' => $notification->user_id,
            'rental_id' => $notification->rental_id,
            'title' => $notification->title,
            'message' => $notification->message,
            'type' => $this->mobileType($notification->type),
            'raw_type' => $notification->type,
            'is_read' => $notification->is_read,
            'created_at' => $notification->created_at?->toJSON(),
            'start_time' => null,
            'end_time' => null,
            'data' => [
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
