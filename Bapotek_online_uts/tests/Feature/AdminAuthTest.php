<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminAuthTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutVite();
    }

    public function test_admin_panel_mengarahkan_ke_halaman_login(): void
    {
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_halaman_login_dapat_ditampilkan(): void
    {
        $this->get(route('admin.login'))
            ->assertOk()
            ->assertSee('Masuk ke Panel');
    }

    public function test_login_menolak_kredensial_yang_salah(): void
    {
        $admin = $this->buatAdmin();

        $this->from(route('admin.login'))
            ->post(route('admin.login.submit'), [
                'email' => $admin->email,
                'password' => 'password-salah',
            ])
            ->assertRedirect(route('admin.login'))
            ->assertSessionHasErrors('email');

        $this->assertGuest();
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_login_hanya_untuk_user_admin(): void
    {
        $pengguna = $this->buatAdmin(['is_admin' => false]);

        $this->from(route('admin.login'))
            ->post(route('admin.login.submit'), [
                'email' => $pengguna->email,
                'password' => 'password-test',
            ])
            ->assertRedirect(route('admin.login'))
            ->assertSessionHasErrors('email');

        $this->assertGuest();
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    public function test_admin_dapat_login_dan_logout(): void
    {
        $admin = $this->buatAdmin();

        $this->post(route('admin.login.submit'), [
            'email' => $admin->email,
            'password' => 'password-test',
        ])->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticatedAs($admin);
        $this->get('/admin')->assertOk()->assertSee($admin->name);

        $this->post(route('admin.logout'))->assertRedirect(route('admin.login'));

        $this->assertGuest();
        $this->get('/admin')->assertRedirect(route('admin.login'));
    }

    private function buatAdmin(array $atribut = []): User
    {
        return User::factory()->create(array_merge([
            'name' => 'Admin Pengujian',
            'email' => 'admin@uji.test',
            'password' => 'password-test',
            'is_admin' => true,
        ], $atribut));
    }
}
