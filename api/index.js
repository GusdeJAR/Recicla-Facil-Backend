const express=require('express');
const cors=require('cors');
const path = require('path'); 
const app=express();
const port=3000;
const conectarDB=require('./config/db');
const router=require('./routes/router');
const host = '0.0.0.0'; // Especifica que el servidor debe escuchar en todas las interfaces de red

conectarDB();

app.use(express.json());
app.use(cors());
// Servir assets estáticos y las imágenes subidas por multer
app.use('/images', express.static(path.join(__dirname, 'public/images')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.get('/', (req, res) => {
  res.send('¡Servidor Node.js funcionando correctamente!');
});

app.use('/api', router);
app.listen(port, host, () => {
  console.log(`🚀 Servidor listo para recibir conexiones.`);
  console.log(`   - Localmente en: http://localhost:${port}`);
});