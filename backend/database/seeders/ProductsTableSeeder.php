<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class ProductsTableSeeder extends Seeder
{
    public function run()
    {
        DB::table('products')->insert([
            [
                'name' => 'Logitech G102 Gaming Mouse',
                'category' => 'Accessories',
                'price' => 1850.00,
                'stock' => 15,
                'description' => 'RGB Gaming Mouse with 8000 DPI Sensor.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'A4Tech FH100 Earphone',
                'category' => 'Accessories',
                'price' => 750.00,
                'stock' => 20,
                'description' => 'High quality noise cancelling earphone.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'HP 12A Toner Cartridge',
                'category' => 'Printer Accessories',
                'price' => 1200.00,
                'stock' => 8,
                'description' => 'Compatible toner cartridge for HP LaserJet printer.',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // ID 4,5,6 ডুপ্লিকেট, তাই বাদ দেয়া ভালো
        ]);
    }
}