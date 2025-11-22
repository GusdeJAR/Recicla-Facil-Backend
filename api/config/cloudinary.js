// /config/cloudinary.js
const cloudinary = require('cloudinary').v2;
// Asegúrate de tener 'dotenv' configurado en tu archivo principal (app.js/server.js)

cloudinary.config({
  cloud_name: process.env.CLOUD_NAME,
  api_key: process.env.API_KEY,
  api_secret: process.env.API_SECRET,
  secure: true // Recomendado para usar URLs HTTPS seguras
});

module.exports = cloudinary;