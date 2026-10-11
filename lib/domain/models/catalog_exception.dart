class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
  @override
  String toString() => message;
}
