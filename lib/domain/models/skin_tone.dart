enum SkinTone {
  fair('Fair', 0xF1C9A8),
  peach('Peach', 0xFAB073),
  honey('Honey', 0xDCA06D),
  deep('Deep bronze', 0x9B6142),
  deepest('Deep umber', 0x844934);

  const SkinTone(this.label, this.rgb);
  final String label;
  final int rgb;

  static SkinTone fromPreference(String? value) =>
      values.where((tone) => tone.name == value).firstOrNull ?? peach;
}
