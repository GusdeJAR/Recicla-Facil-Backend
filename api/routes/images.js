// /routes/images.js
const express = require('express');
const router = express.Router();
const upload = require('../middlewares/multer.config'); // El Multer configurado
const cloudinary = require('../config/cloudinary'); // La configuración de Cloudinary

router.post('/upload', upload.single('imagen'), async (req, res) => {
  try {
    // 1. Verificar si Multer encontró un archivo
    if (!req.file) {
      return res.status(400).json({ message: "No se ha proporcionado un archivo." });
    }

    // 2. Convertir el Buffer del archivo a formato Base64 para Cloudinary
    // Se incluye el 'data:mimetype;base64,' para que Cloudinary pueda interpretar el formato.
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    let dataURI = "data:" + req.file.mimetype + ";base64," + b64;

    // 3. Subir la imagen a Cloudinary
    const result = await cloudinary.uploader.upload(dataURI, {
      folder: "proyecto_node" // Puedes especificar una carpeta de destino
    });

    // 4. Responder con la URL de la imagen
    res.status(200).json({
      message: 'Imagen subida con éxito',
      imageUrl: result.secure_url,
      publicId: result.public_id
    });

  } catch (err) {
    console.error("Error en la subida a Cloudinary:", err);
    res.status(500).json({ message: 'Error al procesar la subida de la imagen.' });
  }
});

module.exports = router;