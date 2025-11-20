
const express = require('express');
const cors = require('cors');
const router = require('./routes/router'); // La ruta ahora es directa
const conectarDB = require('./config/db');   // La ruta ahora es directa

const app = express();

conectarDB();

app.use(cors());
app.use(express.json());

// ¡CRUCIAL! Ahora que el index está en la raíz, montamos el router en /api
app.use('/api', router);

// Exportamos la app para Vercel
module.exports = app;
