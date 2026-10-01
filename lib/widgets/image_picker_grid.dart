import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerGrid extends StatelessWidget {
  const ImagePickerGrid({
    super.key,
    required this.existingUrls,
    required this.newImages,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAddImages,
  });

  final List<String> existingUrls;
  final List<XFile> newImages;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<XFile> onRemoveNew;
  final VoidCallback onAddImages;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final url in existingUrls)
        _ImageTile(
          image: _NetworkImageFallback(url: url),
          onRemove: () => onRemoveExisting(url),
        ),
      for (final image in newImages)
        _ImageTile(
          image: FutureBuilder(
            future: image.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            },
          ),
          onRemove: () => onRemoveNew(image),
        ),
      OutlinedButton.icon(
        onPressed: onAddImages,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add images'),
      ),
    ];
    return Wrap(spacing: 10, runSpacing: 10, children: tiles);
  }
}

class ImageStrip extends StatelessWidget {
  const ImageStrip({super.key, required this.urls, this.height = 170});

  final List<String> urls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _showImageViewer(context, urls, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: _NetworkImageFallback(url: urls[index]),
            ),
          ),
        ),
      ),
    );
  }
}

void _showImageViewer(
    BuildContext context, List<String> urls, int initialIndex) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Stack(
          children: [
            _ImageViewerPages(urls: urls, initialIndex: initialIndex),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ImageViewerPages extends StatefulWidget {
  const _ImageViewerPages({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_ImageViewerPages> createState() => _ImageViewerPagesState();
}

class _ImageViewerPagesState extends State<_ImageViewerPages> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(int delta) {
    final next = (_index + delta).clamp(0, widget.urls.length - 1);
    if (next == _index) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: (index) => setState(() => _index = index),
          itemCount: widget.urls.length,
          itemBuilder: (_, index) => InteractiveViewer(
            child: Image.network(
              widget.urls[index],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1) ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filled(
                tooltip: 'Previous image',
                onPressed: _index == 0 ? null : () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filled(
                tooltip: 'Next image',
                onPressed: _index == widget.urls.length - 1
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NetworkImageFallback extends StatelessWidget {
  const _NetworkImageFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFEDE8FA),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF7A5DFF),
            ),
          ),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 112, height: 112, child: image),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              fixedSize: const Size(32, 32),
            ),
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          ),
        ),
      ],
    );
  }
}
