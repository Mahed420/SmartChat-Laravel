<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ChatController;


Route::post('/send-message', [ChatController::class, 'sendMessage']);
Route::get('/messages', [ChatController::class, 'getMessages']);