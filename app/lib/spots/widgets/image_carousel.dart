import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final Function(int)? onImageTap;
  final int? initialIndex;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.onImageTap,
    this.initialIndex,
  });

  @override
  ImageCarouselState createState() => ImageCarouselState();
}

const double indicatorHeight = 32;

class ImageCarouselState extends State<ImageCarousel> {
  CarouselSliderController carouselController = CarouselSliderController();
  int imageIndex = 0;

  @override
  void initState() {
    super.initState();
    imageIndex = widget.initialIndex ?? 0;

    if (widget.initialIndex != null && widget.initialIndex! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        carouselController.animateToPage(widget.initialIndex!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int imageAmount = widget.imageUrls.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final carouselItems = widget.imageUrls.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final url = entry.value;

      Widget item = Hero(
        tag: 'spot_image_$url',
        child: Image.network(
          url,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.green.shade100,
            child: Icon(Icons.park, size: 64, color: Colors.green.shade400),
          ),
        ),
      );

      if (widget.onImageTap != null) {
        item = GestureDetector(
          onTap: () => widget.onImageTap!(index),
          child: item,
        );
      }

      return item;
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LayoutBuilder(
            builder: (context, constraints) => CarouselSlider(
              items: carouselItems,
              carouselController: carouselController,
              options: CarouselOptions(
                enableInfiniteScroll: false,
                viewportFraction: 1.0,
                height: constraints.maxHeight,
                onPageChanged: (index, _) => setState(() => imageIndex = index),
              ),
            ),
          ),
        ),
        if (imageAmount > 1)
          SizedBox(
            height: indicatorHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.imageUrls
                  .mapIndexed(
                    (index, _) => GestureDetector(
                      onTap: () => carouselController.animateToPage(index),
                      child: Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(
                                alpha: imageIndex == index ? 0.9 : 0.4,
                              ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
