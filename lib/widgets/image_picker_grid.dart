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
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1.25,
            child: _NetworkImageFallback(url: urls[index]),
          ),
        ),
      ),
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
