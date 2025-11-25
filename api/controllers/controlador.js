const modelos = require('../models/modelos');
const cloudinary = require('../config/cloudinary');
const path = require('path');
const { URL } = require('url'); 
const { enviarCorreo } = require('../services/mailService');
const { geocodificarDireccion, obtenerDireccionDesdeCoordenas, TEPIC_BBOX, estaDentroDeBBox, normalizeTexto } = require('../services/geocoding');

// ===================================================================
// @desc    Recuperar contraseña por email y enviarla por correo
// @route   POST /api/usuarios/recuperar-password
// @access  Público
// ===================================================================
exports.recuperarPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ mensaje: 'El email es requerido.' });
        }
        // Buscar usuario por email
        const usuario = await modelos.Usuario.findOne({ email: email.trim() });
        if (!usuario) {
            return res.status(404).json({ mensaje: 'No se encontró usuario con ese email.' });
        }
        // Enviar la contraseña por correo
        await enviarCorreo(
            email,
            'Recuperación de contraseña',
            `Tu contraseña es: ${usuario.password}`
        );
        res.status(200).json({ mensaje: 'La contraseña ha sido enviada a tu correo.' });
    } catch (error) {
        console.error('Error en recuperarPassword:', error);
        res.status(500).json({ mensaje: 'Error interno al recuperar la contraseña.' });
    }
};

exports.crearUsuario = async (req, res) => {
     try {
        const { nombre, email, password } = req.body;

        // 1. Verificar si el correo ya existe en la base de datos
        const nombreExistente = await modelos.Usuario.findOne({ nombre: nombre.trim() });
        if (nombreExistente) {
                    return res.status(409).json({ mensaje: "El nombre de usuario ya está registrado." });
                }

        const emailExistente = await modelos.Usuario.findOne({ email: email.trim() });

        if (emailExistente) {
            return res.status(409).json({ mensaje: "El correo electrónico ya está registrado." });
        }

        // Limpia y crea el nuevo usuario
        const nuevoUsuario = await modelos.Usuario.create({
            nombre: nombre.trim(),
            email: email.trim(),
            password: password,
        });

        // 2. Respuesta de éxito: Código 201 Created
        res.status(201).json({ 
            mensaje: 'Usuario creado con éxito',
            usuario: { nombre: nuevoUsuario.nombre }
        });

    } catch (error) {
        console.error("Error en crearUsuario:", error);
        res.status(500).json({ mensaje: 'Error interno al crear el usuario.' });
    }
}

exports.obtenerUsuarios = async (req, res) => {
    try{
        const usuarios = await modelos.Usuario.find().lean();
        res.status(200).json(usuarios);
    }catch(error){
        res.status(500).json({ mensaje: 'Error al obtener los usuarios', error: error.message });
    }
}

exports.obtenerUsuarioPorEmail = async (req, res) => {
    try {
        const email = req.params.email;

        const usuario = await modelos.Usuario.findOne({ email: email });

        if (!usuario) {
            return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
        }

        const usuarioParaCliente = {
            nombre: usuario.nombre,
            email: usuario.email,
            password: usuario.password,
            admin: usuario.admin
        };

        res.status(200).json(usuarioParaCliente);

    } catch (error) {
        console.error("Error en obtenerUsuarioPorEmail:", error);
        res.status(500).json({ mensaje: 'Error interno al buscar el usuario.' });
    }
};

// ===================================================================
// @desc    Cambiar la contraseña de un usuario
// @route   POST /api/usuarios/cambiar-password
// @access  Privado
// ===================================================================
exports.cambiarPassword = async (req, res) => {
    try {
        const { email, nuevaPassword } = req.body;

        if (!email || !nuevaPassword) {
            return res.status(400).json({ mensaje: 'Faltan datos requeridos (email o nuevaPassword).' });
        }

        const usuario = await modelos.Usuario.findOne({ email: email });

        if (!usuario) {
            return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
        }

        usuario.password = nuevaPassword;
        await usuario.save();

        res.status(200).json({ mensaje: 'Contraseña actualizada exitosamente.' });

    } catch (error) {
        console.error("Error en cambiarPassword:", error);
        res.status(500).json({ mensaje: 'Error interno al cambiar la contraseña.' });
    }
};

exports.loginUsuario = async (req, res) => {
    console.log('API: /usuarios/login alcanzada con método:', req.method);
    console.log('API: Body recibido:', req.body);

    try {
        const { nombre, password } = req.body;

        if (!nombre || !password) {
            console.log('API ERROR: Datos de entrada incompletos.');
            return res.status(400).json({ mensaje: 'Nombre y contraseña son requeridos' });
        }

        console.log(`API: Buscando usuario '${nombre}' en la base de datos...`);
        const usuario = await modelos.Usuario.findOne({ nombre: nombre }).exec();

        if (!usuario) {
            console.log(`API: Usuario '${nombre}' no encontrado.`);
            return res.status(401).json({ mensaje: 'Usuario o contraseña incorrectos' });
        }

        console.log(`API: Usuario '${nombre}' encontrado. Verificando contraseña.`);
        if (password !== usuario.password) {
            console.log('API ERROR: Contraseña incorrecta.');
            return res.status(401).json({ mensaje: 'Usuario o contraseña incorrectos' });
        }

        console.log('API: Login exitoso. Enviando datos del usuario.');
        const usuarioParaCliente = {
            _id: usuario._id,
            nombre: usuario.nombre,
            email: usuario.email,
            admin: usuario.admin
        };
        
        return res.status(200).json({ 
            mensaje: 'Inicio de sesión exitoso', 
            usuario: usuarioParaCliente 
        });

    } catch (error) {
        console.error("API CRITICAL ERROR en login:", error);
        return res.status(500).json({ mensaje: 'Error interno del servidor' });
    }
};

exports.actualizarUsuario = async (req, res) => {
    const { nombre, password, admin, correo } = req.body;
    const email = req.params && req.params.email ? req.params.email : req.body.email;
    try{
        if(!email){
            return res.status(400).json({ mensaje: 'El email es requerido para actualizar el usuario' });
        }

        const update = {};
        if(nombre !== undefined) update.nombre = nombre;
        if(password !== undefined) update.password = password;
        if(admin !== undefined) update.admin = admin;

        const usuarioActualizado = await modelos.Usuario.findOneAndUpdate({ email }, update, { new: true });

        if(!usuarioActualizado){
            return res.status(404).json({ mensaje: 'Usuario no encontrado' });
        }

        res.status(200).json({ mensaje: 'Usuario actualizado exitosamente', usuario: usuarioActualizado });
    }catch(error){
        res.status(500).json({ mensaje: 'Error al actualizar el usuario', error: error.message });
    }
};

exports.eliminarUsuario = async (req, res) => {
    const email=req.params.email;
    try{
        if(!email){
            return res.status(400).json({ mensaje: 'El email es requerido para eliminar el usuario' });
        }
        const usuarioEliminado=await modelos.Usuario.findOneAndDelete({email});
        if(!usuarioEliminado){
            return res.status(404).json({ mensaje: 'Usuario no encontrado' });
        }
        res.status(200).json({ mensaje: 'Usuario eliminado exitosamente', usuario: usuarioEliminado });
    }catch(error){
        res.status(500).json({ mensaje: 'Error al eliminar el usuario', error: error.message });
    }
}

// =========================================================================
// CONTROLADORES DE QUEJAS
// =========================================================================

exports.crearQueja = async (req, res) => {
    try {
        const { correo, categoria, mensaje } = req.body;

        if (!correo) {
            return res.status(400).json({ mensaje: 'El correo es obligatorio.' });
        }

        if (!categoria) {
            return res.status(400).json({ mensaje: 'La categoría es obligatoria.' });
        }

        if (!mensaje) {
            return res.status(400).json({ mensaje: 'El mensaje es obligatorio.' });
        }

        const nuevaQueja = new modelos.Queja({
            correo: correo, 
            categoria: categoria,
            mensaje: mensaje
        });

        await nuevaQueja.save();

        res.status(201).json({
            mensaje: 'Queja enviada con éxito.',
            queja: nuevaQueja
        });

    } catch (error) {
        console.error("Error al crear la queja:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor al procesar la solicitud.' });
    }
};

exports.obtenerMisQuejas = async (req, res) => {
    try {
        const correoUsuario = req.params.email;
        const quejas = await modelos.Queja.find({ correo : correoUsuario }).sort({ fechaCreacion: -1 });
        res.status(200).json(quejas);

    } catch (error) {
        console.error("Error al obtener mis quejas:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

exports.obtenerQuejasPendientes = async (req, res) => {
    try {
        const quejasPendientes = await modelos.Queja.find({ estado: 'Pendiente' })
            .sort({ fechaCreacion: 1 });

        res.status(200).json(quejasPendientes);

    } catch (error) {
        console.error("Error al obtener quejas pendientes:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

// =========================================================================
// @desc    Obtener todas las quejas atendidas (para Administradores)
// @route   GET /api/quejas/atendidas
// @access  Privado (solo para Administradores)
// =========================================================================
exports.obtenerQuejasAtendidas = async (req, res) => {
    try {
        // Buscamos todas las quejas con estado 'Atendida'
        const quejasAtendidas = await modelos.Queja.find({ estado: 'Atendida' })
            .sort({ fechaCreacion: 1 }); // Ordenamos de la más antigua a la más nueva

        res.status(200).json(quejasAtendidas);

    } catch (error) {
        console.error("Error al obtener quejas atendidas:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

exports.obtenerQuejasPorCategoria = async (req, res) => {
    try {
        const categoria = decodeURIComponent(req.params.categoria);
        if (!categoria) {
            return res.status(400).json({ mensaje: 'La categoría es requerida en la URL.' });
        }
        const quejas = await modelos.Queja.find({ categoria: new RegExp(`^${categoria}$`, 'i') })
            .sort({ fechaCreacion: -1 });

        res.status(200).json(quejas);

    } catch (error) {
        console.error("Error al obtener quejas por categoría:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

exports.atenderQueja = async (req, res) => {
    try {
        const { respuestaAdmin } = req.body;
        const quejaId = req.params.id;

        if (!respuestaAdmin) {
            return res.status(400).json({ mensaje: 'La respuesta del administrador es obligatoria.' });
        }

        const quejaAtendida = await modelos.Queja.findByIdAndUpdate(
            quejaId,
            {
                estado: 'Atendida',
                respuestaAdmin: respuestaAdmin,
                fechaAtencion: new Date()
            },
            { new: true }
        );

        if (!quejaAtendida) {
            return res.status(404).json({ mensaje: 'No se encontró una queja con ese ID.' });
        }

        res.status(200).json({
            mensaje: 'La queja ha sido atendida con éxito.',
            queja: quejaAtendida
        });

    } catch (error) {
        console.error("Error al atender la queja:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

exports.eliminarQueja = async (req, res) => {
    try {
        const quejaId = req.params.id;
        const quejaEliminada = await modelos.Queja.findByIdAndDelete(quejaId);

        if (!quejaEliminada) {
            return res.status(404).json({ mensaje: 'No se encontró una queja con ese ID.' });
        }

        res.status(200).json({ mensaje: 'Queja eliminada exitosamente.' });

    } catch (error) {
        res.status(500).json({ mensaje: 'Error del servidor al querer eliminar la queja.' });
    }
};

// =========================================================================
// CONTROLADORES DE CONTENIDO EDUCATIVO
// =========================================================================

exports.crearContenidoEducativo = async (req, res) => {
    let uploadedPublicIds = [];
    let imagenesProcesadas = [];
    try {
        const {
            titulo,
            descripcion,
            contenido,
            categoria,
            tipo_material,
            puntos_clave,
            acciones_correctas,
            acciones_incorrectas,
            etiquetas,
            publicado,
            img_principal,
            imagenes_pre_subidas, 
        } = req.body;

        if (!titulo || !descripcion || !contenido || !categoria || !tipo_material) {
            return res.status(400).json({ mensaje: 'Faltan campos obligatorios.' });
        }
        
        if (req.files && req.files.length > 0) {
            const uploadPromises = req.files.map(file => {
                const b64 = Buffer.from(file.buffer).toString('base64');
                const dataURI = `data:${file.mimetype};base64,${b64}`;

                return cloudinary.uploader.upload(dataURI, {
                    folder: "contenido-educativo",
                });
            });

            const uploadResults = await Promise.all(uploadPromises);
            uploadedPublicIds = uploadResults.map(result => result.public_id);

            imagenesProcesadas = uploadResults.map((result, index) => {
                const esPrincipal = parseInt(img_principal, 10) === index;
                return {
                    ruta: result.secure_url,
                    public_id: result.public_id,
                    pie_de_imagen: `Imagen de ${titulo}`,
                    es_principal: esPrincipal 
                };
            });

        } else if (imagenes_pre_subidas) {
            try {
                const preSubidas = JSON.parse(imagenes_pre_subidas);
                
                if (!Array.isArray(preSubidas) || preSubidas.length === 0) {
                    throw new Error("El formato de las imágenes pre-subidas es inválido o está vacío.");
                }
                
                imagenesProcesadas = preSubidas.map((item, index) => {
                    const esPrincipal = parseInt(img_principal, 10) === index;
                    return {
                        ruta: item.ruta,
                        public_id: item.public_id,
                        pie_de_imagen: item.pie_de_imagen || `Imagen de ${titulo}`,
                        es_principal: esPrincipal 
                    };
                });
                
                uploadedPublicIds = imagenesProcesadas.map(img => img.public_id);

            } catch (parseError) {
                 return res.status(400).json({ mensaje: 'Error al procesar las imágenes pre-subidas (JSON inválido).' });
            }
            
        } else {
             return res.status(400).json({ mensaje: 'Se requiere al menos una imagen (subida directa o pre-subida).' });
        }

        const nuevoContenido = new modelos.ContenidoEducativo({
            titulo: titulo.trim(),
            descripcion: descripcion.trim(),
            contenido: contenido,
            categoria,
            tipo_material,
            imagenes: imagenesProcesadas,
            puntos_clave: JSON.parse(puntos_clave || '[]'),
            acciones_correctas: JSON.parse(acciones_correctas || '[]'),
            acciones_incorrectas: JSON.parse(acciones_incorrectas || '[]'),
            etiquetas: JSON.parse(etiquetas || '[]'),
            publicado: publicado || false
        });

        await nuevoContenido.save();

        res.status(201).json({
            mensaje: 'Contenido educativo creado con éxito.',
            contenido: nuevoContenido
        });

    } catch (error) {
        console.error("Error en crearContenidoEducativo:", error);
        
        if (uploadedPublicIds.length > 0) {
            try {
                await cloudinary.api.delete_resources(uploadedPublicIds);
            } catch (cleanupError) {
                console.error("Error al limpiar imágenes de Cloudinary después de un fallo:", cleanupError);
            }
        }

        res.status(500).json({ 
            mensaje: 'Error interno al crear el contenido educativo.',
            error: error.message 
        });
    }
};

exports.obtenerContenidoEducativo = async (req, res) => {
    try {
        const todosLosContenidos = await modelos.ContenidoEducativo.find();
        res.status(200).json({
            contenidos: todosLosContenidos
        });

    } catch (error) {
        console.error("Error al obtener todos los contenidos:", error);
        res.status(500).json({
            mensaje: 'Error interno al obtener el contenido educativo.',
            error: error.message
        });
    }
};

exports.obtenerContenidoPorId = async (req, res) => {
    try {
        const contenidoId = req.params.id;
        const contenido = await modelos.ContenidoEducativo.findById(contenidoId);

        if (!contenido) {
            return res.status(404).json({ mensaje: 'Contenido educativo no encontrado.' });
        }

        res.status(200).json(contenido);

    } catch (error) {
        console.error("Error en obtenerContenidoPorId:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al obtener el contenido educativo.',
            error: error.message 
        });
    }
};

exports.actualizarContenidoEducativo = async (req, res) => {
    let newUploadedPublicIds = [];

    try {
        const contenidoId = req.params.id;
        const body = req.body || {}; 

        const contenidoExistente = await modelos.ContenidoEducativo.findById(contenidoId);
        if (!contenidoExistente) {
            return res.status(404).json({ mensaje: 'Contenido educativo no encontrado.' });
        }

        const update = {};
        
        if (body.titulo !== undefined) update.titulo = String(body.titulo).trim();
        if (body.descripcion !== undefined) update.descripcion = String(body.descripcion).trim();
        if (body.contenido !== undefined) update.contenido = body.contenido;
        if (body.categoria !== undefined) update.categoria = body.categoria;
        if (body.tipo_material !== undefined) update.tipo_material = body.tipo_material;
        
        if (body.publicado !== undefined) {
             update.publicado = body.publicado === 'true' || body.publicado === true;
        }

        if (body.puntos_clave !== undefined) update.puntos_clave = JSON.parse(body.puntos_clave || '[]');
        if (body.acciones_correctas !== undefined) update.acciones_correctas = JSON.parse(body.acciones_correctas || '[]');
        if (body.acciones_incorrectas !== undefined) update.acciones_incorrectas = JSON.parse(body.acciones_incorrectas || '[]');
        if (body.etiquetas !== undefined) update.etiquetas = JSON.parse(body.etiquetas || '[]');
        
        update.fecha_actualizacion = new Date();

        let imagenesFinal = [...contenidoExistente.imagenes]; 

        let idsParaBorrar = [];
        if (body.ids_imagenes_a_eliminar) {
             idsParaBorrar = JSON.parse(body.ids_imagenes_a_eliminar); 
             if (Array.isArray(idsParaBorrar) && idsParaBorrar.length > 0) {
                 try {
                     await cloudinary.api.delete_resources(idsParaBorrar);
                 } catch (cloudError) {
                     console.error('Error al intentar eliminar imágenes de Cloudinary:', cloudError);
                 }
                 imagenesFinal = imagenesFinal.filter(img => !idsParaBorrar.includes(img.public_id));
             }
        }
        
        let nuevasImagenes = [];
        
        if (req.files && req.files.length > 0) {
            const uploadPromises = req.files.map(file => {
                const b64 = Buffer.from(file.buffer).toString('base64');
                const dataURI = `data:${file.mimetype};base64,${b64}`;

                return cloudinary.uploader.upload(dataURI, {
                    folder: "contenido-educativo",
                });
            });

            const uploadResults = await Promise.all(uploadPromises);
            newUploadedPublicIds = uploadResults.map(result => result.public_id);

            nuevasImagenes = uploadResults.map(result => ({
                ruta: result.secure_url,
                public_id: result.public_id,
                pie_de_imagen: `Imagen de ${body.titulo || contenidoExistente.titulo}`,
                es_principal: false 
            }));
            
            const idsRetenidosParaBorrar = imagenesFinal.map(img => img.public_id);
            if(idsRetenidosParaBorrar.length > 0) {
                 try {
                     await cloudinary.api.delete_resources(idsRetenidosParaBorrar);
                 } catch(err) {
                      console.error('Advertencia: No se pudieron eliminar las imágenes antiguas no deseadas:', err);
                 }
            }
            
            imagenesFinal = nuevasImagenes; 

        } else if (body.imagenes_a_agregar_pre_subidas) {
            try {
                const preSubidas = JSON.parse(body.imagenes_a_agregar_pre_subidas);
                
                nuevasImagenes = preSubidas.map(item => ({
                    ruta: item.ruta,
                    public_id: item.public_id,
                    pie_de_imagen: item.pie_de_imagen || `Imagen de ${body.titulo || contenidoExistente.titulo}`,
                    es_principal: false 
                }));
                
                newUploadedPublicIds = nuevasImagenes.map(img => img.public_id);
                
                imagenesFinal = [...imagenesFinal, ...nuevasImagenes];

            } catch (parseError) {
                 throw new Error("Error al procesar el JSON de imágenes pre-subidas para agregar.");
            }
            
        } 
        
        if (body.img_principal_ruta !== undefined) {
             const rutaPrincipal = body.img_principal_ruta;
             imagenesFinal.forEach(img => {
                 img.es_principal = (img.ruta === rutaPrincipal);
             });
        }
        
        update.imagenes = imagenesFinal;
        
        const contenidoActualizado = await modelos.ContenidoEducativo.findByIdAndUpdate(
             contenidoId,
             { $set: update }, 
             { new: true, runValidators: true }
        );

        res.status(200).json({
             mensaje: 'Contenido educativo actualizado con éxito.',
             contenido: contenidoActualizado
        });

    } catch (error) {
        console.error("Error en actualizarContenidoEducativo:", error);
        
         if (newUploadedPublicIds.length > 0) {
             try {
                 await cloudinary.api.delete_resources(newUploadedPublicIds);
             } catch (cleanupError) {
                 console.error("Error al limpiar imágenes de Cloudinary en actualización:", cleanupError);
             }
         }
         res.status(500).json({ 
             mensaje: 'Error interno al actualizar el contenido educativo.',
             error: error.message 
         });
    }
};

exports.eliminarContenidoEducativo = async (req, res) => {
    try {
        const contenidoId = req.params.id;

        const contenido = await modelos.ContenidoEducativo.findById(contenidoId);
        if (!contenido) {
            return res.status(404).json({ mensaje: 'Contenido educativo no encontrado.' });
        }

        const publicIds = [];
        if (Array.isArray(contenido.imagenes)) {
            for (const img of contenido.imagenes) {
                if (img && img.public_id) {
                    publicIds.push(img.public_id);
                }
            }
        }
        
        if (publicIds.length > 0) {
            try {
                const result = await cloudinary.api.delete_resources(publicIds);
                console.log('Archivos eliminados de Cloudinary:', result);
            } catch (err) {
                console.error('Error al intentar eliminar imágenes de Cloudinary:', err);
            }
        }

        await modelos.ContenidoEducativo.findByIdAndDelete(contenidoId);

        res.status(200).json({ 
            mensaje: 'Contenido educativo y archivos vinculados eliminados exitosamente.',
            archivosEliminados: publicIds
        });

    } catch (error) {
        console.error("Error en eliminarContenidoEducativo:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al eliminar el contenido educativo.',
            error: error.message 
        });
    }
};

exports.obtenerContenidoPorCategoria = async (req, res) => {
    try {
        const categoria = req.params.categoria;
        const { publicado = 'true' } = req.query;

        const filtro = { 
            categoria,
            publicado: publicado === 'true'
        };

        const contenidos = await modelos.ContenidoEducativo.find(filtro)
            .sort({ fecha_creacion: -1 });

        res.status(200).json(contenidos);

    } catch (error) {
        console.error("Error en obtenerContenidoPorCategoria:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al obtener el contenido por categoría.',
            error: error.message 
        });
    }
};

exports.obtenerContenidoPorTipoMaterial = async (req, res) => {
    try {
        const tipo_material = req.params.tipo_material;
        const { publicado = 'true' } = req.query;

        const filtro = { 
            tipo_material,
            publicado: publicado === 'true'
        };

        const contenidos = await modelos.ContenidoEducativo.find(filtro)
            .sort({ fecha_creacion: -1 });

        res.status(200).json(contenidos);

    } catch (error) {
        console.error("Error en obtenerContenidoPorTipoMaterial:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al obtener el contenido por tipo de material.',
            error: error.message 
        });
    }
};

exports.buscarContenidoEducativo = async (req, res) => {
    try {
        const termino = req.params.termino;
        const { publicado = 'true' } = req.query;

        const filtro = {
            publicado: publicado === 'true',
            $or: [
                { titulo: { $regex: termino, $options: 'i' } },
                { descripcion: { $regex: termino, $options: 'i' } },
                { etiquetas: { $in: [new RegExp(termino, 'i')] } }
            ]
        };

        const contenidos = await modelos.ContenidoEducativo.find(filtro)
            .sort({ fecha_creacion: -1 });

        res.status(200).json(contenidos);

    } catch (error) {
        console.error("Error en buscarContenidoEducativo:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al buscar contenido educativo.',
            error: error.message 
        });
    }
};

// =========================================================================
// CONTROLADORES DE PUNTOS DE RECICLAJE
// =========================================================================

exports.obtenerPuntosReciclajePorMaterial = async (req, res)=>{
  try {
        const tipo_material = req.params.tipo_material;
        const { aceptado = 'true' } = req.query;
        const filtro = {
            aceptado: aceptado
        };
        if (tipo_material && tipo_material.toLowerCase() !== 'todos') {
            filtro.tipo_material = { $in: [tipo_material] };
        }

        const puntos = await modelos.PuntosReciclaje.find(filtro);
        res.status(200).json(puntos);

    } catch (error) {
        console.error("Error en obtenerPuntosReciclaje:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al obtener los puntos de reciclaje por material.',
            error: error.message 
        });
    }
};

exports.obtenerPuntosReciclajeEstado = async (req, res)=>{
    try {
        const estadoAceptado = req.params.aceptado;

        if (estadoAceptado !== 'true' && estadoAceptado !== 'false') {
            return res.status(400).json({ mensaje: 'Parámetro inválido.' });
        }

        const filtro = { aceptado: estadoAceptado };
        const puntos = await modelos.PuntosReciclaje.find(filtro);

        res.status(200).json(puntos);

    } catch (error) {
        res.status(500).json({ mensaje: 'Error interno.' });
    }
};

exports.aceptarPunto = async (req, res) => {
    try {
        const puntoId = req.params.id; 
        const puntoAceptado = await modelos.PuntosReciclaje.findByIdAndUpdate(
            puntoId,
            {aceptado: "true"},
            { new: true }
        );

        if (!puntoAceptado) {
            return res.status(404).json({ mensaje: 'No se encontró un punto con ese ID.' });
        }

        res.status(200).json({
            mensaje: 'El punto se aceptó con éxito.',
            punto: puntoAceptado
        });

    } catch (error) {
        console.error("Error al aceptar el punto:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

exports.actualizarPuntoReciclaje = async (req, res) => {
     try {
        const puntoId = req.params.id;
        const {
            nombre,
            descripcion,
            latitud,
            longitud,
            icono,
            tipo_material,
            direccion,
            telefono,
            horario,
            aceptado,
        } = req.body;

        const puntoExistente = await modelos.PuntosReciclaje.findById(puntoId);
        if (!puntoExistente) {
            return res.status(404).json({ mensaje: 'Punto de reciclaje no encontrado.' });
        }

        const update = {};
        if (nombre !== undefined) update.nombre = nombre.trim();
        if (descripcion !== undefined) update.descripcion = descripcion.trim();
        if (latitud !== undefined) update.latitud = latitud;
        if (longitud !== undefined) update.longitud = longitud;
        if (icono !== undefined) update.icono = icono;
        if (tipo_material !== undefined) update.tipo_material = tipo_material;
        if (direccion !== undefined) update.direccion = direccion;
        if (telefono !== undefined) update.telefono = telefono;
        if (horario !== undefined) update.horario = horario;
        if (aceptado !== undefined) update.aceptado = aceptado;

        const puntoActualizado = await modelos.PuntosReciclaje.findByIdAndUpdate(
            puntoId,
            update,
            { new: true, runValidators: true }
        );

        res.status(200).json({
            mensaje: 'Punto de reciclaje actualizado con éxito.',
            punto: puntoActualizado
        });

    } catch (error) {
        console.error("Error en actualizarPuntoReciclaje:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al actualizar el punto de reciclaje.',
            error: error.message 
        });
    }
};

exports.eliminarPuntoReciclaje = async (req, res) => {
    try {
        const puntoId = req.params.id;

        const puntoEliminado = await modelos.PuntosReciclaje.findByIdAndDelete(puntoId);

        if (!puntoEliminado) {
            return res.status(404).json({ mensaje: 'No se encontró un punto de reciclaje con ese ID.' });
        }

        res.status(200).json({ mensaje: 'Punto de reciclaje eliminado exitosamente.' });

    } catch (error) {
        res.status(500).json({ mensaje: 'Error del servidor al querer eliminar el punto de reciclaje.' });
    }
};

// =========================================================================
// CONTROLADORES PARA SOLICITUDES DE PUNTOS DE RECICLAJE - MODIFICADOS
// =========================================================================

// @desc    Crear una nueva solicitud de punto de reciclaje O punto directo si es admin
// @route   POST /api/solicitudes-puntos
// @access  Con autenticación simple
exports.crearSolicitudPunto = async (req, res) => {
    try {
        const {
            nombre,
            descripcion,
            direccion,
            tipo_material,
            telefono,
            horario,
            estado = 'pendiente'
        } = req.body;

        // Validar campos requeridos
        if (!nombre || !descripcion || !direccion || !tipo_material || !telefono || !horario) {
            return res.status(400).json({
                success: false,
                errorMessage: 'Faltan campos obligatorios: nombre, descripción, dirección, tipo de material, teléfono y horario'
            });
        }

        const usuarioSolicitante = req.usuario.nombre;
        const esAdmin = req.usuario.esAdmin;

        // Si es admin, crear el punto de reciclaje directamente
        if (esAdmin) {
            // Validar que se proporcionen coordenadas
            if (!req.body.ubicacion || !req.body.ubicacion.latitud || !req.body.ubicacion.longitud) {
                return res.status(400).json({
                    success: false,
                    errorMessage: 'Para crear un punto directamente se requieren coordenadas válidas'
                });
            }

            const { latitud, longitud } = req.body.ubicacion;
            
            // Verificar que las coordenadas estén dentro de Tepic
            if (!estaDentroDeBBox(latitud, longitud, TEPIC_BBOX)) {
                return res.status(400).json({
                    success: false,
                    errorMessage: 'Las coordenadas deben estar dentro del área de Tepic, Nayarit'
                });
            }

            // Crear dirección completa
            const direccionCompleta = `${direccion.calle} ${direccion.numero}, ${direccion.colonia}, Tepic, Nayarit, México`;

            // Crear el punto de reciclaje
            const nuevoPunto = new modelos.PuntosReciclaje({
                nombre: nombre.trim(),
                descripcion: descripcion.trim(),
                latitud: latitud,
                longitud: longitud,
                icono: 'assets/iconos/recycle_general.png',
                tipo_material: tipo_material,
                direccion: direccionCompleta,
                telefono: telefono,
                horario: horario,
                aceptado: "true",
                estado: 'activo',
                creadoPor: usuarioSolicitante,
                fechaCreacion: new Date()
            });

            await nuevoPunto.save();

            return res.status(201).json({
                success: true,
                message: 'Punto de reciclaje creado y publicado exitosamente',
                data: {
                    punto: nuevoPunto,
                    tipo: 'punto_directo'
                }
            });
        }

        // Si NO es admin, crear solicitud normal
        // Permitir que el cliente envíe una ubicación ajustada por el usuario.
        let latitudFinal = null;
        let longitudFinal = null;

        if (req.body.ubicacion && req.body.ubicacion.latitud !== undefined && req.body.ubicacion.longitud !== undefined) {
            const { latitud, longitud } = req.body.ubicacion;
            // Verificar que las coordenadas estén dentro de Tepic
            if (estaDentroDeBBox(latitud, longitud, TEPIC_BBOX)) {
                latitudFinal = latitud;
                longitudFinal = longitud;
            } else {
                console.warn('Ubicación enviada por cliente fuera de Tepic — se ignorará');
            }
        }

        // Si no tenemos coordenadas válidas aun, geocodificamos
        if (latitudFinal === null || longitudFinal === null) {
            const calleNorm = normalizeTexto(direccion.calle || '');
            const numeroNorm = normalizeTexto(direccion.numero || '');
            const coloniaNorm = normalizeTexto(direccion.colonia || '');
            const ciudadNorm = normalizeTexto(direccion.ciudad || 'Tepic');
            const estadoNorm = normalizeTexto(direccion.estado || 'Nayarit');
            const paisNorm = normalizeTexto(direccion.pais || 'México');

            const coordenadas = await geocodificarDireccion(
                calleNorm,
                numeroNorm,
                coloniaNorm,
                ciudadNorm,
                estadoNorm,
                paisNorm
            );
            latitudFinal = coordenadas.latitud;
            longitudFinal = coordenadas.longitud;
        }

        // Crear la solicitud con las coordenadas finales
        const nuevaSolicitud = new modelos.SolicitudPunto({
            nombre: nombre.trim(),
            descripcion: descripcion.trim(),
            direccion: direccion,
            tipo_material: tipo_material,
            telefono: telefono,
            horario: horario,
            usuarioSolicitante: usuarioSolicitante,
            estado: estado,
            ubicacion: {
                latitud: latitudFinal,
                longitud: longitudFinal
            },
            fechaCreacion: new Date()
        });

        await nuevaSolicitud.save();

        res.status(201).json({
            success: true,
            message: 'Solicitud creada exitosamente',
            data: {
                solicitud: nuevaSolicitud,
                tipo: 'solicitud'
            }
        });

    } catch (error) {
        console.error('Error creando solicitud/punto:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor: ' + error.message
        });
    }
};

// @desc    Obtener las solicitudes del usuario actual (o todas si es admin)
// @route   GET /api/solicitudes-puntos/mis-solicitudes
// @access  Con autenticación simple
exports.obtenerMisSolicitudes = async (req, res) => {
    try {
        const usuario = req.usuario;
        let solicitudes;

        if (usuario.esAdmin) {
            // Admin ve todas las solicitudes
            solicitudes = await modelos.SolicitudPunto.find()
                .sort({ fechaCreacion: -1 });
        } else {
            // Usuario normal ve solo sus solicitudes
            solicitudes = await modelos.SolicitudPunto.find({ 
                usuarioSolicitante: usuario.nombre
            })
            .sort({ fechaCreacion: -1 });
        }

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo solicitudes:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener todas las solicitudes pendientes
// @route   GET /api/solicitudes-puntos/admin/pendientes
// @access  Solo administradores (autenticación simple)
exports.obtenerSolicitudesPendientes = async (req, res) => {
    try {
        if (!req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para realizar esta acción'
            });
        }

        const solicitudes = await modelos.SolicitudPunto.find({ estado: 'pendiente' })
            .sort({ fechaCreacion: 1 });

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo solicitudes pendientes:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener todas las solicitudes con filtros
// @route   GET /api/solicitudes-puntos/admin/todas
// @access  Solo administradores (autenticación simple)
exports.obtenerTodasLasSolicitudes = async (req, res) => {
    try {
        if (!req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para realizar esta acción'
            });
        }

        const { estado } = req.query;
        const filter = estado ? { estado } : {};

        const solicitudes = await modelos.SolicitudPunto.find(filter)
            .sort({ fechaCreacion: -1 });

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo todas las solicitudes:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Aprobar una solicitud de punto de reciclaje
// @route   PUT /api/solicitudes-puntos/admin/:id/aprobar
// @access  Solo administradores (autenticación simple)
exports.aprobarSolicitudPunto = async (req, res) => {
    try {
        if (!req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para realizar esta acción'
            });
        }

        const { comentariosAdmin } = req.body;
        
        const solicitud = await modelos.SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                errorMessage: 'Solicitud no encontrada'
            });
        }

        if (solicitud.estado !== 'pendiente') {
            return res.status(400).json({
                success: false,
                errorMessage: 'La solicitud ya fue procesada'
            });
        }

        // 1. Actualizar la solicitud
        solicitud.estado = 'aprobada';
        solicitud.adminRevisor = req.usuario.nombre;
        solicitud.comentariosAdmin = comentariosAdmin || 'Solicitud aprobada';
        solicitud.fechaRevision = new Date();
        
        await solicitud.save();

        // 2. Crear el punto de reciclaje
        const direccionCompleta = `${solicitud.direccion.calle} ${solicitud.direccion.numero}, ${solicitud.direccion.colonia}, Tepic, Nayarit, México`;
        
        const nuevoPunto = new modelos.PuntosReciclaje({
            nombre: solicitud.nombre,
            descripcion: solicitud.descripcion,
            latitud: solicitud.ubicacion.latitud,
            longitud: solicitud.ubicacion.longitud,
            icono: 'assets/iconos/recycle_general.png',
            tipo_material: solicitud.tipo_material,
            direccion: direccionCompleta,
            telefono: solicitud.telefono,
            horario: solicitud.horario,
            aceptado: "true",
            estado: 'activo',
            creadoPor: solicitud.usuarioSolicitante,
            aprobadoPor: req.usuario.nombre,
            fechaCreacion: new Date(),
            solicitudOrigen: solicitud._id
        });

        await nuevoPunto.save();

        // Asociar el punto creado con la solicitud
        solicitud.puntoCreado = nuevoPunto._id;
        await solicitud.save();

        res.json({
            success: true,
            data: {
                solicitud: solicitud,
                puntoCreado: nuevoPunto
            },
            message: 'Solicitud aprobada y punto creado exitosamente'
        });

    } catch (error) {
        console.error('Error aprobando solicitud:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor: ' + error.message
        });
    }
};

// @desc    Rechazar una solicitud de punto de reciclaje
// @route   PUT /api/solicitudes-puntos/admin/:id/rechazar
// @access  Solo administradores (autenticación simple)
exports.rechazarSolicitudPunto = async (req, res) => {
    try {
        if (!req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para realizar esta acción'
            });
        }

        const { comentariosAdmin } = req.body;
        
        if (!comentariosAdmin || comentariosAdmin.trim() === '') {
            return res.status(400).json({
                success: false,
                errorMessage: 'Los comentarios son obligatorios al rechazar una solicitud'
            });
        }

        const solicitud = await modelos.SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                errorMessage: 'Solicitud no encontrada'
            });
        }

        if (solicitud.estado !== 'pendiente') {
            return res.status(400).json({
                success: false,
                errorMessage: 'La solicitud ya fue procesada'
            });
        }

        solicitud.estado = 'rechazada';
        solicitud.adminRevisor = req.usuario.nombre;
        solicitud.comentariosAdmin = comentariosAdmin;
        solicitud.fechaRevision = new Date();
        
        await solicitud.save();

        res.json({
            success: true,
            data: solicitud,
            message: 'Solicitud rechazada exitosamente'
        });

    } catch (error) {
        console.error('Error rechazando solicitud:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener estadísticas de solicitudes
// @route   GET /api/solicitudes-puntos/admin/estadisticas
// @access  Solo administradores (autenticación simple)
exports.obtenerEstadisticasSolicitudes = async (req, res) => {
    try {
        if (!req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para realizar esta acción'
            });
        }

        const totalSolicitudes = await modelos.SolicitudPunto.countDocuments();
        const solicitudesPendientes = await modelos.SolicitudPunto.countDocuments({ estado: 'pendiente' });
        const solicitudesAprobadas = await modelos.SolicitudPunto.countDocuments({ estado: 'aprobada' });
        const solicitudesRechazadas = await modelos.SolicitudPunto.countDocuments({ estado: 'rechazada' });

        res.json({
            success: true,
            data: {
                total: totalSolicitudes,
                pendientes: solicitudesPendientes,
                aprobadas: solicitudesAprobadas,
                rechazadas: solicitudesRechazadas
            }
        });

    } catch (error) {
        console.error('Error obteniendo estadísticas:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener una solicitud por ID
// @route   GET /api/solicitudes-puntos/:id
// @access  Con autenticación simple
exports.obtenerSolicitudPorId = async (req, res) => {
    try {
        const solicitud = await modelos.SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                errorMessage: 'Solicitud no encontrada'
            });
        }

        // Solo permitir ver la solicitud si es el propietario o admin
        if (solicitud.usuarioSolicitante !== req.usuario.nombre && !req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para ver esta solicitud'
            });
        }

        res.json({
            success: true,
            data: solicitud
        });

    } catch (error) {
        console.error('Error obteniendo solicitud por ID:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Actualizar una solicitud
// @route   PUT /api/solicitudes-puntos/:id
// @access  Con autenticación simple
exports.actualizarSolicitudPunto = async (req, res) => {
    try {
        const {
            nombre,
            descripcion,
            direccion,
            tipo_material,
            telefono,
            horario
        } = req.body;

        const solicitud = await modelos.SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                errorMessage: 'Solicitud no encontrada'
            });
        }

        // Solo permitir actualizar si es el propietario o admin
        if (solicitud.usuarioSolicitante !== req.usuario.nombre && !req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para actualizar esta solicitud'
            });
        }

        // No permitir actualizar si ya fue procesada (a menos que sea admin)
        if (solicitud.estado !== 'pendiente' && !req.usuario.esAdmin) {
            return res.status(400).json({
                success: false,
                errorMessage: 'No se puede actualizar una solicitud ya procesada'
            });
        }

        // Actualizar campos permitidos
        if (nombre !== undefined) solicitud.nombre = nombre;
        if (descripcion !== undefined) solicitud.descripcion = descripcion;
        if (direccion !== undefined) solicitud.direccion = direccion;
        if (tipo_material !== undefined) solicitud.tipo_material = tipo_material;
        if (telefono !== undefined) solicitud.telefono = telefono;
        if (horario !== undefined) solicitud.horario = horario;

        await solicitud.save();

        res.json({
            success: true,
            data: solicitud,
            message: 'Solicitud actualizada exitosamente'
        });

    } catch (error) {
        console.error('Error actualizando solicitud:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Eliminar una solicitud
// @route   DELETE /api/solicitudes-puntos/:id
// @access  Con autenticación simple
exports.eliminarSolicitudPunto = async (req, res) => {
    try {
        const solicitud = await modelos.SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                errorMessage: 'Solicitud no encontrada'
            });
        }

        // Solo permitir eliminar si es el propietario o admin
        if (solicitud.usuarioSolicitante !== req.usuario.nombre && !req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                errorMessage: 'No tienes permisos para eliminar esta solicitud'
            });
        }

        await modelos.SolicitudPunto.findByIdAndDelete(req.params.id);

        res.json({
            success: true,
            message: 'Solicitud eliminada exitosamente'
        });

    } catch (error) {
        console.error('Error eliminando solicitud:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error interno del servidor'
        });
    }
};

// @desc    Geocodificar dirección para vista previa (endpoint público)
// @route   POST /api/geocodificar-preview
// @access  Público (sin autenticación)
exports.geocodificarPreview = async (req, res) => {
    try {
        const { calle, numero, colonia, ciudad = 'Tepic', estado = 'Nayarit', pais = 'México' } = req.body;

        // Validar campos mínimos
        if (!calle || !numero || !colonia) {
            return res.status(400).json({
                success: false,
                errorMessage: 'Campos requeridos: calle, numero, colonia'
            });
        }

        const calleNorm = normalizeTexto(calle || '');
        const numeroNorm = normalizeTexto(numero || '');
        const coloniaNorm = normalizeTexto(colonia || '');
        const ciudadNorm = normalizeTexto(ciudad || 'Tepic');
        const estadoNorm = normalizeTexto(estado || 'Nayarit');
        const paisNorm = normalizeTexto(pais || 'México');

        const ubicacion = await geocodificarDireccion(calleNorm, numeroNorm, coloniaNorm, ciudadNorm, estadoNorm, paisNorm);

        res.json({
            success: true,
            data: ubicacion
        });

    } catch (error) {
        console.error('Error en geocodificarPreview:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error al geocodificar'
        });
    }
};

// @route   POST /api/reverse-geocode
// @access  Público (sin autenticación)
// @desc    Obtiene la dirección aproximada desde coordenadas (lat, lon)
exports.reverseGeocode = async (req, res) => {
    try {
        const { latitud, longitud } = req.body;

        if (latitud === undefined || longitud === undefined) {
            return res.status(400).json({
                success: false,
                errorMessage: 'Campos requeridos: latitud, longitud'
            });
        }

        const direccion = await obtenerDireccionDesdeCoordenas(latitud, longitud);

        if (!direccion) {
            return res.status(400).json({
                success: false,
                errorMessage: 'No se pudo obtener la dirección para estas coordenadas'
            });
        }

        res.json({
            success: true,
            data: direccion
        });

    } catch (error) {
        console.error('Error en reverseGeocode:', error);
        res.status(500).json({
            success: false,
            errorMessage: 'Error al realizar reverse geocoding'
        });
    }
};