<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'Admin Panel') - Apotek Sehat Online</title>
    <link rel="icon" type="image/png" href="{{ asset('assets/images/2.png') }}">
    @vite(['resources/css/admin.css', 'resources/js/admin.js'])
</head>
<body>
    <div class="admin-wrapper">
        <!-- Sidebar -->
        <aside class="admin-sidebar" id="adminSidebar">
            <div class="sidebar-brand">
                <img src="{{ asset('assets/images/2.png') }}" alt="Logo Apotek Sehat" class="sidebar-brand-logo">
                <div class="sidebar-brand-text">
                    <h2>Apotek Sehat</h2>
                    <small>Admin Management</small>
                </div>
                <button type="button" class="sidebar-close" id="sidebarClose" aria-label="Tutup menu">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                        <path d="M18 6 6 18M6 6l12 12"></path>
                    </svg>
                </button>
            </div>
            <ul class="sidebar-menu">
                <li class="sidebar-item">
                    <a href="{{ route('admin.dashboard') }}" class="sidebar-link {{ request()->routeIs('admin.dashboard') ? 'active' : '' }}">
                        <span>📊</span>
                        <span>Dashboard</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.produk.index') }}" class="sidebar-link {{ request()->routeIs('admin.produk.*') ? 'active' : '' }}">
                        <span>📦</span>
                        <span>Kelola Produk Obat</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.pesanan.index') }}" class="sidebar-link {{ request()->routeIs('admin.pesanan.*') ? 'active' : '' }}">
                        <span>🛍️</span>
                        <span>Pesanan Masuk</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.kurir.index') }}" class="sidebar-link {{ request()->routeIs('admin.kurir.*') ? 'active' : '' }}">
                        <span>🚚</span>
                        <span>Kurir & Wilayah</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.keranjang.index') }}" class="sidebar-link {{ request()->routeIs('admin.keranjang.*') ? 'active' : '' }}">
                        <span>🛒</span>
                        <span>Pantau Keranjang</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.profil.edit') }}" class="sidebar-link {{ request()->routeIs('admin.profil.*') ? 'active' : '' }}">
                        <span>🧑‍💼</span>
                        <span>Edit Profil</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.akun.index') }}" class="sidebar-link {{ request()->routeIs('admin.akun.*') ? 'active' : '' }}">
                        <span>👥</span>
                        <span>Kelola Admin</span>
                    </a>
                </li>
                <li class="sidebar-item">
                    <a href="{{ route('admin.kelola-aplikasi.index') }}" class="sidebar-link {{ request()->routeIs('admin.kelola-aplikasi.*') ? 'active' : '' }}">
                        <span>⚙️</span>
                        <span>Kelola Aplikasi</span>
                    </a>
                </li>
            </ul>
            <div class="sidebar-footer">
                <form action="{{ route('admin.logout') }}" method="POST">
                    @csrf
                    <button type="submit" class="btn-logout-sidebar" title="Keluar dari panel admin">
                        <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <path d="M16 17l5-5-5-5"></path>
                            <path d="M21 12H9"></path>
                        </svg>
                        <span>Keluar</span>
                    </button>
                </form>
            </div>
        </aside>
        <div class="sidebar-overlay" id="sidebarOverlay" aria-hidden="true"></div>

        <!-- Main Content -->
        <div class="admin-main">
            <!-- Navbar Header -->
            <header class="admin-navbar">
                <div class="admin-navbar-left">
                    <button type="button" class="sidebar-toggle" id="sidebarToggle" aria-label="Buka menu" aria-controls="adminSidebar" aria-expanded="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
                            <path d="M4 6h16M4 12h16M4 18h16"></path>
                        </svg>
                    </button>
                    <div class="admin-navbar-heading">
                        <h3>@yield('page_heading', 'Dashboard')</h3>
                        <small>Panel Pengaturan Data Terintegrasi Aplikasi Flutter</small>
                    </div>
                </div>
                <div class="admin-navbar-tools">
                    <a href="{{ route('admin.produk.create') }}" class="btn btn-primary btn-sm" title="Tambah produk baru">
                        <span aria-hidden="true">+</span>
                        <span class="btn-label">Tambah Produk</span>
                    </a>
                    <div class="admin-user">
                        <div class="admin-user-avatar" aria-hidden="true">
                            {{ strtoupper(substr(auth()->user()->name ?? 'Admin', 0, 1)) }}
                        </div>
                        <div class="admin-user-meta">
                            <small>Masuk sebagai</small>
                            <strong>{{ auth()->user()->name ?? 'Admin' }}</strong>
                        </div>
                    </div>
                </div>
            </header>

            <!-- Body -->
            <main class="admin-content">
                @if(session('sukses'))
                    <div class="alert alert-success flash-alert" data-type="success" data-message="{{ session('sukses') }}">
                        {{ session('sukses') }}
                    </div>
                @endif

                @if(session('galat'))
                    <div class="alert alert-danger flash-alert" data-type="error" data-message="{{ session('galat') }}">
                        {{ session('galat') }}
                    </div>
                @endif

                @if($errors->any())
                    <div class="alert alert-danger flash-alert" data-type="error" data-message="{{ $errors->first() }}">
                        <ul style="margin: 0; padding-left: 20px;">
                            @foreach($errors->all() as $err)
                                <li>{{ $err }}</li>
                            @endforeach
                        </ul>
                    </div>
                @endif

                @yield('content')
            </main>
        </div>
    </div>
</body>
</html>

