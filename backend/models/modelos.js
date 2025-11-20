const mongoose = require('mongoose');
const materialesPermitidos = ["Todos", "Aluminio", "Cartón", "Papel", "PET", "Vidrio"];
const estadosPermitidos = ["true", "false"];
const estadosSolicitud = ["pendiente", "aprobada", "rechazada"];

//modelo para usuarios
const usuarioSchema = new mongoose.Schema({
    nombre: { 
        type: String, 
        required: true,
        trim: true 
    },
    email: { 
        type: String, 
        required: true, 
        unique: true, 
        trim: true,   
        lowercase: true
    },
    password: { 
        type: String, 
        required: true 
    },
    admin: { 
        type: Boolean, 
        default: false 
    },
    fechaCreacion: { 
        type: Date, 
        default: Date.now 
    }
});

//modelo para quejas
const quejaSchema = new mongoose.Schema({
    correo: {
        type: String,
        required: [true, 'El correo del remitente es obligatorio.'],
        trim: true,
        lowercase: true
    },
    categoria: {
        type: String,
        required: [true, 'La categoría no puede estar vacía.'],
        trim: true
    },
    mensaje: {
        type: String,
        required: [true, 'El mensaje no puede estar vacío.'],
        trim: true
    },
    estado: {
        type: String,
        enum: ['Pendiente', 'Atendida'],
        default: 'Pendiente'
    },
    respuestaAdmin: {
        type: String,
        trim: true
    },
    fechaCreacion: {
        type: Date,
        default: Date.now
    },
    fechaAtencion: {
        type: Date
    }
});

// Modelo para el contenido educativo
const contenidoEducativoSchema = new mongoose.Schema({
    titulo: {
        type: String,
        required: [true, 'El título es obligatorio'],
        trim: true
    },
    descripcion: {
        type: String,
        required: [true, 'La descripción es obligatoria']
    },
    contenido: {
        type: String,
        required: [true, 'El contenido es obligatorio']
    },
    categoria: {
        type: String,
        enum: ['tipos-materiales', 'proceso-reciclaje', 'consejos-practicos', 'preparacion-materiales'],
        required: [true, 'La categoría es obligatoria']
    },
    tipo_material: {
        type: String,
        enum: ['todos', 'aluminio', 'cartón', 'papel', 'pet', 'vidrio'],
        required: [true, 'El tipo de material es obligatorio']
    },
    imagenes: [{
        ruta: {
            type: String,
            required: [true, 'La ruta de la imagen es obligatoria']
        },
        pie_de_imagen: {
            type: String,
            default: ''
        },
        es_principal: {
            type: Boolean,
            default: false
        }
    }],
    puntos_clave: [{
        type: String
    }],
    acciones_correctas: [{
        type: String
    }],
    acciones_incorrectas: [{
        type: String
    }],
    etiquetas: [{
        type: String
    }],
    publicado: {
        type: Boolean,
        default: false
    },
    autor: {
        type: String,
        default: 'Sistema de Reciclaje Local'
    },
    fecha_creacion: {
        type: Date,
        default: Date.now
    },
    fecha_actualizacion: {
        type: Date,
        default: Date.now
    }
});

// Modelo para los puntos de reciclaje
const puntosReciclajeSchema = new mongoose.Schema({
    nombre: {
        type: String,
        required: [true, "El nombre no puede estar vacío"],
        trim: true
    },
    descripcion: {
        type: String,
        required: [true, "La descripción no puede estar vacía"],
        trim: true
    },
    latitud: {
        type: Number,
        required: [true, "La latitud no puede estar vacía"],
        trim: true
    },
    longitud: {
        type: Number,
        required: [true, "La longitud no puede estar vacía"],
        trim: true
    },
    icono: {
        type: String, 
        default: "assets/iconos/recycle_paper.png"
    },
    tipo_material: {
        type: [String],
        required: [true, "El tipo de material es obligatorio"],
        validate: {
            validator: function(arrayDeMateriales) {
                if (!arrayDeMateriales || arrayDeMateriales.length === 0) return false;
                return arrayDeMateriales.every(material => materialesPermitidos.includes(material));
            },
            message: props => `El array contiene materiales no válidos. Solo se permiten: ${materialesPermitidos.join(', ')}`
        }
    },
    direccion: {
        type: String,
        required: [true, "La dirección no puede estar vacía"],
        trim: true
    },
    telefono: {
        type: String,
        required: [true, "El teléfono no puede estar vacío"],
        trim: true
    },
    horario: {
        type: String,
        required: [true, "El horario no puede estar vacío"],
        trim: true
    },
    aceptado: {
        type: String,
        required: true,
        enum: estadosPermitidos,
        default: "false"
    }
});

// Modelo para solicitudes de puntos de reciclaje
const solicitudPuntoSchema = new mongoose.Schema({
    nombre: {
        type: String,
        required: [true, "El nombre no puede estar vacío"],
        trim: true
    },
    descripcion: {
        type: String,
        required: [true, "La descripción no puede estar vacía"],
        trim: true
    },
    // Dirección para geocodificación
    direccion: {
        calle: {
            type: String,
            required: [true, "La calle es obligatoria"],
            trim: true
        },
        numero: {
            type: String,
            required: [true, "El número es obligatorio"],
            trim: true
        },
        colonia: {
            type: String,
            required: [true, "La colonia es obligatoria"],
            trim: true
        },
        ciudad: {
            type: String,
            default: "Tepic",
            trim: true
        },
        estado: {
            type: String,
            default: "Nayarit",
            trim: true
        },
        pais: {
            type: String,
            default: "México",
            trim: true
        }
    },
    // Coordenadas obtenidas por geocodificación (opcionales al crear, se generan automáticamente)
    ubicacion: {
        latitud: {
            type: Number
        },
        longitud: {
            type: Number
        }
    },
    icono: {
        type: String, 
        default: "assets/iconos/recycle_general.png"
    },
    tipo_material: {
        type: [String],
        required: [true, "El tipo de material es obligatorio"],
        validate: {
            validator: function(arrayDeMateriales) {
                if (!arrayDeMateriales || arrayDeMateriales.length === 0) return false;
                return arrayDeMateriales.every(material => materialesPermitidos.includes(material));
            },
            message: props => `El array contiene materiales no válidos. Solo se permiten: ${materialesPermitidos.join(', ')}`
        }
    },
    telefono: {
        type: String,
        required: [true, "El teléfono no puede estar vacío"],
        trim: true
    },
    horario: {
        type: String,
        required: [true, "El horario no puede estar vacío"],
        trim: true
    },
    // Usuario que creó la solicitud
    usuarioSolicitante: {
        type: String,
        required: true
    },
    // Estado de la solicitud
    estado: {
        type: String,
        enum: estadosSolicitud,
        default: "pendiente"
    },
    // Admin que revisó la solicitud
    adminRevisor: {
        type: String
    },
    // Comentarios del admin al aprobar/rechazar
    comentariosAdmin: {
        type: String,
        trim: true
    },
    fechaCreacion: {
        type: Date,
        default: Date.now
    },
    fechaRevision: {
        type: Date
    }
});

// Middleware para actualizar la fecha de actualización antes de guardar
contenidoEducativoSchema.pre('save', function(next) {
    this.fecha_actualizacion = Date.now();
    next();
});

// Middleware para actualizar fecha de revisión cuando cambia el estado
solicitudPuntoSchema.pre('save', function(next) {
    if (this.isModified('estado') && this.estado !== 'pendiente') {
        this.fechaRevision = new Date();
    }
    next();
});

// Índices para optimizar búsquedas
quejaSchema.index({ usuario: 1, estado: 1 });
contenidoEducativoSchema.index({ categoria: 1, publicado: 1 });
contenidoEducativoSchema.index({ tipo_material: 1 });
contenidoEducativoSchema.index({ etiquetas: 1 });
contenidoEducativoSchema.index({ fecha_creacion: -1 });
solicitudPuntoSchema.index({ estado: 1, fechaCreacion: -1 });
solicitudPuntoSchema.index({ usuarioSolicitante: 1 });
solicitudPuntoSchema.index({ 'ubicacion.latitud': 1, 'ubicacion.longitud': 1 });

// Exportar modelos
exports.Usuario = mongoose.model('coleccion_usuarios', usuarioSchema);
exports.Queja = mongoose.model('coleccion_queja', quejaSchema);
exports.ContenidoEducativo = mongoose.model('coleccion_contenido_educativo', contenidoEducativoSchema);
exports.PuntosReciclaje = mongoose.model(
  'PuntoReciclaje',         
  puntosReciclajeSchema,  
  'coleccion_puntos_reciclaje' 
);
exports.SolicitudPunto = mongoose.model('coleccion_solicitudes_puntos', solicitudPuntoSchema);