import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations was not found in context.');
    return localizations!;
  }

  bool get isArabic => locale.languageCode == 'ar';
  String get localeName => isArabic ? 'ar' : 'en';

  String t(String key) => (isArabic ? _ar : _en)[key] ?? _en[key] ?? key;

  String translateKnown(String value) {
    if (!isArabic) return value;
    final text = value.trim();
    if (text.isEmpty) return value;

    final exact = _knownAr[text];
    if (exact != null) return exact;

    final dynamic = _translateDynamic(text);
    if (dynamic != null) return dynamic;

    var translated = text;
    var matched = false;
    final entries = _knownAr.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));
    for (final entry in entries) {
      if (translated.contains(entry.key)) {
        translated = translated.replaceAll(entry.key, entry.value);
        matched = true;
      }
    }
    return matched ? translated : value;
  }

  String formatMonthDay(DateTime date) {
    return DateFormat.MMMMd(localeName).format(date);
  }

  String formatShortDateTime(DateTime date) {
    return DateFormat.yMMMd(localeName).add_jm().format(date);
  }

  String formatFullDateTime(DateTime date) {
    return DateFormat.yMMMMd(localeName).add_jm().format(date);
  }

  String scansCount(int count) => isArabic ? '$count فحوصات' : '$count Scans';

  String recordedOn(DateTime date) {
    final formatted = formatFullDateTime(date);
    return isArabic ? 'سُجل في $formatted' : 'Recorded on $formatted';
  }

  String aiConfidence(double confidence) {
    final percent = confidence.toStringAsFixed(1);
    return isArabic ? 'ثقة الذكاء الاصطناعي: $percent%' : 'AI Confidence: $percent%';
  }

  String _stageLabel(int stage) {
    if (!isArabic) return 'Stage $stage';
    return stage == 1 ? 'المرحلة الأولى' : 'المرحلة الثانية';
  }

  String get stage1 => _stageLabel(1);
  String get stage2 => _stageLabel(2);

  String? _translateDynamic(String text) {
    const prefix =
        'The on-device two-stage AI screening pipeline found acoustic indicators most consistent with ';
    const suffix =
        '. This is not a clinical diagnosis and should be interpreted with professional guidance.';
    if (text.startsWith(prefix) && text.endsWith(suffix)) {
      final label = text.substring(prefix.length, text.length - suffix.length);
      return 'وجد مسار الفحص ثنائي المراحل داخل الجهاز مؤشرات صوتية أكثر اتساقًا مع ${translateKnown(label)}. هذه ليست تشخيصًا طبيًا ويجب تفسيرها بإرشاد مختص.';
    }

    if (text.startsWith('Unsupported WAV bit depth: ')) {
      final depth = text.substring('Unsupported WAV bit depth: '.length);
      return 'عمق بت ملف WAV غير مدعوم: $depth';
    }

    final stageMatch = RegExp(r'^(Stage [12]) ONNX (.+)$').firstMatch(text);
    if (stageMatch != null) {
      final stage = translateKnown(stageMatch.group(1)!);
      final rest = stageMatch.group(2)!;
      if (rest == 'inference could not be started on this device.') {
        return 'تعذر بدء استدلال ONNX في $stage على هذا الجهاز.';
      }
      if (rest ==
          'inference did not finish in time. Please retry with a clear 8 to 15 second WAV sample.') {
        return 'لم ينتهِ استدلال ONNX في $stage في الوقت المحدد. أعد المحاولة بعينة WAV واضحة مدتها من 8 إلى 15 ثانية.';
      }
      if (rest == 'model returned no output.') {
        return 'لم يُرجع نموذج ONNX في $stage أي مخرجات.';
      }
      if (rest == 'model output is invalid.') {
        return 'مخرجات نموذج ONNX في $stage غير صالحة.';
      }
      if (rest.startsWith('inference failed. Check that the model input shape is')) {
        return 'فشل استدلال ONNX في $stage. تحقق من شكل مدخلات النموذج ونوعها.';
      }
    }

    return null;
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

const _en = <String, String>{
  'appTitle': 'SpeechCare AI',
  'splashName': 'SpeechCare',
  'splashTagline': 'AI-Powered Speech Analysis',
  'createAccountTitle': 'Create Your\nAccount',
  'signInTitle': 'Hello\nSign in!',
  'fullName': 'Full Name',
  'fullNameHint': 'e.g. Abubakr Alquhfah',
  'validName': 'Enter a valid name',
  'emailAddress': 'Email Address',
  'emailHint': 'example@domain.com',
  'validEmail': 'Enter a valid email',
  'password': 'Password',
  'passwordHint': '********',
  'minimumPassword': 'Minimum 6 characters',
  'forgotPassword': 'Forgot Password?',
  'signUpAction': 'SIGN UP',
  'signInAction': 'SIGN IN',
  'alreadyHaveAccount': 'Already have an account? ',
  'dontHaveAccount': 'Don\'t have an account? ',
  'signIn': 'Sign In',
  'signUp': 'Sign Up',
  'goodMorning': 'Good Morning,',
  'defaultUser': 'Engineer',
  'mockAi': 'Mock AI',
  'liveSystem': 'Live System',
  'totalScans': 'Total Scans',
  'riskFlags': 'Risk Flags',
  'recentResult': 'Recent Result',
  'confidenceOverview': 'Confidence Overview',
  'firstScanData': 'Data will appear after your first scan',
  'record': 'Record',
  'history': 'History',
  'stats': 'Stats',
  'profile': 'Profile',
  'speechCheck': 'Speech Check',
  'readAloud': 'READ ALOUD',
  'screeningPrompt':
      '"Today I am recording this speech sample so the application can screen my voice clearly."',
  'tapToStart': 'Tap to Start',
  'uploadAudio': 'Upload Existing Audio',
  'quietRoom': 'Quiet Room',
  'distanceHint': '15cm Away',
  'durationHint': '8-15 Secs',
  'screeningHistory': 'Screening History',
  'noScreenings': 'No Screenings Yet',
  'noScreeningsMessage':
      'Your recorded speech checks and their detailed AI reports will appear here.',
  'profileSettings': 'Profile & Settings',
  'systemDetails': 'System Details',
  'localRecords': 'Local Records',
  'sqliteStorage': 'SQLite secure storage',
  'fastApiIntegration': 'FastAPI Integration',
  'backendRoute': '/predict backend route',
  'mocked': 'Mocked',
  'live': 'Live',
  'clearHistory': 'Clear History',
  'signOut': 'Sign Out',
  'preferences': 'Preferences',
  'language': 'Language',
  'languageSubtitle': 'Choose the interface language',
  'english': 'English',
  'arabic': 'Arabic',
  'yourProgress': 'Your Progress',
  'notEnoughData': 'Not Enough Data',
  'notEnoughDataMessage':
      'Run at least one speech check to unlock your AI confidence and risk patterns over time.',
  'avgConfidence': 'Avg Confidence',
  'confidenceTrend': 'Confidence Trend',
  'clinicalInsight': 'Clinical Insight',
  'clinicalInsightMessage':
      'Stable high-confidence results support routine monitoring. Repeated flags should be reviewed with a specialist.',
  'detailedReport': 'Detailed Report',
  'aiSummary': 'AI Summary',
  'recommendation': 'Recommendation',
  'technicalAnalysis': 'Technical Analysis',
  'disclaimer':
      'Early screening only. This app does not provide a medical diagnosis. Consult a speech-language specialist when risk is detected, confidence is low, or symptoms persist.',
};

const _ar = <String, String>{
  'appTitle': 'رعاية النطق بالذكاء الاصطناعي',
  'splashName': 'رعاية النطق',
  'splashTagline': 'تحليل الكلام بالذكاء الاصطناعي',
  'createAccountTitle': 'أنشئ\nحسابك',
  'signInTitle': 'مرحبًا\nسجّل الدخول',
  'fullName': 'الاسم الكامل',
  'fullNameHint': 'مثال: أبو بكر القحفة',
  'validName': 'أدخل اسمًا صحيحًا',
  'emailAddress': 'البريد الإلكتروني',
  'emailHint': 'example@domain.com',
  'validEmail': 'أدخل بريدًا إلكترونيًا صحيحًا',
  'password': 'كلمة المرور',
  'passwordHint': '********',
  'minimumPassword': 'الحد الأدنى 6 أحرف',
  'forgotPassword': 'هل نسيت كلمة المرور؟',
  'signUpAction': 'إنشاء حساب',
  'signInAction': 'تسجيل الدخول',
  'alreadyHaveAccount': 'لديك حساب بالفعل؟ ',
  'dontHaveAccount': 'ليس لديك حساب؟ ',
  'signIn': 'تسجيل الدخول',
  'signUp': 'إنشاء حساب',
  'goodMorning': 'صباح الخير،',
  'defaultUser': 'المستخدم',
  'mockAi': 'ذكاء تجريبي',
  'liveSystem': 'النظام مباشر',
  'totalScans': 'إجمالي الفحوصات',
  'riskFlags': 'مؤشرات الخطر',
  'recentResult': 'أحدث نتيجة',
  'confidenceOverview': 'نظرة على الثقة',
  'firstScanData': 'ستظهر البيانات بعد أول فحص',
  'record': 'تسجيل',
  'history': 'السجل',
  'stats': 'الإحصاءات',
  'profile': 'الملف',
  'speechCheck': 'فحص الكلام',
  'readAloud': 'اقرأ بصوت عالٍ',
  'screeningPrompt':
      '"أسجل اليوم عينة من كلامي حتى يتمكن التطبيق من فحص صوتي بوضوح."',
  'tapToStart': 'اضغط للبدء',
  'uploadAudio': 'رفع ملف صوتي',
  'quietRoom': 'مكان هادئ',
  'distanceHint': 'على بعد 15 سم',
  'durationHint': '8-15 ثانية',
  'screeningHistory': 'سجل الفحوصات',
  'noScreenings': 'لا توجد فحوصات بعد',
  'noScreeningsMessage':
      'ستظهر هنا فحوصات الكلام المسجلة وتقارير الذكاء الاصطناعي التفصيلية الخاصة بها.',
  'profileSettings': 'الملف الشخصي والإعدادات',
  'systemDetails': 'تفاصيل النظام',
  'localRecords': 'السجلات المحلية',
  'sqliteStorage': 'تخزين SQLite آمن',
  'fastApiIntegration': 'تكامل FastAPI',
  'backendRoute': 'مسار الخادم /predict',
  'mocked': 'تجريبي',
  'live': 'مباشر',
  'clearHistory': 'مسح السجل',
  'signOut': 'تسجيل الخروج',
  'preferences': 'التفضيلات',
  'language': 'اللغة',
  'languageSubtitle': 'اختر لغة واجهة التطبيق',
  'english': 'الإنجليزية',
  'arabic': 'العربية',
  'yourProgress': 'تقدمك',
  'notEnoughData': 'لا توجد بيانات كافية',
  'notEnoughDataMessage':
      'أجرِ فحصًا واحدًا على الأقل لإظهار ثقة الذكاء الاصطناعي وأنماط الخطر بمرور الوقت.',
  'avgConfidence': 'متوسط الثقة',
  'confidenceTrend': 'اتجاه الثقة',
  'clinicalInsight': 'ملاحظة إكلينيكية',
  'clinicalInsightMessage':
      'تدعم النتائج المستقرة عالية الثقة المتابعة الدورية. ينبغي مراجعة المؤشرات المتكررة مع مختص.',
  'detailedReport': 'التقرير التفصيلي',
  'aiSummary': 'ملخص الذكاء الاصطناعي',
  'recommendation': 'التوصية',
  'technicalAnalysis': 'التحليل التقني',
  'disclaimer':
      'هذا فحص مبكر فقط. لا يقدم التطبيق تشخيصًا طبيًا. استشر مختصًا في علاج النطق واللغة عند ظهور خطر، أو انخفاض الثقة، أو استمرار الأعراض.',
};

const _knownAr = <String, String>{
  'SpeechCare AI': 'رعاية النطق بالذكاء الاصطناعي',
  'SpeechCare': 'رعاية النطق',
  'AI-Powered Speech Analysis': 'تحليل الكلام بالذكاء الاصطناعي',
  'Uncertain sample': 'عينة غير مؤكدة',
  'Unsuitable sample': 'عينة غير مناسبة',
  'Normal Speech': 'كلام طبيعي',
  'Speech Disorder': 'اضطراب في الكلام',
  'Too short': 'قصيرة جدًا',
  'Dysarthria': 'عسر التلفظ',
  'Stuttering': 'التأتأة',
  'Needs specialist review': 'تحتاج إلى مراجعة مختص',
  'Audio quality screening': 'فحص جودة الصوت',
  'Speech disorder classification': 'تصنيف اضطراب الكلام',
  'Rejected: recording too short': 'مرفوضة: التسجيل قصير جدًا',
  'Rejected: audio quality check': 'مرفوضة: فحص جودة الصوت',
  'Classification skipped': 'تم تخطي التصنيف',
  'Audio quality accepted': 'تم قبول جودة الصوت',
  'Two-stage speech disorder screening completed':
      'اكتمل فحص اضطرابات الكلام على مرحلتين',
  'Normal Speech vs Speech Disorder': 'كلام طبيعي مقابل اضطراب في الكلام',
  'Skipped because Stage 1 predicted Normal Speech':
      'تم التخطي لأن المرحلة الأولى توقعت كلامًا طبيعيًا',
  'Speech Disorder detected': 'تم رصد اضطراب في الكلام',
  'Dysarthria vs Stuttering': 'عسر التلفظ مقابل التأتأة',
  'Stage 1': 'المرحلة الأولى',
  'Stage 2': 'المرحلة الثانية',
  'Please enter your name.': 'يرجى إدخال اسمك.',
  'Please enter a valid email address.':
      'يرجى إدخال بريد إلكتروني صحيح.',
  'An account with this email already exists.':
      'يوجد حساب بهذا البريد الإلكتروني بالفعل.',
  'Use at least 8 characters for the password.':
      'استخدم 8 أحرف على الأقل لكلمة المرور.',
  'Email or password is incorrect.':
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'Recording could not be started. Check microphone access and try again.':
      'تعذر بدء التسجيل. تحقق من صلاحية الميكروفون ثم حاول مرة أخرى.',
  'The recording could not be saved. Please try again.':
      'تعذر حفظ التسجيل. يرجى المحاولة مرة أخرى.',
  'No recording file was created.': 'لم يتم إنشاء ملف تسجيل.',
  'The selected audio file could not be opened.':
      'تعذر فتح ملف الصوت المحدد.',
  'Please sign in before running a screening.':
      'يرجى تسجيل الدخول قبل إجراء الفحص.',
  'Analysis did not finish. Please retry with a clear 8 to 15 second recording.':
      'لم يكتمل التحليل. أعد المحاولة بتسجيل واضح مدته من 8 إلى 15 ثانية.',
  'Analysis failed. Please try a clearer sample or reconnect later.':
      'فشل التحليل. جرّب عينة أوضح أو أعد الاتصال لاحقًا.',
  'Something went wrong. Please try again.':
      'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
  'Microphone permission was denied.': 'تم رفض صلاحية الميكروفون.',
  'Only WAV audio files are supported for analysis.':
      'يدعم التحليل ملفات WAV الصوتية فقط.',
  'The selected audio file could not be found.':
      'تعذر العثور على ملف الصوت المحدد.',
  'The recording file was not created correctly. Please try again.':
      'لم يتم إنشاء ملف التسجيل بشكل صحيح. يرجى المحاولة مرة أخرى.',
  'Invalid storage location.': 'موقع التخزين غير صالح.',
  'The speech sample is too short for reliable analysis.':
      'عينة الكلام قصيرة جدًا لتحليل موثوق.',
  'Record at least 8 to 15 seconds in a quiet room and try again.':
      'سجّل مدة من 8 إلى 15 ثانية على الأقل في مكان هادئ ثم حاول مرة أخرى.',
  'No screening conclusion was generated because the input was incomplete.':
      'لم يتم توليد نتيجة فحص لأن الإدخال غير مكتمل.',
  'Analysis did not finish. Please retry with a clear 8 to 15 second WAV recording.':
      'لم يكتمل التحليل. أعد المحاولة بتسجيل WAV واضح مدته من 8 إلى 15 ثانية.',
  'On-device AI analysis failed. Make sure the ONNX models are in assets/models, declared in pubspec.yaml, and the audio is WAV format.':
      'فشل تحليل الذكاء الاصطناعي داخل الجهاز. تأكد من وجود نماذج ONNX داخل assets/models وتعريفها في pubspec.yaml وأن الصوت بصيغة WAV.',
  'The screening backend did not respond in time.':
      'لم يستجب خادم الفحص في الوقت المحدد.',
  'No connection to the screening backend.':
      'لا يوجد اتصال بخادم الفحص.',
  'The backend could not process this audio sample.':
      'تعذر على الخادم معالجة عينة الصوت هذه.',
  'Confidence is below the recommended threshold for a clear screening result.':
      'الثقة أقل من الحد الموصى به للحصول على نتيجة فحص واضحة.',
  'Continue periodic self-checks if concerns persist.':
      'استمر في الفحوصات الذاتية الدورية إذا استمرت المخاوف.',
  'Consult a speech-language specialist for a professional assessment.':
      'استشر مختصًا في علاج النطق واللغة للحصول على تقييم مهني.',
  'The submitted speech sample was screened for acoustic patterns associated with dysarthria and stuttering. This early screening result is not a diagnosis and should be interpreted with clinical guidance.':
      'تم فحص عينة الكلام المرسلة بحثًا عن أنماط صوتية مرتبطة بعسر التلفظ والتأتأة. نتيجة هذا الفحص المبكر ليست تشخيصًا ويجب تفسيرها بإرشاد إكلينيكي.',
  'Analysis took too long. Please close other apps, record a shorter clear sample, and try again.':
      'استغرق التحليل وقتًا طويلًا. أغلق التطبيقات الأخرى وسجّل عينة أقصر وواضحة ثم حاول مرة أخرى.',
  'Record again in a quiet room for 8 to 15 seconds, then retry the screening.':
      'سجّل مرة أخرى في مكان هادئ لمدة من 8 إلى 15 ثانية، ثم أعد الفحص.',
  'No screening conclusion was generated because the audio sample was incomplete, unclear, too silent, or unsuitable for analysis.':
      'لم يتم توليد نتيجة فحص لأن عينة الصوت غير مكتملة أو غير واضحة أو منخفضة جدًا أو غير مناسبة للتحليل.',
  'Continue periodic self-checks if concerns persist. This result is only an early screening result.':
      'استمر في الفحوصات الذاتية الدورية إذا استمرت المخاوف. هذه النتيجة فحص مبكر فقط.',
  'The on-device AI model analyzed the submitted speech sample and did not detect strong acoustic indicators of dysarthria or stuttering in this recording.':
      'حلل نموذج الذكاء الاصطناعي داخل الجهاز عينة الكلام المرسلة ولم يرصد مؤشرات صوتية قوية لعسر التلفظ أو التأتأة في هذا التسجيل.',
  'Consult a speech-language specialist for a professional assessment, especially if symptoms continue or affect daily communication.':
      'استشر مختصًا في علاج النطق واللغة للحصول على تقييم مهني، خاصة إذا استمرت الأعراض أو أثرت في التواصل اليومي.',
  'Could not initialize the ONNX model on this device. The model may be incompatible with the mobile runtime or too large for available memory.':
      'تعذر تهيئة نموذج ONNX على هذا الجهاز. قد يكون النموذج غير متوافق مع بيئة الهاتف أو كبيرًا جدًا للذاكرة المتاحة.',
  'Could not load ONNX model assets. Add the two ONNX files under assets/models and declare them in pubspec.yaml.':
      'تعذر تحميل ملفات نماذج ONNX. أضف ملفي ONNX داخل assets/models وعرّفهما في pubspec.yaml.',
  'Confidence is below the recommended threshold. Please repeat the screening with a clearer recording and consult a specialist if concerns persist.':
      'الثقة أقل من الحد الموصى به. كرر الفحص بتسجيل أوضح واستشر مختصًا إذا استمرت المخاوف.',
  'On-device AI analysis currently supports WAV files only. Please record inside the app or upload a WAV file.':
      'يدعم تحليل الذكاء الاصطناعي داخل الجهاز ملفات WAV فقط حاليًا. سجّل من داخل التطبيق أو ارفع ملف WAV.',
  'The audio file is empty or unsupported.':
      'ملف الصوت فارغ أو غير مدعوم.',
  'The speech sample is too short for reliable analysis. Please record a clearer 8 to 15 second sample.':
      'عينة الكلام قصيرة جدًا لتحليل موثوق. سجّل عينة أوضح مدتها من 8 إلى 15 ثانية.',
  'The recording contains too little clear speech. Please read the prompt again in a quiet room.':
      'يحتوي التسجيل على مقدار قليل جدًا من الكلام الواضح. اقرأ النص مرة أخرى في مكان هادئ.',
  'The speech sample is too silent or unclear for reliable analysis.':
      'عينة الكلام منخفضة جدًا أو غير واضحة لتحليل موثوق.',
  'The recording is distorted or too loud. Keep the phone around 15cm away and try again.':
      'التسجيل مشوش أو مرتفع جدًا. أبقِ الهاتف على بعد نحو 15 سم وحاول مرة أخرى.',
  'Invalid WAV file: file is too small.':
      'ملف WAV غير صالح: حجم الملف صغير جدًا.',
  'Invalid WAV file.': 'ملف WAV غير صالح.',
  'Invalid WAV file: corrupted chunk size.':
      'ملف WAV غير صالح: حجم جزء تالف.',
  'Invalid WAV file: unsupported fmt chunk.':
      'ملف WAV غير صالح: جزء fmt غير مدعوم.',
  'Unsupported WAV structure.': 'بنية ملف WAV غير مدعومة.',
  'Invalid WAV file: audio stream metadata is invalid.':
      'ملف WAV غير صالح: بيانات تدفق الصوت غير صالحة.',
  'Unsupported WAV encoding. Please use PCM WAV audio.':
      'ترميز WAV غير مدعوم. استخدم صوت PCM WAV.',
  'The usable speech portion is short. A longer 8 to 15 second recording may improve reliability.':
      'الجزء القابل للاستخدام من الكلام قصير. قد يحسّن تسجيل أطول من 8 إلى 15 ثانية موثوقية النتيجة.',
  'Some parts of the recording are loud or clipped. Repeat in a quieter room if the result seems unexpected.':
      'بعض أجزاء التسجيل مرتفعة أو مقصوصة. كرر التسجيل في مكان أهدأ إذا بدت النتيجة غير متوقعة.',
  'The sample may contain background noise. Repeat in a quieter room if needed.':
      'قد تحتوي العينة على ضوضاء خلفية. كرر التسجيل في مكان أهدأ عند الحاجة.',
};
