<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apotek Sugeng - Dokumentasi REST API</title>
    @vite(['resources/css/swagger.css', 'resources/js/swagger.js'])
</head>
<body class="swagger-body">
    <div id="swagger-ui" data-spec-url="{{ asset('docs/openapi.json') }}"></div>
</body>
</html>