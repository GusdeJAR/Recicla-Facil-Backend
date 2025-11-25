
const express = require('express');
const cors = require('cors');
const router = require('./routes/router'); // La ruta ahora es directa
const conectarDB = require('./config/db');   // La ruta ahora es directa
const host = '0.0.0.0';
const port=3000;

const app = express();

conectarDB();

app.use(cors());
app.use(express.json());

// ¡CRUCIAL! Ahora que el index está en la raíz, montamos el router en /api
app.use('/api', router);
app.listen(port, host, () => {
  console.log(`🚀 Servidor listo para recibir conexiones.`);
  console.log(`   - Localmente en: http://localhost:${port}`);
});


// Exportamos la app para Vercel
module.exports = app;
