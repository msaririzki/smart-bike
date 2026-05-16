<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function create()
    {
        return view('admin.notifications.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string',
        ]);

        // Broadcast to all users by leaving user_id as null
        NotificationService::send(
            null,
            $validated['title'],
            $validated['message'],
            'pengumuman'
        );

        return redirect()->route('admin.notifications.create')->with('success', 'Pengumuman berhasil dikirim ke semua pengguna!');
    }
}
