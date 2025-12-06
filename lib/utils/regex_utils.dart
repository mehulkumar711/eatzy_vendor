String normalize(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s\u0900-\u097F\u0A80-\u0AFF]'), ' ')
    .trim();

// keywords across languages
final acceptKeywords = [
  'accept',
  'ok',
  'yes',
  'ready',
  'tayyar',
  'thik',
  'theek',
  'haan',
  'svikar',
  'स्वीकार',
  'સ્વીકૃત',
];
final rejectKeywords = [
  'reject',
  'cancel',
  'no',
  'nahi',
  'nathi',
  'rad',
  'रद्द',
  'રદ',
];
final readyKeywords = [
  'ready',
  'order ready',
  'tayyar',
  'tayyar chhe',
  'तैयार',
  'તૈયાર',
];
final repeatKeywords = [
  'repeat',
  'dobara',
  'fari',
  'dobara bolo',
  'फिर से',
  'ફરીથી',
];
final moreTimeKeywords = [
  'more time',
  '5 minutes',
  'delay',
  'thodu time',
  'thoda time',
  'थोड़ा समय',
  'થોડું समय',
];
final paidKeywords = [
  'paid',
  'cash received',
  'cash',
  'payment received',
  'paid',
  'भुगतान मिला',
  'પૌરે ચૂકવ્યો',
];

bool matchesAccept(
  String recognized, {
  String? orderNumber,
  List<String>? items,
}) {
  final r = normalize(recognized);
  if (orderNumber != null && r.contains(orderNumber.toLowerCase())) {
    return acceptKeywords.any((k) => r.contains(k));
  }
  if (items != null) {
    for (var it in items) {
      final n = normalize(it);
      if (r.contains(n) && acceptKeywords.any((k) => r.contains(k)))
        return true;
    }
  }
  return acceptKeywords.any((k) => r.contains(k));
}
