const express = require('express');
const router = express.Router();
const upload = require('../config/multer.config'); 
const cloudinary = require('../config/cloudinary'); 

router.post('/upload', upload.single('imagen'), async (req, res) => {
  try {
    // 1. Verificar si Multer encontró un archivo
    if (!req.file) {
      return res.status(400).json({ message: "No se ha proporcionado un archivo." });
    }

    // 2. Convertir el Buffer del archivo a formato Base64 para Cloudinary
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    let dataURI = "data:" + req.file.mimetype + ";base64," + b64;
    
    // **NUEVO: Extraer el nombre original del archivo sin la extensión**
    const originalFileName = req.file.originalname.split('.')[0];
    
    // 3. Subir la imagen a Cloudinary
    const result = await cloudinary.uploader.upload(dataURI, {
      folder: "proyecto_node",
      // ********************************************************
      // *** ⭐️ CAMBIO CLAVE: Usar el nombre original como public_id ***
      // ********************************************************
      public_id: originalFileName, 
      // Opcional: Para evitar que añada sufijos únicos si ya existe
      unique_filename: false 
    });

    // 4. Responder con la URL de la imagen
    res.status(200).json({
      message: 'Imagen subida con éxito',
      imageUrl: result.secure_url,
      publicId: result.public_id // Ahora publicId debe coincidir con el nombre original
    });

  } catch (err) {
    console.error("Error en la subida a Cloudinary:", err);
    res.status(500).json({ message: 'Error al procesar la subida de la imagen.' });
  }
});

module.exports = router;