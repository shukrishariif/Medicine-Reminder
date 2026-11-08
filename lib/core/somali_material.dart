import 'package:flutter/material.dart';

const somaliMonths = [
  'Jannaayo',
  'Febraayo',
  'Maarso',
  'Abriil',
  'Maajo',
  'Juun',
  'Luulyo',
  'Agoosto',
  'Sebtembar',
  'Oktoobar',
  'Nofeembar',
  'Diseembar',
];
const somaliWeekdays = [
  'Isniin',
  'Talaado',
  'Arbaco',
  'Khamiis',
  'Jimco',
  'Sabti',
  'Axad',
];
String formatSomaliDate(DateTime date, String pattern) =>
    pattern.replaceAllMapped(
      RegExp(r'EEEE|EEE|EE|MMMM|MMM|yyyy|MM|dd|d'),
      (m) => switch (m[0]) {
        'EEEE' => somaliWeekdays[date.weekday - 1],
        'EEE' || 'EE' => somaliWeekdays[date.weekday - 1].substring(0, 3),
        'MMMM' => somaliMonths[date.month - 1],
        'MMM' => somaliMonths[date.month - 1].substring(0, 3),
        'yyyy' => '${date.year}',
        'MM' => '${date.month}'.padLeft(2, '0'),
        'dd' => '${date.day}'.padLeft(2, '0'),
        _ => '${date.day}',
      },
    );

/// Somali Material copy and date formatting for the controls used by Daryeel.
class SomaliMaterialLocalizations extends DefaultMaterialLocalizations {
  const SomaliMaterialLocalizations();
  @override
  String get cancelButtonLabel => 'Jooji';
  @override
  String get closeButtonLabel => 'Xir';
  @override
  String get continueButtonLabel => 'Sii wad';
  @override
  String get okButtonLabel => 'Hagaag';
  @override
  String get saveButtonLabel => 'Kaydi';
  @override
  String get copyButtonLabel => 'Nuqul';
  @override
  String get cutButtonLabel => 'Jar';
  @override
  String get pasteButtonLabel => 'Ku dheji';
  @override
  String get selectAllButtonLabel => 'Dooro dhammaan';
  @override
  String get shareButtonLabel => 'La wadaag';
  @override
  String get lookUpButtonLabel => 'Raadi';
  @override
  String get searchWebButtonLabel => 'Ka raadi internetka';
  @override
  String get scanTextButtonLabel => 'Sawir qoraalka';
  @override
  String get datePickerHelpText => 'Dooro taariikh';
  @override
  String get dateRangePickerHelpText => 'Dooro muddada';
  @override
  String get dateInputLabel => 'Geli taariikh';
  @override
  String get dateRangeStartLabel => 'Taariikhda bilowga';
  @override
  String get dateRangeEndLabel => 'Taariikhda dhammaadka';
  @override
  String get dateHelpText => 'mm/dd/yyyy';
  @override
  String get invalidDateFormatLabel => 'Qaabka taariikhdu ma saxna.';
  @override
  String get invalidDateRangeLabel => 'Muddadu ma saxna.';
  @override
  String get dateOutOfRangeLabel => 'Taariikhdu waxay ka baxsan tahay muddada.';
  @override
  String get calendarModeButtonLabel => 'U beddel jadwalka';
  @override
  String get inputDateModeButtonLabel => 'Geli taariikhda qoraal ahaan';
  @override
  String get selectYearSemanticsLabel => 'Dooro sannadka';
  @override
  String get unspecifiedDate => 'Taariikh';
  @override
  String get unspecifiedDateRange => 'Muddada taariikhda';
  @override
  String get currentDateLabel => 'Maanta';
  @override
  String get selectedDateLabel => 'La doortay';
  @override
  String get nextMonthTooltip => 'Bisha xigta';
  @override
  String get previousMonthTooltip => 'Bishii hore';
  @override
  String get nextPageTooltip => 'Bogga xiga';
  @override
  String get previousPageTooltip => 'Boggii hore';
  @override
  String get firstPageTooltip => 'Bogga koowaad';
  @override
  String get lastPageTooltip => 'Bogga ugu dambeeya';
  @override
  String get timePickerDialHelpText => 'Dooro waqti';
  @override
  String get timePickerInputHelpText => 'Geli waqti';
  @override
  String get timePickerHourLabel => 'Saacad';
  @override
  String get timePickerMinuteLabel => 'Daqiiqo';
  @override
  String get invalidTimeLabel => 'Geli waqti sax ah';
  @override
  String get dialModeButtonLabel => 'U beddel saacadda';
  @override
  String get inputTimeModeButtonLabel => 'Geli waqtiga qoraal ahaan';
  @override
  String get timePickerHourModeAnnouncement => 'Dooro saacadaha';
  @override
  String get timePickerMinuteModeAnnouncement => 'Dooro daqiiqadaha';
  @override
  String get anteMeridiemAbbreviation => 'GH';
  @override
  String get postMeridiemAbbreviation => 'GD';
  @override
  String get backButtonTooltip => 'Dib u noqo';
  @override
  String get closeButtonTooltip => 'Xir';
  @override
  String get deleteButtonTooltip => 'Tirtir';
  @override
  String get clearButtonTooltip => 'Tirtir qoraalka';
  @override
  String get moreButtonTooltip => 'Dheeraad';
  @override
  String get openAppDrawerTooltip => 'Fur liiska';
  @override
  String get showMenuTooltip => 'Muuji liiska';
  @override
  String get drawerLabel => 'Liiska hagidda';
  @override
  String get popupMenuLabel => 'Liiska soo baxa';
  @override
  String get dialogLabel => 'Wadahadal';
  @override
  String get alertDialogLabel => 'Digniin';
  @override
  String get searchFieldLabel => 'Raadi';
  @override
  String get modalBarrierDismissLabel => 'Xir';
  @override
  String get menuDismissLabel => 'Xir liiska';
  @override
  String get bottomSheetLabel => 'Faahfaahin';
  @override
  String get licensesPageTitle => 'Ruqsadaha';
  @override
  String get viewLicensesButtonLabel => 'Eeg ruqsadaha';
  @override
  String get refreshIndicatorSemanticLabel => 'Cusboonaysii';
  @override
  String aboutListTileTitle(String applicationName) =>
      'Ku saabsan $applicationName';
  @override
  String licensesPackageDetailText(int licenseCount) =>
      '$licenseCount ruqsadood';
  @override
  String remainingTextFieldCharacterCount(int remaining) => remaining < 0
      ? '${-remaining} xaraf ayaa xadka dhaafay'
      : '$remaining xaraf ayaa haray';
  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'Qaybta $tabIndex ee $tabCount';
  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      'Taariikhda bilowga $formattedDate';
  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      'Taariikhda dhammaadka $formattedDate';
  @override
  String scrimOnTapHint(String modalRouteContentName) =>
      'Xir $modalRouteContentName';
  @override
  List<String> get narrowWeekdays => const [
    'Ax',
    'Is',
    'Ta',
    'Ar',
    'Kh',
    'Ji',
    'Sa',
  ];
  @override
  String formatShortDate(DateTime date) => formatSomaliDate(date, 'd MMM yyyy');
  @override
  String formatMediumDate(DateTime date) =>
      formatSomaliDate(date, 'EEE, d MMM');
  @override
  String formatFullDate(DateTime date) =>
      formatSomaliDate(date, 'EEEE, d MMMM yyyy');
  @override
  String formatMonthYear(DateTime date) => formatSomaliDate(date, 'MMMM yyyy');
  @override
  String formatShortMonthDay(DateTime date) => formatSomaliDate(date, 'd MMM');
}
