<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class UserController extends Controller
{
    public function index(Request $request): View
    {
        $role = $request->query('role', 'all');
        $search = trim((string) $request->query('search', ''));

        return view('admin.users.index', [
            'users' => User::query()
                ->withCount('rentals')
                ->when(in_array($role, ['user', 'admin', 'superadmin', 'device'], true), function ($query) use ($role): void {
                    $query->where('role', $role);
                })
                ->when($search !== '', function ($query) use ($search): void {
                    $query->where(function ($query) use ($search): void {
                        $query->where('name', 'like', '%'.$search.'%')
                            ->orWhere('email', 'like', '%'.$search.'%')
                            ->orWhere('phone', 'like', '%'.$search.'%');
                    });
                })
                ->orderBy('name')
                ->paginate(20)
                ->withQueryString(),
            'role' => $role,
            'search' => $search,
        ]);
    }

    public function show(User $user): View
    {
        return view('admin.users.show', [
            'targetUser' => $user->loadCount('rentals')->load([
                'rentals' => fn ($query) => $query->with('bike')->latest('started_at')->limit(30),
                'assignedBikes',
            ]),
        ]);
    }

    public function updateRole(Request $request, User $user): RedirectResponse
    {
        $data = $request->validate([
            'role' => ['required', 'in:user,admin,superadmin,device'],
        ]);

        $user->update(['role' => $data['role']]);

        return redirect()->route('admin.users.show', $user)->with('status', 'Hak akses pengguna diperbarui.');
    }
}
