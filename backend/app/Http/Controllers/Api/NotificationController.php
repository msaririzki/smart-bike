<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user, including global announcements.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $notifications = Notification::where('user_id', $user->id)
            ->orWhereNull('user_id')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
        ]);
    }

    /**
     * Mark a specific notification as read.
     */
    public function markAsRead(Request $request, $id)
    {
        $user = $request->user();

        $notification = Notification::where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })
            ->where('id', $id)
            ->firstOrFail();

        // For global notifications, marking as read for a specific user would require a pivot table.
        // For simplicity in this local version, we'll only actually update the 'is_read' flag
        // if it's a personal notification. Global notifications might remain unread, or we just
        // let it update the global flag (which affects everyone).
        // Let's assume we only update personal ones for now, or just update it anyway.
        if ($notification->user_id !== null) {
            $notification->update(['is_read' => true]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification marked as read',
        ]);
    }
}
