import SwaggerUI from 'swagger-ui-dist/swagger-ui-es-bundle.js';

document.addEventListener('DOMContentLoaded', () => {
    const el = document.getElementById('swagger-ui');
    if (!el) return;

    const specUrl = el.dataset.specUrl || '/docs/openapi.json';

    SwaggerUI({
        url: specUrl,
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
            SwaggerUI.presets.apis,
        ],
        layout: "BaseLayout",
        docExpansion: "list",
        defaultModelsExpandDepth: 1,
        persistAuthorization: true,
    });
});

