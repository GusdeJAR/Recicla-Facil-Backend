class CloudinaryImage {
  final String ruta;      // secure_url de Cloudinary
  final String publicId;  // public_id de Cloudinary

  CloudinaryImage({required this.ruta, required this.publicId});

  Map<String, dynamic> toJson() => {
    'ruta': ruta,
    'public_id': publicId,
  };
}