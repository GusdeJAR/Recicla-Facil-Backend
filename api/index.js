
const express = require('express');
const cors = require('cors');
const router = require('./routes/router'); // La ruta ahora es directa
const conectarDB = require('./config/db');   // La ruta ahora es directa
const imageRoutes = require('./routes/images');
const app = express();
conectarDB();

app.use(cors());
app.use(express.json());

app.use('/api/v1/images', imageRoutes);
app.use('/api', router);
// Exportamos la app para Vercel
module.exports = app;
