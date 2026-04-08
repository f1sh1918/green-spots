String convertDateString(String dateString) {
  if (dateString.length != 8) {
    throw ArgumentError('Datum muss 8 Zeichen haben (YYYYMMDD)');
  }

  String isoString =
      '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}';
  DateTime date = DateTime.parse(isoString);

  String day = date.day.toString().padLeft(2, '0');
  String month = date.month.toString().padLeft(2, '0');
  String year = date.year.toString();

  return '$day.$month.$year';
}

DateTime parseDateString(String dateString) {
  final year = dateString.substring(0, 4);
  final month = dateString.substring(4, 6);
  final day = dateString.substring(6, 8);

  return DateTime.parse('$year-$month-$day');
}
