<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Products;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatController extends Controller
{
    /**
     * Send a user message and get a bot reply using Gemini API.
     */
    public function sendMessage(Request $request)
    {
        $request->validate([
            'message' => 'required|string',
        ]);


        $userMessage = new Message();
        $userMessage->sender = 'user';
        $userMessage->content = $request->message;
        $userMessage->save();


        $keywords = $this->extractSearchKeywords($request->message);
        Log::info('কীওয়ার্ড:', $keywords);


        if (!empty($keywords)) {
            $products = Products::where(function ($q) use ($keywords) {
                $q->where('name', 'LIKE', "%{$keywords[0]}%")
                    ->orWhere('description', 'LIKE', "%{$keywords[0]}%");
                for ($i = 1; $i < count($keywords); $i++) {
                    $keyword = $keywords[$i];
                    $q->orWhere('name', 'LIKE', "%{$keyword}%")
                        ->orWhere('description', 'LIKE', "%{$keyword}%");


                    $englishKeyword = $this->toEnglish($keyword);
                    if ($englishKeyword !== $keyword) {
                        $q->orWhere('name', 'LIKE', "%{$englishKeyword}%")
                            ->orWhere('description', 'LIKE', "%{$englishKeyword}%");
                    }
                }
            })->get();
        } else {
            $products = Products::where('name', 'LIKE', '%' . $request->message . '%')
                ->orWhere('description', 'LIKE', '%' . $request->message . '%')
                ->get();
        }

        Log::info('প্রোডাক্ট সংখ্যা:', [$products->count()]);


        if ($products->isNotEmpty()) {
            $productList = "📦 আমাদের পাওয়া প্রাসঙ্গিক পণ্যসমূহ:\n";
            foreach ($products as $product) {
                $productList .= "• **{$product->name}**\n";
                $productList .= "  📝 বিবরণ: {$product->description}\n";
                $productList .= "  💰 দাম: {$product->price} টাকা\n";
                $productList .= "  📦 স্টক: {$product->stock}টি\n\n";
            }
        } else {
            $productList = "🔍 '{$request->message}' সম্পর্কিত কোনো পণ্য আমরা খুঁজে পাইনি। আপনি কি অন্য কোনো পণ্য সম্পর্কে জানতে চান?";
        }
        Log::info('কীওয়ার্ড:', $keywords);
        Log::info('প্রোডাক্ট সংখ্যা:', [$products->count()]);
        Log::info('পণ্যের তালিকা:', [$productList]);

        $systemPrompt = config('bot.system_prompt') . "\n\n" . $productList;


        $pastMessages = Message::orderBy('id', 'asc')->get();
        $contents = [];
        foreach ($pastMessages as $msg) {
            $role = ($msg->sender === 'user') ? 'user' : 'model';
            $contents[] = [
                'role' => $role,
                'parts' => [['text' => $msg->content]],
            ];
        }

        $payload = [
            'contents' => $contents,
        ];

        if (!empty($systemPrompt)) {
            $payload['system_instruction'] = [
                'parts' => [['text' => $systemPrompt]],
            ];
        }


        try {
            $apiKey = env('GEMINI_API_KEY');
            $model = env('GEMINI_MODEL', 'gemini-1.5-flash');
            $model = preg_replace('#^models/#', '', $model);

            if (empty($apiKey)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'GEMINI_API_KEY is not configured.',
                ], 500);
            }

            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}";

            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->asJson()->post($url, $payload);

            $httpCode = $response->status();
            $responseData = $response->json();


            if ($httpCode === 200 && isset($responseData['candidates'][0]['content']['parts'][0]['text'])) {
                $botReply = trim($responseData['candidates'][0]['content']['parts'][0]['text']);

                $botMessage = new Message();
                $botMessage->sender = 'bot';
                $botMessage->content = $botReply;
                $botMessage->save();

                return response()->json([
                    'status' => 'success',
                    'user_message' => $userMessage,
                    'bot_message' => $botMessage,
                ]);
            }

            Log::error('Gemini API error', [
                'status' => $httpCode,
                'response' => $responseData ?? $response->body(),
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get a valid response from Gemini.',
                'details' => $responseData ?? $response->body(),
            ], 500);
        } catch (\Exception $e) {
            Log::error('Gemini API exception', ['message' => $e->getMessage()]);
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to communicate with the bot.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }


    private function toEnglish(string $text): string
    {
        $transliterationMap = [
            'মাউস' => 'mouse',
            'কী-বোর্ড' => 'keyboard',
            'কীবোর্ড' => 'keyboard',
            'মনিটর' => 'monitor',
            'ল্যাপটপ' => 'laptop',
            'প্রিন্টার' => 'printer',
            'স্ক্যানার' => 'scanner',
            'হেডফোন' => 'headphone',
            'ইয়ারফোন' => 'earphone',
            'মাইক্রোফোন' => 'microphone',
            'স্পিকার' => 'speaker',
            'পেনড্রাইভ' => 'pendrive',
            'হার্ডডিস্ক' => 'harddisk',
            'স্মার্টফোন' => 'smartphone',
        ];

        return str_ireplace(array_keys($transliterationMap), array_values($transliterationMap), $text);
    }


    private function extractSearchKeywords($query)
    {

        $stopWords = ['আছে', 'কি', 'কী', 'পাওয়া', 'যাবে', 'দরকার', 'প্রয়োজন', 'জানতে', 'চাই', 'আমার', 'আপনাদের', 'কোনো', 'হবে', 'করে', 'থেকে', 'মধ্যে', 'জন্য', 'সাথে', 'বলে', 'দিয়ে', 'নিয়ে', 'এবং', 'ও', 'বা'];


        $words = array_map('strtolower', explode(' ', $query));

        $keywords = array_filter($words, function ($word) use ($stopWords) {
            return !in_array($word, $stopWords) && strlen($word) > 2;
        });

        $keywords = array_values($keywords); 

        return $keywords;
    }

    /**
     * Retrieve all messages in chronological order.
     */
    public function getMessages()
    {
        $messages = Message::orderBy('id', 'asc')->get();
        return response()->json([
            'status'   => 'success',
            'messages' => $messages,
        ]);
    }
}
