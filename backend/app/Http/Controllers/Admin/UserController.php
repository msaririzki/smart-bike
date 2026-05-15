<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
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
                ->where('role', '!=', 'device')
                ->when(in_array($role, ['user', 'admin', 'superadmin'], true), function ($query) use ($role): void {
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


    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users'],
            'phone' => ['required', 'string', 'max:20', 'unique:users'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'in:user,admin,superadmin'],
        ]);

        $data['password'] = Hash::make($data['password']);

        User::create($data);

        return redirect()->route('admin.users.index')->with('status', 'User berhasil ditambahkan.');
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
