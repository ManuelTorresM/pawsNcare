import 'package:flutter/material.dart';
import '../memory_image_card.dart';

class PetRecentMemoriesWidget extends StatelessWidget {
  final List<String> photos;
  final VoidCallback onViewAlbum;
  final VoidCallback onAddPhoto;
  final Function(int index) onPhotoTap;
  final Color textPrimary;
  final Color headerColor;

  const PetRecentMemoriesWidget({
    super.key,
    required this.photos,
    required this.onViewAlbum,
    required this.onAddPhoto,
    required this.onPhotoTap,
    required this.textPrimary,
    required this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    final recentPhotos = photos.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Photos',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: onViewAlbum,
                child: Text(
                  'View Album',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: headerColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recentPhotos.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == recentPhotos.length) {
                return _buildAddPhotoButton(context);
              }
              final photoUrl = recentPhotos[index];
              final originalIndex = photos.lastIndexOf(photoUrl);

              return MemoryImageCard(
                url: photoUrl,
                width: 120,
                onTap: () => onPhotoTap(
                  originalIndex != -1 ? originalIndex : index,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton(BuildContext context) {
    return GestureDetector(
      onTap: onAddPhoto,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: headerColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          color: headerColor.withValues(alpha: 0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: headerColor,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              'Add Photo',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: headerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
