import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../application/club_feed_provider.dart';
import '../../../shared/widgets/bebo_shell_background.dart';
import '../../../shared/widgets/tactile/tactile_clay_button.dart';
import '../../../shared/widgets/tactile/tactile_clay_card.dart';
import '../../library/domain/library_age_band.dart';
import '../../quran/presentation/widgets/tactile/quran_tactile_app_bar.dart';
import '../data/community_cloud_repository.dart';
import 'widgets/club_shared.dart';

/// «اسألي الأمهات» — returns true when the question was sent for review.
class ClubNewPostScreen extends ConsumerStatefulWidget {
  const ClubNewPostScreen({super.key, this.initialAgeId});

  final String? initialAgeId;

  @override
  ConsumerState<ClubNewPostScreen> createState() => _ClubNewPostScreenState();
}

class _ClubNewPostScreenState extends ConsumerState<ClubNewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  late String? _ageId = widget.initialAgeId;
  bool _anonymous = false;
  bool _sending = false;
  Uint8List? _imageBytes;
  String _imageExt = 'jpg';

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) showClubSnack(context, 'الصورة كبيرة أوي — اختاري صورة أصغر');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      });
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر فتح الصور');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ageId == null) {
      showClubSnack(context, 'اختاري عمر البيبي الأول');
      return;
    }
    setState(() => _sending = true);
    try {
      final repo = ref.read(communityCloudRepositoryProvider);
      final bytes = _imageBytes;
      final imagePath = bytes == null ? null : await repo.uploadClubImage(bytes, extension: _imageExt);
      await repo.createPost(
        title: _title.text,
        body: _body.text,
        categoryId: _ageId!,
        anonymous: _anonymous,
        imagePath: imagePath,
      );
      ref.invalidate(mothersClubPostsProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ClubActionException catch (e) {
      if (mounted) showClubSnack(context, e.message);
    } catch (_) {
      if (mounted) showClubSnack(context, 'تعذّر إرسال السؤال، حاولي تاني');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: QuranTactileAppBar(title: 'اسألي الأمهات', onBack: () => Navigator.of(context).pop()),
      body: Stack(
        children: [
          const BeboShellBackground(showBottomCurve: false),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  TactileClayCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Symbols.forum, color: AppColors.primary, size: 28, fill: 1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'سؤالك هيتراجع من فريق بيانور قبل ما يظهر للأمهات، عشان النادي يفضل مكان آمن ومفيد 💛',
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'عمر البيبي',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final band in LibraryAgeBand.values)
                        ChoiceChip(
                          label: Text(band.label),
                          selected: _ageId == band.dbValue,
                          onSelected: (_) => setState(() => _ageId = band.dbValue),
                          selectedColor: AppColors.primaryFixed,
                          labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClubField(
                    controller: _title,
                    label: 'عنوان سؤالك',
                    hint: 'مثال: البيبي بيصحى كتير بالليل',
                    maxLength: 120,
                    validator: (v) => (v == null || v.trim().length < 5) ? 'اكتبي عنوان أوضح (5 حروف على الأقل)' : null,
                  ),
                  const SizedBox(height: 14),
                  ClubField(
                    controller: _body,
                    label: 'التفاصيل',
                    hint: 'احكي للأمهات بالتفصيل عشان يقدروا يساعدوكي…',
                    maxLines: 7,
                    maxLength: 3000,
                    validator: (v) => (v == null || v.trim().length < 15) ? 'اكتبي تفاصيل أكتر (15 حرف على الأقل)' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_imageBytes == null)
                    OutlinedButton.icon(
                      onPressed: _sending ? null : _pickImage,
                      icon: const Icon(Symbols.add_photo_alternate),
                      label: const Text('ضيفي صورة (اختياري)'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                      ),
                    )
                  else
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.brMd,
                          child: Image.memory(_imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: IconButton.filled(
                            onPressed: _sending ? null : () => setState(() => _imageBytes = null),
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            icon: const Icon(Symbols.close, color: Colors.white),
                            tooltip: 'شيلي الصورة',
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: clubInsetDecoration(),
                    child: SwitchListTile(
                      value: _anonymous,
                      onChanged: (v) => setState(() => _anonymous = v),
                      secondary: Icon(
                        _anonymous ? Symbols.visibility_off : Symbols.person,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'اسألي بدون اسم',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        _anonymous
                            ? 'هيظهر باسم «${MothersClubPost.anonymousName}» — محدش من الأمهات هيعرف إنه إنتي'
                            : 'سؤالك هيظهر باسمك',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TactileClayButton(
                    label: _sending ? 'جاري الإرسال…' : 'إرسال السؤال',
                    icon: Symbols.send,
                    onPressed: _sending ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
