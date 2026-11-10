<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pesanans', function (Blueprint $table) {
            // Menyimpan path file foto resep dokter (nullable)
            $table->string('foto_resep')->nullable()->after('nomor_resep');
        });
    }

    public function down(): void
    {
        Schema::table('pesanans', function (Blueprint $table) {
            $table->dropColumn('foto_resep');
        });
    }
};

