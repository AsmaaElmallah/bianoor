/// الفئة العمرية في المكتبة — `dbValue` هي نفس عمود `age_band` في Supabase.
enum LibraryAgeBand {
  m0to3('m0_3', '0–3 شهور'),
  m3to6('m3_6', '3–6 شهور'),
  m6to12('m6_12', '6–12 شهر'),
  m12to18('m12_18', '12–18 شهر'),
  m18to24('m18_24', '18–24 شهر');

  const LibraryAgeBand(this.dbValue, this.label);
  final String dbValue;
  final String label;

  static LibraryAgeBand fromDb(String? value) {
    for (final b in values) {
      if (b.dbValue == value) return b;
    }
    return m0to3;
  }
}
