// Formatting toolbar helpers remain available for future editor actions.
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';
import '../widgets/app_shell.dart';
import '../widgets/image_picker_grid.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({super.key, this.postId});

  final String? postId;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tagInput = TextEditingController();
  final _bodyFocus = FocusNode();
  final _picker = ImagePicker();
  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final Set<String> _selectedTags = {};
  final List<String> _customTags = [];
  bool _loading = false;
  bool _saving = false;

  bool get _isEditing => widget.postId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final post = await context.read<PostProvider>().getPost(widget.postId!);
      _title.text = post.title;
      _body.text = post.body;
      _existingImages.addAll(post.imageUrls);
      final foundTags = RegExp(r'#([A-Za-z0-9][A-Za-z0-9_/-]*)')
          .allMatches(post.body)
          .map((match) => match.group(1)!)
          .toSet();
      _selectedTags
        ..clear()
        ..addAll(_availableTags.where((tag) {
          final text = '${post.title} ${post.body}'.toLowerCase();
          return text.contains(tag.toLowerCase());
        }))
        ..addAll(foundTags.where((tag) {
          return !_availableTags.any(
            (available) => available.toLowerCase() == tag.toLowerCase(),
          );
        }));
      _customTags
        ..clear()
        ..addAll(_selectedTags.where((tag) => !_availableTags.contains(tag)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load this post: $error')),
        );
        context.go('/');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    List<XFile> images;
    try {
      images = await _picker.pickMultiImage(imageQuality: 100);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select images: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _newImages.addAll(images));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final selectedTags = _selectedTags.map(_tagToHashtag);
      final bodyWithTags = selectedTags.isEmpty
          ? _body.text
          : '${_body.text.trim()}\n\n${selectedTags.join(' ')}';
      await context.read<PostProvider>().savePost(
            id: widget.postId,
            title: _title.text,
            body: bodyWithTags,
            keptImages: _existingImages,
            newImages: _newImages,
          );
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TextSelection _safeBodySelection() {
    final length = _body.text.length;
    final selection = _body.selection;
    if (!selection.isValid) {
      return TextSelection.collapsed(offset: length);
    }
    return TextSelection(
      baseOffset: selection.baseOffset.clamp(0, length).toInt(),
      extentOffset: selection.extentOffset.clamp(0, length).toInt(),
    );
  }

  void _replaceBodySelection(
    String replacement, {
    int? selectionStart,
    int? selectionEnd,
  }) {
    final selection = _safeBodySelection();
    final text = _body.text;
    final start = selection.start;
    final end = selection.end;
    _body.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection(
        baseOffset: selectionStart ?? start + replacement.length,
        extentOffset: selectionEnd ?? start + replacement.length,
      ),
    );
    _bodyFocus.requestFocus();
    setState(() {});
  }

  void _wrapBodySelection({
    required String before,
    required String after,
    required String placeholder,
  }) {
    final selection = _safeBodySelection();
    final selectedText = _body.text.substring(selection.start, selection.end);
    final innerText = selectedText.isEmpty ? placeholder : selectedText;
    final replacement = '$before$innerText$after';
    final innerStart = selection.start + before.length;
    _replaceBodySelection(
      replacement,
      selectionStart: innerStart,
      selectionEnd: innerStart + innerText.length,
    );
  }

  void _applyInlineCode() {
    final selection = _safeBodySelection();
    final selectedText = _body.text.substring(selection.start, selection.end);
    if (selectedText.contains('\n')) {
      final codeText =
          selectedText.trim().isEmpty ? 'code block' : selectedText;
      _replaceBodySelection('```\n$codeText\n```');
      return;
    }
    _wrapBodySelection(before: '`', after: '`', placeholder: 'code');
  }

  void _applyBulletList() {
    _applyLineList(
      placeholder: 'List item',
      prefixForIndex: (_) => '- ',
    );
  }

  void _applyNumberedList() {
    _applyLineList(
      placeholder: 'List item',
      prefixForIndex: (index) => '${index + 1}. ',
    );
  }

  void _applyLineList({
    required String placeholder,
    required String Function(int index) prefixForIndex,
  }) {
    final selection = _safeBodySelection();
    final selectedText = _body.text.substring(selection.start, selection.end);
    if (selectedText.isEmpty) {
      final prefix = prefixForIndex(0);
      _replaceBodySelection(
        '$prefix$placeholder',
        selectionStart: selection.start + prefix.length,
        selectionEnd: selection.start + prefix.length + placeholder.length,
      );
      return;
    }

    final lines = selectedText.split('\n');
    final replacement = [
      for (var index = 0; index < lines.length; index++)
        if (lines[index].trim().isEmpty)
          lines[index]
        else
          '${prefixForIndex(index)}${lines[index].replaceFirst(RegExp(r'^\s*(?:[-*+]\s+|\d+[.)]\s+)'), '')}',
    ].join('\n');
    _replaceBodySelection(replacement);
  }

  Future<void> _insertLink() async {
    final selection = _safeBodySelection();
    final selectedText = _body.text.substring(selection.start, selection.end);
    final labelController = TextEditingController(
      text: selectedText.trim().isEmpty ? 'link text' : selectedText.trim(),
    );
    final urlController = TextEditingController(text: 'https://');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert link'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Text'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final label = labelController.text.trim();
              final url = urlController.text.trim();
              if (label.isEmpty || url.isEmpty || url == 'https://') return;
              Navigator.of(context).pop({'label': label, 'url': url});
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );

    labelController.dispose();
    urlController.dispose();
    if (!mounted || result == null) return;
    _replaceBodySelection('[${result['label']}](${result['url']})');
  }

  void _addCustomTag() {
    final cleaned = _tagInput.text
        .replaceFirst(RegExp(r'^#+'), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9 /_-]'), '')
        .trim();
    if (cleaned.isEmpty) return;

    final existingTag = [..._availableTags, ..._customTags].where((item) {
      return item.toLowerCase() == cleaned.toLowerCase();
    }).firstOrNull;

    setState(() {
      final selectedTag = existingTag ?? cleaned;
      if (existingTag == null) _customTags.add(cleaned);
      _selectedTags.add(selectedTag);
      _tagInput.clear();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tagInput.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 1,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1040;

                return Container(
                  color: const Color(0xFFF6F8FC),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 16,
                      22,
                      wide ? 28 : 16,
                      48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: _buildForm(),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _ComposeHeader(
                saving: _saving,
                onPublish: _save,
              ),
              const SizedBox(height: 18),
              _ComposeCard(
                title: 'Post title',
                trailing: _CounterText(text: _title.text, max: 100),
                child: TextFormField(
                  controller: _title,
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                  decoration: _fieldDecoration(
                    hintText: 'Give your post a title...',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              _ComposeCard(
                title: 'Content',
                trailing: _CounterText(text: _body.text, max: 2000),
                child: TextFormField(
                  controller: _body,
                  focusNode: _bodyFocus,
                  minLines: 8,
                  maxLines: 12,
                  maxLength: 2000,
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(
                    hintText:
                        'Start writing your story, idea, question, or update...',
                    counterText: '',
                    attachedTop: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Body is required'
                      : null,
                ),
              ),
              const SizedBox(height: 22),
              _ComposeCard(
                icon: Icons.local_offer_outlined,
                title: 'Tags',
                subtitle: 'Add relevant tags to help others find your post.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        for (final tag in [..._availableTags, ..._customTags])
                          _TagChip(
                            label: tag,
                            selected: _selectedTags.contains(tag),
                            onPressed: () {
                              setState(() {
                                if (_selectedTags.contains(tag)) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagInput,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addCustomTag(),
                            decoration: _fieldDecoration(
                              hintText: '#AddYourTag',
                            ).copyWith(
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: _addCustomTag,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add #'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _ComposeCard(
                icon: Icons.image_outlined,
                title: 'Images',
                subtitle: 'Add images to make your post more engaging.',
                child: ImagePickerGrid(
                  existingUrls: _existingImages,
                  newImages: _newImages,
                  onRemoveExisting: (url) => setState(
                    () => _existingImages.remove(url),
                  ),
                  onRemoveNew: (image) => setState(
                    () => _newImages.remove(image),
                  ),
                  onAddImages: _pickImages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  String? counterText,
  bool attachedTop = false,
}) {
  return InputDecoration(
    hintText: hintText,
    counterText: counterText,
    filled: true,
    fillColor: const Color(0xFFFBFCFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(attachedTop ? 0 : 10),
        bottom: const Radius.circular(10),
      ),
      borderSide: const BorderSide(color: Color(0xFFDCE4F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(attachedTop ? 0 : 10),
        bottom: const Radius.circular(10),
      ),
      borderSide: const BorderSide(color: Color(0xFFDCE4F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(attachedTop ? 0 : 10),
        bottom: const Radius.circular(10),
      ),
      borderSide: const BorderSide(color: Color(0xFF5B4DF7), width: 1.4),
    ),
  );
}

const _availableTags = [
  'Flutter',
  'Dart',
  'Supabase',
  'Mobile',
  'Design',
  'UI/UX',
];

String _tagToHashtag(String tag) {
  final compactTag = tag.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '');
  return compactTag.isEmpty ? '' : '#$compactTag';
}

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.trailing,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              _SectionIcon(icon: icon!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1E2A44),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xFF7E8BA3),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _ComposeHeader extends StatelessWidget {
  const _ComposeHeader({
    required this.saving,
    required this.onPublish,
  });

  final bool saving;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: saving ? null : onPublish,
              icon: saving
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(saving ? 'Publishing...' : 'Publish Post'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B4DF7),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Divider(height: 1),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF5B4DF7)),
    );
  }
}

class _FormattingToolbar extends StatelessWidget {
  const _FormattingToolbar({
    required this.onItalic,
    required this.onLink,
    required this.onCode,
    required this.onBulletList,
    required this.onNumberedList,
    required this.onImage,
  });

  final VoidCallback onItalic;
  final VoidCallback onLink;
  final VoidCallback onCode;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  final VoidCallback onImage;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ToolbarAction(
        icon: Icons.format_italic_rounded,
        tooltip: 'Italic',
        onPressed: onItalic,
      ),
      _ToolbarAction(
        icon: Icons.link_rounded,
        tooltip: 'Link',
        onPressed: onLink,
      ),
      _ToolbarAction(
        icon: Icons.code_rounded,
        tooltip: 'Code',
        onPressed: onCode,
      ),
      _ToolbarAction(
        icon: Icons.format_list_bulleted_rounded,
        tooltip: 'Bulleted list',
        onPressed: onBulletList,
      ),
      _ToolbarAction(
        icon: Icons.format_list_numbered_rounded,
        tooltip: 'Numbered list',
        onPressed: onNumberedList,
      ),
      _ToolbarAction(
        icon: Icons.image_outlined,
        tooltip: 'Add images',
        onPressed: onImage,
      ),
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        border: Border(
          top: BorderSide(color: Color(0xFFDCE4F0)),
          left: BorderSide(color: Color(0xFFDCE4F0)),
          right: BorderSide(color: Color(0xFFDCE4F0)),
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final action in actions)
              IconButton(
                onPressed: action.onPressed,
                icon: Icon(action.icon, size: 16),
                color: const Color(0xFF536179),
                splashRadius: 18,
                tooltip: action.tooltip,
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction {
  const _ToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

class _CounterText extends StatelessWidget {
  const _CounterText({required this.text, required this.max});

  final String text;
  final int max;

  @override
  Widget build(BuildContext context) {
    return _PillText('${text.length}/$max');
  }
}

class _PillText extends StatelessWidget {
  const _PillText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor:
            selected ? const Color(0xFFEEF2FF) : Colors.transparent,
        foregroundColor:
            selected ? const Color(0xFF5B4DF7) : const Color(0xFF7D879D),
        side: BorderSide(
          color: selected ? const Color(0xFF5B4DF7) : const Color(0xFFDBE2ED),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text('${selected ? '-' : '+'} $label'),
    );
  }
}
