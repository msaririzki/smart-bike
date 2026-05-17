<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

try {
    $user = App\Models\User::first();
    $notifications = App\Models\Notification::where('user_id', $user->id)
        ->orWhereNull('user_id')
        ->orderBy('created_at', 'desc')
        ->get();
    
    $readIds = \Illuminate\Support\Facades\DB::table('notification_reads')
        ->where('user_id', $user->id)
        ->pluck('notification_id')
        ->toArray();
    
    foreach ($notifications as $notif) {
        if ($notif->user_id === null) {
            $notif->is_read = in_array($notif->id, $readIds);
        }
    }
    echo json_encode(['status' => 'success', 'data' => $notifications]);
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n" . $e->getTraceAsString();
}
