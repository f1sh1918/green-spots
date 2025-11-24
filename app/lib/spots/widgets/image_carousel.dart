import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<Widget> images;
  final int imageIndex;

  const ImageCarousel({
    super.key,
    required this.images,
    required this.imageIndex,
  });

  @override
  ImageCarouselState createState() => ImageCarouselState();
}

const double indicatorHeight = 32;

class ImageCarouselState extends State<ImageCarousel> {
  CarouselSliderController carouselController = CarouselSliderController();
  int cardIndex = 0;

  @override
  Widget build(BuildContext context) {
    final int imageAmount = widget.images.length;

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LayoutBuilder(
            builder: (context, constraints) => CarouselSlider(
              items: widget.images,
              carouselController: carouselController,
              options: CarouselOptions(
                enableInfiniteScroll: false,
                viewportFraction: 1,
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
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withValues(
                                    alpha: widget.imageIndex == index
                                        ? 0.9
                                        : 0.4,
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
      cardIndex = index;
    });
  }
}
