import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'translations_extra.dart';
import 'somali_material.dart';
import 'medicine_strings.dart';
import 'auth_strings.dart';

class AppStrings {
  final String language;
  const AppStrings(this.language);
  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context).languageCode);
  String call(String text) =>
      translations[text]?[language] ??
      extraTranslations[text]?[language] ??
      medicineTranslations[text]?[language] ??
      authTranslations[text]?[language] ??
      text;
  static const supported = [Locale('en'), Locale('so'), Locale('ar')];
  static const delegates = <LocalizationsDelegate<dynamic>>[
    SomaliMaterialDelegate(),
    SomaliCupertinoDelegate(),
    SomaliWidgetsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
  static const translations = <String, Map<String, String>>{
    'Home': {'so': 'Hoyga', 'ar': 'الرئيسية'},
    'Schedule': {'so': 'Jadwalka', 'ar': 'الجدول'},
    'History': {'so': 'Taariikhda', 'ar': 'السجل'},
    'Profile': {'so': 'Akoonka', 'ar': 'الملف الشخصي'},
    'Good morning!': {'so': 'Subax wanaagsan!', 'ar': 'صباح الخير!'},
    'Good afternoon!': {'so': 'Galab wanaagsan!', 'ar': 'مساء الخير!'},
    'Good evening!': {'so': 'Fiid wanaagsan!', 'ar': 'مساء الخير!'},
    'Your daily wellness': {
      'so': 'Caafimaadkaaga maalinlaha ah',
      'ar': 'عافيتك اليومية',
    },
    'doses taken today': {
      'so': 'qiyaasood ayaa maanta la qaatay',
      'ar': 'جرعات تم تناولها اليوم',
    },
    'A little care, every day.': {
      'so': 'Daryeel yar, maalin kasta.',
      'ar': 'قليل من العناية، كل يوم.',
    },
    'Up next': {'so': 'Ku xiga', 'ar': 'التالي'},
    'Mark as taken': {'so': 'U calaamadee la qaatay', 'ar': 'تم تناول الجرعة'},
    'Snooze': {'so': 'Dib u dhig', 'ar': 'تأجيل'},
    'Skip dose': {'so': 'Ka bood qiyaasta', 'ar': 'تخطي الجرعة'},
    "Today's schedule": {'so': 'Jadwalka maanta', 'ar': 'جدول اليوم'},
    'See all': {'so': 'Eeg dhammaan', 'ar': 'عرض الكل'},
    'Add medicine': {'so': 'Ku dar daawo', 'ar': 'إضافة دواء'},
    'Edit medicine': {'so': 'Wax ka beddel daawada', 'ar': 'تعديل الدواء'},
    'Medicines': {'so': 'Daawooyinka', 'ar': 'الأدوية'},
    'Weekly adherence': {
      'so': 'Joogtaynta toddobaadka',
      'ar': 'الالتزام الأسبوعي',
    },
    'No doses scheduled': {
      'so': 'Qiyaaso ma qorshaysna',
      'ar': 'لا توجد جرعات مجدولة',
    },
    'Add your first medicine': {
      'so': 'Ku dar daawadaada koowaad',
      'ar': 'أضف دواءك الأول',
    },
    'Your routine starts here': {
      'so': 'Jadwalkaagu halkan ayuu ka bilaabmaa',
      'ar': 'روتينك يبدأ هنا',
    },
    'Taken': {'so': 'La qaatay', 'ar': 'تم تناولها'},
    'Skipped': {'so': 'Laga booday', 'ar': 'تم تخطيها'},
    'Missed': {'so': 'La seegay', 'ar': 'فائتة'},
    'Upcoming': {'so': 'Soo socda', 'ar': 'قادمة'},
    'Due now': {'so': 'Hadda la gaaray', 'ar': 'حان الموعد'},
    'Snoozed': {'so': 'Dib loo dhigay', 'ar': 'مؤجلة'},
    'All': {'so': 'Dhammaan', 'ar': 'الكل'},
    'Day': {'so': 'Maalin', 'ar': 'يوم'},
    'Week': {'so': 'Toddobaad', 'ar': 'أسبوع'},
    'Month': {'so': 'Bil', 'ar': 'شهر'},
    'Today': {'so': 'Maanta', 'ar': 'اليوم'},
    'Personal information': {
      'so': 'Macluumaadka shakhsiga',
      'ar': 'المعلومات الشخصية',
    },
    'Your name': {'so': 'Magacaaga', 'ar': 'اسمك'},
    'Language': {'so': 'Luqadda', 'ar': 'اللغة'},
    'Dark mode': {'so': 'Muuqaal madow', 'ar': 'الوضع الداكن'},
    'Notifications': {'so': 'Ogeysiisyada', 'ar': 'الإشعارات'},
    'Alarm settings': {'so': 'Dejinta digniinta', 'ar': 'إعدادات التنبيه'},
    'Privacy': {'so': 'Asturnaanta', 'ar': 'الخصوصية'},
    'Backup and restore': {
      'so': 'Kaydi oo soo celi',
      'ar': 'النسخ الاحتياطي والاستعادة',
    },
    'Export data': {'so': 'Soo saar xogta', 'ar': 'تصدير البيانات'},
    'Help and about': {
      'so': 'Caawimaad iyo faahfaahin',
      'ar': 'المساعدة وحول التطبيق',
    },
    'Save': {'so': 'Kaydi', 'ar': 'حفظ'},
    'Cancel': {'so': 'Jooji', 'ar': 'إلغاء'},
    'Delete': {'so': 'Tirtir', 'ar': 'حذف'},
    'Archive': {'so': 'Kaydi taariikhda', 'ar': 'أرشفة'},
    'Pause': {'so': 'Hakad geli', 'ar': 'إيقاف مؤقت'},
    'Resume': {'so': 'Dib u bilow', 'ar': 'استئناف'},
    'Continue': {'so': 'Sii wad', 'ar': 'متابعة'},
    'Back': {'so': 'Dib u noqo', 'ar': 'رجوع'},
    'Get started': {'so': 'Bilow', 'ar': 'ابدأ'},
    'Continue as guest': {'so': 'Sii wad marti ahaan', 'ar': 'المتابعة كضيف'},
    'Sign in': {'so': 'Soo gal', 'ar': 'تسجيل الدخول'},
    'Create account': {'so': 'Samee akoon', 'ar': 'إنشاء حساب'},
    'Sign out': {'so': 'Ka bax', 'ar': 'تسجيل الخروج'},
    'Forgot password?': {
      'so': 'Ma illowday erayga sirta?',
      'ar': 'نسيت كلمة المرور؟',
    },
    'Email': {'so': 'Iimayl', 'ar': 'البريد الإلكتروني'},
    'Password': {'so': 'Erayga sirta', 'ar': 'كلمة المرور'},
    'Medicine name': {'so': 'Magaca daawada', 'ar': 'اسم الدواء'},
    'Dosage': {'so': 'Qiyaasta', 'ar': 'الجرعة'},
    'Type': {'so': 'Nooca', 'ar': 'النوع'},
    'Instructions': {'so': 'Tilmaamaha', 'ar': 'التعليمات'},
    'Start date': {'so': 'Taariikhda bilowga', 'ar': 'تاريخ البدء'},
    'End date': {'so': 'Taariikhda dhammaadka', 'ar': 'تاريخ الانتهاء'},
    'No end date': {'so': 'Taariikh dhammaad ma leh', 'ar': 'بلا تاريخ انتهاء'},
    'Reminder times': {'so': 'Waqtiyada xusuusinta', 'ar': 'أوقات التذكير'},
    'Add time': {'so': 'Ku dar waqti', 'ar': 'إضافة وقت'},
    'Enable reminders': {'so': 'Daar xusuusinta', 'ar': 'تفعيل التذكيرات'},
    'Review': {'so': 'Dib u eeg', 'ar': 'مراجعة'},
    'Search medicines': {'so': 'Raadi daawooyin', 'ar': 'البحث عن الأدوية'},
    'Test reminder': {'so': 'Tijaabi xusuusinta', 'ar': 'اختبار التذكير'},
    'Reminders may not appear': {
      'so': 'Xusuusintu ma muuqan karto',
      'ar': 'قد لا تظهر التذكيرات',
    },
    'Open settings': {'so': 'Fur dejinta', 'ar': 'فتح الإعدادات'},
    'Medicine reminder': {'so': 'Xusuusin daawo', 'ar': 'تذكير الدواء'},
    'Saved on this device': {
      'so': 'Waxaa lagu kaydiyay qalabkan',
      'ar': 'محفوظ على هذا الجهاز',
    },
  };
}

String tr(BuildContext context, String text) => AppStrings.of(context)(text);

// Framework pickers fall back to English; application labels are translated.
class SomaliMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const SomaliMaterialDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const SomaliMaterialLocalizations());
  @override
  bool shouldReload(SomaliMaterialDelegate old) => false;
}

class SomaliCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const SomaliCupertinoDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());
  @override
  bool shouldReload(SomaliCupertinoDelegate old) => false;
}

class SomaliWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const SomaliWidgetsDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultWidgetsLocalizations());
  @override
  bool shouldReload(SomaliWidgetsDelegate old) => false;
}

/// Locale-aware application copy. Keep user-entered medical content in Text.
class LocalizedText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final String? semanticsLabel;
  final int? maxLines;
  final TextOverflow? overflow;
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.semanticsLabel,
    this.maxLines,
    this.overflow,
  });
  @override
  Widget build(BuildContext context) => Text(
    tr(context, data),
    style: style,
    textAlign: textAlign,
    semanticsLabel: semanticsLabel == null
        ? null
        : tr(context, semanticsLabel!),
    maxLines: maxLines,
    overflow: overflow,
  );
}

const messageTemplates = <String, Map<String, String>>{
  'repeatCount': {
    'en': '{count} additional reminders',
    'so': '{count} xusuusin oo dheeraad ah',
    'ar': '{count} تذكيرات إضافية',
  },
  'earlyDose': {
    'en':
        'This dose is scheduled for {time}. Record that you have already taken it?',
    'so':
        'Qiyaastan waxaa loo qorsheeyay {time}. Ma diiwaangelinaysaa inaad hore u qaadatay?',
    'ar': 'هذه الجرعة مجدولة في {time}. هل تريد تسجيل أنك تناولتها بالفعل؟',
  },
  'deleteMedicine': {
    'en':
        'Delete {name} and cancel its reminders? Existing dose history will be retained.',
    'so':
        'Ma tirtiraysaa {name} oo ma joojinaysaa xusuusinteeda? Taariikhda qiyaasaha waa la hayn doonaa.',
    'ar':
        'هل تريد حذف {name} وإلغاء تذكيراته؟ سيتم الاحتفاظ بسجل الجرعات السابق.',
  },
};
String trf(BuildContext context, String key, Map<String, String> values) {
  var result =
      messageTemplates[key]![Localizations.localeOf(context).languageCode] ??
      messageTemplates[key]!['en']!;
  for (final entry in values.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}
