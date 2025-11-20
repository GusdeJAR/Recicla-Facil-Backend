// En /api/index.js

const express = require('express');
const cors = require('cors');
const path = require('path');
const conectarDB = require('../config/db');
const router = require('../routes/router'); // Importamos el router centralizado

const app = express();

// Conectar a la Base de Datos
conectarDB();

// Middlewares
app.use(cors());
app.use(express.json());

// Servir archivos estáticos (¡OJO! La ruta debe ajustarse para Vercel)
// Vercel no maneja bien las rutas relativas como __dirname en un entorno serverless.
// Por ahora, para depurar, podemos comentarlas o buscar una solución más avanzada después.
// app.use('/images', express.static(path.join(__dirname, '../public/images')));
// app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// El router principal maneja TODAS las rutas.
// Express montará este router en la raíz ('/').
// Vercel se encargará de que solo se active para peticiones a '/api'.
app.use(router);

// Exportar la aplicación para que Vercel la sirva.
// ¡NO USAR serverless(app) NI app.listen()!
module.exports = app;
