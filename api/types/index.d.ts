// Este archivo le dice a TypeScript cómo manejar la librería 'multer-storage-cloudinary',
// ya que no tiene sus propios archivos de tipos.

declare module 'multer-storage-cloudinary' {
    import { StorageEngine } from 'multer';
    import { ConfigOptions, UploadApiOptions, UploadApiResponse } from 'cloudinary';

    /**
     * Define la interfaz para las opciones de Cloudinary Storage.
     */
    export interface CloudinaryStorageOptions {
        cloudinary: {
            config: ConfigOptions;
        };
        params?: {
            folder?: string;
            allowed_formats?: string[];
            public_id?: (req: Express.Request, file: Express.Multer.File) => string | Promise<string>;
            // Puedes añadir cualquier otra opción de UploadApiOptions que necesites aquí
            // Por ejemplo: transformation, tags, etc.
            [key: string]: any; 
        };
    }

    /**
     * La clase CloudinaryStorage que extiende StorageEngine de Multer.
     */
    export class CloudinaryStorage implements StorageEngine {
        constructor(options: CloudinaryStorageOptions);
        _handleFile: (req: Express.Request, file: Express.Multer.File, callback: (error?: any, info?: Partial<Express.Multer.File> & { path: string }) => void) => void;
        _removeFile: (req: Express.Request, file: Express.Multer.File, callback: (error: Error | null) => void) => void;
    }
    
    // Si la librería exporta la clase directamente como la única cosa:
    // export default CloudinaryStorage;
    // Ya que usamos 'require' y desestructuración ({ CloudinaryStorage }), la exportación con nombre es la más segura.
}