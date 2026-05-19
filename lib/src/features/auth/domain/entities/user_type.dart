enum UserType {
  client('Cliente'),
  provider('Prestador');

  const UserType(this.label);

  final String label;
}
