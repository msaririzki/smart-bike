<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <title>Kode Reset Password FlowBike</title>
</head>
<body style="margin:0; padding:0; background:#f4fbf7; font-family:Arial, sans-serif; color:#133c36;">
    <div style="max-width:560px; margin:0 auto; padding:32px 20px;">
        <div style="background:#ffffff; border:1px solid #dbeee4; border-radius:16px; padding:28px;">
            <p style="margin:0 0 8px; color:#349665; font-weight:700;">FlowBike</p>
            <h1 style="margin:0; font-size:24px; line-height:1.25;">Reset password akun</h1>
            <p style="margin:16px 0 0; line-height:1.6; color:#475569;">
                Halo {{ $user->name }}, masukkan kode berikut di aplikasi FlowBike untuk membuat password baru.
            </p>
            <div style="margin:24px 0; padding:18px; background:#ecfdf5; border-radius:12px; text-align:center;">
                <div style="font-size:34px; letter-spacing:8px; font-weight:800; color:#133c36;">{{ $code }}</div>
            </div>
            <p style="margin:0; line-height:1.6; color:#64748b;">
                Kode ini berlaku {{ $expiresInMinutes }} menit. Abaikan email ini jika kamu tidak meminta reset password.
            </p>
        </div>
    </div>
</body>
</html>
