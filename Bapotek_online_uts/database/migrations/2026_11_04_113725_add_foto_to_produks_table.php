<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (! Schema::hasTable('produks') || Schema::hasColumn('produks', 'foto')) {
            return;
        }

        Schema::table('produks', function (Blueprint $table) {
            $table->string('foto')->nullable()->after('deskripsi');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('produks') && Schema::hasColumn('produks', 'foto')) {
            Schema::table('produks', function (Blueprint $table) {
                $table->dropColumn('foto');
            });
        }
    }
};
