   // api/index.js
   const express = require('express');
   const cors = require('cors');
   const conectarDB = require('../config/db');
   const router = require('../routes/router');

   const app = express();
   conectarDB();

   app.use(cors());
   app.use(express.json());

   // El router se monta en la raíz. Vercel se encarga del prefijo /api.
   app.use(router);

   // Exportamos la app para Vercel. NO app.listen().
   module.exports = app;
   