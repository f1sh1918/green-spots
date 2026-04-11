import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:spots/add/add_spots.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/home.dart';
import 'package:spots/location/determine_position.dart';
import 'package:spots/settings/provider/spots_provider.dart';

import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/widgets/image_carousel.dart';
import 'package:spots/spots/widgets/spots_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:spots/utils/date_format.dart';
import 'package:spots/utils/distance.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:spots/widgets/delete_spot_dialog.dart';
import 'package:spots/widgets/security_info_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/comment_service.dart';
import '../services/spot_service.dart';
import 'comments_page.dart';

class SpotDetailPage extends StatefulWidget {
  final Spot currentSpot;
  final Position? userPosition;
  final bool locationPermissionGiven;
  final LocationStatus? locationStatus;

  const SpotDetailPage({
    required this.currentSpot,
    this.userPosition,
    this.locationPermissionGiven = false,
    this.locationStatus,
    super.key,
  });

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  Position? _currentUserPosition;
  bool _currentLocationPermissionGiven = false;
  LocationStatus? _currentLocationStatus;
  final bool _isLoadingPosition = false;
  final _spotsService = SpotService();
  final _commentService = CommentService();
  int? _commentCount;

  @override
  void initState() {
    super.initState();
    _currentUserPosition = widget.userPosition;
    _currentLocationPermissionGiven = widget.locationPermissionGiven;
    _currentLocationStatus = widget.locationStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
      spotsProvider.setActiveSpot(widget.currentSpot);
      if (!spotsProvider.isOffline) {
        _loadCommentCount();
      }
    });
  }

  Future<void> _loadCommentCount() async {
    final count = await _commentService.fetchCommentCount(
      widget.currentSpot.id,
    );
    if (mounted) setState(() => _commentCount = count);
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<SettingsModel>(context, listen: false).token;
    return Consumer<SpotsProvider>(
      builder: (context, spotsProvider, child) {
        final imageUrls = (widget.currentSpot.images ?? [])
            .where((url) => url is String && url.trim().isNotEmpty)
            .cast<String>()
            .toList();

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) {
              Provider.of<SpotsProvider>(
                context,
                listen: false,
              ).setActiveSpot(null);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  onPressed: () => _openEditPage(
                    widget.currentSpot,
                    widget.userPosition,
                    context,
                  ),
                  icon: Icon(Icons.edit),
                ),
                if (token != null) ...[
                  IconButton(
                    onPressed: () => _deleteSpot(
                      widget.currentSpot,
                      _spotsService,
                      context,
                      widget.userPosition,
                    ),
                    icon: Icon(Icons.delete),
                  ),
                ],
              ],
              title: Text(widget.currentSpot.title),
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrls.isNotEmpty)
                            ImageCarousel(
                              imageUrls: imageUrls,
                              onImageTap: (index) => _showFullScreenCarousel(
                                context,
                                imageUrls,
                                index,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eigenschaften
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _SectionLabel('Eigenschaften'),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () =>
                                                showSecurityInfoDialog(context),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.help_outline,
                                                  size: 16,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Sicherheit',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SpotsSubtitle(
                                        spot: widget.currentSpot,
                                        textStyle: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge!,
                                        sizeFactor: 1.0,
                                        showLabel: true,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Notiz
                                _SectionCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionLabel('Notiz'),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.currentSpot.note!.isNotEmpty
                                            ? widget.currentSpot.note!
                                            : 'Keine Notiz vorhanden',
                                        style:
                                            widget.currentSpot.note!.isNotEmpty
                                            ? Theme.of(
                                                context,
                                              ).textTheme.bodyMedium
                                            : Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Metadaten
                                _SectionCard(
                                  child: Column(
                                    children: [
                                      if (widget.userPosition != null) ...[
                                        _MetaRow(
                                          icon: Icons.straighten,
                                          color: Colors.teal,
                                          label: 'Entfernung',
                                          value:
                                              '${calculateDistanceFromSpot(widget.currentSpot, widget.userPosition!).toStringAsFixed(1)} km',
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      if (widget.currentSpot.lastVisited !=
                                          null) ...[
                                        _MetaRow(
                                          icon: Icons.calendar_today_outlined,
                                          color: Colors.orange,
                                          label: 'Zuletzt besucht',
                                          value: convertDateString(
                                            widget.currentSpot.lastVisited!,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                      _MetaRow(
                                        icon: Icons.person_outline,
                                        color: Colors.green,
                                        label: 'Erstellt von',
                                        value: widget.currentSpot.author,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _isLoadingPosition
                              ? null
                              : () => Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => Home(
                                      initialIndex: 0,
                                      locationPermissionGiven:
                                          _currentLocationPermissionGiven,
                                      userPosition: _currentUserPosition,
                                      locationStatus: _currentLocationStatus,
                                    ),
                                  ),
                                  (route) => false,
                                ),
                          icon: Icon(Icons.map_outlined),
                          label: Text('Auf Karte anzeigen'),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchMap(
                                  widget.currentSpot.lat,
                                  widget.currentSpot.long,
                                  context,
                                ),
                                icon: Icon(Icons.directions_outlined),
                                label: Text('Navigieren'),
                              ),
                            ),
                            if (!spotsProvider.isOffline && token != null) ...[
                              SizedBox(width: 8),
                              Expanded(
                                child: _commentCount == null
                                    ? OutlinedButton.icon(
                                        onPressed: null,
                                        icon: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        label: Text('Kommentare'),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => CommentsPage(
                                                spotId: widget.currentSpot.id,
                                                spotTitle:
                                                    widget.currentSpot.title,
                                              ),
                                            ),
                                          );
                                          if (mounted) _loadCommentCount();
                                        },
                                        icon: Icon(Icons.chat_bubble_outline),
                                        label: Text(
                                          'Kommentare ($_commentCount)',
                                        ),
                                      ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> _deleteSpot(
  Spot spot,
  SpotService spotService,
  BuildContext context,
  Position? userPosition,
) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DeleteSpotDialog(
        spot: spot,
        spotService: spotService,
        userPosition: userPosition,
      );
    },
  );
}

Future<void> _openEditPage(
  Spot spot,
  Position? userPosition,
  BuildContext context,
) async {
  Navigator.of(context).pop();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AddSpots(userPosition: userPosition, existingSpot: spot),
    ),
  );
}

Future<void> _launchMap(double? lat, double? long, BuildContext context) async {
  if (lat == null || long == null) {
    showSnackBar(
      context,
      'Spot konnte nicht in externer Anwendung geöffnet werden.',
      Colors.red,
    );
  } else {
    final geoUriWithZoom = Uri.parse('geo:$lat,$long?z=14&q=$lat,$long');
    await launchUrl(geoUriWithZoom);
  }
}

Widget _buildImagePlaceholder() {
  return Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.green.shade100,
    child: Icon(Icons.park, size: 64, color: Colors.green.shade400),
  );
}

void _showFullScreenCarousel(
  BuildContext context,
  List<String> imageUrls,
  int initialIndex,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (context, _, __) =>
        _FullScreenGallery(imageUrls: imageUrls, initialIndex: initialIndex),
  );
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pageController;
  late int _currentIndex;
  bool _isZoomed = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy.abs();
    if (_dragOffset.abs() > 100 || velocity > 500) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final opacity = (1.0 - _dragOffset.abs() / 250).clamp(0.0, 1.0);
    return GestureDetector(
      onVerticalDragUpdate: _isZoomed ? null : _onVerticalDragUpdate,
      onVerticalDragEnd: _isZoomed ? null : _onVerticalDragEnd,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, _dragOffset * 0.4),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: _isZoomed
                      ? const NeverScrollableScrollPhysics()
                      : const ClampingScrollPhysics(),
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (i) => setState(() {
                    _currentIndex = i;
                    _isZoomed = false;
                  }),
                  itemBuilder: (context, index) => _ZoomablePage(
                    imageUrl: widget.imageUrls[index],
                    onZoomChanged: (zoomed) =>
                        setState(() => _isZoomed = zoomed),
                  ),
                ),
                if (widget.imageUrls.length > 1)
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.imageUrls.length, (i) {
                        return GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                alpha: _currentIndex == i ? 0.9 : 0.4,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                Positioned(
                  top: topPadding + 8,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  final String imageUrl;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomablePage({required this.imageUrl, required this.onZoomChanged});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final _transformationController = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_zoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      final x = -position.dx * 1.5;
      final y = -position.dy * 1.5;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: () {},
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: _zoomed,
        scaleEnabled: true,
        child: Hero(
          tag: 'spot_image_${widget.imageUrl}',
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _MetaRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
