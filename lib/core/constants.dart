class Constants {
  static const String apiBaseUrl = String.fromEnvironment(
    'EATZY_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
}
