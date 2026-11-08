<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="noindex, nofollow">
    <title>Login Admin - Apotek Sehat Online</title>
    <link rel="icon" type="image/png" href="{{ asset('assets/images/2.png') }}">
    @vite(['resources/css/admin.css', 'resources/js/admin.js'])
</head>
<body class="login-body">
    <main class="login-page">
        <div class="login-shell">
            <section class="login-brand">
                <div>
                    <div class="login-logo" aria-hidden="true">
                        <img src="{{ asset('assets/images/2.png') }}" alt="Logo Apotek Sehat" class="login-logo-img">
                    </div>
                    <span class="login-eyebrow">APOTEK SEHAT ONLINE</span>
                    <h1>Panel Admin<br>Apotek</h1>
                    <p class="login-brand-text">
                        Kelola produk, pesanan, kurir, dan pantau keranjang pelanggan
                        langsung dari satu panel terintegrasi.
                    </p>
                    <ul class="login-features">
                        <li>
                            <span class="login-feature-check">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M20 6 9 17l-5-5"></path>
                                </svg>
                            </span>
                            Kelola katalog obat dan stok
                        </li>
                        <li>
                            <span class="login-feature-check">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M20 6 9 17l-5-5"></path>
                                </svg>
                            </span>
                            Pantau pesanan dan status pengiriman
                        </li>
                        <li>
                            <span class="login-feature-check">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M20 6 9 17l-5-5"></path>
                                </svg>
                            </span>
                            Atur kurir dan tarif wilayah
                        </li>
                    </ul>
                </div>
                <div class="login-brand-footer">
                    <span class="login-status-dot" aria-hidden="true"></span>
                    Sinkronisasi API Flutter aktif
                </div>
            </section>

            <section class="login-card">
                <span class="login-card-badge">Admin Access</span>
                <h2>Masuk ke Panel</h2>
                <p class="login-card-sub">Gunakan akun admin yang terdaftar untuk melanjutkan ke dashboard.</p>

                @if (session('sukses'))
                    <div class="alert alert-success login-alert" role="status">
                        {{ session('sukses') }}
                    </div>
                @endif

                @if ($errors->any())
                    <div class="alert alert-danger login-alert" role="alert">
                        {{ $errors->first() }}
                    </div>
                @endif

                <form action="{{ route('admin.login.submit') }}" method="POST" autocomplete="on">
                    @csrf

                    <div class="form-group">
                        <label class="form-label" for="email">Email</label>
                        <div class="login-field">
                            <span class="login-field-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="5" width="18" height="14" rx="2"></rect>
                                    <path d="m3 7 9 6 9-6"></path>
                                </svg>
                            </span>
                            <input
                                type="email"
                                id="email"
                                name="email"
                                class="form-control login-input @error('email') is-invalid @enderror"
                                value="{{ old('email') }}"
                                placeholder="Masukkan email admin"
                                autocomplete="email"
                                required
                                autofocus
                                @error('email') aria-invalid="true" @enderror
                            >
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label" for="password">Password</label>
                        <div class="login-field">
                            <span class="login-field-icon" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="4" y="10" width="16" height="11" rx="2"></rect>
                                    <path d="M8 10V7a4 4 0 0 1 8 0v3"></path>
                                </svg>
                            </span>
                            <input
                                type="password"
                                id="password"
                                name="password"
                                class="form-control login-input has-toggle @error('password') is-invalid @enderror"
                                placeholder="Masukkan password admin"
                                autocomplete="current-password"
                                required
                                @error('password') aria-invalid="true" @enderror
                            >
                            <button
                                type="button"
                                id="togglePassword"
                                class="login-field-toggle"
                                aria-label="Tampilkan password"
                                aria-controls="password"
                            >
                                <svg id="eyeIcon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12Z"></path>
                                    <circle cx="12" cy="12" r="3"></circle>
                                </svg>
                                <svg id="eyeOffIcon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" style="display: none;">
                                    <path d="M9.9 4.24A9.1 9.1 0 0 1 12 4c6.5 0 10 7 10 7a18.9 18.9 0 0 1-2.16 3.19"></path>
                                    <path d="M6.61 6.61A18.8 18.8 0 0 0 2 12s3.5 7 10 7a9.1 9.1 0 0 0 5.39-1.61"></path>
                                    <path d="M14.12 14.12A3 3 0 0 1 9.88 9.88"></path>
                                    <path d="M2 2l20 20"></path>
                                </svg>
                            </button>
                        </div>
                    </div>

                    <div class="login-options">
                        <label class="login-remember">
                            <input type="checkbox" name="remember" value="1" @checked(old('remember'))>
                            <span>Ingat saya di perangkat ini</span>
                        </label>
                    </div>

                    <button type="submit" class="btn login-submit">
                        Masuk ke Panel
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <path d="M5 12h14M13 6l6 6-6 6"></path>
                        </svg>
                    </button>
                </form>

                <div class="login-footer">
                    Apotek Sehat Online &copy; {{ date('Y') }} &middot; Panel Admin
                </div>
            </section>
        </div>
    </main>

    <script>
        (function () {
            const toggle = document.getElementById('togglePassword');
            const input = document.getElementById('password');
            const eye = document.getElementById('eyeIcon');
            const eyeOff = document.getElementById('eyeOffIcon');

            if (!toggle || !input || !eye || !eyeOff) {
                return;
            }

            toggle.addEventListener('click', function () {
                const show = input.type === 'password';
                input.type = show ? 'text' : 'password';
                eye.style.display = show ? 'none' : 'block';
                eyeOff.style.display = show ? 'block' : 'none';
                toggle.setAttribute('aria-label', show ? 'Sembunyikan password' : 'Tampilkan password');
            });
        })();
    </script>
</body>
</html>
