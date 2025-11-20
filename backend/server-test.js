// server-test.js
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

// 1. Middleware CORS: Permite todas las peticiones.
app.use(cors());
console.log("CORS middleware habilitado para todas las rutas.");

// 2. Middleware de Archivos Estáticos: Mapea la URL '/' a la carpeta física 'assets'.
app.use(express.static(path.join(__dirname, 'assets')));
console.log(`Sirviendo archivos estáticos desde: ${path.join(__dirname, 'assets')}`);

// 3. Ruta de prueba de la API
app.get('/api/test', (req, res) => {
  console.log("Petición recibida en /api/test");
  res.json({ message: '¡El servidor de prueba está funcionando!' });
});

// Inicia el servidor
app.listen(PORT, () => {
  console.log(`--- SERVIDOR DE PRUEBA corriendo en http://localhost:${PORT} ---`);
});
