import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<Widget> images;
  final bool isFullscreen;
  final Function(int)? onImageTap;
  final int? initialIndex;

  const ImageCarousel({
    super.key,
    required this.images,
    this.isFullscreen = false,
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

    // Navigate to initial index after widget is built
    if (widget.initialIndex != null && widget.initialIndex! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        carouselController.animateToPage(widget.initialIndex!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int imageAmount = widget.images.length;

    // Wrap images with GestureDetector for tap handling if not in fullscreen mode
    List<Widget> carouselItems = widget.images.asMap().entries.map<Widget>((entry) {
      int index = entry.key;
      Widget image = entry.value;

      if (!widget.isFullscreen && widget.onImageTap != null) {
        return GestureDetector(
          onTap: () => widget.onImageTap!(index),
          child: image,
        );
      }

      return image;
    }).toList();

    if (widget.isFullscreen) {
      // For fullscreen mode, use Stack to overlay indicators
      return Stack(
        children: [
          Positioned.fill(
            child: CarouselSlider(
              items: carouselItems,
              carouselController: carouselController,
              options: CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: imageAmount > 1,
                height: double.infinity,
                onPageChanged: (index, reason) => _updateIndex(index),
              ),
            ),
          ),
          if (imageAmount > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images
                    .mapIndexed(
                      (index, value) => GestureDetector(
                        onTap: () => carouselController.animateToPage(index),
                        child: Container(
                          width: 12.0,
                          height: 12.0,
                          margin: EdgeInsets.symmetric(horizontal: 6.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
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

    // For normal mode, use Column layout
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
                onPageChanged: (index, reason) => _updateIndex(index),
              ),
            ),
          ),
        ),
        if (imageAmount > 1)
          SizedBox(
            height: indicatorHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.images
                  .mapIndexed(
                    (index, value) => GestureDetector(
                      onTap: () => carouselController.animateToPage(index),
                      child: Container(
                        width: 8.0,
                        height: 8.0,
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
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

  Future<void> _updateIndex(int index) async {
    setState(() {
      imageIndex = index;
    });
  }
}
