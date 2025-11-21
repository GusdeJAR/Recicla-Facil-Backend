// config/multer.config.js
const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary'); 
const cloudinary = require('cloudinary').v2;


cloudinary.config({
  cloud_name: 'dugacfyo1',     
  api_key: '497871225357139',        
  api_secret: 'SQY4OdjOqSpo03jLYXzNFchzdLo',    
});

const storage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'recicla-facil/contenido', 
    allowed_formats: ['jpeg', 'png', 'jpg'], 
    public_id: (req, file) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        return `contenido-${uniqueSuffix}`;
    },
  },
});

const upload = multer({
  storage: storage, 
  limits: {
    fileSize: 5 * 1024 * 1024, 
  }
});

module.exports = upload;
