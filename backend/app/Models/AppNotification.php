<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'rental_id', 'type', 'title', 'message', 'is_read'])]
class AppNotification extends Model
{
    protected $table = 'notifications';

    protected function casts(): array
    {
        return ['is_read' => 'boolean'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
