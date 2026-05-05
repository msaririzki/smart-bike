<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['key', 'value', 'value_type', 'group_name', 'description', 'updated_by'])]
class PricingSetting extends Model {}
