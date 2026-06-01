<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $notifications = Notification::where('user_id', $user->id)
            ->orWhereNull('user_id')
            ->orderBy('created_at', 'desc')
            ->get();

        $readIds = \Illuminate\Support\Facades\DB::table('notification_reads')
            ->where('user_id', $user->id)
            ->pluck('notification_id')
            ->toArray();

        foreach ($notifications as $notif) {
            if ($notif->user_id === null) {
                // Determine read status from pivot for broadcast notifications
                $notif->is_read = in_array($notif->id, $readIds);
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
        ]);
    }

    public function unreadCount(Request $request)
    {
        $user = $request->user();

        $personalUnread = Notification::where('user_id', $user->id)->where('is_read', false)->count();

        $readBroadcastIds = \Illuminate\Support\Facades\DB::table('notification_reads')
            ->where('user_id', $user->id)
            ->pluck('notification_id')
            ->toArray();

        $broadcastUnread = Notification::whereNull('user_id')
            ->whereNotIn('id', $readBroadcastIds)
            ->count();

        return response()->json([
            'status' => 'success',
            'data' => [
                'count' => $personalUnread + $broadcastUnread,
            ],
        ]);
    }

    public function markAsRead(Request $request, $id)
    {
        $user = $request->user();

        $notification = Notification::where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })
            ->where('id', $id)
            ->firstOrFail();

        if ($notification->user_id !== null) {
            $notification->update(['is_read' => true]);
        } else {
            \Illuminate\Support\Facades\DB::table('notification_reads')->updateOrInsert([
                'user_id' => $user->id,
                'notification_id' => $notification->id,
            ], [
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification marked as read',
        ]);
    }

    public function markAsUnread(Request $request, $id)
    {
        $user = $request->user();

        $notification = Notification::where(function ($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })
            ->where('id', $id)
            ->firstOrFail();

        if ($notification->user_id !== null) {
            $notification->update(['is_read' => false]);
        } else {
            \Illuminate\Support\Facades\DB::table('notification_reads')
                ->where('user_id', $user->id)
                ->where('notification_id', $notification->id)
                ->delete();
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification marked as unread',
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $user = $request->user();

        $notification = Notification::where('user_id', $user->id)
            ->where('id', $id)
            ->firstOrFail();

        $notification->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Notification deleted successfully',
        ]);
    }
}
