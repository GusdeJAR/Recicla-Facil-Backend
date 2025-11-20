// services/geocoding.js - VERSIÓN MEJORADA
const axios = require('axios');

// Coordenadas por defecto para Tepic, Nayarit
const TEPIC_DEFAULT = {
    latitud: 21.5018,
    longitud: -104.8946
};

// Bounding box aproximado de Tepic
const TEPIC_BBOX = {
    minLat: 21.44,
    maxLat: 21.57,
    minLon: -104.95,
    maxLon: -104.83
};

// Puntos de referencia conocidos en Tepic
const PUNTOS_REFERENCIA_TEPIC = {
    'centro': { latitud: 21.5018, longitud: -104.8946 },
    'tecnologico': { latitud: 21.4567, longitud: -104.8902 },
    'plaza civica': { latitud: 21.5012, longitud: -104.8934 },
    'ayuntamiento': { latitud: 21.5018, longitud: -104.8950 }
};

// Normaliza texto: elimina diacríticos (acentos), colapsa espacios y recorta
function normalizeTexto(s) {
    if (!s && s !== '') return s;
    try {
        return String(s)
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/\s+/g, ' ')
            .trim();
    } catch (e) {
        return s;
    }
}
function validarDireccion(direccion) {
    if (!direccion) return false;
    const { calle, numero, colonia } = direccion;
    return calle && calle.trim() && numero && numero.trim() && colonia && colonia.trim();
}

async function geocodificarConNominatim(query, reintentos = 0, bbox) {
    const MAX_REINTENTOS = 3;
    
    try {
        const params = {
            q: normalizeTexto(query),
            format: 'json',
            limit: 5,
            timeout: 5000,
            countrycodes: 'mx',
            addressdetails: 1
        };

        if (bbox) {
            params.viewbox = `${bbox.minLon},${bbox.maxLat},${bbox.maxLon},${bbox.minLat}`;
            params.bounded = 1;
        }

        console.log(`  Nominatim query: "${query}" -> normalized: "${normalizeTexto(query)}" ${bbox ? ' (con bbox)' : ''}`);
        
        const response = await axios.get('https://nominatim.openstreetmap.org/search', {
            params,
            headers: {
                'User-Agent': 'ReciclaFacilApp/1.0'
            },
            timeout: 6000
        });
        
        if (response.data && response.data.length > 0) {
            console.log(`  Encontrados ${response.data.length} resultados`);
            
            let resultado = response.data[0];
            if (bbox) {
                const dentro = response.data.filter(r => 
                    estaDentroDeBBox(parseFloat(r.lat), parseFloat(r.lon), bbox)
                );
                if (dentro.length > 0) {
                    resultado = dentro[0];
                    console.log(`  Resultado dentro de bbox: ${resultado.display_name}`);
                } else {
                    console.log(`  Ningún resultado dentro de bbox, usando primero: ${resultado.display_name}`);
                }
            } else {
                console.log(`  Primer resultado: ${resultado.display_name}`);
            }
            
            return {
                latitud: parseFloat(resultado.lat),
                longitud: parseFloat(resultado.lon),
                precisión: resultado.class || 'desconocida',
                displayName: resultado.display_name
            };
        }
        
        console.log(`  Sin resultados para: "${query}"`);
        
        if (reintentos < MAX_REINTENTOS) {
            const querySimplificada = query.split(',')[0];
            console.log(`  Reintentando con búsqueda simplificada: "${querySimplificada}" (intento ${reintentos + 1}/${MAX_REINTENTOS})`);
            await new Promise(resolve => setTimeout(resolve, 500));
            return geocodificarConNominatim(querySimplificada, reintentos + 1, bbox);
        }
        
        return null;
        
    } catch (error) {
        if (reintentos < MAX_REINTENTOS && error.code === 'ECONNABORTED') {
            console.log(`  Timeout en Nominatim, reintentando... (${reintentos + 1}/${MAX_REINTENTOS})`);
            await new Promise(resolve => setTimeout(resolve, 1000));
            return geocodificarConNominatim(query, reintentos + 1, bbox);
        }
        console.error(`  Error en Nominatim: ${error.message}`);
        return null;
    }
}

function estaDentroDeBBox(lat, lon, bbox) {
    if (!bbox) return true;
    return lat >= bbox.minLat && lat <= bbox.maxLat && lon >= bbox.minLon && lon <= bbox.maxLon;
}

async function geocodificarDireccion(calle, numero, colonia, ciudad = 'Tepic', estado = 'Nayarit', pais = 'México') {
    try {
        // Normalizar entradas para que no se distinga entre acentos
        const calleNorm = normalizeTexto(calle || '');
        const numeroNorm = normalizeTexto(numero || '');
        const coloniaNorm = normalizeTexto(colonia || '');
        const ciudadNorm = normalizeTexto(ciudad || 'Tepic');
        const estadoNorm = normalizeTexto(estado || 'Nayarit');
        const paisNorm = normalizeTexto(pais || 'México');

        if (!calleNorm || !numeroNorm || !coloniaNorm) {
            console.warn('Dirección incompleta. Usando coordenadas por defecto de Tepic.');
            return TEPIC_DEFAULT;
        }
        const direccionCompleta = `${calleNorm} ${numeroNorm}, ${coloniaNorm}, ${ciudadNorm}, ${estadoNorm}, ${paisNorm}`;
        console.log(`Geocodificando: ${direccionCompleta}`);

        const usarBBox = ciudadNorm && ciudadNorm.toLowerCase() === 'tepic';
        let resultado = await geocodificarConNominatim(direccionCompleta, 0, usarBBox ? TEPIC_BBOX : null);

        if (resultado) {
            if (usarBBox && !estaDentroDeBBox(resultado.latitud, resultado.longitud, TEPIC_BBOX)) {
                console.warn(`Resultado fuera de Tepic (completa): ${resultado.latitud}, ${resultado.longitud} — descartando.`);
            } else {
                console.log(`Geocodificación exitosa (completa): Lat ${resultado.latitud}, Lon ${resultado.longitud}`);
                return resultado;
            }
        }
        
        const busqueda2 = `${calleNorm}, ${coloniaNorm}, ${ciudadNorm}, ${estadoNorm}, ${paisNorm}`;
        resultado = await geocodificarConNominatim(busqueda2, 0, usarBBox ? TEPIC_BBOX : null);
        
        if (resultado) {
            if (usarBBox && !estaDentroDeBBox(resultado.latitud, resultado.longitud, TEPIC_BBOX)) {
                console.warn(`Resultado fuera de Tepic (calle+colonia+ciudad): ${resultado.latitud}, ${resultado.longitud} — descartando.`);
            } else {
                console.log(`Geocodificación exitosa (calle+colonia+ciudad): Lat ${resultado.latitud}, Lon ${resultado.longitud}`);
                return resultado;
            }
        }
        
        const busqueda3 = `${coloniaNorm}, ${ciudadNorm}, ${estadoNorm}, ${paisNorm}`;
        resultado = await geocodificarConNominatim(busqueda3, 0, usarBBox ? TEPIC_BBOX : null);
        
        if (resultado) {
            if (usarBBox && !estaDentroDeBBox(resultado.latitud, resultado.longitud, TEPIC_BBOX)) {
                console.warn(`Resultado fuera de Tepic (colonia+ciudad): ${resultado.latitud}, ${resultado.longitud} — descartando.`);
            } else {
                console.log(`Geocodificación exitosa (colonia+ciudad): Lat ${resultado.latitud}, Lon ${resultado.longitud}`);
                return resultado;
            }
        }
        
        if (ciudadNorm.toLowerCase() === 'tepic') {
            const palabrasClave = `${calleNorm} ${coloniaNorm}`.toLowerCase();
            for (const [lugar, coords] of Object.entries(PUNTOS_REFERENCIA_TEPIC)) {
                if (palabrasClave.includes(lugar)) {
                    console.log(`Geocodificación por punto de referencia (${lugar}): Lat ${coords.latitud}, Lon ${coords.longitud}`);
                    return coords;
                }
            }
        }
        
        console.warn(`No se pudo geocodificar la dirección. Usando coordenadas por defecto de Tepic.`);
        return TEPIC_DEFAULT;
        
    } catch (error) {
        console.error('Error crítico en geocodificación:', error.message);
        console.warn('Usando coordenadas por defecto de Tepic como fallback');
        return TEPIC_DEFAULT;
    }
}

async function geocodificarParaPreview(calle, numero, colonia, ciudad = 'Tepic', estado = 'Nayarit', pais = 'México') {
    const resultado = await geocodificarDireccion(calle, numero, colonia, ciudad, estado, pais);
    return resultado;
}

async function obtenerDireccionDesdeCoordenas(latitud, longitud) {
    try {
        console.log(`Reverse geocoding: Lat ${latitud.toFixed(6)}, Lon ${longitud.toFixed(6)}`);
        
        // Intentar con múltiples niveles de zoom
        const zooms = [20, 18, 16, 14];
        let response = null;
        let zoomUsado = null;
        
        for (const zoom of zooms) {
            try {
                const res = await axios.get('https://nominatim.openstreetmap.org/reverse', {
                    params: {
                        lat: latitud,
                        lon: longitud,
                        format: 'json',
                        zoom: zoom,
                        addressdetails: 1
                    },
                    headers: {
                        'User-Agent': 'ReciclaFacilApp/1.0'
                    },
                    timeout: 5000
                });
                
                if (res.data && res.data.address) {
                    response = res.data;
                    zoomUsado = zoom;
                    console.log(`  Zoom ${zoom} exitoso`);
                    break;
                }
            } catch (e) {
                console.log(`  Zoom ${zoom} no disponible, intentando siguiente...`);
                continue;
            }
        }
        
        if (!response || !response.address) {
            console.warn('Reverse geocoding sin resultado en ningún zoom');
            return {
                calle: 'Desconocida',
                numero: '',
                colonia: 'Desconocida',
                ciudad: 'Tepic',
                estado: 'Nayarit',
                direccion: `Lat: ${latitud.toFixed(4)}, Lon: ${longitud.toFixed(4)}`
            };
        }
        
        const address = response.address;
        console.log(`  Componentes Nominatim:`, JSON.stringify(address, null, 2));
        
        // Parsing mejorado con múltiples alternativas
        const calle = address.road 
            || address.street 
            || address.pedestrian 
            || address.footway 
            || 'Calle desconocida';
        
        const numero = address.house_number 
            || address.house 
            || '';
        
        const colonia = address.suburb 
            || address.neighbourhood 
            || address.village 
            || address.county 
            || address.district 
            || 'Colonia desconocida';
        
        const ciudad = address.city 
            || address.town 
            || address.municipality 
            || 'Tepic';
        
        const estado = address.state 
            || address.province 
            || 'Nayarit';
        
        const resultado = {
            calle: calle,
            numero: numero,
            colonia: colonia,
            ciudad: ciudad,
            estado: estado,
            direccion: response.display_name || `${calle} ${numero}, ${colonia}`.trim()
        };
        
        console.log(`Reverse geocoding exitoso (zoom ${zoomUsado}):`, resultado);
        return resultado;
        
    } catch (error) {
        console.error('Error crítico en reverse geocoding:', error.message);
        return {
            calle: 'Error',
            numero: '',
            colonia: 'No disponible',
            ciudad: 'Tepic',
            estado: 'Nayarit',
            direccion: 'No se pudo obtener la dirección'
        };
    }
}

module.exports = {
    geocodificarDireccion,
    geocodificarParaPreview,
    validarDireccion,
    obtenerDireccionDesdeCoordenas,
    normalizeTexto,
    TEPIC_DEFAULT,
    TEPIC_BBOX,
    estaDentroDeBBox
};
