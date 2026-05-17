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
            'target' => 'required|in:all,specific',
            'user_id' => 'required_if:target,specific|nullable|exists:users,id',
        ]);

        $userId = $validated['target'] === 'specific' ? $validated['user_id'] : null;

        Notification::create([
            'user_id' => $userId,
            'title' => $validated['title'],
            'message' => $validated['message'],
            'type' => 'pengumuman',
        ]);

        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil dikirim!');
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
            'target' => 'required|in:all,specific',
            'user_id' => 'required_if:target,specific|nullable|exists:users,id',
        ]);

        $userId = $validated['target'] === 'specific' ? $validated['user_id'] : null;

        $notification->update([
            'user_id' => $userId,
            'title' => $validated['title'],
            'message' => $validated['message'],
        ]);

        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil diperbarui!');
    }

    public function destroy(Notification $notification)
    {
        $notification->delete();
        return redirect()->route('admin.notifications.index')->with('success', 'Pengumuman berhasil dihapus!');
    }
}
