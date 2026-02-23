import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/settings/app_settings_cubit.dart';

// ── Firestore collection ──────────────────────────────────────────────────────
const _kCollection = 'feedback';
// ─────────────────────────────────────────────────────────────────────────────

enum _FeedbackType {
  suggestion,
  bug,
  other;

  String label(bool isAr) => switch (this) {
        _FeedbackType.suggestion => isAr ? '💡 اقتراح' : '💡 Suggestion',
        _FeedbackType.bug => isAr ? '🐛 مشكلة تقنية' : '🐛 Bug Report',
        _FeedbackType.other => isAr ? '💬 أخرى' : '💬 Other',
      };

  String get key => switch (this) {
        _FeedbackType.suggestion => 'suggestion',
        _FeedbackType.bug => 'bug',
        _FeedbackType.other => 'other',
      };
}

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  _FeedbackType _selectedType = _FeedbackType.suggestion;
  bool _isSending = false;
  bool _sent = false;

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _send(bool isAr) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final name = _nameController.text.trim();
      final message = _messageController.text.trim();
      String appVersion = '';
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = '${info.version}+${info.buildNumber}';
      } catch (_) {}

      await FirebaseFirestore.instance.collection(_kCollection).add({
        'type': _selectedType.key,
        'name': name.isEmpty ? null : name,
        'message': message,
        'appVersion': appVersion.isEmpty ? null : appVersion,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _sent = true;
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      // Show real error in debug builds to help diagnose Firestore / rules issues
      final detail = e.toString().length > 120 ? e.toString().substring(0, 120) : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? '❌ حدث خطأ، يرجى المحاولة مجدداً\n$detail'
                : '❌ Error: $detail',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _reset() {
    _messageController.clear();
    _nameController.clear();
    setState(() {
      _sent = false;
      _selectedType = _FeedbackType.suggestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context
        .watch<AppSettingsCubit>()
        .state
        .appLanguageCode
        .toLowerCase()
        .startsWith('ar');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'اقتراحات ومشاركات' : 'Feedback & Suggestions',
          ),
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
        ),
        body: _sent
            ? _SuccessView(isAr: isAr, onSendAnother: _reset)
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ─── Beta Banner ─────────────────────────────────────
              _BetaBanner(isAr: isAr, isDark: isDark),
              const SizedBox(height: 24),

              // ─── Feedback Type ────────────────────────────────────
              _FieldLabel(
                  label: isAr ? 'نوع المشاركة' : 'Feedback Type'),
              const SizedBox(height: 10),
              _FeedbackTypeChips(
                selected: _selectedType,
                isAr: isAr,
                onSelected: (t) => setState(() => _selectedType = t),
              ),
              const SizedBox(height: 22),

              // ─── Name ─────────────────────────────────────────────
              _FieldLabel(
                  label: isAr ? 'اسمك (اختياري)' : 'Your Name (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDeco(
                  isAr ? 'يمكنك البقاء مجهولًا' : 'You may remain anonymous',
                  Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 22),

              // ─── Message ──────────────────────────────────────────
              _FieldLabel(
                  label: isAr ? 'رسالتك *' : 'Your Message *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                minLines: 4,
                maxLength: 1000,
                textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDeco(
                  isAr
                      ? 'اكتب اقتراحك أو ملاحظتك هنا...'
                      : 'Write your suggestion or observation here...',
                  Icons.edit_note_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return isAr
                        ? 'يرجى كتابة رسالة'
                        : 'Please write a message';
                  }
                  if (v.trim().length < 10) {
                    return isAr
                        ? 'الرسالة قصيرة جدًا (10 أحرف على الأقل)'
                        : 'Message too short (at least 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ─── Send Button ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _send(isAr),
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    isAr ? 'إرسال' : 'Send Feedback',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ─── Footnote ─────────────────────────────────────────
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isAr
                            ? 'يُحفظ بشكل آمن ومباشر'
                            : 'Saved securely & privately',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.primary.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

// ─── Success View ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final bool isAr;
  final VoidCallback onSendAnother;

  const _SuccessView({required this.isAr, required this.onSendAnother});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 28),
            Text(
              isAr ? 'شكراً لك! 🎉' : 'Thank you! 🎉',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'تم إرسال رسالتك بنجاح.\nرأيك يُشكّل مستقبل التطبيق ✨'
                  : 'Your feedback was sent successfully.\nYour input shapes the app\'s future ✨',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            OutlinedButton.icon(
              onPressed: onSendAnother,
              icon: const Icon(Icons.add_comment_outlined, size: 18),
              label: Text(isAr ? 'إرسال رسالة أخرى' : 'Send Another'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Beta Banner ─────────────────────────────────────────────────────────────

class _BetaBanner extends StatelessWidget {
  final bool isAr;
  final bool isDark;
  const _BetaBanner({required this.isAr, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withValues(alpha: 0.14),
            AppColors.primary.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr
                      ? 'أنت من أوائل المستخدمين!'
                      : "You're an early user!",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFFE8DCC8)
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'رأيك يُشكّل مستقبل التطبيق — شكرًا لمشاركتك ✨'
                      : 'Your feedback shapes the app\'s future — thank you ✨',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
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

// ─── Feedback Type Chips ─────────────────────────────────────────────────────

class _FeedbackTypeChips extends StatelessWidget {
  final _FeedbackType selected;
  final bool isAr;
  final ValueChanged<_FeedbackType> onSelected;

  const _FeedbackTypeChips({
    required this.selected,
    required this.isAr,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _FeedbackType.values.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(
            type.label(isAr),
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.06),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.cardBorder,
            width: 1.2,
          ),
          onSelected: (_) => onSelected(type),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          showCheckmark: false,
          elevation: isSelected ? 2 : 0,
          pressElevation: 1,
        );
      }).toList(),
    );
  }
}

// ─── Field Label ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }
}
