// En un archivo de modelos o encima del servicio
class ServiceResponse {
  final bool success;
  final String? errorMessage;

  ServiceResponse(this.success, {this.errorMessage});
}