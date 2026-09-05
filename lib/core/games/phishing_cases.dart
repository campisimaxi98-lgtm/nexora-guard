/// Catálogo de casos de Phishing Detector — Dart puro, sin Flutter.
///
/// La VERDAD de cada caso (fraude o legítimo) vive aquí, no en la UI ni en
/// el texto traducido: el texto cambia por idioma, el veredicto jamás.
/// `isFraud == true` es fraude; los textos por idioma están en `strings.dart`.
library;

class PhishingCase {
  const PhishingCase(this.id, this.isFraud);

  final int id;
  final bool isFraud;
}

const List<PhishingCase> phishingCases = [
  PhishingCase(1, true),
  PhishingCase(2, false),
  PhishingCase(3, true),
  PhishingCase(4, true),
  PhishingCase(5, false),
  PhishingCase(6, true),
];

int phishingTotal() => phishingCases.length;

int phishingFrauds() => phishingCases.where((c) => c.isFraud).length;

bool phishingIsFraud(int id) =>
    phishingCases.firstWhere((c) => c.id == id).isFraud;