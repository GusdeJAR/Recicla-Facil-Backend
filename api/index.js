// api/index.js (Versión de Diagnóstico)

const express = require('express');
const app = express();

// Middleware para parsear JSON, siempre es bueno tenerlo
app.use(express.json());

// Creamos una ruta para /api/usuarios DIRECTAMENTE aquí
app.get('/api/usuarios', (req, res) => {
  console.log("¡La ruta /api/usuarios fue alcanzada!");
  res.status(200).json([
    { id: 1, nombre: "Usuario de prueba" }
  ]);
});

// Un "catch-all" para cualquier otra ruta que llegue a la API
// Esto nos ayudará a ver si la petición al menos llega al servidor
app.use('/api/(.*)', (req, res) => {
  console.log(`Ruta no encontrada: ${req.method} ${req.originalUrl}`);
  res.status(404).json({
    error: `La ruta interna '${req.path}' no fue encontrada dentro de la aplicación Express.`,
    originalUrl: req.originalUrl
  });
});

// Exportamos la app para Vercel
module.exports = app;
