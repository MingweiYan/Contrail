enum WebDavAccessMode { direct, gateway }

extension WebDavAccessModeStorage on WebDavAccessMode {
  String get storageValue => name;
}

WebDavAccessMode webDavAccessModeFromStorage(String? value) {
  return WebDavAccessMode.values.firstWhere(
    (mode) => mode.storageValue == value,
    orElse: () => WebDavAccessMode.direct,
  );
}
