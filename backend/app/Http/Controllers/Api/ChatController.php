<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    /**
     * ফ্ল্যাটার অ্যাপ থেকে মেসেজ রিসিভ করা এবং ডাটাবেজে সেভ করা।
     */
    public function sendMessage(Request $request)
    {
        // ১. ফ্ল্যাটার থেকে আসা রিকোয়েস্ট ভ্যালিডেশন করা
        $request->validate([
            'message' => 'required|string',
        ]);

        // ২. ইউজারের পাঠানো মেসেজটি ডাটাবেজে সেভ করা
        $userMessage = new Message();
        $userMessage->sender = 'user';
        $userMessage->content = $request->message;
        $userMessage->save(); 

        // ৩. বটের একটি ডামি রিপ্লাই তৈরি করা এবং সেটিও ডাটাবেজে সেভ করা
        $botMessage = new Message();
        $botMessage->sender = 'bot';
        $botMessage->content = 'লারাভেল ব্যাকএন্ড আপনার মেসেজটি পেয়েছে: ' . $request->message;
        $botMessage->save();

        // ৪. ফ্রন্টএন্ড (Flutter)-এ JSON রেসপন্স রিটার্ন করা
        return response()->json([
            'status' => 'success',
            'user_message' => $userMessage,
            'bot_message' => $botMessage
        ]);
    }
}
