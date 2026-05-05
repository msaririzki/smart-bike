<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bike;
use Illuminate\Http\JsonResponse;

class BikeController extends Controller
{
    public function index(): JsonResponse
    {
        return response()->json([
            'data' => Bike::query()
                ->orderBy('code')
                ->get(),
        ]);
    }

    public function show(Bike $bike): JsonResponse
    {
        return response()->json(['data' => $bike]);
    }
}
