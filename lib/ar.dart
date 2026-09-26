/// Centralized Arabic Localization Strings for Dawaai App (دوائي)
/// All UI texts, labels, messages, buttons, dialogs, and tooltips are maintained here.
library;

class Ar {
  // App General
  static const String appName = 'دوائي';
  static const String appFullName = 'دوائي - منظم الأدوية الذكي';
  static const String appTagline = 'صحتك أولويتنا، استمر في الانتظام';

  // Navigation Bar
  static const String navToday = 'جدول الجرعات';
  static const String navMedicines = 'أدويتي';
  static const String navPharmacy = 'صيدليتي';
  static const String navHistory = 'ملفي الطبي';
  // kept for compat
  static const String navPainkillers = 'أدويتي';
  static const String navStock = 'صيدليتي';

  // AppBar & Menus
  static const String moreAndTools = 'المزيد والأدوات';
  static const String encyclopediaMenu = 'موسوعة وبحث الأدوية الشامل';
  static const String interactionsMenu = 'فاحص التعارضات الطبية';
  static const String doctorReportMenu = 'تقرير الطبيب ومشاركته';
  static const String familyProfilesMenu = 'ملفات العائلة';
  static const String darkMode = 'الوضع الليلي';
  static const String lightMode = 'الوضع النهاري';
  static const String notificationsCenterTitle = 'مركز الإشعارات والتذكيرات';
  static const String notificationsTooltip = 'الإشعارات والتذكيرات';
  static const String clearAllNotifications = 'مسح الكل';
  static const String noNotificationsYet = 'لا توجد إشعارات جديدة حالياً';
  static const String noNotificationsDesc =
      'ستصلك تنبيهات عند حلول موعد الجرعات وعندما يصبح المسكن آمناً للتناول';
  static const String nowTime = 'الآن';
  static const String testLiveNotificationTitle =
      'اختبار الإشعارات فوراً (تجربة حية):';
  static const String testSafePainkillerBtn = 'إشعار المسكن الآمن';
  static const String testMedTimeBtn = 'إشعار موعد الدواء';
  static const String recordTakeNow = 'تسجيل التناول الآن';

  // Today Tab
  static const String welcome = 'مرحباً بك،';
  static const String today = 'اليوم';
  static const String welcomeTitle = 'أهلاً بك في دوائي';
  static const String welcomeSubtitle =
      'لا توجد أدوية مسجلة بعد.\nابدأ بإضافة أدويتك لتنظيم أوقاتها وتتبع عدد الحبات المتبقية.';
  static const String addNewMedicine = 'إضافة دواء جديد';
  static const String todayAdherenceTitle = 'التزامك الدوائي لليوم';
  static const String completedDosesStat = 'الجرعات المكتملة';
  static const String remainingDosesStat = 'المتبقية لليوم';
  static const String totalMedicinesStat = 'إجمالي الأدوية';
  static const String todayScheduleTitle = 'جدول جرعات العلاج اليوم';
  static const String appointmentsCount = 'مواعيد';
  static const String takeMedicineBtn = 'أخذت الدواء';
  static const String doseTakenBadge = 'تم الأخذ ✓';
  static const String refillBtn = 'تعبئة';
  static const String takePainkillerNowBtn = 'أخذ المسكن';
  static const String safePainkillerNotice =
      'يمكنك تناول المسكن الآن بأمان إذا كنت تشعر بألم';
  static const String painkillerTag = 'مسكن ألم';
  static const String treatmentTag = 'علاج منتظم';
  static const String dosePrefix = 'جرعة:';
  static const String stockPrefix = '• المخزون:';
  static const String noTreatmentsScheduledTitle =
      'لا توجد أدوية علاج مجدولة حالياً';
  static const String noTreatmentsScheduledDesc =
      'أضف أدويتك العلاجية لتنظيم مواعيدها اليومية وتتبع عدد الحبات المتبقية بدقة';
  static const String noTimesSetDesc =
      'لم تحدد مواعيد جرعات بعد لأدويتك العلاجية. اضغط تعديل الدواء وحدد أوقات التذكير.';

  // Next Dose Only strings (الجرعة التالية لكل دواء)
  static const String nextDosesOnlyTitle = 'الجرعة القادمة لكل دواء';
  static const String nextDosesOnlySubtitle =
      'تظهر فقط الجرعة التالية؛ وبمجرد أخذها ينتقل الموعد فوراً للتالي';
  static const String nextDoseBadge = 'الجرعة القادمة';
  static const String takeDoseInstantBtn = 'أخذت الجرعة';
  static const String allDosesDoneForToday = 'اكتملت جرعات اليوم لهذا الدواء ✓';
  static const String nextDoseIsTomorrow = 'الجرعة القادمة غداً';
  static const String timeToTakeNow = 'حان موعد الجرعة الآن!';
  static String doseTakenAdvancedMsg(String name, String nextTime) =>
      'عافاك الله! تم تسجيل جرعة $name بنجاح. الموعد القادم: $nextTime';

  // My Medicines Tab (أدويتي - كل أدوية المستخدم)
  static const String myMedicinesTabTitle = 'أدويتي';
  static const String myMedicinesSubtitle =
      'جميع الأدوية المسجلة مع إمكانية الإضافة والحذف';
  static const String myMedicinesCount = 'دواء مسجل';
  static String myMedicinesCountLabel(int count) => '$count دواء مسجل';
  static const String noMedicinesYetTitle = 'لا توجد أدوية مسجلة بعد';
  static const String noMedicinesYetDesc =
      'اضغط على زر الإضافة لتسجيل أدويتك وتنظيم مواعيدها';
  static const String addMedicineBtn = 'إضافة دواء';
  static const String deleteMedConfirmTitle = 'حذف الدواء';
  static String deleteMedConfirmBody(String name) =>
      'هل تريد حذف "$name" من قائمتك؟ لا يمكن التراجع.';
  static const String treatmentTypeBadge = 'علاج منتظم';
  static const String painkillerTypeBadge = 'مسكن ألم';
  static const String editBtn = 'تعديل';
  static const String deleteBtn = 'حذف';
  static const String pillsUnit = 'حبة';
  static const String stockRemainingLabel = 'مخزون متبقٍ';
  static const String nextDoseLabel = 'الجرعة القادمة';
  static const String notScheduledLabel = 'غير محدد';

  // Painkillers Tab & Safety (kept for compat)
  static const String painkillerGuideTitle = 'دليل الأمان لمسكنات الألم';
  static const String asNeededOnly = 'عند اللزوم فقط';
  static const String painkillerGuideDesc =
      'المسكنات تؤخذ عند الشعور بالألم فقط مع الالتزام التام بالفاصل الزمني لحماية الكبد والمعدة من فرط الجرعات.';
  static const String liveNotificationTest = 'تجربة إشعار الأمان الحي الآن';
  static const String myPainkillersTitle = 'مسكناتك ومؤشرات الأمان';
  static const String registeredPainkillers = 'مسكنات مسجلة';
  static String registeredPainkillersCount(int count) => '$count مسكنات مسجلة';
  static const String noPainkillersTitle = 'لم تضف أي مسكن ألم بعد';
  static const String noPainkillersDesc =
      'أضف مسكناتك (مثل باراسيتامول، بروفين، بنادول) لحساب فاصل الأمان وتلقي إشعار: "يمكنك تناول المسكن الآن بأمان إذا كنت تشعر بألم"';
  static const String addPainkillerBtn = 'إضافة مسكن ألم';
  static const String safeIntervalPrefix = 'الفاصل الآمن: كل';
  static const String maxDailyPrefix = '• الحد الأقصى:';
  static const String hoursSuffix = 'ساعات';
  static const String dosesPerDaySuffix = 'جرعات/يوم';
  static const String safeToTakeBadge = 'آمن للتناول';
  static const String dailyLimitConsumed = 'الحد الأقصى اليومي مستهلك';
  static const String safeIntervalBetweenDoses = 'فترة أمان بين الجرعات';
  static const String ofTotalDosesToday = 'من';
  static const String dosesTodaySuffix = 'جرعات اليوم';
  static const String outOfStockTapToRefill = 'نفذ المخزون - اضغط للتعبئة';
  static const String takePainkillerIfInPain =
      'تناول المسكن الآن (إذا كنت تشعر بألم)';
  static const String recordPainkillerDose = 'تسجيل أخذ جرعة مسكن';
  static String safeIntervalAndMaxDesc(int interval, int maxDoses) =>
      'الفاصل الآمن: كل $interval ساعات • الحد الأقصى: $maxDoses جرعات/يوم';
  static String dosesTodaySummary(int taken, int max) =>
      '($taken من $max جرعات اليوم)';

  // Pharmacy Future Work Tab (صيدليتي - قريباً)
  static const String pharmacyFutureTitle = 'صيدليتي الذكية';
  static const String pharmacyFutureSubtitle = 'مميزات قادمة قريباً';
  static const String pharmacyComingSoonBadge = 'قريباً';
  static const String pharmacyFeature1Title = 'بحث وطلب الأدوية';
  static const String pharmacyFeature1Desc =
      'ابحث عن دوائك في أقرب صيدلية وتحقق من توفره قبل الذهاب';
  static const String pharmacyFeature2Title = 'تنبيه انتهاء الصلاحية';
  static const String pharmacyFeature2Desc =
      'يذكرك التطبيق بتواريخ انتهاء صلاحية أدويتك تلقائياً';
  static const String pharmacyFeature3Title = 'مقارنة الأسعار';
  static const String pharmacyFeature3Desc =
      'قارن أسعار الأدوية بين الصيدليات المختلفة لتوفير المال';
  static const String pharmacyFeature4Title = 'الوصفات الطبية الرقمية';
  static const String pharmacyFeature4Desc =
      'احفظ وصفاتك الطبية رقمياً وشاركها مع الصيدلاني بسهولة';
  static const String pharmacyFutureDesc =
      'نحن نعمل بجد لإحضار هذه المميزات قريباً. شكراً لصبرك وثقتك بتطبيق دوائي.';

  // Futuristic Home Pharmacy & Shared Household Inventory (صيدلية المنزل الذكية المتصلة)
  static const String homePharmacyFuturisticTitle = 'صيدلية المنزل الذكية';
  static const String homePharmacyFuturisticSubtitle =
      'خزانة أدوية البيت المشتركة بين أفراد المنزل';
  static const String connectedToHomeNetwork =
      'متصل بالشبكة المنزلية • صيدلية سحابية نشطة';
  static const String homePharmacyId = 'معرف الصيدلية (ID)';
  static const String homePharmacyPassword = 'رمز الأمان / كلمة السر';
  static const String copyCredentialsBtn = 'نسخ بيانات الصيدلية';
  static const String shareHomeInviteBtn = 'مشاركة الرمز مع العائلة';
  static const String joinHomePharmacyAction = 'الانضمام لصيدلية منزل';
  static const String createHomePharmacyAction = 'إنشاء صيدلية منزل جديدة';
  static const String leaveHomePharmacyAction = 'مغادرة هذه الصيدلية';
  static const String switchPharmacyAction = 'تبديل أو مغادرة الصيدلية';
  static const String homeMembersSection = 'أفراد المنزل المتصلين بالصيدلية';
  static const String homeStockSection = 'مخزون أدوية المنزل الحالي';
  static const String addMedToHomeStock = 'إضافة دواء لمخزون البيت';
  static const String searchHomeMedicines = 'ابحث عن أي دواء متوفر في البيت...';
  static const String consumeHomeDose = 'استهلاك (-1)';
  static const String refillHomeDose = 'تعبئة (+)';
  static const String storagePlaceLabel = 'مكان الحفظ بالمنزل';
  static const String locationCabinetDefault = 'خزانة الأدوية الرئيسية';
  static const String locationFridgeDefault = 'ثلاجة المطبخ (مبرد)';
  static const String locationFirstAidDefault = 'حقيبة الإسعافات الأولية';
  static const String locationRoomDefault = 'درج الغرفة / مكان آخر';
  static const String joinedSuccessAlert = 'تم الانضمام لصيدلية المنزل بنجاح!';
  static const String createdSuccessAlert =
      'تم إنشاء صيدلية المنزل الذكية بنجاح!';
  static const String invalidCredentialsAlert =
      'عذراً! معرف الصيدلية أو كلمة السر غير صحيحة.';
  static const String joinHomeHeaderTitle = 'انضم إلى صيدلية منزلك 🏠';
  static const String joinHomeHeaderSubtitle =
      'أدخل المعرف وكلمة السر لتتشارك أنت وأفراد أسرتك مخزون أدوية البيت وتعرفوا ما يتوفر بالمنزل';
  static const String joinPharmacyDialogDesc =
      'أدخل معرف صيدلية البيت وكلمة السر المقدمة من مدير الخزانة أو أحد أفراد المنزل';
  static const String createHomeHeaderTitle = 'إنشاء صيدلية منزل جديدة 💊';
  static const String createHomeHeaderSubtitle =
      'أنشئ خزانة ذكية لبيتك وشارك المعرف ورمز المرور مع عائلتك';
  static const String createPharmacyDialogDesc =
      'أنشئ خزانة منزلية ذكية خاصة ببيتك وشارك معرفها وكلمة سرها مع أفراد منزلك';
  static const String pharmacyNameInputLabel =
      'اسم صيدلية المنزل (مثلاً: بيت العائلة)';
  static const String pharmacyIdInputLabel = 'معرف الصيدلية (Pharmacy ID)';
  static const String pharmacyPasswordInputLabel = 'كلمة السر / رمز الدخول';
  static const String memberNameInputLabel =
      'اسمك بالمنزل (مثلاً: أحمد، سارة، الوالد)';
  static const String copiedToClipboard =
      'تم نسخ المعرف وكلمة السر إلى الحافظة بنجاح!';
  static String shareHomeInviteText(String name, String id, String pass) =>
      'انضم إلى صيدلية منزلنا "$name" في تطبيق دوائي لمتابعة أدوية البيت المشتركة!\n🔑 معرف الصيدلية (ID): $id\n🔒 كلمة السر: $pass';

  // Pharmacy & Stock Tab (كم حبة عندك)
  static const String stockSummaryTitle = 'ملخص صيدليتي والمخزون';
  static const String addMedicineToPharmacy = 'إضافة دواء';
  static const String totalMedicinesBox = 'إجمالي الأدوية';
  static const String treatmentMedicinesBox = 'أدوية علاج';
  static const String painkillerMedicinesBox = 'مسكنات ألم';
  static const String lowStockMedicinesBox = 'نقص مخزون';
  static const String encyclopediaBannerTitle =
      'موسوعة الأدوية الشاملة وبحث الجرعات';
  static const String encyclopediaBannerSubtitle =
      'ابحث بالاسم التجاري، العلمي، العيار، أو الشركة - أدوية شائعة ونادرة';
  static const String browseEncyclopedia = 'تصفح الموسوعة';
  static const String filterAll = 'الكل';
  static const String filterTreatment = 'أدوية علاج';
  static const String filterPainkillers = 'مسكنات ألم';
  static const String filterLowStock = 'نقص المخزون';
  static const String emptyPharmacyTitle = 'صيدليتك فارغة حالياً';
  static const String emptyPharmacyDesc =
      'لم تقم بإضافة أي دواء بعد. أضف أدويتك لتتبع عدد الحبات والمخزون المتبقي.';
  static const String noMedicinesMatchFilter =
      'لا توجد أدوية مطابقة لهذا التصنيف';
  static const String viewAllMedicines = 'عرض جميع الأدوية';
  static const String availableStockLabel = 'المخزون المتوفر:';
  static const String lowStockAlertBadge = 'اقترب النفاذ';
  static const String outOfStockBadge = 'نفذ المخزون - يرجى التعبئة';
  static const String scheduledTimesLabel = 'مواعيد الجرعات: ';
  static const String recordDoseAction = 'تسجيل أخذ الجرعة';
  static const String refillStockAction = 'تعبئة المخزون';
  static const String editMedicineAction = 'تعديل الدواء';
  static const String deleteMedicineAction = 'حذف الدواء';
  static const String confirmDeleteTitle = 'حذف الدواء';
  static String confirmDeletePrompt(String name) =>
      'هل أنت متأكد من رغبتك في حذف ($name) من قائمتك؟';
  static String recordDoseWithAmount(int amount, String unit) =>
      'تسجيل تناول الجرعة ($amount $unit)';

  // Dose Log Sheet (تسجيل الجرعة)
  static const String takeDoseSheetTitle = 'تسجيل تناول الجرعة';
  static const String painQuestionTitle = 'هل تشعر بألم حالياً؟ (تقييم الألم)';
  static const String painQuestionDesc =
      'حدد شدة الألم من 1 إلى 10 لمساعدة طبيبك في متابعة حالتك';
  static const String currentPainLevelLabel = 'مستوى الألم الحالي:';
  static const String painCausePrompt = 'سبب تناول المسكن / مكان الألم:';
  static const String consumedQuantityLabel = 'الكمية المتناولة:';
  static const String stockAfterDoseLabel = 'المخزون بعد الجرعة:';
  static const String dynamicRescheduleExplainer =
      'الجدولة الذكية: يبدأ احتساب موعد الجرعة التالية تلقائياً من وقت تناولك الفعلي الآن لمنع التداخل والجرعة الزائدة.';
  static const String confirmTakePainkillerNow = 'تأكيد أخذ المسكن الآن ✓';
  static const String confirmTakeMedicineNow = 'تأكيد أخذ الدواء الآن ✓';
  static String limitReachedWarning(int maxDailyDoses) =>
      'تحذير: تجاوزت الحد الأقصى اليومي ($maxDailyDoses جرعات). لا ينصح بتناول جرعة إضافية.';
  static String cooldownWarning(int mins) =>
      'تحذير طبي: لم ينتهِ الفاصل الآمن بعد ($mins دقيقة متبقية).';
  static const String earlyIntakeWarningTitle =
      '⚠️ تحذير طبي: تناول الدواء قبل موعده الآمن';
  static const String earlyIntakeWarningDesc =
      'تناول الجرعة قبل اكتمال الفاصل الزمني الآمن قد يسبب تراكم المادة الفعالة في الدم وخطر التسمم الدوائي أو المضاعفات الخطيرة.';
  static String earlyIntakeLastDoseInfo(String timeAgoStr, int safeHours) =>
      'آخر جرعة تم تناولها كانت قبل $timeAgoStr. الحد الأدنى للفاصل الآمن هو $safeHours ساعات.';
  static String earlyIntakeCooldownRemaining(int hours, int mins) {
    if (hours > 0 && mins > 0) return '$hours ساعة و $mins دقيقة';
    if (hours > 0) return '$hours ساعة';
    return '$mins دقيقة';
  }

  static const String earlyIntakeWaitRecommendation =
      'الانتظار حتى الموعد الآمن (موصى به طبياً)';
  static const String earlyIntakeConfirmOverride =
      'أنا على دراية بالخطر، تأكيد التناول الآن';
  static String delayedRescheduledSafeNotice(String newTime, int safeHours) =>
      'تم تأجيل موعد الجرعة التالية تلقائياً إلى $newTime للحفاظ على الفاصل الزمني الآمن ($safeHours ساعات) بعد تأخر الجرعة.';
  static const String safeIntervalEnforcedBadge = 'موعد مصحح للأمان الطبي';
  static String stockRemainingFormatted(
    int remaining,
    int total,
    String unit,
  ) => '$remaining من أصل $total $unit';
  static String painDescription(double level) {
    if (level <= 2) return 'ألم خفيف جداً';
    if (level <= 4) return 'ألم خفيف إلى متوسط';
    if (level <= 6) return 'ألم متوسط';
    if (level <= 8) return 'ألم شديد ومزعج';
    return 'ألم شديد جداً لا يحتمل';
  }

  static const List<String> quickPainNotes = [
    'صداع',
    'صداع نصفي',
    'ألم أسنان',
    'ألم ظهر ومفاصل',
    'حرارة ووعكة',
    'ألم بالمعدة',
  ];

  // Add/Edit Medicine Sheet - Elderly Friendly (بسيطة لكبار السن)
  static const String addNewMedicineSheetTitle = 'إضافة دواء جديد';
  static const String editMedicineSheetTitle = 'تعديل بيانات الدواء';
  static const String addMedElderlySubtitle =
      'خطوات بسيطة وواضحة لتنظيم دوائك وتذكيرك بمواعيده';
  static const String searchEncyclopediaOptional =
      'ابحث بالموسوعة لاختيار الدواء وعياره تلقائياً (اختياري):';
  static const String searchEncyclopediaHint =
      'اكتب اسم الدواء (مثال: بنادول، كونكور، جلوكوفاج)...';
  static const String tapToAutoFill = 'اضغط للاختيار';
  static const String customAddFreedomNote =
      '💡 لست مقيداً بالموسوعة: يمكنك كتابة أي دواء أو عيار خاص بك بالأسفل بحرية تامة.';

  // Elderly Step 1: Name
  static const String step1NameTitle = '1. ما هو اسم الدواء وعياره؟';
  static const String medicineNameField = 'اسم الدواء والجرعة *';
  static const String medicineNameHintElderly =
      'اكتب اسم الدواء (مثال: بنادول 500، كونكور 5 ملغ، دواء السكر)';
  static const String medicineNameError = 'يرجى كتابة اسم الدواء';

  // Elderly Step 2: Type
  static const String step2TypeTitle = '2. ما نوع هذا الدواء؟';
  static const String treatmentTypeCardTitle = 'علاج يومي منتظم';
  static const String treatmentTypeCardDesc =
      'دواء مستمر يؤخذ بمواعيد محددة (مثل: الضغط، السكر، القلب)';
  static const String painkillerTypeCardTitle = 'مسكن ألم عند اللزوم';
  static const String painkillerTypeCardDesc =
      'يؤخذ فقط عند الشعور بألم مع فاصل أمان (مثل: الصداع، المفاصل)';

  // Elderly Step 3: Stock
  static const String step3StockTitle = '3. كم حبة متوفرة عندك الآن بالعلبة؟';
  static const String totalPillsLabel = 'عدد الحبات المتوفرة';
  static const String quickAddPills = 'إضافة سريعة:';
  static const String unitPill = 'حبة';
  static const String unitPills = 'حبات';

  // Elderly Step 4: Timing & Schedule
  static const String step4TimingTitle = '4. متى تأخذ هذا الدواء؟';
  static const String dailyTimesSectionTitle = 'أوقات التذكير اليومية:';
  static const String morningPreset = 'صباحاً (08:00 ص)';
  static const String noonPreset = 'ظهراً (02:00 م)';
  static const String eveningPreset = 'مساءً (08:00 م)';
  static const String nightPreset = 'قبل النوم (11:00 م)';
  static const String addCustomTimeBtn = '+ إضافة وقت محدد';
  static const String noScheduledTimesYet =
      'اضغط على أحد الأوقات أعلاه (صباحاً / مساءً) لتحديد موعد التنبيه.';

  // Elderly Step 4 for Painkiller: Safe interval
  static const String painkillerIntervalQuestion =
      'كم ساعة يجب أن تنتظر بين كل حبة وأخرى على الأقل؟';
  static const String safeInterval4Hours = 'كل 4 ساعات';
  static const String safeInterval6Hours = 'كل 6 ساعات (المعتاد)';
  static const String safeInterval8Hours = 'كل 8 ساعات';
  static const String safeInterval12Hours = 'كل 12 ساعة';

  // Elderly Step 5: Food instructions
  static const String step5FoodTitle = '5. متى تأخذه بالنسبة للأكل؟';
  static const String foodAfter = 'بعد الأكل';
  static const String foodBefore = 'قبل الأكل';
  static const String keywordBefore = 'قبل';
  static const String foodWith = 'مع الأكل';
  static const String foodBedtime = 'قبل النوم مباشرة';

  // Collapsible Advanced Section
  static const String advancedOptionsToggle = 'خيارات إضافية (اختياري)';
  static const String pillsPerDoseField = 'كم حبة في الجرعة الواحدة؟';
  static const String lowStockAlertField = 'تنبيه النقص عندما يتبقى في العلبة:';
  static const String medicineShapeField = 'شكل الدواء:';
  static const String activeIngredientField = 'المادة الفعالة (الاسم العلمي):';
  static const String activeIngredientHint = 'مثال: Paracetamol, Metformin';
  static const String colorSelectionField = 'اختر لوناً مميزاً للدواء:';

  static const String saveMedicineBtn = 'حفظ الدواء في صيدليتي ✓';
  static const String updateMedicineBtn = 'حفظ التعديلات ✓';

  // Medicine Forms & Types
  static const String typePainkillerLabel = 'مسكن ألم (عند اللزوم)';
  static const String typeTreatmentLabel = 'دواء علاج (منتظم)';
  static const String formPill = 'حبوب / أقراص';
  static const String formCapsule = 'كبسولات';
  static const String formSyrup = 'شراب';
  static const String formSyrupMl = 'شراب (مل)';
  static const String formInjection = 'حقنة';
  static const String formInjectionPlural = 'حقن';
  static const String formDrops = 'قطرات';
  static const String formInhaler = 'بخاخ';
  static const String formOintment = 'مرهم / كريم';
  static const String unitMl = 'مل';
  static const String unitInjection = 'حقنة';
  static const String unitDrop = 'قطرة';
  static const String unitPuff = 'بخة';
  static const String unitDose = 'جرعة';
  static const String unitDoses = 'جرعات';

  // History Tab
  static const String adherenceHistoryTitle = 'سجل الجرعات والالتزام';
  static const String adherenceStatsTitle = 'ملخص الالتزام المسجل';
  static const String totalDosesRecorded = 'إجمالي الجرعات المسجلة';
  static const String painkillerDosesStat = 'جرعات مسكنات الألم';
  static const String treatmentDosesStat = 'جرعات العلاج المنتظم';
  static const String timelineHistoryTitle = 'سجل الجرعات الزمني';
  static const String emptyHistoryTitle = 'لم يتم تسجيل أي جرعة بعد';
  static const String emptyHistoryDesc =
      'عند الضغط على "أخذت الدواء" في أي دواء، ستظهر هنا مع التوقيت ودرجة الألم بدقة.';
  static String deductedPillsDesc(int count) => 'تم خصم $count حبة من المخزون';
  static String painScoreText(int score) => 'مستوى الألم: $score/10';

  // Drug Encyclopedia Screen
  static const String encyclopediaTitle =
      'موسوعة الأدوية الشاملة بجميع العيارات';
  static const String customAddTooltip = 'إضافة دواء مخصص من عندك';
  static const String searchDrugHintDetailed =
      'ابحث بالاسم التجاري، العلمي، العيار (مثلاً: 500 ملغ، 10 ملغ)، أو الشركة...';
  static const String allCategories = 'الكل';
  static const String rareMedicinesFilter = 'أدوية نادرة وتخصصية';
  static const String customAddPromptTitle = 'تريد إضافة دواء خاص من عندك؟';
  static const String customAddPromptDesc =
      'لست مجبراً على الاختيار من الموسوعة؛ يمكنك إضافة أي دواء بحرية تامة.';
  static const String customAddBtnShort = 'إضافة مخصصة';
  static String searchResultsCount(int count) =>
      'نتائج البحث ($count دواء وجرعة)';
  static const String rareOnlyActiveFilter =
      'عرض الأدوية النادرة والتخصصية فقط';
  static const String noSearchResults = 'لم يتم العثور على دواء مطابق للبحث';
  static const String noSearchResultsDesc =
      'يمكنك إضافة الدواء يدوياً بجميع بياناته وتفاصيله المخصصة الآن.';
  static const String addThisDrugManually = 'إضافة هذا الدواء يدوياً';
  static const String rareBadge = 'نادر';
  static String scientificNameLabel(String name) => 'الاسم العلمي: $name';
  static String companyLabel(String comp) => 'الشركة: $comp';
  static String indicationsLabel(String uses) => 'دواعي الاستعمال: $uses';
  static const String fullDetailsBtn = 'تفاصيل واستخدامات';
  static const String addToMySchedule = 'أضف لجدولي';
  static const String availableDosagesTitle =
      'العيارات والجرعات المتوفرة لهذا الدواء:';
  static const String availableDosagesSubtitle =
      'اضغط على عيارك ليتم ضبط اسم الدواء وجرعته تلقائياً';
  static const String availableDosagesBadgePrefix = 'العيارات المتوفرة: ';
  static const String availableDosagesSection =
      'الجرعات والعيارات المصنعية المتوفرة';
  static const String selectDosagePrompt = 'اختر العيار والجرعة المناسبة لك:';

  // Drug Monograph Sheet
  static const String drugDetailsTitle = 'الدليل الدوائي والمونوغراف الطبي';
  static String activeIngredientNamed(String generic) =>
      'المادة الفعالة (الاسم العلمي): $generic';
  static String manufacturerNamed(String comp) => 'الشركة المصنعة: $comp';
  static const String painkillerAsNeeded = 'مسكن ألم عند اللزوم';
  static const String treatmentScheduled = 'علاج مجدول منتظم';
  static const String specializedRareDrug = 'دواء تخصصي ونادر';
  static const String medicalDisclaimer =
      'تنبيه طبي صارم: هذه المعلومات للتوعية والتنظيم الدوائي فقط. لا تبدأ بتناول أي دواء أو تعديل الجرعات إلا بعد استشارة الطبيب المعالج أو الصيدلي المعتمد.';
  static const String indicationsSection = 'دواعي الاستعمال والتأثير الطبي';
  static const String usageInstructionsSection =
      'طريقة الاستخدام والجرعات المعتادة';
  static const String safetyWarningsSection =
      'محاذير الاستخدام وموانع الاستعمال';
  static const String sideEffectsSection = 'الأعراض الجانبية المحتملة';
  static const String addThisDrugToMyMeds =
      'إضافة هذا الدواء إلى جدول أدويتي ومخزوني';

  // Drug Interactions Sheet
  static const String interactionsTitle = 'فاحص التعارضات ودليل الصيدلي';
  static String interactionsResultTitle(int count) =>
      'نتيجة فحص تعارض أدويتك ($count أدوية)';
  static const String noCurrentInteractions = 'أدويتك متوافقة وآمنة معاً';
  static const String noInteractionsDesc =
      'لم يتم رصد أي تعارض خطير أو ازدواجية في المواد الفعالة في قائمة أدويتك الحالية.';
  static const String foodInteractionsTitle =
      'دليل الاستخدام مع الطعام والشراب';
  static const String missedDoseLabel = '⏰ عند النسيان: ';

  // Doctor Report Sheet
  static const String reportSheetTitle = 'التقرير الطبي للطبيب / العيادة';
  static const String shareViaWhatsApp = 'نسخ التقرير لمشاركته ';
  static const String reportCopiedSuccess =
      '✅ تم نسخ التقرير الطبي بالكامل! يمكنك الآن لصقه في واتساب أو إرساله لطبيبك.';
  static const String reportDocHeader =
      '📋 *تقرير الالتزام الدوائي وسجل الألم الطبي*';
  static const String reportPatientName = '👤 *اسم المريض / الملف:*';
  static const String reportGeneratedDate = '📅 *تاريخ إصدار التقرير:*';
  static const String reportMedsAndStock = '💊 *الأدوية الحالية والمخزون:*';
  static const String reportNoMeds = '- لا توجد أدوية مسجلة حالياً.';
  static const String reportDoseLabel = 'الجرعة:';
  static const String reportRemainingStock = 'المخزون المتبقي:';
  static const String reportDailyTimes = 'المواعيد اليومية:';
  static const String reportAdherenceStats7Days =
      '📊 *إحصائيات الالتزام لآخر 7 أيام:*';
  static const String reportTotalDosesTaken = 'إجمالي الجرعات المتناولة:';
  static const String reportPainAndPainkillersLog =
      '🩹 *سجل نوبات الألم والمسكنات:*';
  static const String reportNoRecentPain = '- لم يتم تسجيل أي نوبات ألم حديثة.';
  static const String reportNotSpecified = 'غير محدد';
  static const String reportGeneralPain = 'ألم عام';
  static const String reportPainkiller = 'المسكن:';
  static const String reportPainIntensity = 'شدة الألم:';
  static const String reportPainSite = 'الموضع:';
  static const String reportAutoGeneratedFooter =
      'تم إنشاء هذا التقرير آلياً عبر تطبيق «دوائي»';

  // Doctor A4 Official Report
  static const String reportA4HeaderTitle = 'تقرير المتابعة السريرية والالتزام بالدواء';
  static const String reportA4SubTitle = 'CLINICAL MEDICATION & ADHERENCE REPORT';
  static const String reportA4SystemName = 'منظومة دوائي للرعاية الصحية';
  static const String reportBtnDownloadPdf = 'تحميل PDF';
  static const String reportBtnDownloadImage = 'حفظ كصورة';
  static const String reportBtnPrint = 'طباعة';
  static const String reportBtnCopy = 'نسخ النص';
  static const String reportPatientDetails = 'بيانات المريض والملف';
  static const String reportPatientRelationship = 'الصلة / القرابة:';
  static const String reportMedicationsCount = 'عدد الأدوية الحالية:';
  static const String reportAdherenceRateLabel = 'نسبة الالتزام (7 أيام):';
  static const String reportDocumentRef = 'رقم الوثيقة:';
  static const String reportTableColMedName = 'اسم الدواء والنوع';
  static const String reportTableColDose = 'الجرعة';
  static const String reportTableColSchedule = 'جدول المواعيد';
  static const String reportTableColStock = 'المخزون';
  static const String reportTableColStatus = 'الحالة';
  static const String reportStatusGood = 'منتظم';
  static const String reportStatusLow = 'مخزون منخفض';
  static const String reportStatusAsNeeded = 'عند اللزوم';
  static const String reportPainHistory = 'سجل نوبات الألم وتناول المسكنات الطارئة';
  static const String reportNoPainLogged =
      'لا توجد نوبات ألم مسجلة في السجل الأخير (حالة المريض مستقرة).';
  static const String reportColTime = 'التاريخ والوقت';
  static const String reportColMed = 'المسكن';
  static const String reportColSeverity = 'الشدة';
  static const String reportColLocation = 'الموضع / السبب';
  static const String reportDoctorNotesTitle = 'ملاحظات وتوصيات الطبيب المعالج:';
  static const String reportDoctorSignatureLabel = 'توقيع الطبيب المعالج:';
  static const String reportDoctorStampLabel = 'الختم الرسمي للمركز / العيادة:';
  static const String reportFooterConfidential =
      'وثيقة طبية سرية - تم توليدها آلياً عبر منصة دوائي - صالحة للمراجعة السريرية الرسمية.';
  static const String reportPdfSaving = 'جارٍ إعداد ملف PDF الرسمي...';
  static const String reportImageSaving = 'جارٍ حفظ صورة التقرير عالية الدقة...';
  static const String reportPdfSavedSuccess = 'تم إعداد ملف PDF بنجاح!';
  static const String reportImageSavedSuccess =
      'تم حفظ صورة التقرير بنجاح في مجلد التنزيلات (Downloads)!';
  static const String reportSaveError =
      'حدث خطأ أثناء حفظ التقرير، يرجى المحاولة ثانية.';

  // Refill Dialog
  static const String refillDialogTitle = 'إعادة تعبئة المخزون';
  static const String currentStockPrefix = 'الكمية الحالية المتوفرة:';
  static const String quickAddPillsTitle = 'أضف حبات جديدة بسرعة:';
  static String quickAddAmount(int amount, String unit) => '+$amount $unit';
  static String newTotalStockLabel(String unit) =>
      'إجمالي المخزون الجديد ($unit)';
  static const String saveStockBtn = 'حفظ المخزون';

  // Profile Dialogs
  static const String selectProfileTitle = 'اختر الملف الشخصي';
  static const String addNewProfileBtn = 'إضافة فرد عائلة جديد';
  static const String addProfileDialogTitle = 'إضافة ملف عائلي جديد';
  static const String profileNameLabel = 'الاسم (مثلاً: الوالد، سارة)';
  static const String relationLabel = 'صلة القرابة (مثلاً: أب، أم، ابن)';
  static const String relationPrefix = 'صلة القرابة: ';
  static const String myProfileDefaultName = 'أنا (الملف الشخصي)';
  static const String myProfileRelation = 'أنا';
  static const String fatherRelationDefault = 'الوالد';
  static const String activeProfileToast = 'الملف النشط حالياً:';

  // SnackBar helpers
  static String doseRecordedSuccess(String name) =>
      'تم تسجيل تناول $name وبدء العد التنازلي للجرعة التالية بأمان.';
  static String stockUpdatedSuccess(String name, int total, String unit) =>
      'تم تحديث مخزون $name إلى $total $unit';
  static String medAddedSuccessNamed(String name) =>
      'تمت إضافة ($name) إلى قائمة أدويتك بنجاح';

  // Common Dialogs & Actions
  static const String cancel = 'إلغاء';
  static const String confirm = 'تأكيد';
  static const String delete = 'حذف';
  static const String save = 'حفظ';
  static const String add = 'إضافة';
  static const String close = 'إغلاق';
  static const String amPeriod = 'صباحاً';
  static const String pmPeriod = 'مساءً';
  static const String amShort = 'ص';
  static const String pmShort = 'م';
  static const String medicineAddedSuccess =
      'تمت إضافة الدواء بنجاح إلى صيدليتك';
  static const String medicineUpdatedSuccess = 'تم تعديل بيانات الدواء بنجاح';
  static const String medicineDeletedSuccess = 'تم حذف الدواء من قائمتك';

  // Notification Service texts
  static const String notifRescheduleTitle =
      '⏰ تم ضبط موعد الجرعة التالية بذكاء';
  static String notifRescheduleMsg(String time) =>
      'نظراً لتناول الجرعة الآن، بدأ العد للجرعة القادمة لتكون في موعدها الآمن الساعة $time.';
  static String notifSnoozeTitle(int minutes) =>
      '💤 تم تأجيل التنبيه ($minutes دقيقة)';
  static String notifSnoozeMsg(String name, String time) =>
      'سنذكرك مجدداً بدواء ($name) الساعة $time.';
  static String statusPainkillerLimitReached(int dosesToday, int maxDoses) =>
      'وصلت للحد الأقصى اليومي ($dosesToday من $maxDoses جرعات). لا تتناول المزيد اليوم دون استشارة الطبيب.';
  static String statusPainkillerWait(String timeStr) =>
      'يرجى الانتظار: باقي $timeStr حتى تصبح الجرعة التالية آمنة لحمايتك من الجرعة الزائدة.';
  static String remainingHoursAndMins(int h, int m) => '$h ساعة و $m دقيقة';
  static String remainingMinsOnly(int m) => '$m دقيقة';
  static const String notifPainkillerSafeTitle = '✅ مسكن آمن للتناول';
  static String notifPainkillerSafeMsg(String name) =>
      'يمكنك تناول المسكن ($name) الآن بأمان إذا كنت تشعر بألم';
  static const String notifMedTimeTitle = '⏰ موعد تناول الدواء';
  static String notifMedTimeMsg(
    String name,
    int count,
    String unit,
    String time,
  ) => 'حان موعد تناول دواء ($name) - $count $unit الساعة $time';
  static const String notifDynamicMedTimeTitle =
      '⏰ موعد الجرعة التالية (المعدل بذكاء)';
  static String notifDynamicMedTimeMsg(String name, String time) =>
      'حان موعد تناول ($name) الساعة $time المحسوب بناءً على وقت استيقاظك وجرعتك السابقة.';
  static const String notifLowStockTitle = '⚠️ تنبيه انخفاض المخزون';
  static String notifLowStockMsg(String name, int remaining, String unit) =>
      'اقترب نفاذ ($name)! متبقي لديك $remaining $unit فقط.';
  static String rescheduleNoteText(String nextTime) =>
      'تم بدء العد التنازلي للجرعة التالية: موعدها الآمن $nextTime لمنع الجرعة الزائدة.';

  // Dates and Time
  static const List<String> arabicDays = [
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  static const List<String> arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const String timeAm = 'ص';
  static const String timePm = 'م';

  // Drug Interactions Service
  static const String interactionParacetamolTitle =
      '⚠️ خطر مضاعفة مادة الباراسيتامول (تسمم الكبد)';
  static String interactionParacetamolDesc(String a, String b) =>
      'كلا الدواءين ($a و $b) يحتويان على نفس المادة الفعالة (الباراسيتامول). تناولهما معاً قد يؤدي لتجاوز الحد الأقصى الآمن (4000 ملغ/يوم) مما يسبب إجهاداً أو تسمماً حاداً للكبد.';
  static const String interactionParacetamolAdvice =
      'لا تجمع بين دوائين يحتويان على الباراسيتامول في نفس الوقت. اختر أحدهما أو استشر الطبيب/الصيدلي.';

  static const String interactionNsaidTitle =
      '⛔ تعارض خطير: مضادات التهاب غير ستيرويدية متعددة (نزيف المعدة)';
  static String interactionNsaidDesc(String a, String b) =>
      'الجمع بين ($a) و ($b) يضاعف بشدة خطر الإصابة بقرحة المعدة والنزيف المعوي وأمراض الكلى دون أي فائدة إضافية لتسكين الألم.';
  static const String interactionNsaidAdvice =
      'يمنع الجمع بين هذين الدواءين. يجب الاكتفاء بمسكن واحد منهما مع تناوله دائماً بعد وجبة كاملة.';

  static const String interactionAntibioticTitle =
      '⚠️ تداخل في الامتصاص: مضاد حيوي مع معادن/مضاد حموضة';
  static const String interactionAntibioticDesc =
      'مكملات المعادن أو مضادات الحموضة ترتبط بالمضاد الحيوي في المعدة وتمنع امتصاصه في مجرى الدم، مما يقلل فاعلية العلاج في القضاء على البكتيريا.';
  static const String interactionAntibioticAdvice =
      'افصل بين تناول المضاد الحيوي ومكملات الكالسيوم/الحديد/مضادات الحموضة بفاصل زمني لا يقل عن ساعتين إلى 3 ساعات.';

  // Food Guidelines
  static const String foodNsaidMeal =
      'يؤخذ دائماً بعد وجبة كاملة أو مع كوب حليب لحماية جدار المعدة من التهيج.';
  static const String foodNsaidAvoid =
      'تجنب تناوله على معدة فارغة تماماً، والابتعاد عن المشروبات الغازية معه.';
  static const String foodNsaidMissed =
      'إذا نسيت الجرعة، تناولها فور تذكرك بعد الأكل، إلا إذا اقترب موعد الجرعة التالية.';

  static const String foodAntibioticMeal =
      'يفضل تناوله في بداية وجبة الطعام لتقليل اضطرابات الجهاز الهضمي وتحسين الامتصاص.';
  static const String foodAntibioticAvoid =
      'أكمل الكورس كاملاً حتى لو شعرت بالتحسن لمنع مقاومة البكتيريا.';
  static const String foodAntibioticMissed =
      'تناول الجرعة المنسية فوراً، وسيتم ضبط موعد الجرعة التالية ديناميكياً بناءً على وقت تناولك الحالي.';

  static const String foodCardiacMeal =
      'يؤخذ صباحاً في نفس الموعد يومياً، يمكن تناوله مع أو بدون الطعام.';
  static const String foodCardiacAvoid =
      'تجنب التوقف المفاجئ عن الدواء دون استشارة الطبيب لتفادي ارتفاع الضغط الارتدادي.';
  static const String foodCardiacMissed =
      'إذا نسيت الجرعة، خذها في نفس اليوم، ولا تضاعف الجرعة لتعويض ما فاتك.';

  static const String foodParacetamolMeal =
      'يمكن تناوله على معدة فارغة أو بعد الأكل مع كوب ماء كبير.';
  static const String foodParacetamolAvoid =
      'تجنب تجاوز 8 حبات (4000 ملغ) في 24 ساعة، وتجنب الجمع بينه وبين أدوية الرشح التي تحتوي عليه.';
  static const String foodParacetamolMissed =
      'المسكن يؤخذ عند اللزوم والشعور بالألم فقط.';

  static const String foodGeneralMeal =
      'يفضل تناوله بعد وجبة خفيفة مع كوب كامل من الماء.';
  static const String foodGeneralAvoid =
      'تجنب تناول المشروبات الكحولية أو المنبهات بكثرة مع العلاج.';
  static const String foodGeneralMissed =
      'تناول الجرعة حين تذكرها، ولا تأخذ جرعتين معاً في نفس الوقت.';

  // Punctuation & Date separators
  static const String arabicComma = '، ';
  static const String arabicDash = ' - ';

  // Interaction Search Keywords
  static const List<String> paracetamolSearchKeywords = [
    'بنادول',
    'panadol',
    'باراسيتامول',
    'paracetamol',
    'فيفادول',
    'fevadol',
    'سيتامول',
    'cetamol',
    'ادول',
    'adol',
    'كومتركس',
    'comtrex',
    'كولد',
    'cold',
  ];

  static const List<String> nsaidSearchKeywords = [
    'بروفين',
    'brufen',
    'ايبوبروفين',
    'ibuprofen',
    'فولتارين',
    'voltaren',
    'ديكلوفيناك',
    'diclofenac',
    'اسبرين',
    'aspirin',
    'رومافين',
    'cataflam',
    'كتافلام',
  ];

  static const List<String> antibioticSearchKeywords = [
    'سيبرو',
    'cipro',
    'دوكسي',
    'doxy',
    'تيتراسايكلين',
    'اوجمينتين',
    'augmentin',
  ];

  static const List<String> cardiacSearchKeywords = ['كونكور', 'concor', 'ضغط'];

  static const List<String> mineralSearchKeywords = [
    'كالسيوم',
    'calcium',
    'حديد',
    'iron',
    'حموضة',
    'antacid',
    'رينيه',
    'جافيسكون',
  ];

  // Automatic Color & Auto First-Dose Scheduling
  static const String autoColorSelected = 'تم تحديد لون الدواء تلقائياً';
  static const String autoColorHint =
      'يتم اختيار لون مميز لكل دواء تلقائياً لتمييزه بسهولة';
  static const String firstDoseAnchorTitle = 'موعد أول جرعة أخذتها:';
  static const String firstDoseAnchorDesc =
      'حدد فقط متى أخذت أول جرعة، وسيقوم التطبيق ببدء الجدول وحساب كافة المواعيد التالية تلقائياً!';
  static const String doseFrequencyTitle = 'تكرار الجرعات:';
  static const String freqOnceDaily = 'مرة واحدة يومياً (كل 24 ساعة)';
  static const String freqTwiceDaily = 'مرتين يومياً (كل 12 ساعة)';
  static const String freqThreeTimes = '3 مرات يومياً (كل 8 ساعات)';
  static const String freqFourTimes = '4 مرات يومياً (كل 6 ساعات)';
  static const String freqEveryXHours = 'فاصل ساعات مخصص';
  static const String tookItNowBtn = 'أخذتها الآن (الوقت الحالي)';
  static const String changeFirstDoseTime = 'تغيير موعد أول جرعة';
  static const String autoCalculatedTimesTitle = 'المواعيد المحسوبة تلقائياً:';
  static String autoCalculatedTimesSubtitle(int count) =>
      '$count جرعات مجدولة تلقائياً بدءاً من موعد أول جرعة';
  static String doseNumberTitle(int num, String time) => 'الجرعة $num: $time';
  static const String nextDoseCalculatedFromLast =
      'الجرعة القادمة محسوبة تلقائياً بناءً على موعد آخر جرعة';
  static String lastDoseTakenAtText(String time) => 'آخر جرعة أُخذت: $time';
  static String nextDoseScheduledAtText(String time, int hours) =>
      'الجرعة التالية بعد $hours ساعات: الساعة $time';

  // Backup & Restore across reinstall
  static const String backupRestoreTitle = 'النسخ الاحتياطي واسترجاع الأدوية';
  static const String backupRestoreSubtitle =
      'بياناتك محفوظة؛ إذا حذفت التطبيق وأعدت تثبيته تُسترجع أدويتك تلقائياً';
  static const String exportBackupBtn = 'حفظ نسخة احتياطية للجهاز';
  static const String restoreBackupBtn = 'استرجاع أدويتي السابقة';
  static const String autoRestoreSuccess =
      'تم استرجاع أدويتك وبياناتك السابقة تلقائياً بنجاح!';
  static const String manualRestoreSuccess = 'تم استرجاع جميع الأدوية بنجاح!';
  static const String noBackupFound =
      'لم يتم العثور على ملف نسخة احتياطية سابقة في الجهاز';
  static const String backupSavedSuccess =
      'تم حفظ نسخة احتياطية بنجاح في مجلد التنزيلات (Download)';
  static const String backupAutoProtected =
      'أدويتك محمية تلقائياً بنسخ احتياطي محلي وسحابي';

  // Delete Actions
  static const String deleteMedicineTitle = 'حذف هذا الدواء';
  static const String deleteMedicineButton = 'حذف الدواء';
  static const String confirmDeleteMedicinePrompt =
      'هل أنت متأكد من رغبتك في حذف هذا الدواء؟ سيتم حذف جميع جرعاته ومواعيده نهائياً.';
  static const String confirmDeleteBtn = 'نعم، احذف الدواء';
  static const String cancelBtn = 'إلغاء';

  // Barcode / QR Scanner
  static const String scanBarcodeBtn = 'مسح باركود العلبة';
  static const String scanBarcodeTooltip =
      'مسح الباركود أو رمز الاستجابة السريعة بالكاميرا';
  static const String scanBarcodeTitle = 'ماسح باركود علبة الدواء';
  static const String scanBarcodeSubtitle =
      'وجّه الكاميرا نحو باركود العلبة (EAN / QR / DataMatrix)';
  static const String torchOn = 'تشغيل الإضاءة';
  static const String torchOff = 'إيقاف الإضاءة';
  static const String switchCamera = 'تبديل الكاميرا';
  static const String drugRecognized = 'تم التعرف على الدواء بنجاح!';
  static const String drugNotRecognized =
      'تم قراءة الباركود، ولم يتم العثور على تطابق بالموسوعة';
  static const String useDrugData = 'استخدام وتعبئة بيانات الدواء فوراً';
  static const String scanAgain = 'مسح علبة أخرى';
  static const String manualBarcodeInput = 'إدخال رقم الباركود يدوياً';
  static const String enterBarcodeDialogTitle = 'إدخال كود الباركود للبحث';
  static const String barcodeFieldHint = 'مثال: 6291003440019';
  static const String searchAndApply = 'بحث ومطابقة';
  static const String cameraPermissionRequired =
      'يرجى تفعيل صلاحية الكاميرا لمسح الباركود';
  static const String scannedBarcodeLabel = 'الباركود: ';

  // Home Pharmacy QR Sharing & Synchronization
  static const String sharePharmacyQrBtn = 'مشاركة الصيدلية عبر QR';
  static const String sharePharmacyTooltip =
      'مشاركة هذه الصيدلية مع أفراد العائلة عبر رمز QR أو كود المشاركة';
  static const String pharmacyQrTitle = 'مشاركة صيدلية المنزل';
  static const String pharmacyQrSubtitle =
      'امسح هذا الرمز من هاتف أي فرد بالعائلة للانضمام الفوري ومزامنة المخزون';
  static const String scanPharmacyQrBtn = 'مسح رمز QR للانضمام';
  static const String scanPharmacyQrSubtitle =
      'وجّه الكاميرا نحو رمز QR على هاتف مدير الصيدلية أو أحد أفرادها';
  static const String copyPharmacyCodeBtn = 'نسخ كود المشاركة للواتساب';
  static const String pharmacyCodeCopied =
      'تم نسخ كود الصيدلية إلى الحافظة! يمكنك إرساله بالواتساب لأفراد أسرتك.';
  static const String pastePharmacyCodeBtn = 'لصق كود المشاركة';
  static const String pastePharmacyCodeTitle = 'الانضمام عبر كود مشاركة نصي';
  static const String pastePharmacyCodeHint =
      'الصق هنا كود الصيدلية (يبدأ بـ DAWAAI_PHARMACY_V1:)';
  static const String pastePharmacyCodeConfirm = 'انضمام ومزامنة الآن';
  static const String pharmacyImportSuccess =
      'تم الانضمام ومزامنة أدوية ومخزون الصيدلية بنجاح!';
  static const String pharmacyImportFailed =
      'رمز الصيدلية غير صالح أو تالف، تأكد من نسخه كاملاً.';
  static const String pharmacyQrInstructions =
      '• افتح التطبيق على الهاتف الآخر.\n• اضغط على (مسح رمز QR للانضمام) من تبويب خزانة الأدوية.\n• أو انسخ الكود وأرسله عبر واتساب وسيتم الانضمام بضغطة زر.';
}
