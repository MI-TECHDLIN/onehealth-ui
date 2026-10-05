/// Meteorological season (Northern-hemisphere convention), used only to
/// decide whether two checks were far enough apart to count as a genuine
/// seasonal gap -- never shown to the citizen as a label.
enum Season { winter, spring, summer, autumn }

Season seasonOf(DateTime date) {
  final month = date.toUtc().month;
  if (month == 12 || month <= 2) return Season.winter;
  if (month <= 5) return Season.spring;
  if (month <= 8) return Season.summer;
  return Season.autumn;
}
