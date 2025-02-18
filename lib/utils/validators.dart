// ************* lib/utils/validators.dart *************

class MiaChatValidators {
  static final RegExp _apiKeyRegExp = RegExp(
    r'^miachat_prod_[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}$'
  );

  static bool isValidApiKey(String key) => _apiKeyRegExp.hasMatch(key);

  static String? apiKeyValidator(String? value) {
    if (value == null || value.isEmpty) return 'Inserisci API Key';
    if (!isValidApiKey(value)) {
      return 'Formato non valido. Esempio: miachat_prod_123e4567-h89i-12j3-k456-l789m012n345';
    }
    return null;
  }
}