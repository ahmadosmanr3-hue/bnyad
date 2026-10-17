import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localized_numbers.dart';

/// Flutter's bundled delegates do not include Central Kurdish. Keep this small,
/// app-owned delegate explicit instead of silently resolving Sorani to English.
/// Gregorian dates and Western display digits are intentional; input accepts all three digit scripts.
const bnyadLocales = [Locale('en'), Locale('ar'), Locale('ckb'), Locale('ku')];
Locale bnyadLocale(String language) =>
    Locale(language == 'ku' ? 'ckb' : language);
const bnyadDelegates = <LocalizationsDelegate<dynamic>>[
  SoraniMaterialDelegate(),
  SoraniCupertinoDelegate(),
  SoraniWidgetsDelegate(),
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
bool _sorani(Locale locale) => ['ckb', 'ku'].contains(locale.languageCode);

class SoraniDates {
  static const months = [
    'کانوونی دووەم',
    'شوبات',
    'ئازار',
    'نیسان',
    'ئایار',
    'حوزەیران',
    'تەممووز',
    'ئاب',
    'ئەیلوول',
    'تشرینی یەکەم',
    'تشرینی دووەم',
    'کانوونی یەکەم',
  ];
  static const weekdays = [
    'دووشەممە',
    'سێشەممە',
    'چوارشەممە',
    'پێنجشەممە',
    'هەینی',
    'شەممە',
    'یەکشەممە',
  ];
  static String date(DateTime date) =>
      '${date.day} ${months[date.month - 1]} ${date.year}';
}

class SoraniMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SoraniMaterialDelegate();
  @override
  bool isSupported(Locale locale) => _sorani(locale);
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const SoraniMaterialLocalizations());
  @override
  bool shouldReload(SoraniMaterialDelegate old) => false;
}

class SoraniWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const SoraniWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => _sorani(locale);
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const SoraniWidgetsLocalizations());
  @override
  bool shouldReload(SoraniWidgetsDelegate old) => false;
}

class SoraniWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const SoraniWidgetsLocalizations();
  static const _material = SoraniMaterialLocalizations();
  @override String get reorderItemUp => _material.reorderItemUp;
  @override String get reorderItemDown => _material.reorderItemDown;
  @override String get reorderItemLeft => _material.reorderItemLeft;
  @override String get reorderItemRight => _material.reorderItemRight;
  @override String get reorderItemToEnd => _material.reorderItemToEnd;
  @override String get reorderItemToStart => _material.reorderItemToStart;
  @override String get searchResultsFound => 'ئەنجامی گەڕان دۆزرایەوە';
  @override String get noResultsFound => 'هیچ ئەنجامێک نەدۆزرایەوە';
  @override String get radioButtonUnselectedLabel => 'هەڵنەبژێردراو';
  @override String get copyButtonLabel => _material.copyButtonLabel;
  @override String get cutButtonLabel => _material.cutButtonLabel;
  @override String get pasteButtonLabel => _material.pasteButtonLabel;
  @override String get selectAllButtonLabel => _material.selectAllButtonLabel;
  @override String get lookUpButtonLabel => _material.lookUpButtonLabel;
  @override String get searchWebButtonLabel => _material.searchWebButtonLabel;
  @override String get shareButtonLabel => _material.shareButtonLabel;
  @override
  TextDirection get textDirection => TextDirection.rtl;
}

class SoraniMaterialLocalizations extends DefaultMaterialLocalizations {
  const SoraniMaterialLocalizations();
  @override
  String get dateHelpText => 'ڕۆژ/مانگ/ساڵ';
  @override
  String get selectYearSemanticsLabel => 'ساڵ هەڵبژێرە';
  @override
  String get unspecifiedDate => 'بەروار';
  @override
  String get unspecifiedDateRange => 'ماوەی بەروار';
  @override
  String get dateInputLabel => 'بەروار بنووسە';
  @override
  String get dateRangeStartLabel => 'بەرواری دەستپێک';
  @override
  String get dateRangeEndLabel => 'بەرواری کۆتایی';
  @override
  String get invalidDateFormatLabel => 'شێوازی بەروار دروست نییە.';
  @override
  String get invalidDateRangeLabel => 'ماوەی بەروار دروست نییە.';
  @override
  String get dateOutOfRangeLabel => 'بەروار لە دەرەوەی سنوورە.';
  @override
  String get saveButtonLabel => 'پاشەکەوتکردن';
  @override
  String get datePickerHelpText => 'بەروار هەڵبژێرە';
  @override
  String get dateRangePickerHelpText => 'ماوە هەڵبژێرە';
  @override
  String get calendarModeButtonLabel => 'گۆڕین بۆ ڕۆژژمێر';
  @override
  String get inputDateModeButtonLabel => 'نووسینی بەروار';
  @override
  String get timePickerDialHelpText => 'کات هەڵبژێرە';
  @override
  String get timePickerInputHelpText => 'کات بنووسە';
  @override
  String get timePickerHourLabel => 'کاتژمێر';
  @override
  String get timePickerMinuteLabel => 'خولەک';
  @override
  String get invalidTimeLabel => 'کاتێکی دروست بنووسە';
  @override
  String get dialModeButtonLabel => 'گۆڕین بۆ کاتژمێر';
  @override
  String get inputTimeModeButtonLabel => 'نووسینی کات';
  @override
  String get openAppDrawerTooltip => 'کردنەوەی لیستی ڕێنیشاندەر';
  @override
  String get backButtonTooltip => 'گەڕانەوە';
  @override
  String get clearButtonTooltip => 'سڕینەوەی دەق';
  @override
  String get closeButtonTooltip => 'داخستن';
  @override
  String get deleteButtonTooltip => 'سڕینەوە';
  @override
  String get moreButtonTooltip => 'زیاتر';
  @override
  String get nextMonthTooltip => 'مانگی داهاتوو';
  @override
  String get previousMonthTooltip => 'مانگی پێشوو';
  @override
  String get nextPageTooltip => 'لاپەڕەی داهاتوو';
  @override
  String get previousPageTooltip => 'لاپەڕەی پێشوو';
  @override
  String get firstPageTooltip => 'لاپەڕەی یەکەم';
  @override
  String get lastPageTooltip => 'لاپەڕەی کۆتایی';
  @override
  String get showMenuTooltip => 'پیشاندانی لیست';
  @override
  String get drawerLabel => 'لیستی ڕێنیشاندەر';
  @override
  String get menuBarMenuLabel => 'لیستی سەرەکی';
  @override
  String get popupMenuLabel => 'لیستی هەڵبژاردەکان';
  @override
  String get dialogLabel => 'پەنجەرە';
  @override
  String get alertDialogLabel => 'ئاگاداری';
  @override
  String get searchFieldLabel => 'گەڕان';
  @override
  String get currentDateLabel => 'ئەمڕۆ';
  @override
  String get selectedDateLabel => 'هەڵبژێردراو';
  @override
  String get scrimLabel => 'پەردە';
  @override
  String get bottomSheetLabel => 'پەنجەرەی خوارەوە';
  @override
  String get licensesPageTitle => 'مۆڵەتنامەکان';
  @override
  String get rowsPerPageTitle => 'ڕیز لە هەر لاپەڕەیەک:';
  @override
  String get cancelButtonLabel => 'هەڵوەشاندنەوە';
  @override
  String get closeButtonLabel => 'داخستن';
  @override
  String get continueButtonLabel => 'بەردەوامبوون';
  @override
  String get copyButtonLabel => 'لەبەرگرتنەوە';
  @override
  String get cutButtonLabel => 'بڕین';
  @override
  String get scanTextButtonLabel => 'خوێندنەوەی دەق';
  @override
  String get okButtonLabel => 'باشە';
  @override
  String get pasteButtonLabel => 'لکاندن';
  @override
  String get selectAllButtonLabel => 'هەڵبژاردنی هەموو';
  @override
  String get lookUpButtonLabel => 'گەڕان بەدوادا';
  @override
  String get searchWebButtonLabel => 'گەڕان لە وێب';
  @override
  String get shareButtonLabel => 'هاوبەشکردن';
  @override
  String get viewLicensesButtonLabel => 'بینینی مۆڵەتنامەکان';
  @override
  String get anteMeridiemAbbreviation => 'پ.ن';
  @override
  String get postMeridiemAbbreviation => 'د.ن';
  @override
  String get timePickerHourModeAnnouncement => 'کاتژمێر هەڵبژێرە';
  @override
  String get timePickerMinuteModeAnnouncement => 'خولەک هەڵبژێرە';
  @override
  String get modalBarrierDismissLabel => 'داخستن';
  @override
  String get menuDismissLabel => 'داخستنی لیست';
  @override
  String get signedInLabel => 'چوویتە ژوورەوە';
  @override
  String get hideAccountsLabel => 'شاردنەوەی هەژمارەکان';
  @override
  String get showAccountsLabel => 'پیشاندانی هەژمارەکان';
  @override
  String get reorderItemUp => 'گواستنەوە بۆ سەرەوە';
  @override
  String get reorderItemDown => 'گواستنەوە بۆ خوارەوە';
  @override
  String get reorderItemLeft => 'گواستنەوە بۆ چەپ';
  @override
  String get reorderItemRight => 'گواستنەوە بۆ ڕاست';
  @override
  String get reorderItemToEnd => 'گواستنەوە بۆ کۆتایی';
  @override
  String get reorderItemToStart => 'گواستنەوە بۆ دەستپێک';
  @override
  String get expandedIconTapHint => 'داخستن';
  @override
  String get collapsedIconTapHint => 'کردنەوە';
  @override
  String get expansionTileExpandedHint => 'دوو جار دابگرە بۆ داخستن';
  @override
  String get expansionTileCollapsedHint => 'دوو جار دابگرە بۆ کردنەوە';
  @override
  String get expansionTileExpandedTapHint => 'داخستن';
  @override
  String get expansionTileCollapsedTapHint => 'کردنەوە بۆ وردەکاریی زیاتر';
  @override
  String get expandedHint => 'داخراو';
  @override
  String get collapsedHint => 'کراوە';
  @override
  String get refreshIndicatorSemanticLabel => 'نوێکردنەوە';
  @override
  String formatMediumDate(DateTime date) =>
      '${SoraniDates.weekdays[date.weekday - 1]}، ${date.day} ${SoraniDates.months[date.month - 1]}';
  @override
  String formatFullDate(DateTime date) =>
      '${SoraniDates.weekdays[date.weekday - 1]}، ${SoraniDates.date(date)}';
  @override
  String formatShortDate(DateTime date) => SoraniDates.date(date);
  @override
  String formatShortMonthDay(DateTime date) =>
      '${date.day} ${SoraniDates.months[date.month - 1]}';
  @override
  String formatMonthYear(DateTime date) =>
      '${SoraniDates.months[date.month - 1]} ${date.year}';
  @override
  String formatCompactDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  @override
  List<String> get narrowWeekdays => const ['ی', 'د', 'س', 'چ', 'پ', 'ه', 'ش'];
  @override
  DateTime? parseCompactDate(String? inputString) {
    final parts = normalizeDigits(inputString ?? '').split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]),
        month = int.tryParse(parts[1]),
        year = int.tryParse(parts[2]);
    if (day == null ||
        month == null ||
        year == null ||
        year < 1 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.month == month && date.day == day ? date : null;
  }

  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      'دەستپێک: $formattedDate';
  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      'کۆتایی: $formattedDate';
  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      'داخستنی $modalRouteContentName';
  @override
  String aboutListTileTitle(String applicationName) =>
      'دەربارەی $applicationName';
  @override
  String licensesPackageDetailText(int licenseCount) =>
      '$licenseCount مۆڵەتنامە';
  @override
  String pageRowsInfoTitle(
    int firstRow,
    int lastRow,
    int rowCount,
    bool rowCountIsApproximate,
  ) => '${ltrFragment('$firstRow–$lastRow')} لە $rowCount';
  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'بەشی $tabIndex لە $tabCount';
  @override
  String selectedRowCountTitle(int selectedRowCount) =>
      '$selectedRowCount ڕیز هەڵبژێردراوە';
  @override
  String remainingTextFieldCharacterCount(int remaining) =>
      '$remaining پیت ماوە';
}

class SoraniCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SoraniCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => _sorani(locale);
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const SoraniCupertinoLocalizations());
  @override
  bool shouldReload(SoraniCupertinoDelegate old) => false;
}

class SoraniCupertinoLocalizations extends DefaultCupertinoLocalizations {
  @override
  DatePickerDateOrder get datePickerDateOrder => DatePickerDateOrder.dmy;
  const SoraniCupertinoLocalizations();
  @override
  String datePickerMonth(int monthIndex) => SoraniDates.months[monthIndex - 1];
  @override
  String datePickerStandaloneMonth(int monthIndex) =>
      datePickerMonth(monthIndex);
  @override
  String datePickerDayOfMonth(int dayIndex, [int? weekDay]) => '$dayIndex';
  @override
  String datePickerMediumDate(DateTime date) => SoraniDates.date(date);
  @override
  String datePickerHourSemanticsLabel(int hour) => '$hour کاتژمێر';
  @override
  String datePickerMinuteSemanticsLabel(int minute) => '$minute خولەک';
  @override
  String timerPickerHourLabel(int hour) => 'کاتژمێر';
  @override
  String timerPickerMinuteLabel(int minute) => 'خولەک';
  @override
  String timerPickerSecondLabel(int second) => 'چرکە';
  @override
  String tabSemanticsLabel({required int tabIndex, required int tabCount}) =>
      'بەشی $tabIndex لە $tabCount';
  @override
  String get anteMeridiemAbbreviation => 'پ.ن';
  @override
  String get postMeridiemAbbreviation => 'د.ن';
  @override
  String get todayLabel => 'ئەمڕۆ';
  @override
  String get alertDialogLabel => 'ئاگاداری';
  @override
  String get clearButtonLabel => 'سڕینەوەی دەق';
  @override
  String get noSpellCheckReplacementsLabel => 'هیچ جێگرەوەیەک نەدۆزرایەوە';
  @override
  String get searchTextFieldPlaceholderLabel => 'گەڕان';
  @override
  String get backButtonLabel => 'گەڕانەوە';
  @override
  String get cutButtonLabel => 'بڕین';
  @override
  String get copyButtonLabel => 'لەبەرگرتنەوە';
  @override
  String get pasteButtonLabel => 'لکاندن';
  @override
  String get selectAllButtonLabel => 'هەڵبژاردنی هەموو';
  @override
  String get lookUpButtonLabel => 'گەڕان بەدوادا';
  @override
  String get searchWebButtonLabel => 'گەڕان لە وێب';
  @override
  String get shareButtonLabel => 'هاوبەشکردن';
  @override
  String get modalBarrierDismissLabel => 'داخستن';
  @override
  String get menuDismissLabel => 'داخستنی لیست';
  @override
  String get cancelButtonLabel => 'هەڵوەشاندنەوە';
  @override
  String get expansionTileExpandedHint => 'دوو جار دابگرە بۆ داخستن';
  @override
  String get expansionTileCollapsedHint => 'دوو جار دابگرە بۆ کردنەوە';
  @override
  String get expansionTileExpandedTapHint => 'داخستن';
  @override
  String get expansionTileCollapsedTapHint => 'کردنەوە بۆ وردەکاریی زیاتر';
  @override
  String get expandedHint => 'داخراو';
  @override
  String get collapsedHint => 'کراوە';
}
