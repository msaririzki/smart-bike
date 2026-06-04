<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\PasswordResetCodeMail;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:6'],
            'phone' => ['nullable', 'string', 'max:30'],
        ]);

        $user = User::query()->create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => $data['password'],
            'phone' => $data['phone'] ?? null,
            'role' => 'user',
        ]);

        return response()->json([
            'user' => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => 'Credential tidak valid.',
            ]);
        }

        return response()->json([
            'user' => $user,
            'token' => $user->createToken($user->role.'-token')->plainTextToken,
        ]);
    }

    public function requestPasswordReset(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
        ]);

        $user = User::query()
            ->where('email', $data['email'])
            ->where('role', 'user')
            ->first();

        if (! $user) {
            return response()->json([
                'message' => 'Jika email terdaftar, kode reset password akan dikirim.',
            ]);
        }

        $throttleSeconds = (int) config('auth.passwords.users.throttle', 60);
        $recentTokenExists = DB::table('password_reset_tokens')
            ->where('email', $user->email)
            ->where('created_at', '>', now()->subSeconds($throttleSeconds))
            ->exists();

        if ($recentTokenExists) {
            throw ValidationException::withMessages([
                'email' => "Tunggu {$throttleSeconds} detik sebelum meminta kode baru.",
            ]);
        }

        $code = (string) random_int(100000, 999999);

        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => Hash::make($code),
                'created_at' => now(),
            ],
        );

        Mail::to($user->email)->send(new PasswordResetCodeMail(
            user: $user,
            code: $code,
            expiresInMinutes: (int) config('auth.passwords.users.expire', 60),
        ));

        return response()->json([
            'message' => 'Kode reset password sudah dikirim ke email akun.',
        ]);
    }

    public function confirmPasswordReset(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'token' => ['required', 'digits:6'],
            'password' => ['required', 'string', 'min:6', 'confirmed'],
        ]);

        $resetToken = DB::table('password_reset_tokens')
            ->where('email', $data['email'])
            ->first();

        $expiresInMinutes = (int) config('auth.passwords.users.expire', 60);
        $isExpired = ! $resetToken || now()->subMinutes($expiresInMinutes)->greaterThan($resetToken->created_at);

        if ($isExpired || ! Hash::check($data['token'], $resetToken->token)) {
            throw ValidationException::withMessages([
                'token' => 'Kode reset tidak valid atau sudah kedaluwarsa.',
            ]);
        }

        $user = User::query()
            ->where('email', $data['email'])
            ->where('role', 'user')
            ->first();

        if (! $user) {
            throw ValidationException::withMessages([
                'email' => 'Akun tidak ditemukan.',
            ]);
        }

        $user->forceFill([
            'password' => $data['password'],
        ])->save();

        $user->tokens()->delete();

        DB::table('password_reset_tokens')
            ->where('email', $user->email)
            ->delete();

        return response()->json([
            'message' => 'Password berhasil diubah. Silakan login kembali.',
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()]);
    }

    public function updateMe(Request $request): JsonResponse
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:30'],
            'weight' => ['nullable', 'integer', 'min:30', 'max:300'],
        ]);

        $user->forceFill([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'weight' => $data['weight'] ?? null,
        ])->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user' => $user->fresh(),
        ]);
    }
}
