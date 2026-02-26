import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../quran/data/models/juz_data.dart';
import '../../../quran/presentation/bloc/surah/surah_bloc.dart';
import '../../../quran/presentation/bloc/surah/surah_state.dart';
import '../../../quran/presentation/screens/surah_detail_screen.dart';
import '../cubit/wird_cubit.dart';
import '../cubit/wird_state.dart';
import '../../data/wird_service.dart';
import '../../data/quran_boundaries.dart';

// ── Surah Arabic-name fallback map (number → Arabic name) ─────────────────
const Map<int, String> _surahArabicNames = {
  1: 'الفاتحة', 2: 'البقرة', 3: 'آل عمران', 4: 'النساء', 5: 'المائدة',
  6: 'الأنعام', 7: 'الأعراف', 8: 'الأنفال', 9: 'التوبة', 10: 'يونس',
  11: 'هود', 12: 'يوسف', 13: 'الرعد', 14: 'إبراهيم', 15: 'الحجر',
  16: 'النحل', 17: 'الإسراء', 18: 'الكهف', 19: 'مريم', 20: 'طه',
  21: 'الأنبياء', 22: 'الحج', 23: 'المؤمنون', 24: 'النور', 25: 'الفرقان',
  26: 'الشعراء', 27: 'النمل', 28: 'القصص', 29: 'العنكبوت', 30: 'الروم',
  31: 'لقمان', 32: 'السجدة', 33: 'الأحزاب', 34: 'سبأ', 35: 'فاطر',
  36: 'يس', 37: 'الصافات', 38: 'ص', 39: 'الزمر', 40: 'غافر',
  41: 'فصلت', 42: 'الشورى', 43: 'الزخرف', 44: 'الدخان', 45: 'الجاثية',
  46: 'الأحقاف', 47: 'محمد', 48: 'الفتح', 49: 'الحجرات', 50: 'ق',
  51: 'الذاريات', 52: 'الطور', 53: 'النجم', 54: 'القمر', 55: 'الرحمن',
  56: 'الواقعة', 57: 'الحديد', 58: 'المجادلة', 59: 'الحشر', 60: 'الممتحنة',
  61: 'الصف', 62: 'الجمعة', 63: 'المنافقون', 64: 'التغابن', 65: 'الطلاق',
  66: 'التحريم', 67: 'الملك', 68: 'القلم', 69: 'الحاقة', 70: 'المعارج',
  71: 'نوح', 72: 'الجن', 73: 'المزمل', 74: 'المدثر', 75: 'القيامة',
  76: 'الإنسان', 77: 'المرسلات', 78: 'النبأ', 79: 'النازعات', 80: 'عبس',
  81: 'التكوير', 82: 'الانفطار', 83: 'المطففين', 84: 'الانشقاق',
  85: 'البروج', 86: 'الطارق', 87: 'الأعلى', 88: 'الغاشية', 89: 'الفجر',
  90: 'البلد', 91: 'الشمس', 92: 'الليل', 93: 'الضحى', 94: 'الشرح',
  95: 'التين', 96: 'العلق', 97: 'القدر', 98: 'البينة', 99: 'الزلزلة',
  100: 'العاديات', 101: 'القارعة', 102: 'التكاثر', 103: 'العصر',
  104: 'الهمزة', 105: 'الفيل', 106: 'قريش', 107: 'الماعون', 108: 'الكوثر',
  109: 'الكافرون', 110: 'النصر', 111: 'المسد', 112: 'الإخلاص',
  113: 'الفلق', 114: 'الناس',
};

// ── Arabic helpers ─────────────────────────────────────────────────────────
String _arabicNumerals(int n) {
  const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}

const _arabicMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String _formatDateAr(DateTime d) =>
    '${_arabicNumerals(d.day)} ${_arabicMonths[d.month - 1]} ${_arabicNumerals(d.year)}';

String _formatDateEn(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ── Time formatting helper ──────────────────────────────────────────────────

String _formatTime12h(TimeOfDay tod, {required bool isAr}) {
  final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
  final m = tod.minute.toString().padLeft(2, '0');
  final suffix = tod.period == DayPeriod.am
      ? (isAr ? 'ص' : 'AM')
      : (isAr ? 'م' : 'PM');
  if (isAr) {
    return '${_arabicNumerals(h)}:${m.split('').map((c) => ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'][int.parse(c)]).join()} $suffix';
  }
  return '$h:$m $suffix';
}

// ── Main Screen ─────────────────────────────────────────────────────────────

class WirdScreen extends StatefulWidget {
  const WirdScreen({super.key});

  @override
  State<WirdScreen> createState() => _WirdScreenState();
}

class _WirdScreenState extends State<WirdScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<WirdCubit>().load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      context.read<WirdCubit>().refreshNotificationsIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        // Transparent so the gradient AppBar bleeds nicely on iOS.
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, isAr),
        body: BlocConsumer<WirdCubit, WirdState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state is WirdInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WirdNoPlan) {
              return _NoPlanView(isAr: isAr);
            }
            if (state is WirdPlanLoaded) {
              return _ActivePlanView(
                plan: state.plan,
                isAr: isAr,
                reminderHour: state.reminderHour,
                reminderMinute: state.reminderMinute,
                lastReadSurah: state.lastReadSurah,
                lastReadAyah: state.lastReadAyah,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isAr) {
    return AppBar(
      title: Text(isAr ? 'الورد اليومي' : 'Daily Wird'),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
          ),
        ),
      ),
    );
  }
}

// ── No-plan View ────────────────────────────────────────────────────────────

class _NoPlanView extends StatelessWidget {
  final bool isAr;
  const _NoPlanView({required this.isAr});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // ── Decorative header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '﴿ وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا ﴾',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiriQuran(
                    fontSize: 20,
                    color: AppColors.primary,
                    height: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'سورة المزمل: ٤'
                      : 'Surah Al-Muzzammil: 4',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isAr ? 'اختر نوع وردك اليومي' : 'Choose your daily wird plan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 20),

          // ── Ramadan Khatm Card ──────────────────────────────────────────
          _PlanTypeCard(
            isAr: isAr,
            isDark: isDark,
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFFD4AF37),
            gradientColors: const [Color(0xFF2E1760), Color(0xFF0D5E3A)],
            title: isAr ? 'ختمة رمضان' : 'Ramadan Khatm',
            subtitle: isAr
                ? 'ختم القرآن الكريم في ٣٠ يومًا\nجزء واحد كل يوم'
                : 'Complete the Quran in 30 days\nOne Juz per day',
            badge: isAr ? '٣٠ يومًا' : '30 days',
            onTap: () => _showSetupSheet(context, isRamadan: true),
          ),
          const SizedBox(height: 14),

          // ── Regular Khatm Card ──────────────────────────────────────────
          _PlanTypeCard(
            isAr: isAr,
            isDark: isDark,
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.secondary,
            gradientColors: const [AppColors.gradientStart, AppColors.gradientEnd],
            title: isAr ? 'ختمة منتظمة' : 'Regular Khatm',
            subtitle: isAr
                ? 'حدد هدفك الخاص لختم القرآن الكريم'
                : 'Set your own target to complete the Quran',
            badge: isAr ? 'مرن' : 'Flexible',
            onTap: () => _showSetupSheet(context, isRamadan: false),
          ),
          const SizedBox(height: 24),

          // ── Info footer ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkCard : AppColors.surfaceVariant)
                  .withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr
                        ? 'يمكنك تعديل الخطة أو إعادة ضبطها في أي وقت.'
                        : 'You can modify or reset your plan at any time.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupSheet(BuildContext context, {required bool isRamadan}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<WirdCubit>(),
        child: _SetupSheet(isRamadan: isRamadan, isAr: isAr),
      ),
    );
  }
}

// ── Plan Type Selector Card ─────────────────────────────────────────────────

class _PlanTypeCard extends StatelessWidget {
  final bool isAr;
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _PlanTypeCard({
    required this.isAr,
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: gradientColors.last.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkCard, AppColors.darkSurface]
                  : [Colors.white, Colors.white],
            ),
            border: Border.all(
              color: gradientColors.last.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: isAr
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isAr
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Setup Bottom Sheet ──────────────────────────────────────────────────────

/// Egypt Ramadan 2026 start date — shown as the default suggestion.
final _kRamadan2026Egypt = DateTime(2026, 2, 19);

class _SetupSheet extends StatefulWidget {
  final bool isRamadan;
  final bool isAr;

  const _SetupSheet({required this.isRamadan, required this.isAr});

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  static const _regularOptions = [7, 10, 14, 20, 30, 60];

  // ── Shared state
  late DateTime _startDate;
  TimeOfDay? _reminderTime;

  // ── Ramadan-specific
  bool _alreadyStarted = false;
  bool _markPastDaysComplete = true;

  // ── Regular-specific
  late int _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = 30;
    _startDate = widget.isRamadan ? _kRamadan2026Egypt : DateTime.now();
  }

  /// Number of days that have passed since the chosen start date (0 if today).
  int get _pastDaysCount {
    if (!_alreadyStarted) return 0;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final startOnly =
        DateTime(_startDate.year, _startDate.month, _startDate.day);
    final diff = todayOnly.difference(startOnly).inDays;
    return diff.clamp(0, 29);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: widget.isAr ? 'اختر تاريخ البدء' : 'Select start date',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? const TimeOfDay(hour: 20, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: widget.isAr ? 'وقت التذكير اليومي' : 'Daily reminder time',
    );
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _confirm() async {
    // Build list of auto-completed past days.
    final List<int> completedDays = [];
    if (widget.isRamadan && _alreadyStarted && _markPastDaysComplete) {
      for (var i = 1; i <= _pastDaysCount; i++) {
        completedDays.add(i);
      }
    }

    // For Ramadan: ALWAYS anchor to the real Ramadan start date so that missed
    // days surface correctly. When user says "No, starting today" we still start
    // from the Ramadan begin, but completedDays stays empty → they show as missed.
    final startDate = widget.isRamadan
        ? (_alreadyStarted ? _startDate : _kRamadan2026Egypt)
        : _startDate;

    await context.read<WirdCubit>().setupPlan(
          type: widget.isRamadan ? WirdType.ramadan : WirdType.regular,
          targetDays: widget.isRamadan ? 30 : _selectedDays,
          startDate: startDate,
          completedDays: completedDays,
          reminderHour: _reminderTime?.hour,
          reminderMinute: _reminderTime?.minute,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = widget.isAr;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAr
                  ? (widget.isRamadan
                      ? '🌙  إعداد ختمة رمضان'
                      : '📖  إعداد الختمة المنتظمة')
                  : (widget.isRamadan
                      ? '🌙  Setup Ramadan Khatm'
                      : '📖  Setup Regular Khatm'),
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Ramadan section ──────────────────────────────────────────
            if (widget.isRamadan) ..._buildRamadanSection(isDark, isAr),

            // ── Regular section ──────────────────────────────────────────
            if (!widget.isRamadan) ..._buildRegularSection(isDark, isAr),

            // ── Reminder time (both plan types) ──────────────────────────
            ..._buildReminderSection(isDark, isAr),

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: Text(
                isAr ? 'ابدأ الآن' : 'Start Now',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ramadan section ────────────────────────────────────────────────────────

  /// Days elapsed since Ramadan begin (used for the "No, start today" badge).
  int get _ramadanElapsedDays {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final start = DateTime(
        _kRamadan2026Egypt.year,
        _kRamadan2026Egypt.month,
        _kRamadan2026Egypt.day);
    return todayOnly.difference(start).inDays.clamp(0, 29);
  }

  List<Widget> _buildRamadanSection(bool isDark, bool isAr) {
    final past = _pastDaysCount;
    final elapsed = _ramadanElapsedDays;
    return [
      Text(
        isAr
            ? 'هل واظبت على القراءة منذ بداية رمضان؟'
            : 'Have you been reading since Ramadan started?',
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _OptionButton(
              label: isAr ? 'نعم، بدأت' : 'Yes, I started',
              icon: Icons.check_circle_rounded,
              selected: _alreadyStarted,
              isDark: isDark,
              onTap: () => setState(() {
                _alreadyStarted = true;
                _startDate = _kRamadan2026Egypt;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OptionButton(
              label: isAr ? 'لا، لم أواظب' : 'No, I missed days',
              icon: Icons.history_edu_rounded,
              selected: !_alreadyStarted,
              isDark: isDark,
              onTap: () => setState(() {
                _alreadyStarted = false;
              }),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // ── Notice for "No, start today" path ────────────────────────────
      if (!_alreadyStarted && elapsed > 0) ...[  
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF8F00).withValues(alpha: 0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.info_outline_rounded,
                    color: Color(0xFFE65100), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'ستظهر الأيام الـ ${_arabicNumerals(elapsed)} الماضية كأيام فائتة في «ورد القضاء» — يمكنك تعويضها في أي وقت بإذن الله.'
                      : '$elapsed missed day${elapsed == 1 ? "" : "s"} will appear in the Makeup section so you can catch up at your own pace.',
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    color: Color(0xFFBF360C),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],


      // If already started: date picker + past days switch
      if (_alreadyStarted) ...[
        Text(
          isAr ? 'متى بدأت؟' : 'When did you start?',
          textAlign: isAr ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  isAr ? _formatDateAr(_startDate) : _formatDateEn(_startDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                const Icon(Icons.edit_rounded,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (past > 0) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: AppColors.secondary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAr
                        ? 'مرّت ${_arabicNumerals(past)} ${past == 1 ? "يوم" : "أيام"} من الورد حتى الآن'
                        : '$past day${past == 1 ? "" : "s"} of Ramadan have passed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: isAr
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr
                            ? 'حدّد الأيام الماضية كمكتملة'
                            : 'Mark past days as complete',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      Text(
                        isAr
                            ? '${_arabicNumerals(past)} أيام ستُضاف لتقدمك تلقائيًا'
                            : '$past days will be added to your progress',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _markPastDaysComplete,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) =>
                      setState(() => _markPastDaysComplete = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],

      // Info card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF2E1760).withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.08),
          ]),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAr
                    ? 'جزء واحد كاملاً كل يوم — تختم القرآن بإذن الله في ٣٠ يومًا'
                    : 'One full Juz per day — complete the Quran in 30 days, Inshallah',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
    ];
  }

  // ── Regular plan section ───────────────────────────────────────────────────

  List<Widget> _buildRegularSection(bool isDark, bool isAr) {
    return [
      Text(
        isAr ? 'مدة الختمة' : 'Plan Duration',
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: isAr ? WrapAlignment.end : WrapAlignment.start,
        children: _regularOptions.map((days) {
          final selected = _selectedDays == days;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => _selectedDays = days),
            label: Text(
              isAr ? '${_arabicNumerals(days)} يومًا' : '$days days',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected
                    ? AppColors.onPrimary
                    : AppColors.textPrimary,
              ),
            ),
            selectedColor: AppColors.primary,
            backgroundColor:
                isDark ? AppColors.darkCard : AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            side: BorderSide(
                color: selected ? AppColors.primary : AppColors.divider),
          );
        }).toList(),
      ),
      const SizedBox(height: 6),
      Text(
        isAr
            ? _getDurationHint(_selectedDays, isAr: true)
            : _getDurationHint(_selectedDays, isAr: false),
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
      ),
      const SizedBox(height: 20),
      Text(
        isAr ? 'تاريخ البدء' : 'Start Date',
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _startDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked != null) setState(() => _startDate = picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                isAr ? _formatDateAr(_startDate) : _formatDateEn(_startDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.edit_rounded,
                  color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // ── Reminder time section ──────────────────────────────────────────────────

  List<Widget> _buildReminderSection(bool isDark, bool isAr) {
    final isSet = _reminderTime != null;
    return [
      Text(
        isAr ? 'وقت التذكير اليومي' : 'Daily Reminder Time',
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        isAr
            ? 'ستصلك إشعارات بصوت مميز، مع تذكير كل ٤ ساعات إن لم تسجّل ورد اليوم'
            : 'A distinctive-sound notification fires at your time, with follow-ups every 4 h if not marked',
        textAlign: isAr ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
      ),
      const SizedBox(height: 10),
      InkWell(
        onTap: _pickReminderTime,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSet
                ? AppColors.primary.withValues(alpha: 0.08)
                : (isDark ? AppColors.darkCard : AppColors.surfaceVariant),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSet
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                color: isSet ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                isSet
                    ? _formatTime12h(_reminderTime!, isAr: isAr)
                    : (isAr
                        ? 'اختر وقتًا (اختياري)'
                        : 'Pick a time (optional)'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isSet ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Icon(
                isSet ? Icons.edit_rounded : Icons.add_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
    ];
  }

  String _getDurationHint(int days, {required bool isAr}) {
    if (days <= 30) {
      final juzPerDay = (30 / days).ceil();
      final extra = juzPerDay > 1
          ? (isAr
              ? ' ($juzPerDay أجزاء يوميًا)'
              : ' ($juzPerDay juz/day)')
          : (isAr ? ' (جزء واحد يوميًا)' : ' (1 juz/day)');
      return isAr
          ? 'تختم في $days يومًا$extra'
          : 'Complete in $days days$extra';
    }
    final portions = days ~/ 30;
    return isAr
        ? 'جزء واحد كل $portions أيام'
        : '1 juz every $portions days';
  }
}

// ── Active Plan View ────────────────────────────────────────────────────────

class _ActivePlanView extends StatelessWidget {
  final WirdPlan plan;
  final bool isAr;
  final int? reminderHour;
  final int? reminderMinute;
  final int? lastReadSurah;
  final int? lastReadAyah;

  const _ActivePlanView({
    required this.plan,
    required this.isAr,
    this.reminderHour,
    this.reminderMinute,
    this.lastReadSurah,
    this.lastReadAyah,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = plan.currentDay;
    final todayComplete = plan.isDayComplete(today);
    final range = getReadingRangeForDay(today, plan.targetDays);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Progress Header ─────────────────────────────────────────────
          _ProgressHeader(plan: plan, isAr: isAr, isDark: isDark),
          const SizedBox(height: 18),

          // ── Late Warning ─────────────────────────────────────────────────
          _LateWarningCard(plan: plan, isAr: isAr, isDark: isDark),

          // ── Today's Wird Card ───────────────────────────────────────────
          _TodayCard(
            plan: plan,
            today: today,
            range: range,
            isComplete: todayComplete,
            isAr: isAr,
            isDark: isDark,
            lastReadSurah: lastReadSurah,
            lastReadAyah: lastReadAyah,
          ),
          const SizedBox(height: 18),

          // ── Makeup Wird Card (shown only after today's wird is done) ──────
          _MakeupCard(
            plan: plan,
            isAr: isAr,
            isDark: isDark,
            todayComplete: todayComplete,
          ),

          // ── Days Grid ───────────────────────────────────────────────────
          _DaysGrid(plan: plan, isAr: isAr, isDark: isDark),
          const SizedBox(height: 18),

          // ── Reminder time card ──────────────────────────────────────────
          _ReminderCard(
            isAr: isAr,
            isDark: isDark,
            reminderHour: reminderHour,
            reminderMinute: reminderMinute,
          ),
          const SizedBox(height: 18),

          // ── Reset / Delete ──────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isAr ? 'إعادة ضبط الخطة' : 'Reset Plan'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تأكيد إعادة الضبط' : 'Confirm Reset'),
        content: Text(
          isAr
              ? 'هل تريد حذف خطتك الحالية والبدء من جديد؟'
              : 'Delete your current plan and start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<WirdCubit>().deletePlan();
              Navigator.pop(ctx);
            },
            child: Text(
              isAr ? 'حذف' : 'Delete',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Late Warning Card ─────────────────────────────────────────────────────

class _LateWarningCard extends StatelessWidget {
  final WirdPlan plan;
  final bool isAr;
  final bool isDark;

  const _LateWarningCard({
    required this.plan,
    required this.isAr,
    required this.isDark,
  });

  // ── Juz label helper ──────────────────────────────────────────────────────

  /// Formats a juz count (may be fractional) into a readable string.
  /// Rounds up to the nearest quarter-juz for display.
  static String _juzLabel(double juz, bool ar) {
    if (juz <= 0) return ar ? '٠ جزء' : '0 juz';
    // Ceiling to nearest 0.25
    final double rounded = (juz * 4).ceil() / 4;
    final int whole = rounded.floor();
    final double frac = rounded - whole;

    if (ar) {
      // Fraction label
      String fracLabel;
      if (frac == 0) {
        fracLabel = '';
      } else if (frac <= 0.26) {
        fracLabel = ' وربع';
      } else if (frac <= 0.51) {
        fracLabel = ' ونصف';
      } else {
        fracLabel = ' وثلاثة أرباع';
      }
      if (whole == 0) {
        if (frac <= 0.26) return 'ربع جزء';
        if (frac <= 0.51) return 'نصف جزء';
        return 'ثلاثة أرباع جزء';
      }
      final juzWord = whole == 1 ? 'جزء' : 'أجزاء';
      return '${_arabicNumerals(whole)} $juzWord$fracLabel';
    } else {
      String fracLabel;
      if (frac == 0) {
        fracLabel = '';
      } else if (frac <= 0.26) {
        fracLabel = '¼';
      } else if (frac <= 0.51) {
        fracLabel = '½';
      } else {
        fracLabel = '¾';
      }
      if (whole == 0) return '$fracLabel juz';
      return '$whole$fracLabel juz';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Guard: plan already complete ─────────────────────────────────────
    if (plan.isComplete) return const SizedBox.shrink();

    final int today = plan.currentDay; // 1-indexed, clamped [1, targetDays]
    // Can't be "late" on the first day — nothing has elapsed yet.
    if (today <= 1) return const SizedBox.shrink();

    // Sanitise completed set to valid day numbers only.
    final Set<int> done = plan.completedDays
        .where((d) => d >= 1 && d <= plan.targetDays)
        .toSet();

    // ── How many past days are missed? ────────────────────────────────────
    // "Past" = days 1 .. (today - 1) that are NOT in done.
    int daysBehind = 0;
    for (int d = 1; d < today; d++) {
      if (!done.contains(d)) daysBehind++;
    }
    if (daysBehind <= 0) return const SizedBox.shrink();

    // ── Remaining work from today onward ──────────────────────────────────
    // Count uncompleted days from today..targetDays.
    int remainingUncompleted = 0;
    for (int d = today; d <= plan.targetDays; d++) {
      if (!done.contains(d)) remainingUncompleted++;
    }

    // Calendar days left including today (always >= 1 because currentDay is clamped).
    final int daysLeft = plan.targetDays - today + 1;

    // ── Juz math ──────────────────────────────────────────────────────────
    // Each plan-day represents this many juz (e.g. 1.0 for 30-day Ramadan khatm,
    // 0.5 for 60-day, 2.0 for 15-day).
    final double juzPerPlanDay = 30.0 / plan.targetDays;

    // Total juz still needed = future uncompleted days + missed past days.
    // Both must be read to finish the khatm, so we include daysBehind as well.
    final double juzNeeded = (remainingUncompleted + daysBehind) * juzPerPlanDay;

    // Juz per calendar day required to finish exactly on schedule.
    final double catchUpRate = juzNeeded / daysLeft;

    // Normal (on-schedule) rate.
    final double normalRate = juzPerPlanDay; // same as 30/targetDays

    // Considered impossible if it would require >8 juz/day.
    final bool canCatchUp = catchUpRate <= 8.0;

    // ── Build text ────────────────────────────────────────────────────────
    final String behindStr = isAr
        ? '${_arabicNumerals(daysBehind)} ${daysBehind == 1 ? "يوم" : "أيام"}'
        : '$daysBehind ${daysBehind == 1 ? "day" : "days"}';

    final String daysBehindText = isAr
        ? 'أنت متأخر $behindStr عن جدول الورد.'
        : 'You are $behindStr behind your wird schedule.';

    final String adviceText;
    if (!canCatchUp) {
      adviceText = isAr
          ? 'التأخر كبير — حاول إكمال ما فاتك تدريجياً بإذن الله، كل جهد يُحتسب.'
          : 'The gap is large — try to catch up gradually. Every effort counts.';
    } else if (daysLeft == 1) {
      // Last day of the plan.
      adviceText = isAr
          ? 'هذا آخر يوم — اقرأ ${_juzLabel(juzNeeded, true)} اليوم لإتمام الختمة.'
          : 'Last day — read ${_juzLabel(juzNeeded, false)} today to complete your khatm.';
    } else if (catchUpRate <= normalRate + 0.01) {
      // Essentially on track (daysBehind all already-marked days? Rare edge case).
      adviceText = isAr
          ? 'تبقى ${_juzLabel(juzNeeded, true)} في ${_arabicNumerals(daysLeft)} ${daysLeft == 1 ? "يوم" : "أيام"} — واصل بالحجم المعتاد.'
          : '${_juzLabel(juzNeeded, false)} left in $daysLeft ${daysLeft == 1 ? "day" : "days"} — keep your usual pace.';
    } else {
      adviceText = isAr
          ? 'لإنهاء الختمة في موعدها، اقرأ ${_juzLabel(catchUpRate, true)} يومياً — تبقى ${_juzLabel(juzNeeded, true)} في ${_arabicNumerals(daysLeft)} ${daysLeft == 1 ? "يوم" : "أيام"}.'
          : 'To finish on time, read ${_juzLabel(catchUpRate, false)}/day — ${_juzLabel(juzNeeded, false)} left in $daysLeft ${daysLeft == 1 ? "day" : "days"}.';
    }

    final Color cardBg =
        isDark ? const Color(0xFF2D1F00) : const Color(0xFFFFF3CD);
    final Color textClr =
        isDark ? const Color(0xFFFFD060) : const Color(0xFF7A4F00);
    final Color iconClr =
        isDark ? const Color(0xFFFFD060) : const Color(0xFFB07800);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6A817), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber_rounded,
              color: iconClr,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  daysBehindText,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: textClr,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  adviceText,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: textClr,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder Card ────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final bool isAr;
  final bool isDark;
  final int? reminderHour;
  final int? reminderMinute;

  const _ReminderCard({
    required this.isAr,
    required this.isDark,
    this.reminderHour,
    this.reminderMinute,
  });

  bool get _hasReminder => reminderHour != null && reminderMinute != null;

  @override
  Widget build(BuildContext context) {
    final String timeLabel;
    if (_hasReminder) {
      final tod = TimeOfDay(hour: reminderHour!, minute: reminderMinute!);
      timeLabel = _formatTime12h(tod, isAr: isAr);
    } else {
      timeLabel = isAr ? 'لم يُحدَّد وقت' : 'Not set';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasReminder
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hasReminder
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color:
                  _hasReminder ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'وقت التذكير اليومي' : 'Daily Reminder',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _hasReminder
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: _hasReminder
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _editReminder(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              isAr ? 'تعديل' : 'Edit',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editReminder(BuildContext context) async {
    final initial = _hasReminder
        ? TimeOfDay(hour: reminderHour!, minute: reminderMinute!)
        : const TimeOfDay(hour: 20, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isAr ? 'وقت التذكير اليومي' : 'Daily reminder time',
    );
    if (picked != null && context.mounted) {
      await context
          .read<WirdCubit>()
          .updateReminderTime(picked.hour, picked.minute);
    }
  }
}


class _ProgressHeader extends StatelessWidget {
  final WirdPlan plan;
  final bool isAr;
  final bool isDark;

  const _ProgressHeader(
      {required this.plan, required this.isAr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (plan.progressPercent * 100).round();
    final isRamadan = plan.type == WirdType.ramadan;
    final planName = isRamadan
        ? (isAr ? 'ختمة رمضان' : 'Ramadan Khatm')
        : (isAr ? 'ختمة منتظمة' : 'Regular Khatm');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRamadan
              ? const [Color(0xFF1A0050), Color(0xFF0D5E3A)]
              : [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRamadan
                        ? Icons.nightlight_round
                        : Icons.auto_stories_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    planName,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                isAr
                    ? '${_arabicNumerals(plan.completedDays.length)} / ${_arabicNumerals(plan.targetDays)}'
                    : '${plan.completedDays.length} / ${plan.targetDays}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.progressPercent,
              minHeight: 10,
              backgroundColor: Colors.white24,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isAr
                      ? 'بدأت: ${_formatDateAr(plan.startDate)}'
                      : 'Started: ${_formatDateEn(plan.startDate)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAr
                    ? 'الإنجاز: ${_arabicNumerals(pct)}٪'
                    : 'Progress: $pct%',
                style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Today's Wird Card ───────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  final WirdPlan plan;
  final int today;
  final ReadingRange range;
  final bool isComplete;
  final bool isAr;
  final bool isDark;
  final int? lastReadSurah;
  final int? lastReadAyah;

  const _TodayCard({
    required this.plan,
    required this.today,
    required this.range,
    required this.isComplete,
    required this.isAr,
    required this.isDark,
    this.lastReadSurah,
    this.lastReadAyah,
  });

  bool get _hasBookmark => lastReadSurah != null && lastReadAyah != null;

  // ── Surah name helper (prefers SurahBloc, falls back to hard-coded map) ───

  String _surahName(BuildContext context, int surahNum) {
    final surahState = context.read<SurahBloc>().state;
    if (surahState is SurahListLoaded) {
      final match =
          surahState.surahs.where((s) => s.number == surahNum).toList();
      if (match.isNotEmpty) {
        return isAr ? match.first.name : match.first.englishName;
      }
    }
    if (isAr) return _surahArabicNames[surahNum] ?? 'سورة $surahNum';
    return allJuzData
            .expand((j) => j.surahNumbers)
            .contains(surahNum)
        ? 'Surah $surahNum'
        : 'Surah $surahNum';
  }

  @override
  Widget build(BuildContext context) {
    // ── Identify today's juz (for the big header text) ───────────────────
    final juzList = WirdService.getJuzForDay(today, plan.targetDays);
    final firstJuzInfo =
        juzList.isNotEmpty ? allJuzData[juzList.first - 1] : null;

    // ── Reading range labels ─────────────────────────────────────────────
    final startName = _surahName(context, range.start.surah);
    final endName   = _surahName(context, range.end.surah);

    final String rangeLineAr;
    final String rangeLineEn;
    if (range.isSingleSurah) {
      rangeLineAr =
          '$startName  ${_arabicNumerals(range.start.ayah)} – ${_arabicNumerals(range.end.ayah)}';
      rangeLineEn = '$startName  ${range.start.ayah}–${range.end.ayah}';
    } else {
      rangeLineAr =
          'من $startName ${_arabicNumerals(range.start.ayah)} إلى $endName ${_arabicNumerals(range.end.ayah)}';
      rangeLineEn =
          'From $startName ${range.start.ayah} to $endName ${range.end.ayah}';
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isComplete ? AppColors.success : AppColors.secondary)
                .withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    isAr
                        ? 'اليوم ${_arabicNumerals(today)}'
                        : 'Day $today',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          isAr ? 'مكتمل ✓' : 'Done ✓',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Juz title (big Arabic name) ─────────────────────────────
            if (firstJuzInfo != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      WirdService.getDayDescription(today, plan.targetDays,
                          isArabic: true),
                      style: GoogleFonts.amiriQuran(
                        fontSize: 26,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstJuzInfo.arabicName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiriQuran(
                        fontSize: 17,
                        color: AppColors.secondary,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // ── Exact reading range card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'نطاق القراءة اليوم' : "Today's reading",
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr ? rangeLineAr : rangeLineEn,
                          textAlign:
                              isAr ? TextAlign.right : TextAlign.left,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Reading bookmark ─────────────────────────────────────────
            if (_hasBookmark) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded,
                        color: AppColors.secondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAr
                            ? 'وصلت إلى: ${_surahArabicNames[lastReadSurah] ?? "سورة $lastReadSurah"} آية ${_arabicNumerals(lastReadAyah!)}'
                            : 'Stopped at: ${_surahArabicNames[lastReadSurah] ?? "Surah $lastReadSurah"} $lastReadAyah',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.read<WirdCubit>().clearLastRead(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              children: [
                // Read button — navigates to bookmark pos or day start
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToRead(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      _hasBookmark
                          ? Icons.play_arrow_rounded
                          : (isAr
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_forward_ios_rounded),
                      size: 18,
                    ),
                    label: Text(
                      _hasBookmark
                          ? (isAr ? 'تابع القراءة' : 'Continue Reading')
                          : (isAr ? 'ابدأ القراءة' : 'Start Reading'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Update bookmark button
                if (!isComplete)
                  ElevatedButton(
                    onPressed: () => _showBookmarkDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary
                          .withValues(alpha: 0.12),
                      foregroundColor: AppColors.secondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              AppColors.secondary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    child: const Icon(Icons.bookmark_add_rounded, size: 20),
                  ),
                if (!isComplete) const SizedBox(width: 8),

                // Mark complete toggle
                ElevatedButton(
                  onPressed: () =>
                      context.read<WirdCubit>().toggleDayComplete(today),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isComplete
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.secondary.withValues(alpha: 0.15),
                    foregroundColor:
                        isComplete ? AppColors.success : AppColors.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isComplete
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.secondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: Icon(
                    isComplete
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigate to reading screen ──────────────────────────────────────────

  void _navigateToRead(BuildContext context) {
    // If user has a bookmark, resume from there; otherwise start from range start.
    final int targetSurah = _hasBookmark ? lastReadSurah! : range.start.surah;
    final int targetAyah  = _hasBookmark ? lastReadAyah!  : range.start.ayah;

    final surahName = _surahName(context, targetSurah);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailScreen(
          surahNumber: targetSurah,
          surahName: surahName,
          initialAyahNumber: targetAyah,
        ),
      ),
    );
  }

  // ── Bookmark / progress dialog ──────────────────────────────────────────

  void _showBookmarkDialog(BuildContext context) {
    // Determine default selection: bookmark if set, else range start.
    int selectedSurah = _hasBookmark ? lastReadSurah! : range.start.surah;
    int enteredAyah   = _hasBookmark ? lastReadAyah!  : range.start.ayah;
    final cubit = context.read<WirdCubit>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final maxAyah = kSurahAyahCounts[selectedSurah - 1];
          // Clamp entered ayah whenever surah changes.
          if (enteredAyah > maxAyah) enteredAyah = maxAyah;
          final ayahCtrl = TextEditingController(
              text: enteredAyah.toString());

          return AlertDialog(
            title: Text(isAr ? 'حدّث موضعك في القراءة' : 'Update Reading Position'),
            content: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isAr
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'السورة:' : 'Surah:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: selectedSurah,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(114, (i) {
                    final n = i + 1;
                    return DropdownMenuItem(
                      value: n,
                      child: Text(
                        isAr
                            ? '${_arabicNumerals(n)}. ${_surahArabicNames[n] ?? n.toString()}'
                            : '$n. Surah $n',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() {
                        selectedSurah = v;
                        enteredAyah = 1;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  isAr
                      ? 'رقم الآية (١ – ${_arabicNumerals(maxAyah)}):'
                      : 'Ayah number (1–$maxAyah):',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: ayahCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    hintText: '1 – $maxAyah',
                  ),
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n >= 1 && n <= maxAyah) {
                      enteredAyah = n;
                    }
                  },
                ),
              ],
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () {
                  final n = int.tryParse(ayahCtrl.text);
                  final ayah = (n != null &&
                          n >= 1 &&
                          n <= maxAyah)
                      ? n
                      : enteredAyah;
                  cubit.saveLastRead(selectedSurah, ayah);
                  Navigator.pop(ctx);
                },
                child: Text(isAr ? 'حفظ' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Days Grid ───────────────────────────────────────────────────────────────

class _DaysGrid extends StatelessWidget {
  final WirdPlan plan;
  final bool isAr;
  final bool isDark;

  const _DaysGrid(
      {required this.plan, required this.isAr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final today = plan.currentDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment:
            isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'تقدم الأيام' : 'Day Progress',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: plan.targetDays,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isCompleted = plan.isDayComplete(day);
              final isToday = day == today;
              final isFuture = day > today;

              Color bgColor;
              Color textColor;
              Color borderColor;

              if (isCompleted) {
                bgColor = AppColors.success;
                textColor = Colors.white;
                borderColor = AppColors.success;
              } else if (isToday) {
                bgColor = AppColors.secondary.withValues(alpha: 0.2);
                textColor = AppColors.accent;
                borderColor = AppColors.secondary;
              } else if (isFuture) {
                bgColor = isDark
                    ? AppColors.darkSurface
                    : AppColors.surfaceVariant;
                textColor = AppColors.textSecondary;
                borderColor = AppColors.divider;
              } else {
                // Past and not completed
                bgColor = AppColors.error.withValues(alpha: 0.08);
                textColor = AppColors.error.withValues(alpha: 0.7);
                borderColor = AppColors.error.withValues(alpha: 0.3);
              }

              return GestureDetector(
                onTap: () {
                  if (!isFuture) {
                    context.read<WirdCubit>().toggleDayComplete(day);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.secondary
                                  .withValues(alpha: 0.3),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : Text(
                            isAr
                                ? _arabicNumerals(day)
                                : day.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _LegendItem(
                  color: AppColors.success,
                  label: isAr ? 'مكتمل' : 'Done'),
              _LegendItem(
                  color: AppColors.secondary,
                  label: isAr ? 'اليوم' : 'Today'),
              _LegendItem(
                  color: AppColors.textSecondary,
                  label: isAr ? 'قادم' : 'Upcoming'),
              _LegendItem(
                  color: AppColors.error,
                  label: isAr ? 'لم يُقرأ' : 'Missed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Makeup Wird Card ────────────────────────────────────────────────────────

/// Appears below the today card whenever the user has missed past days.
/// Lets them pick a missed day, navigate to read its portion, and mark it done.
class _MakeupCard extends StatefulWidget {
  final WirdPlan plan;
  final bool isAr;
  final bool isDark;
  /// The makeup card is only revealed once the user has finished today's wird.
  final bool todayComplete;

  const _MakeupCard({
    required this.plan,
    required this.isAr,
    required this.isDark,
    required this.todayComplete,
  });

  @override
  State<_MakeupCard> createState() => _MakeupCardState();
}

class _MakeupCardState extends State<_MakeupCard> {
  /// Index into the sorted missed-days list (0 = oldest missed day).
  int _index = 0;

  static const _kOrange = Color(0xFFE65100);
  static const _kOrangeLight = Color(0xFFFFF3E0);
  static const _kOrangeBorder = Color(0xFFFF8F00);

  String _surahName(BuildContext context, int surahNum) {
    if (widget.isAr) return _surahArabicNames[surahNum] ?? 'سورة $surahNum';
    final surahState = context.read<SurahBloc>().state;
    if (surahState is SurahListLoaded) {
      final match = surahState.surahs.where((s) => s.number == surahNum).toList();
      if (match.isNotEmpty) return match.first.englishName;
    }
    return 'Surah $surahNum';
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isAr = widget.isAr;
    final isDark = widget.isDark;
    final today = plan.currentDay;

    // Only reveal after the user has completed today's wird.
    if (!widget.todayComplete) return const SizedBox.shrink();

    // All past days that are not yet complete, sorted oldest first.
    final List<int> missed = [
      for (int d = 1; d < today; d++)
        if (!plan.isDayComplete(d)) d,
    ];

    if (missed.isEmpty) return const SizedBox.shrink();

    // Keep index in bounds after days are marked complete.
    if (_index >= missed.length) _index = missed.length - 1;
    if (_index < 0) _index = 0;

    final day = missed[_index];
    final range = getReadingRangeForDay(day, plan.targetDays);
    final juzList = WirdService.getJuzForDay(day, plan.targetDays);
    final dayDesc = WirdService.getDayDescription(
        day, plan.targetDays, isArabic: isAr);

    final startName = _surahName(context, range.start.surah);
    final endName = _surahName(context, range.end.surah);

    final String rangeLine = range.isSingleSurah
        ? (isAr
            ? '$startName  ${_arabicNumerals(range.start.ayah)} – ${_arabicNumerals(range.end.ayah)}'
            : '$startName  ${range.start.ayah}–${range.end.ayah}')
        : (isAr
            ? 'من $startName ${_arabicNumerals(range.start.ayah)} إلى $endName ${_arabicNumerals(range.end.ayah)}'
            : 'From $startName ${range.start.ayah} to $endName ${range.end.ayah}');

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: _kOrangeBorder.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header bar ────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isDark
                  ? _kOrange.withValues(alpha: 0.15)
                  : _kOrangeLight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(
                bottom:
                    BorderSide(color: _kOrangeBorder.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_edu_rounded,
                      color: _kOrange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isAr
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'ورد القضاء' : 'Makeup Wird',
                        style: const TextStyle(
                          color: _kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        isAr
                            ? 'تبقى ${_arabicNumerals(missed.length)} ${missed.length == 1 ? "يوم" : "أيام"} لم تُقرأ بعد'
                            : '${missed.length} day${missed.length == 1 ? "" : "s"} not yet made up',
                        style: const TextStyle(
                          color: _kOrange,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation arrows (only when multiple missed days)
                if (missed.length > 1) ...[
                  // Previous missed day (older) — Flutter auto-mirrors in RTL
                  IconButton(
                    onPressed: _index > 0
                        ? () => setState(() => _index--)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 15),
                    color: _kOrange,
                    disabledColor: _kOrange.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      isAr
                          ? '${_arabicNumerals(_index + 1)}/${_arabicNumerals(missed.length)}'
                          : '${_index + 1}/${missed.length}',
                      style: const TextStyle(
                        color: _kOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // Next missed day (newer) — Flutter auto-mirrors in RTL
                  IconButton(
                    onPressed: _index < missed.length - 1
                        ? () => setState(() => _index++)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                    color: _kOrange,
                    disabledColor: _kOrange.withValues(alpha: 0.2),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Day badge + juz title in same row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _kOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _kOrange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        isAr
                            ? 'اليوم ${_arabicNumerals(day)}'
                            : 'Day $day',
                        style: const TextStyle(
                          color: _kOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (juzList.isNotEmpty)
                      Text(
                        dayDesc,
                        style: GoogleFonts.amiriQuran(
                          fontSize: 18,
                          color: _kOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Reading range
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _kOrange.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded,
                          color: _kOrange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rangeLine,
                          style: const TextStyle(
                            color: _kOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Motivational line
                Text(
                  isAr
                      ? 'كل ورد تقضيه يُكمل ختمتك — ما فات لا يُهمَل 📖'
                      : 'Every session you make up brings you closer — keep going 📖',
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    color: _kOrange.withValues(alpha: 0.65),
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    // Read button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToRead(context, range),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(
                          isAr
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isAr ? 'اقرأ القضاء' : 'Read Makeup',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mark done button
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<WirdCubit>().toggleDayComplete(day),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.success.withValues(alpha: 0.12),
                        foregroundColor: AppColors.success,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: AppColors.success
                                  .withValues(alpha: 0.4)),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isAr ? 'أكملته' : 'Done',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRead(BuildContext context, ReadingRange range) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailScreen(
          surahNumber: range.start.surah,
          surahName: _surahName(context, range.start.surah),
          initialAyahNumber: range.start.ayah,
        ),
      ),
    );
  }
}

// ── Option Button (Yes/No selector used in Ramadan setup) ────────────────────

class _OptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.surfaceVariant),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
