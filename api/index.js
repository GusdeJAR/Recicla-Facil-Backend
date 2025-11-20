const express = require('express');
const cors = require('cors');
const path = require('path'); 
const conectarDB = require('../config/db');
const router = require('../routes/router');
const serverless = require("serverless-http");

const app = express();

// Conectar DB
conectarDB();

// Middlewares
app.use(express.json());
app.use(cors());

// Archivos estáticos
app.use('/images', express.static(path.join(__dirname, '../public/images')));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Ruta principal
app.get('/', (req, res) => {
  res.send('¡Servidor Node.js funcionando correctamente en Vercel!');
});

// Rutas API
app.use('/api', router);

// Exportar modo serverless
module.exports = serverless(app);
