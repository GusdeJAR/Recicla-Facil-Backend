require('dotenv').config();
const express = require('express');
const cors = require('cors');
const router = require('./routes/router'); // La ruta ahora es directa
const conectarDB = require('./config/db');   // La ruta ahora es directa
<<<<<<< HEAD
const host = '0.0.0.0';
const port=3000;

=======
const imageRoutes = require('./routes/images');
>>>>>>> 7051052bbdddd8bae97feedece29c57c14129ca6
const app = express();
conectarDB();

app.use(cors());
app.use(express.json());

app.use('/api/v1/images', imageRoutes);
app.use('/api', router);
<<<<<<< HEAD
app.listen(port, host, () => {
  console.log(`🚀 Servidor listo para recibir conexiones.`);
  console.log(`   - Localmente en: http://localhost:${port}`);
});


=======
>>>>>>> 7051052bbdddd8bae97feedece29c57c14129ca6
// Exportamos la app para Vercel
module.exports = app;
