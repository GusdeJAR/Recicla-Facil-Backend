// config/multer.config.js
//IMPORTANTE, ADAPTAR ESTO CON CLOUDFIRE
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Asegurar que la carpeta uploads existe (ruta absoluta dentro de la carpeta /api)
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadsDir);
    },
    filename: function (req, file, cb) {
        // Generar nombre único con timestamp
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const extension = path.extname(file.originalname);
        cb(null, 'contenido-' + uniqueSuffix + extension);
    }
});

const fileFilter = (req, file, cb) => {
    // if (file.mimetype.startsWith('image/')) {
    //     cb(null, true);
    // } else {
    //     cb(new Error('Solo se permiten archivos de imagen (JPEG, PNG, JPG)'), false);
    // }
    cb(null, true); // Permitir todos los tipos de archivos
};

const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024, // Límite de 5MB por archivo
        files: 10 // Máximo 10 archivos
    }
});

module.exports = upload;