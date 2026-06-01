<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index()
    {
        $notifications = Notification::where('type', '!=', 'sewa')->with('user')->orderBy('created_at', 'desc')->paginate(15);
        return view('admin.notifications.index', compact('notifications'));
    }

    public function create()
    {
        $users = User::orderBy('name')->get();
        return view('admin.notifications.create', compact('users'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:pengumuman,promosi',
            'target' => 'required|in:all,specific',
            'user_id' => 'required_if:target,specific|nullable|exists:users,id',
            'start_time' => 'nullable|date',
            'end_time' => 'nullable|date|after_or_equal:start_time',
        ]);

        $userId = $validated['target'] === 'specific' ? $validated['user_id'] : null;

        Notification::create([
            'user_id' => $userId,
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => $validated['type'],
            'start_time' => !empty($validated['start_time']) ? \Carbon\Carbon::parse($validated['start_time'])->format('Y-m-d H:i:s') : null,
            'end_time' => !empty($validated['end_time']) ? \Carbon\Carbon::parse($validated['end_time'])->format('Y-m-d H:i:s') : null,
        ]);

        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil dikirim!');
    }

    public function show(Notification $notification)
    {
        return view('admin.notifications.show', compact('notification'));
    }

    public function edit(Notification $notification)
    {
        $users = User::orderBy('name')->get();
        return view('admin.notifications.edit', compact('notification', 'users'));
    }

    public function update(Request $request, Notification $notification)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'required|in:pengumuman,promosi',
            'target' => 'required|in:all,specific',
            'user_id' => 'required_if:target,specific|nullable|exists:users,id',
            'start_time' => 'nullable|date',
            'end_time' => 'nullable|date|after_or_equal:start_time',
        ]);

        $userId = $validated['target'] === 'specific' ? $validated['user_id'] : null;

        $notification->update([
            'user_id' => $userId,
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => $validated['type'],
            'start_time' => !empty($validated['start_time']) ? \Carbon\Carbon::parse($validated['start_time'])->format('Y-m-d H:i:s') : null,
            'end_time' => !empty($validated['end_time']) ? \Carbon\Carbon::parse($validated['end_time'])->format('Y-m-d H:i:s') : null,
        ]);

        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil diperbarui!');
    }

    public function destroy(Notification $notification)
    {
        $notification->delete();
        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil dihapus!');
    }
}
