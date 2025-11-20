const express = require('express');
const router=express.Router();
const controlador=require('../controllers/controlador');
const upload = require('../config/multer.config');

router.get('/test', (req, res) => {
  res.status(200).json({ message: 'API en línea' });
});
// =========================================================================
// RUTAS DE USUARIOS
// =========================================================================
router.post('/usuarios', controlador.crearUsuario);
router.get('/usuarios', controlador.obtenerUsuarios);
router.get('/usuarios/:email', controlador.obtenerUsuarioPorEmail);
router.post('/usuarios/login', controlador.loginUsuario);
router.put('/usuarios/:email', controlador.actualizarUsuario);
router.delete('/usuarios/:email', controlador.eliminarUsuario);
router.post('/usuarios/cambiar-password', controlador.cambiarPassword);

// =========================================================================
// RUTAS DE QUEJAS
// =========================================================================
router.post('/quejas', controlador.crearQueja);
router.get('/quejas/mis-quejas/:email', controlador.obtenerMisQuejas);
router.get('/quejas/pendientes', controlador.obtenerQuejasPendientes);
router.get('/quejas/categoria/:categoria', controlador.obtenerQuejasPorCategoria);
router.put('/quejas/:id', controlador.atenderQueja);
router.delete('/quejas/:id', controlador.eliminarQueja);

// =========================================================================
// RUTAS DE CONTENIDO EDUCATIVO
// =========================================================================

// Ruta para crear nuevo contenido educativo (Admin)
router.post('/contenido-educativo',upload.array('imagenes', 10), controlador.crearContenidoEducativo);
// Ruta para obtener todo el contenido educativo (con filtros opcionales)
router.get('/contenido-educativo', controlador.obtenerContenidoEducativo);
// Ruta para obtener contenido educativo por ID
router.get('/contenido-educativo/:id', controlador.obtenerContenidoPorId);
// Ruta para actualizar contenido educativo (Admin) — permitimos enviar archivos ('imagenes') también
router.put('/contenido-educativo/:id', upload.array('imagenes', 10), controlador.actualizarContenidoEducativo);
// Ruta para eliminar contenido educativo (Admin)
router.delete('/contenido-educativo/:id', controlador.eliminarContenidoEducativo);
// Ruta para obtener contenido por categoría
router.get('/contenido-educativo/categoria/:categoria', controlador.obtenerContenidoPorCategoria);
// Ruta para obtener contenido por tipo de material
router.get('/contenido-educativo/material/:tipo_material', controlador.obtenerContenidoPorTipoMaterial);
// Ruta para buscar contenido educativo
router.get('/contenido-educativo/buscar/:termino', controlador.buscarContenidoEducativo);

// =========================================================================
// RUTAS DE PUNTOS DE RECICLAJE
// =========================================================================
router.get('/puntos-reciclaje/material/:tipo_material', controlador.obtenerPuntosReciclajePorMaterial);
router.get('/puntos-reciclaje/estado/:aceptado', controlador.obtenerPuntosReciclajeEstado);
router.put('/puntos-reciclaje/:id', controlador.actualizarPuntoReciclaje);
router.put('/puntos-reciclaje/estado/:id', controlador.aceptarPunto);
router.delete('/puntos-reciclaje/:id', controlador.eliminarPuntoReciclaje);

// =========================================================================
// RUTAS DE SOLICITUDES DE PUNTOS DE RECICLAJE - AUTENTICACIÓN SIMPLE
// =========================================================================

// Middleware de autenticación simple
const authSimple = (req, res, next) => {
  // Verificar si se proporcionó usuario y contraseña básicos en headers
  const usuario = req.headers['x-usuario'];
  const esAdminHeader = req.headers['x-admin'];

  if (!usuario) {
    return res.status(401).json({
      success: false,
      error: 'Acceso denegado. Se requiere identificación de usuario.'
    });
  }

  // Adjuntar información del usuario al request
  req.usuario = {
    nombre: usuario,
    esAdmin: esAdminHeader === 'true'
  };

  next();
};

// Middleware para verificar si es admin
const esAdminSimple = (req, res, next) => {
  if (!req.usuario.esAdmin) {
    return res.status(403).json({
      success: false,
      error: 'Acceso denegado. Se requieren permisos de administrador.'
    });
  }
  next();
};

// CREAR NUEVA SOLICITUD (usuarios identificados)
router.post('/solicitudes-puntos', authSimple, controlador.crearSolicitudPunto);

// OBTENER MIS SOLICITUDES (usuario actual)
router.get('/solicitudes-puntos/mis-solicitudes', authSimple, controlador.obtenerMisSolicitudes);

// OBTENER SOLICITUDES PENDIENTES (solo admin)
router.get('/solicitudes-puntos/admin/pendientes', authSimple, esAdminSimple, controlador.obtenerSolicitudesPendientes);

// OBTENER TODAS LAS SOLICITUDES (solo admin, con filtros)
router.get('/solicitudes-puntos/admin/todas', authSimple, esAdminSimple, controlador.obtenerTodasLasSolicitudes);

// APROBAR SOLICITUD (solo admin)
router.put('/solicitudes-puntos/admin/:id/aprobar', authSimple, esAdminSimple, controlador.aprobarSolicitudPunto);

// RECHAZAR SOLICITUD (solo admin)
router.put('/solicitudes-puntos/admin/:id/rechazar', authSimple, esAdminSimple, controlador.rechazarSolicitudPunto);

// OBTENER ESTADÍSTICAS DE SOLICITUDES (solo admin)
router.get('/solicitudes-puntos/admin/estadisticas', authSimple, esAdminSimple, controlador.obtenerEstadisticasSolicitudes);

// OBTENER SOLICITUD POR ID (cualquier usuario identificado)
router.get('/solicitudes-puntos/:id', authSimple, controlador.obtenerSolicitudPorId);

// ACTUALIZAR SOLICITUD (cualquier usuario identificado)
router.put('/solicitudes-puntos/:id', authSimple, controlador.actualizarSolicitudPunto);

// ELIMINAR SOLICITUD (cualquier usuario identificado)
router.delete('/solicitudes-puntos/:id', authSimple, controlador.eliminarSolicitudPunto);

// =========================================================================
// ENDPOINT DE GEOCODIFICACIÓN PARA PREVIEW (público, sin autenticación)
// =========================================================================
router.post('/geocodificar-preview', controlador.geocodificarPreview);

// =========================================================================
// ENDPOINT DE GEOCODIFICACIÓN INVERSA (obtener dirección desde coordenadas)
// =========================================================================
router.post('/reverse-geocode', controlador.reverseGeocode);

module.exports = router;