enum SecureStorageKey {
  accessToken('access_token'),
  refreshToken('refresh_token');

  const SecureStorageKey(this.name);
  final String name;
}
