<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Notification extends Model
{
    protected $fillable = [
        'user_id',
        'title',
        'message',
        'type',
        'is_read',
        'start_time',
        'end_time',
        'data',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'data' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
