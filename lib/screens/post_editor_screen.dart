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
  final _picker = ImagePicker();
  final List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  final Set<String> _selectedTags = {};
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
    final post = await context.read<PostProvider>().getPost(widget.postId!);
    _title.text = post.title;
    _body.text = post.body;
    _existingImages.addAll(post.imageUrls);
    _selectedTags
      ..clear()
      ..addAll(_availableTags.where((tag) {
        final text = '${post.title} ${post.body}'.toLowerCase();
        return text.contains(tag.toLowerCase());
      }));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 82);
    if (!mounted) return;
    setState(() => _newImages.addAll(images));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final selectedTags =
          _selectedTags.map((tag) => '#${tag.replaceAll('/', '')}');
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

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 1,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
              children: [
                Container(
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE9EDF3)),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Cancel'),
                          ),
                          Text(
                            _isEditing ? 'Edit post' : 'New post',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Saving...' : 'Publish'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _ComposeCard(
                            child: TextFormField(
                              controller: _title,
                              style: const TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'TITLE',
                                hintText: 'What are you writing about?',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Title is required'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ComposeCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TAGS (up to 5)',
                                  style: TextStyle(
                                    color: Color(0xFF65718A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final tag in _availableTags)
                                      _TagChip(
                                        label: tag,
                                        selected: _selectedTags.contains(tag),
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedTags.contains(tag)) {
                                              _selectedTags.remove(tag);
                                            } else if (_selectedTags.length <
                                                5) {
                                              _selectedTags.add(tag);
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ComposeCard(
                            child: TextFormField(
                              controller: _body,
                              minLines: 8,
                              maxLines: 12,
                              decoration: const InputDecoration(
                                labelText: 'CONTENT',
                                hintText: 'Write your post here...',
                                alignLabelWithHint: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'Body is required'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ComposeCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'IMAGES',
                                  style: TextStyle(
                                    color: Color(0xFF65718A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ImagePickerGrid(
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => context.go('/'),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _saving ? null : _save,
                                  child: Text(
                                    _saving ? 'Publishing...' : 'Publish post',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

const _availableTags = [
  'Flutter',
  'Dart',
  'Supabase',
  'Mobile',
  'Design',
  'UI/UX',
];

class _ComposeCard extends StatelessWidget {
  const _ComposeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
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
            selected ? const Color(0xFF4F46E5) : const Color(0xFF7D879D),
        side: BorderSide(
          color: selected ? const Color(0xFF4F46E5) : const Color(0xFFDBE2ED),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text('${selected ? '-' : '+'} $label'),
    );
  }
}


