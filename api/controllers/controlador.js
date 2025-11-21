const modelos = require('../models/modelos');
const cloudinary = require('cloudinary').v2;
const path = require('path');

exports.crearUsuario = async (req, res) => {
     try {
        const { nombre, email, password } = req.body;

        // 1. Verificar si el correo ya existe en la base de datos
        const nombreExistente = await modelos.Usuario.findOne({ nombre: nombre.trim() });
        if (nombreExistente) {
                    // Usa el código 409 Conflict: El recurso no se puede crear porque ya existe.
                    return res.status(409).json({ mensaje: "El nombre de usuario ya está registrado." });
                }

        const emailExistente = await modelos.Usuario.findOne({ email: email.trim() });

        if (emailExistente) {
            // Usa el código 409 Conflict: El recurso no se puede crear porque ya existe.
            return res.status(409).json({ mensaje: "El correo electrónico ya está registrado." });
        }

        // (Aquí va tu lógica para hashear la contraseña con bcrypt, si la usas)

        // Limpia y crea el nuevo usuario
        const nuevoUsuario = await modelos.Usuario.create({
            nombre: nombre.trim(),
            email: email.trim(),
            password: password, // O la contraseña hasheada
        });

        // 2. Respuesta de éxito: Código 201 Created
        res.status(201).json({ 
            mensaje: 'Usuario creado con éxito',
            usuario: { nombre: nuevoUsuario.nombre }
        });

    } catch (error) {
        console.error("Error en crearUsuario:", error);
        // 3. Respuesta de error del servidor: Código 500
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
        // 1. Obtiene el email de los parámetros de la URL
        const email = req.params.email;

        // 2. Busca al usuario en la base de datos
        const usuario = await modelos.Usuario.findOne({ email: email });

        // 3. Si no se encuentra el usuario, envía un error 404
        if (!usuario) {
            return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
        }

        // 4. Si se encuentra, envía los datos (¡SIN LA CONTRASEÑA!)
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
// @access  Privado (debería estar protegido)
// ===================================================================
exports.cambiarPassword = async (req, res) => {
    try {
        // 1. Obtiene el email y la nueva contraseña del cuerpo de la petición
        const { email, nuevaPassword } = req.body;

        // 2. Valida que los datos necesarios fueron enviados
        if (!email || !nuevaPassword) {
            return res.status(400).json({ mensaje: 'Faltan datos requeridos (email o nuevaPassword).' });
        }

        // 3. Busca al usuario por su email
        const usuario = await modelos.Usuario.findOne({ email: email });

        if (!usuario) {
            return res.status(404).json({ mensaje: 'Usuario no encontrado.' });
        }

        // 4. Actualiza la contraseña del usuario encontrado
        // En un proyecto real, la 'nuevaPassword' debería ser hasheada antes de guardarla.
        usuario.password = nuevaPassword;
        await usuario.save();

        // 5. Envía una respuesta de éxito
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
            // Usamos .exec() para una promesa más robusta
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
            console.error("API CRITICAL ERROR en login:", error); // Esto nos mostrará el error de la BD si lo hay
            return res.status(500).json({ mensaje: 'Error interno del servidor' });
        }
    };
    
exports.actualizarUsuario = async (req, res) => {

    // Lógica para actualizar un usuario
    // Aceptar email por body o por parámetro de ruta (req.params.email)
    const { nombre, password, admin, correo } = req.body;
    const email = req.params && req.params.email ? req.params.email : req.body.email;
    try{
        if(!email){
            return res.status(400).json({ mensaje: 'El email es requerido para actualizar el usuario' });
        }

        // Construir objeto de actualización sólo con campos presentes
        const update = {};
        if(nombre !== undefined) update.nombre = nombre;
        if(password !== undefined) update.password = password;
        if(admin !== undefined) update.admin = admin;
        // Buscar por email y actualizar
        const usuarioActualizado = await modelos.Usuario.findOneAndUpdate({ email }, update, { new: true });

        if(!usuarioActualizado){
            return res.status(404).json({ mensaje: 'Usuario no encontrado' });
        }

        res.status(200).json({ mensaje: 'Usuario actualizado exitosamente', usuario: usuarioActualizado });
    }catch(error){
        res.status(500).json({ mensaje: 'Error al actualizar el usuario', error: error.message });
    }

}  
exports.eliminarUsuario = async (req, res) => {
    // Lógica para eliminar un usuario
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
// @desc    Crear una nueva queja (desde un formulario público)
// @route   POST /api/quejas
// @access  Público
// =========================================================================
exports.crearQueja = async (req, res) => {
    try {
        // --- ¡CAMBIO CLAVE! Leemos 'correo' y 'mensaje' del cuerpo ---
        const { correo, categoria, mensaje } = req.body;

        // Validamos que los datos necesarios hayan llegado
        if (!correo) {
            return res.status(400).json({ mensaje: 'El correo es obligatorio.' });
        }

        if (!categoria) {
            return res.status(400).json({ mensaje: 'La categoría es obligatoria.' });
        }

        if (!mensaje) {
            return res.status(400).json({ mensaje: 'El mensaje es obligatorio.' });
        }

        // Creamos el nuevo documento 'Queja' en la base de datos
        const nuevaQueja = new modelos.Queja({
            correo: correo, 
            categoria: categoria,
            mensaje: mensaje
        });

        // Guardamos la nueva queja en la base de datos
        await nuevaQueja.save();

        // Enviamos una respuesta de éxito (201 Created)
        res.status(201).json({
            mensaje: 'Queja enviada con éxito.',
            queja: nuevaQueja
        });

    } catch (error) {
        console.error("Error al crear la queja:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor al procesar la solicitud.' });
    }
};

// =========================================================================
// @desc    Obtener todas las quejas del usuario que está logueado
// @route   GET /api/quejas/mis-quejas
// @access  Privado (solo para el usuario dueño de las quejas)
// =========================================================================
exports.obtenerMisQuejas = async (req, res) => {
    try {
        const correoUsuario = req.params.email;

        // Buscamos todas las quejas que coincidan con el correo del usuario
        // y las ordenamos de la más reciente a la más antigua.
        const quejas = await modelos.Queja.find({ correo : correoUsuario }).sort({ fechaCreacion: -1 });

        res.status(200).json(quejas);

    } catch (error) {
        console.error("Error al obtener mis quejas:", error);
        res.status(500).json({ mensaje: 'Error interno del servidor.' });
    }
};

// =========================================================================
// @desc    Obtener todas las quejas pendientes (para Administradores)
// @route   GET /api/quejas/pendientes
// @access  Privado (solo para Administradores)
// =========================================================================
exports.obtenerQuejasPendientes = async (req, res) => {
    try {
        // Buscamos todas las quejas con estado 'Pendiente'
        // 'populate' es muy útil aquí: reemplaza el ID del usuario con los datos del usuario (nombre y email).
        const quejasPendientes = await modelos.Queja.find({ estado: 'Pendiente' })
            .sort({ fechaCreacion: 1 }); // Ordenamos de la más antigua a la más nueva

        res.status(200).json(quejasPendientes);

    } catch (error) {
        console.error("Error al obtener quejas pendientes:", error);
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

// =========================================================================
// @desc    Atender una queja (para Administradores)
// @route   PUT /api/quejas/:id
// @access  Privado (solo para Administradores)
// =========================================================================
exports.atenderQueja = async (req, res) => {
    try {
        const { respuestaAdmin } = req.body;
        const quejaId = req.params.id; // El ID de la queja viene de la URL

        if (!respuestaAdmin) {
            return res.status(400).json({ mensaje: 'La respuesta del administrador es obligatoria.' });
        }

        // Buscamos la queja por su ID y la actualizamos
        const quejaAtendida = await modelos.Queja.findByIdAndUpdate(
            quejaId,
            {
                estado: 'Atendida',
                respuestaAdmin: respuestaAdmin,
                fechaAtencion: new Date() // Guardamos la fecha actual
            },
            { new: true } // {new: true} hace que Mongoose devuelva el documento ya actualizado
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

// @desc    Eliminar una queja
// @route   DELETE /api/quejas/:id
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

// @desc    Crear nuevo contenido educativo
// @route   POST /api/contenido-educativo
// @access  Privado (Admin)

exports.crearContenidoEducativo = async (req, res) => {
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
            // Recibimos el índice de la imagen que será la principal
            img_principal 
        } = req.body;

        // Validaciones (se mantienen igual)
        if (!titulo || !descripcion || !contenido || !categoria || !tipo_material) {
            return res.status(400).json({ mensaje: 'Faltan campos obligatorios.' });
        }
        
        // El middleware ya subió los archivos a Cloudinary.
        if (!req.files || req.files.length === 0) {
            return res.status(400).json({ mensaje: 'Se requiere al menos una imagen.' });
        }

        // --- TRADUCCIÓN A CLOUDINARY ---
        const imagenesProcesadas = req.files.map((file, index) => {
            // El índice de la imagen principal viene del body (ej. '0')
            // Comparamos el índice actual del bucle con el índice recibido.
            const esPrincipal = parseInt(img_principal, 10) === index;

            return {
                ruta: file.path,          // URL segura (https://) de Cloudinary
                public_id: file.filename, // ID para poder borrarla después
                pie_de_imagen: `Imagen de ${titulo}`,
                es_principal: esPrincipal 
            };
        });

        // Tu lógica de parseo de arrays es buena, la mantenemos
        const nuevoContenido = new modelos.ContenidoEducativo({
            titulo: titulo.trim(),
            descripcion: descripcion.trim(),
            contenido: contenido,
            categoria,
            tipo_material,
            imagenes: imagenesProcesadas, // Usamos el array procesado
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
        
        // --- LIMPIEZA DE EMERGENCIA ---
        // Si falla el guardado en la BD, borramos las imágenes ya subidas
        if (req.files && req.files.length > 0) {
            const publicIds = req.files.map(file => file.filename);
            try {
                await cloudinary.api.delete_resources(publicIds);
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


// @desc    Obtener todo el contenido educativo (con filtros opcionales)
// @route   GET /api/contenido-educativo
// @access  Público
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

// @desc    Obtener contenido educativo por ID
// @route   GET /api/contenido-educativo/:id
// @access  Público
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

// @desc    Actualizar contenido educativo
// @route   PUT /api/contenido-educativo/:id
// @access  Privado (Admin)
exports.actualizarContenidoEducativo = async (req, res) => {
    try {
        const contenidoId = req.params.id;
        const body = req.body || {};

        const contenidoExistente = await modelos.ContenidoEducativo.findById(contenidoId);
        if (!contenidoExistente) {
            return res.status(404).json({ mensaje: 'Contenido educativo no encontrado.' });
        }

        // Tu lógica para construir el objeto de actualización de campos simples se mantiene
        const update = {};
        if (body.titulo !== undefined) update.titulo = String(body.titulo).trim();
        // ... etc para descripcion, contenido, categoria, etc...
        update.puntos_clave = JSON.parse(body.puntos_clave || '[]');
        update.etiquetas = JSON.parse(body.etiquetas || '[]');
        // ...

        // ========== TRADUCCIÓN: MANEJO DE IMÁGENES ==========
        let imagenesFinal = [...contenidoExistente.imagenes];

        // --- 1. Borrar imágenes marcadas para eliminación ---
        if (body.borrar_imagenes) {
            // Esperamos un array de public_ids en formato JSON string
            let idsParaBorrar = JSON.parse(body.borrar_imagenes);
            if (Array.isArray(idsParaBorrar) && idsParaBorrar.length > 0) {
                // Borrar de Cloudinary
                await cloudinary.api.delete_resources(idsParaBorrar);
                // Filtrar del array que se guardará en la BD
                imagenesFinal = imagenesFinal.filter(img => !idsParaBorrar.includes(img.public_id));
            }
        }
        
        // --- 2. Agregar nuevas imágenes (si las hay) ---
        if (req.files && req.files.length > 0) {
            const nuevasImagenes = req.files.map(file => ({
                ruta: file.path,
                public_id: file.filename,
                pie_de_imagen: `Imagen de ${body.titulo || contenidoExistente.titulo}`,
                es_principal: false // Por defecto, las nuevas no son principales. Se podría ajustar si se envía esa info.
            }));
            imagenesFinal.push(...nuevasImagenes);
        }

        // --- 3. Actualizar la imagen principal (si se especifica) ---
        if (body.img_principal_ruta !== undefined) {
             // El cliente envía la 'ruta' de la imagen que debe ser la principal
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
        // Limpieza de emergencia para las imágenes nuevas que se subieron
        if (req.files && req.files.length > 0) {
            const publicIds = req.files.map(file => file.filename);
            try {
                await cloudinary.api.delete_resources(publicIds);
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


// @desc    Eliminar contenido educativo
// @route   DELETE /api/contenido-educativo/:id
// @access  Privado (Admin)
exports.eliminarContenidoEducativo = async (req, res) => {
    try {
        const contenidoId = req.params.id;

        // Primero buscamos el documento para obtener las rutas de las imágenes
        const contenido = await modelos.ContenidoEducativo.findById(contenidoId);
        if (!contenido) {
            return res.status(404).json({ mensaje: 'Contenido educativo no encontrado.' });
        }

        // Directorio donde multer guarda las imágenes (coincide con config/multer.config.js)
        const uploadsDir = path.join(__dirname, '..', 'uploads');

        const archivosEliminados = [];
        // Intentar eliminar cada archivo referenciado en contenido.imagenes
        if (Array.isArray(contenido.imagenes)) {
            for (const img of contenido.imagenes) {
                try {
                    const ruta = img && img.ruta ? img.ruta : null;
                    if (!ruta) continue;

                    // La ruta almacenada es una URL pública (ej. http://host/uploads/archivo.jpg)
                    // Extraemos el nombre de archivo
                    let filename = ruta;
                    try {
                        if (typeof ruta === 'string' && ruta.startsWith('http')) {
                            const url = new URL(ruta);
                            filename = path.basename(url.pathname);
                        } else {
                            filename = path.basename(ruta);
                        }
                    } catch (e) {
                        // Si falló el parseo como URL, usar basename directamente
                        filename = path.basename(ruta);
                    }

                    const filePath = path.join(uploadsDir, filename);
                    if (fs.existsSync(filePath)) {
                        await fs.promises.unlink(filePath);
                        archivosEliminados.push(filename);
                    } else {
                        // Archivo no existe; loggear para debug pero continuar
                        console.warn(`Archivo no encontrado al intentar eliminar: ${filePath}`);
                    }
                } catch (err) {
                    console.error('Error eliminando imagen vinculada al contenido:', err);
                    // continuar con las demás imágenes
                }
            }
        }

        // Finalmente eliminar el documento de la base de datos
        await modelos.ContenidoEducativo.findByIdAndDelete(contenidoId);

        res.status(200).json({ 
            mensaje: 'Contenido educativo eliminado exitosamente.',
            archivosEliminados
        });

    } catch (error) {
        console.error("Error en eliminarContenidoEducativo:", error);
        res.status(500).json({ 
            mensaje: 'Error interno al eliminar el contenido educativo.',
            error: error.message 
        });
    }
};

// @desc    Obtener contenido por categoría
// @route   GET /api/contenido-educativo/categoria/:categoria
// @access  Público
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

// @desc    Obtener contenido por tipo de material
// @route   GET /api/contenido-educativo/material/:tipo_material
// @access  Público
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

// @desc    Buscar contenido educativo por término
// @route   GET /api/contenido-educativo/buscar/:termino
// @access  Público
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

// @desc    Obtener todos los puntos de reciclaje por material (aceptado)
// @route   GET /api/puntos-reciclaje/material/:material
// @access  Público
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

// @desc    Obtener todos los puntos de reciclaje de acuerdo al estado
// @route   GET /api/puntos-reciclaje/estado/:aceptado
// @access  Público
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

// @desc    Cambiar el punto de reciclaje de no estar aceptado a aceptado.
// @route   PUT /api/puntos-reciclaje/estado/:id
// @access  Público
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

// @desc    Editar un registro de puntos de reciclaje
// @route   PUT /api/puntos-reciclaje/:id
// @access  Público
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

// @desc    Eliminar un registro de puntos de reciclaje
// @route   DELETE /api/puntos-reciclaje/:id
// @access  Público
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
// CONTROLADORES PARA SOLICITUDES DE PUNTOS DE RECICLAJE - ACTUALIZADOS
// =========================================================================

const { SolicitudPunto, PuntosReciclaje } = require('../models/modelos');
const { geocodificarDireccion, obtenerDireccionDesdeCoordenas, TEPIC_BBOX, estaDentroDeBBox, normalizeTexto } = require('../services/geocoding');

// @desc    Crear una nueva solicitud de punto de reciclaje
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
            horario
        } = req.body;

        // Validar campos requeridos
        if (!nombre || !descripcion || !direccion || !tipo_material) {
            return res.status(400).json({
                success: false,
                error: 'Faltan campos obligatorios: nombre, descripción, dirección y tipo de material'
            });
        }

        // Permitir que el cliente envíe una ubicación ajustada por el usuario.
        // Si no se envía o no es válida, geocodificamos la dirección.
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
        const nuevaSolicitud = new SolicitudPunto({
            nombre,
            descripcion,
            direccion,
            tipo_material,
            telefono: telefono || '',
            horario: horario || '',
            usuarioSolicitante: req.usuario.nombre, // Del middleware authSimple
            estado: 'pendiente',
            ubicacion: {
                latitud: latitudFinal,
                longitud: longitudFinal
            }
        });

        await nuevaSolicitud.save();

        res.status(201).json({
            success: true,
            data: nuevaSolicitud,
            message: 'Solicitud creada exitosamente'
        });

    } catch (error) {
        console.error('Error creando solicitud:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor: ' + error.message
        });
    }
};

// @desc    Obtener las solicitudes del usuario actual
// @route   GET /api/solicitudes-puntos/mis-solicitudes
// @access  Con autenticación simple
exports.obtenerMisSolicitudes = async (req, res) => {
    try {
        const solicitudes = await SolicitudPunto.find({ 
            usuarioSolicitante: req.usuario.nombre // Del middleware authSimple
        })
        .sort({ fechaCreacion: -1 });

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo solicitudes:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener todas las solicitudes pendientes
// @route   GET /api/solicitudes-puntos/admin/pendientes
// @access  Solo administradores (autenticación simple)
exports.obtenerSolicitudesPendientes = async (req, res) => {
    try {
        const solicitudes = await SolicitudPunto.find({ estado: 'pendiente' })
            .sort({ fechaCreacion: 1 });

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo solicitudes pendientes:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener todas las solicitudes con filtros
// @route   GET /api/solicitudes-puntos/admin/todas
// @access  Solo administradores (autenticación simple)
exports.obtenerTodasLasSolicitudes = async (req, res) => {
    try {
        const { estado } = req.query;
        const filter = estado ? { estado } : {};

        const solicitudes = await SolicitudPunto.find(filter)
            .sort({ fechaCreacion: -1 });

        res.json({
            success: true,
            data: solicitudes
        });

    } catch (error) {
        console.error('Error obteniendo todas las solicitudes:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Aprobar una solicitud de punto de reciclaje
// @route   PUT /api/solicitudes-puntos/admin/:id/aprobar
// @access  Solo administradores (autenticación simple)
exports.aprobarSolicitudPunto = async (req, res) => {
    try {
        const { comentariosAdmin } = req.body;
        
        const solicitud = await SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                error: 'Solicitud no encontrada'
            });
        }

        if (solicitud.estado !== 'pendiente') {
            return res.status(400).json({
                success: false,
                error: 'La solicitud ya fue procesada'
            });
        }

        // 1. Actualizar la solicitud
        solicitud.estado = 'aprobada';
        solicitud.adminRevisor = req.usuario.nombre; // Nombre del admin del middleware
        solicitud.comentariosAdmin = comentariosAdmin || 'Solicitud aprobada';
        solicitud.fechaRevision = new Date();
        
        await solicitud.save();

        // 2. Crear el punto de reciclaje
        // Obtener coordenadas por geocodificación
        const calleNorm = normalizeTexto(solicitud.direccion.calle || '');
        const numeroNorm = normalizeTexto(solicitud.direccion.numero || '');
        const coloniaNorm = normalizeTexto(solicitud.direccion.colonia || '');
        const ciudadNorm = normalizeTexto(solicitud.direccion.ciudad || 'Tepic');
        const estadoNorm = normalizeTexto(solicitud.direccion.estado || 'Nayarit');
        const paisNorm = normalizeTexto(solicitud.direccion.pais || 'México');

        const coordenadas = await geocodificarDireccion(
            calleNorm,
            numeroNorm,
            coloniaNorm,
            ciudadNorm,
            estadoNorm,
            paisNorm
        );
        
        const direccionCompleta = `${solicitud.direccion.calle} ${solicitud.direccion.numero}, ${solicitud.direccion.colonia}, ${solicitud.direccion.ciudad}, ${solicitud.direccion.estado}`;
        
        const nuevoPunto = new PuntosReciclaje({
            nombre: solicitud.nombre,
            descripcion: solicitud.descripcion,
            latitud: coordenadas.latitud,
            longitud: coordenadas.longitud,
            icono: solicitud.icono || 'assets/iconos/recycle_general.png',
            tipo_material: solicitud.tipo_material,
            direccion: direccionCompleta,
            telefono: solicitud.telefono,
            horario: solicitud.horario,
            aceptado: "true"
        });

        await nuevoPunto.save();

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
            error: 'Error interno del servidor: ' + error.message
        });
    }
};

// @desc    Rechazar una solicitud de punto de reciclaje
// @route   PUT /api/solicitudes-puntos/admin/:id/rechazar
// @access  Solo administradores (autenticación simple)
exports.rechazarSolicitudPunto = async (req, res) => {
    try {
        const { comentariosAdmin } = req.body;
        
        if (!comentariosAdmin || comentariosAdmin.trim() === '') {
            return res.status(400).json({
                success: false,
                error: 'Los comentarios son obligatorios al rechazar una solicitud'
            });
        }

        const solicitud = await SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                error: 'Solicitud no encontrada'
            });
        }

        if (solicitud.estado !== 'pendiente') {
            return res.status(400).json({
                success: false,
                error: 'La solicitud ya fue procesada'
            });
        }

        solicitud.estado = 'rechazada';
        solicitud.adminRevisor = req.usuario.nombre; // Nombre del admin del middleware
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
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener estadísticas de solicitudes
// @route   GET /api/solicitudes-puntos/admin/estadisticas
// @access  Solo administradores (autenticación simple)
exports.obtenerEstadisticasSolicitudes = async (req, res) => {
    try {
        const totalSolicitudes = await SolicitudPunto.countDocuments();
        const solicitudesPendientes = await SolicitudPunto.countDocuments({ estado: 'pendiente' });
        const solicitudesAprobadas = await SolicitudPunto.countDocuments({ estado: 'aprobada' });
        const solicitudesRechazadas = await SolicitudPunto.countDocuments({ estado: 'rechazada' });

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
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Obtener una solicitud por ID
// @route   GET /api/solicitudes-puntos/:id
// @access  Con autenticación simple
exports.obtenerSolicitudPorId = async (req, res) => {
    try {
        const solicitud = await SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                error: 'Solicitud no encontrada'
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
            error: 'Error interno del servidor'
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

        const solicitud = await SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                error: 'Solicitud no encontrada'
            });
        }

        // Solo permitir actualizar si es el propietario o admin
        if (solicitud.usuarioSolicitante !== req.usuario.nombre && !req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                error: 'No tienes permisos para actualizar esta solicitud'
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
            error: 'Error interno del servidor'
        });
    }
};

// @desc    Eliminar una solicitud
// @route   DELETE /api/solicitudes-puntos/:id
// @access  Con autenticación simple
exports.eliminarSolicitudPunto = async (req, res) => {
    try {
        const solicitud = await SolicitudPunto.findById(req.params.id);

        if (!solicitud) {
            return res.status(404).json({
                success: false,
                error: 'Solicitud no encontrada'
            });
        }

        // Solo permitir eliminar si es el propietario o admin
        if (solicitud.usuarioSolicitante !== req.usuario.nombre && !req.usuario.esAdmin) {
            return res.status(403).json({
                success: false,
                error: 'No tienes permisos para eliminar esta solicitud'
            });
        }

        await SolicitudPunto.findByIdAndDelete(req.params.id);

        res.json({
            success: true,
            message: 'Solicitud eliminada exitosamente'
        });

    } catch (error) {
        console.error('Error eliminando solicitud:', error);
        res.status(500).json({
            success: false,
            error: 'Error interno del servidor'
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
                error: 'Campos requeridos: calle, numero, colonia'
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
            error: 'Error al geocodificar'
        });
    }
};

// @route   POST /api/reverse-geocode
// @access  Público (sin autenticación)
// @desc    Obtiene la dirección aproximada desde coordenadas (lat, lon)
//          Útil cuando el usuario ajusta manualmente la ubicación en el mapa
exports.reverseGeocode = async (req, res) => {
    try {
        const { latitud, longitud } = req.body;

        // Validar coordenadas
        if (latitud === undefined || longitud === undefined) {
            return res.status(400).json({
                success: false,
                error: 'Campos requeridos: latitud, longitud'
            });
        }

        const direccion = await obtenerDireccionDesdeCoordenas(latitud, longitud);

        if (!direccion) {
            return res.status(400).json({
                success: false,
                error: 'No se pudo obtener la dirección para estas coordenadas'
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
            error: 'Error al realizar reverse geocoding'
        });
    }
};