// /api/index.js - VERSIÓN DE DIAGNÓSTICO CON LOGS

const express = require('express');
const cors = require('cors');
const router = require('./routes/router');

// NO conectar a la DB por ahora, para aislar el problema
// const conectarDB = require('../config/db');

console.log("=========================================");
console.log("FUNCIÓN INVOCADA: El archivo api/index.js se ha iniciado.");
console.log(`Fecha y Hora (UTC): ${new Date().toUTCString()}`);
console.log("=========================================");

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Middleware de Logging para CADA petición
app.use((req, res, next) => {
  console.log("--- Petición Recibida ---");
  console.log(`Método: ${req.method}`);
  console.log(`URL Original: ${req.originalUrl}`); // La URL completa que llegó
  console.log(`Path: ${req.path}`);               // La parte de la ruta que Express procesa
  console.log("--------------------------");
  next(); // Pasa la petición al siguiente middleware o ruta
});

// Montamos el router en la raíz '/'
// Express intentará emparejar rutas como /usuarios, /test, etc.
app.use(router);

// Middleware "Catch-All" (Captura-Todo) al FINAL
// Si una petición llega hasta aquí, significa que NO coincidió con NINGUNA ruta en `router.js`
app.use((req, res, next) => {
  console.error("!!! ERROR: RUTA NO ENCONTRADA EN EXPRESS !!!");
  console.error(`La petición para ${req.originalUrl} no fue manejada por el router.`);
  res.status(404).json({
    error: 'Ruta no encontrada dentro de la aplicación Express.',
    path_solicitado: req.originalUrl,
  });
});

// Exportamos la app para Vercel
module.exports = app;
