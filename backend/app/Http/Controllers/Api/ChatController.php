<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class ChatController extends Controller
{
    public function sendMessage(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);

        $userMessage = new Message();
        $userMessage->sender = 'user';
        $userMessage->content = $request->message;
        $userMessage->save();

        $pastmessages = Message::orderBy('id', 'desc')->get()->reverse();

        $ontext = '';

        foreach ($pastmessages as $message) {
            $rote = ($message->sender === 'user') ? 'User' : 'Model';
            $ontext .= $rote . ': ' . $message->content . "\n";
        }

        $context = "User: " . $request->message . "\n" . $ontext;

        $api_key = env('GEMINI_API_KEY');
        $url = "https://generativelanguage.googleapis.com/v1beta/interactions";

        $system_prompt = config('bot.system_prompt');

        
        $response = Http::withHeaders([
            'x-goog-api-key' => $api_key,
            'content-type' => 'application/json',
        ])->withBody(
            json_encode([
                'model' => 'gemini-3.5-flash',
                'input' => $system_prompt . "\n\n" . $context,
            ]),
            'application/json'
        )->post($url);

        $http_code = $response->status();
        $responseData = $response->json();


        if ($http_code == 200 && isset($responseData)) {

            $botMessageContent = $this->extractBotResponseFromInteraction($responseData);

            $botMessage = new Message();
            $botMessage->sender = 'bot';
            $botMessage->content = $botMessageContent;
            $botMessage->save();

            return response()->json([
                'status' => 'success',
                'user_message' => $userMessage,
                'bot_message' => $botMessage,
            ]);
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get response from the bot.',
                'error_details' => $responseData ?? $response->body()
            ], 500);
        }
    }

    private function extractBotResponseFromInteraction($data)
    {

        if (isset($data['steps']) && is_array($data['steps'])) {
            foreach ($data['steps'] as $step) {

                if (isset($step['type']) && $step['type'] === 'model_output') {
                    if (isset($step['content'][0]['text'])) {
                        return $step['content'][0]['text'];
                    }
                }
            }
        }

        if (isset($data['output'])) {
            return $data['output'];
        }

        return json_encode($data);
    }

    public function getMessages()
    {
        $messages = Message::orderBy('id', 'asc')->get();
        return response()->json(['status' => 'success', 'messages' => $messages]);
    }
}
