// /middlewares/multer.config.js
const multer = require('multer');

// **CLAVE:** Usamos memoryStorage. Esto almacena el archivo en la memoria (buffer)
// del servidor, y lo puedes acceder a través de req.file.buffer
const storage = multer.memoryStorage();

// Opcional pero recomendado: un filtro para asegurar que solo se suban imágenes
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true); // Acepta el archivo
  } else {
    // Rechaza el archivo y lanza un error
    cb(new Error('Tipo de archivo no soportado. Solo se permiten imágenes.'), false);
  }
};

const upload = multer({
  storage: storage, // Almacenamiento en memoria
  fileFilter: fileFilter,
  limits: {
    fileSize: 1024 * 1024 * 5 // Límite de 5MB por archivo (ajusta según necesites)
  }
});

module.exports = upload;