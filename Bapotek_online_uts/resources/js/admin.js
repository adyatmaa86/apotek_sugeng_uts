// Script interaksi admin panel (modal, konfirmasi, dll)
document.addEventListener('DOMContentLoaded', () => {
    // Modal Kurir Form
    const modalKurir = document.getElementById('modalKurir');
    const btnBukaKurir = document.getElementById('btnBukaModalKurir');
    const btnTutupKurir = document.getElementById('btnTutupModalKurir');

    if (btnBukaKurir && modalKurir) {
        btnBukaKurir.addEventListener('click', () => {
            document.getElementById('formKurir').reset();
            document.getElementById('formKurir').action = btnBukaKurir.dataset.urlStore;
            document.getElementById('kurirMethod').value = 'POST';
            document.getElementById('modalKurirTitle').innerText = 'Tambah Kurir Baru';
            modalKurir.style.display = 'flex';
        });
    }

    if (btnTutupKurir && modalKurir) {
        btnTutupKurir.addEventListener('click', () => {
            modalKurir.style.display = 'none';
        });
    }

    // Modal Edit Kurir trigger
    document.querySelectorAll('.btn-edit-kurir').forEach(btn => {
        btn.addEventListener('click', () => {
            const id = btn.dataset.id;
            const nama = btn.dataset.nama;
            const wilayah = btn.dataset.wilayah;
            const tarif = btn.dataset.tarif;
            const estimasi = btn.dataset.estimasi;
            const urlUpdate = btn.dataset.urlUpdate;

            document.getElementById('formKurir').action = urlUpdate;
            document.getElementById('kurirMethod').value = 'PUT';
            document.getElementById('modalKurirTitle').innerText = 'Edit Kurir: ' + nama;
            document.getElementById('kurirNama').value = nama;
            document.getElementById('kurirWilayah').value = wilayah;
            document.getElementById('kurirTarif').value = tarif;
            document.getElementById('kurirEstimasi').value = estimasi;

            modalKurir.style.display = 'flex';
        });
    });

    // Sidebar responsif
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebarClose = document.getElementById('sidebarClose');
    const sidebarOverlay = document.getElementById('sidebarOverlay');

    const aturSidebar = (terbuka) => {
        document.body.classList.toggle('sidebar-open', terbuka);
        sidebarToggle?.setAttribute('aria-expanded', terbuka ? 'true' : 'false');
    };

    sidebarToggle?.addEventListener('click', () => {
        aturSidebar(!document.body.classList.contains('sidebar-open'));
    });

    sidebarClose?.addEventListener('click', () => aturSidebar(false));
    sidebarOverlay?.addEventListener('click', () => aturSidebar(false));

    document.querySelectorAll('.sidebar-link').forEach((link) => {
        link.addEventListener('click', () => aturSidebar(false));
    });

    document.addEventListener('keydown', (event) => {
        if (event.key === 'Escape') {
            aturSidebar(false);

            if (modalKurir) {
                modalKurir.style.display = 'none';
            }
        }
    });

    if (modalKurir) {
        modalKurir.addEventListener('click', (event) => {
            if (event.target === modalKurir) {
                modalKurir.style.display = 'none';
            }
        });
    }

    window.addEventListener('resize', () => {
        if (window.innerWidth > 1024) {
            aturSidebar(false);
        }
    });

    // Auto dismiss alert after 5s
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.transition = 'opacity 0.5s ease';
            alert.style.opacity = '0';
            setTimeout(() => alert.remove(), 500);
        }, 5000);
    });
});

