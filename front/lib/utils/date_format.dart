class DateFormatter {
  static String format(DateTime dateTime, String pattern) {
    String day = dateTime.day.toString().padLeft(2, '0');
    String month = dateTime.month.toString().padLeft(2, '0');
    String year = dateTime.year.toString();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String second = dateTime.second.toString().padLeft(2, '0');
    
    // Substitui os padrões pelo formato
    String result = pattern
      .replaceAll('dd', day)
      .replaceAll('MM', month)
      .replaceAll('yyyy', year)
      .replaceAll('HH', hour)
      .replaceAll('mm', minute)
      .replaceAll('ss', second);
      
    return result;
  }
}