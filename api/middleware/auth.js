const jwt = require('jsonwebtoken');
const { Usuario } = require('../models/modelos');

const auth = async (req, res, next) => {
    try {
        // Obtener el token del header
        const token = req.header('Authorization')?.replace('Bearer ', '');
        
        if (!token) {
            return res.status(401).json({ 
                success: false,
                error: 'Acceso denegado. No se proporcionó token.' 
            });
        }

        // Verificar el token
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secreto_por_defecto');
        
        // Buscar el usuario en la base de datos
        const usuario = await Usuario.findById(decoded.id).select('-password');
        
        if (!usuario) {
            return res.status(401).json({ 
                success: false,
                error: 'Token no válido.' 
            });
        }

        // Agregar el usuario a la request
        req.user = usuario;
        req.userId = usuario._id;
        next();
    } catch (error) {
        console.error('Error en autenticación:', error);
        res.status(401).json({ 
            success: false,
            error: 'Token no válido.' 
        });
    }
};

module.exports = auth;