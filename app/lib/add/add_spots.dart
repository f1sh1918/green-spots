import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'package:spots/spots/services/spot_cache.dart';
import 'package:spots/utils/date_format.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:spots/widgets/delete_draft_dialog.dart';
import 'package:spots/widgets/security_info_dialog.dart';
import 'models/add_spot.dart';

class AddSpots extends StatefulWidget {
  final Position? userPosition;
  final LatLng? coordinates;
  final Spot? existingSpot;
  final String? title;
  final AddSpot? queuedSpot;
  final String? queuedSpotId;

  const AddSpots({
    super.key,
    this.userPosition,
    this.coordinates,
    this.existingSpot,
    this.title,
    this.queuedSpot,
    this.queuedSpotId,
  });

  @override
  State<AddSpots> createState() => _AddSpotsState();
}

class _AddSpotsState extends State<AddSpots> {
  final _formKey = GlobalKey<FormState>();
  final _spotsService = SpotService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _imagesSectionKey = GlobalKey();

  // Form Controllers
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _specialController = TextEditingController();
  final _lastVisitedController = TextEditingController();

  final List<String> _waterQualityOptions = [
    'keine',
    'stehend',
    'fließend',
    'Trinkwasser',
  ];
  final List<String> _availableSpecials = [
    'Unterstand',
    'Tisch',
    'Bank',
    'Hängematte',
  ];
  final List<String> _selectedSpecials = [];

  // Image handling
  final List<File> _selectedImages = [];
  // Paths of images already saved to permanent draft storage (must not be deleted on back)
  final Set<String> _persistedImagePaths = {};
  // Mutable copies of existing spot images (for delete-on-save)
  late List<String> _existingImageUrls;
  late List<int> _existingImageIds;

  // Form Values
  double _secure = 1.0;
  int _space = 1;
  bool _swim = false;
  bool _fire = false;
  String _waterquality = 'keine';
  bool _isLoading = false;

  // Initial count of existing images for change detection
  late int _initExistingImageCount;

  // Initial state snapshot for change detection
  late String _initTitle;
  late String _initNote;
  late String _initLat;
  late String _initLong;
  late double _initSecure;
  late int _initSpace;
  late bool _initSwim;
  late bool _initFire;
  late String _initWaterquality;
  late List<String> _initSpecials;
  late DateTime _initDate;
  late int _initImageCount;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _latController.dispose();
    _longController.dispose();
    _specialController.dispose();
    _lastVisitedController.dispose();
    super.dispose();
  }

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _existingImageUrls = (widget.existingSpot?.images ?? [])
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString())
        .toList();
    _existingImageIds = List<int>.from(widget.existingSpot?.imageIds ?? []);
    _initExistingImageCount = _existingImageIds.length;
    if (widget.coordinates != null) {
      _latController.text = widget.coordinates!.latitude.toString();
      _longController.text = widget.coordinates!.longitude.toString();
    }
    if (widget.existingSpot != null) {
      _latController.text = widget.existingSpot?.lat.toString() ?? '';
      _longController.text = widget.existingSpot?.long.toString() ?? '';
    }

    if (widget.queuedSpot != null) {
      final q = widget.queuedSpot!;
      _titleController.text = q.title;
      _noteController.text = q.acf.note ?? '';
      _latController.text = q.acf.lat.toString();
      _longController.text = q.acf.long.toString();
      _secure = q.acf.secure;
      _space = q.acf.space;
      _fire = q.acf.fire;
      _swim = q.acf.swim;
      _waterquality = q.acf.waterquality;
      _selectedSpecials.addAll((q.acf.specials ?? []).cast<String>());
      if (q.acf.lastvisited.isNotEmpty) {
        _selectedDate = parseDateString(q.acf.lastvisited);
      }
      if (widget.queuedSpotId != null) {
        SpotCache.loadQueuedImages(widget.queuedSpotId!).then((files) {
          if (mounted && files.isNotEmpty) {
            setState(() {
              _selectedImages.addAll(files);
              _persistedImagePaths.addAll(files.map((f) => f.path));
              _initImageCount = files.length;
            });
          }
        });
      }
    } else {
      _titleController.text = widget.existingSpot?.title ?? widget.title ?? '';
      _noteController.text = widget.existingSpot?.note ?? '';
      _secure = widget.existingSpot?.secure ?? 1.0;
      _space = widget.existingSpot?.space.toInt() ?? 1;
      _fire = widget.existingSpot?.fire ?? false;
      _swim = widget.existingSpot?.swim ?? false;
      _waterquality = widget.existingSpot?.water ?? 'keine';
      _selectedSpecials.addAll(
        (widget.existingSpot?.specials ?? []).cast<String>(),
      );
      if (widget.existingSpot?.lastVisited != null) {
        _selectedDate = parseDateString(widget.existingSpot!.lastVisited!);
      }
    }
    _lastVisitedController.text = _formatDate(_selectedDate);

    // Snapshot for change detection (images loaded async, handled separately)
    _initTitle = _titleController.text;
    _initNote = _noteController.text;
    _initLat = _latController.text;
    _initLong = _longController.text;
    _initSecure = _secure;
    _initSpace = _space;
    _initSwim = _swim;
    _initFire = _fire;
    _initWaterquality = _waterquality;
    _initSpecials = List.unmodifiable(_selectedSpecials);
    _initDate = _selectedDate;
    _initImageCount = 0; // updated once draft images finish loading
  }

  String _formatDate(DateTime date) => DateFormat('dd.MM.yyyy').format(date);

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('de'),
      helpText: 'Datum auswählen',
      cancelText: 'Abbrechen',
      confirmText: 'OK',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _lastVisitedController.text = _formatDate(picked);
      });
    }
  }

  bool _hasUnsavedChanges() {
    if (_titleController.text != _initTitle) return true;
    if (_noteController.text != _initNote) return true;
    if (_latController.text != _initLat) return true;
    if (_longController.text != _initLong) return true;
    if (_secure != _initSecure) return true;
    if (_space != _initSpace) return true;
    if (_swim != _initSwim) return true;
    if (_fire != _initFire) return true;
    if (_waterquality != _initWaterquality) return true;
    if (_selectedDate != _initDate) return true;
    if (_selectedImages.length != _initImageCount) return true;
    if (_existingImageIds.length != _initExistingImageCount) return true;
    if (!_listsEqual(_selectedSpecials, _initSpecials)) return true;
    return false;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> _showExitConfirmDialog() async {
    if (!_hasUnsavedChanges()) return true;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Bestätigung'),
              content: Text(
                'Möchtest du wirklich zurückgehen? Alle eingegebenen Daten gehen verloren.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Zurückgehen'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _handleBackNavigation() async {
    final shouldExit = await _showExitConfirmDialog();
    if (shouldExit && mounted) {
      for (final file in _selectedImages) {
        if (!_persistedImagePaths.contains(file.path)) {
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
        }
      }
      Navigator.of(context).pop();
    }
  }

  Future<File?> _resizeImage(File imageFile) async {
    try {
      // Bild laden
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) return null;

      // Größe berechnen (max 1024 Breite, Seitenverhältnis beibehalten)
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (originalImage.width > 1024) {
        newWidth = 1024;
        newHeight = (originalImage.height * 1024 / originalImage.width).round();
      }

      // Bild verkleinern
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
      );

      // Als JPEG speichern
      final List<int> resizedBytes = img.encodeJpg(resizedImage, quality: 85);

      // Temporäre Datei erstellen
      final String fileName =
          'resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File resizedFile = File('${imageFile.parent.path}/$fileName');
      await resizedFile.writeAsBytes(resizedBytes);

      return resizedFile;
    } catch (e) {
      debugPrint('Fehler beim Verkleinern des Bildes: $e');
      return null;
    }
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Bild verkleinern
        File? resizedImage = await _resizeImage(imageFile);
        if (resizedImage != null) {
          setState(() {
            _selectedImages.add(resizedImage);
          });
        } else {
          // Fallback: Originalbild verwenden
          setState(() {
            _selectedImages.add(imageFile);
          });
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_imagesSectionKey.currentContext != null) {
            Scrollable.ensureVisible(
              _imagesSectionKey.currentContext!,
              curve: Curves.easeInOut,
            );
          }
        });
      }
    } catch (e) {
      showSnackBar(context, 'Fehler beim Auswählen des Bildes: $e', Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImageThumbnails() {
    if (_selectedImages.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _existingImageIds.isNotEmpty
              ? 'Zusätzliche Bilder'
              : 'Ausgewählte Bilder',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExistingThumbnails({required bool canDelete}) {
    if (_existingImageUrls.isEmpty) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bisherige Bilder',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingImageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _existingImageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.green.shade100,
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.green.shade300,
                          ),
                        ),
                      ),
                    ),
                    if (canDelete)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _existingImageUrls.removeAt(index);
                            _existingImageIds.removeAt(index);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitSpot() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final spot = AddSpot(
        title: _titleController.text,
        acf: AddSpotACF(
          lat: double.tryParse(_latController.text) ?? 0.0,
          long: double.tryParse(_longController.text) ?? 0.0,
          secure: _secure,
          space: _space,
          swim: _swim,
          fire: _fire,
          note: _noteController.text,
          waterquality: _waterquality,
          lastvisited: DateFormat('yyyyMMdd').format(_selectedDate),
          specials: _selectedSpecials.isEmpty ? null : _selectedSpecials,
        ),
      );

      final token = Provider.of<SettingsModel>(context, listen: false).token;
      final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);

      // If offline, queue (or update queued) spot instead of submitting
      if (spotsProvider.isOffline) {
        final queueId =
            widget.queuedSpotId ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final spotData = spot.toJson();
        spotData['_queueId'] = queueId;

        List<String> savedPaths = [];
        if (_selectedImages.isNotEmpty) {
          savedPaths = await SpotCache.saveQueuedImages(
            queueId,
            _selectedImages,
          );
          spotData['_imagePaths'] = savedPaths;
          _persistedImagePaths
            ..clear()
            ..addAll(savedPaths);
        }

        if (widget.queuedSpotId != null) {
          await spotsProvider.updateQueuedSpot(widget.queuedSpotId!, spotData);
        } else {
          await spotsProvider.enqueueSpot(spotData);
        }

        // Nur Temp-Dateien löschen, nicht die gerade gespeicherten Draft-Bilder
        final savedSet = savedPaths.toSet();
        for (final file in _selectedImages) {
          if (!savedSet.contains(file.path)) {
            try {
              if (await file.exists()) await file.delete();
            } catch (_) {}
          }
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showSnackBar(
            context,
            'Spot gespeichert – wird übertragen sobald du online bist.',
            Colors.orange,
            const Duration(seconds: 4),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Hier würden Sie die Bilder zusammen mit dem Spot hochladen
      final success = widget.existingSpot != null
          ? await _spotsService.updateSpot(
              widget.existingSpot!,
              spot,
              token,
              context,
              images: _selectedImages,
              keptImageIds: _existingImageIds,
            )
          : await _spotsService.addSpot(
              spot,
              token,
              context,
              images: _selectedImages,
            );

      setState(() {
        _isLoading = false;
      });

      // Temp-Dateien löschen (resized_*.jpg)
      for (final file in _selectedImages) {
        try {
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }

      if (success) {
        if (mounted) {
          Spot activeSpot = Spot(
            title: spot.title,
            secure: spot.acf.secure,
            space: spot.acf.space.toDouble(),
            swim: spot.acf.swim,
            fire: spot.acf.fire,
            lat: spot.acf.lat,
            // will be set automatically in the backend
            author: '',
            long: spot.acf.long,
            note: spot.acf.note,
            water: spot.acf.waterquality,
            specials: spot.acf.specials,
            // dummyId
            id: 999,
          );
          Provider.of<SpotsProvider>(
            context,
            listen: false,
          ).setActiveSpot(activeSpot);
          Navigator.pop(context);
          final sp = Provider.of<SpotsProvider>(context, listen: false);
          await sp.refresh(context, widget.userPosition);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = Provider.of<SpotsProvider>(
      context,
      listen: false,
    ).isOffline;
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final canDeleteExisting =
        !isOffline &&
        widget.existingSpot != null &&
        settings.user != null &&
        settings.user == widget.existingSpot!.author;
    final totalPicturesCount =
        _existingImageIds.length + _selectedImages.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(
            widget.queuedSpotId != null
                ? 'Entwurf bearbeiten'
                : widget.existingSpot != null
                ? 'Spot bearbeiten'
                : 'Spot hinzufügen',
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          actions: [
            if (widget.queuedSpotId != null)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    DeleteDraftDialog.show(context, widget.queuedSpotId!),
              ),
            if (widget.existingSpot != null || widget.queuedSpotId != null)
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                onPressed: _isLoading ? null : _submitSpot,
              ),
          ],
        ),
        body: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: Theme.of(context).inputDecorationTheme
                  .copyWith(
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Allgemein ──────────────────────────────────────
                    _FormCard(
                      label: 'Allgemein',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Titel *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Titel ist erforderlich';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              labelText: 'Notiz',
                              hintText:
                                  'Beschreibung, Hinweise wie Entfernung zu Wasserstelle, wann frequentiert...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastVisitedController,
                            readOnly: true,
                            enableInteractiveSelection: false,
                            decoration: InputDecoration(
                              labelText: 'Zuletzt besucht',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                tooltip: 'Datum auswählen',
                                onPressed: _pickDate,
                              ),
                            ),
                            onTap: _pickDate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Standort ───────────────────────────────────────
                    _FormCard(
                      label: 'Standort',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latController,
                                  decoration: const InputDecoration(
                                    labelText: 'Breitengrad *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^-?\d{1,3}\.?\d{0,6}$'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Breitengrad erforderlich';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _longController,
                                  decoration: const InputDecoration(
                                    labelText: 'Längengrad *',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^-?\d{1,3}\.?\d{0,6}$'),
                                    ),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Längengrad erforderlich';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _updateUserPosition,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Aktuelle Position verwenden'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Details ────────────────────────────────────────
                    _FormCard(
                      label: 'Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Sicherheit: ${_secure.toStringAsFixed(1)}/5 (${securityLabels[_secure.toInt()]})',
                                ),
                              ),
                              GestureDetector(
                                onTap: () => showSecurityInfoDialog(context),
                                child: Icon(
                                  Icons.help_outline,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _secure,
                            min: 1.0,
                            max: 5.0,
                            divisions: 8,
                            label: securityLabels[_secure.toInt()],
                            activeColor: Colors.green,
                            onChanged: (value) =>
                                setState(() => _secure = value),
                          ),
                          const SizedBox(height: 4),
                          Text('Platz: $_space (Anzahl kleiner Zelte)'),
                          Slider(
                            value: _space.toDouble(),
                            min: 1,
                            max: 6,
                            divisions: 5,
                            label: _space.toString(),
                            activeColor: Colors.green,
                            onChanged: (value) =>
                                setState(() => _space = value.toInt()),
                          ),
                          const Divider(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Baden möglich'),
                            value: _swim,
                            activeThumbColor: Colors.green,
                            onChanged: (value) => setState(() => _swim = value),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Feuer erlaubt'),
                            value: _fire,
                            activeThumbColor: Colors.green,
                            onChanged: (value) => setState(() => _fire = value),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _waterquality,
                            decoration: const InputDecoration(
                              labelText: 'Wasserqualität',
                              border: OutlineInputBorder(),
                            ),
                            items: _waterQualityOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) => setState(
                              () => _waterquality = newValue ?? 'keine',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Besonderheiten ─────────────────────────────────
                    _FormCard(
                      label: 'Besonderheiten',
                      child: Column(
                        children: _availableSpecials.map((special) {
                          return CheckboxListTile(
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: Text(special),
                            value: _selectedSpecials.contains(special),
                            activeColor: Colors.green,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedSpecials.add(special);
                                } else {
                                  _selectedSpecials.remove(special);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Bilder ─────────────────────────────────────────
                    _FormCard(
                      label: 'Bilder',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...[
                            OutlinedButton.icon(
                              key: _imagesSectionKey,
                              onPressed: totalPicturesCount >= 3
                                  ? null
                                  : _pickImages,
                              icon: const Icon(Icons.add_a_photo),
                              label: Text(
                                totalPicturesCount >= 3
                                    ? 'Maximum erreicht (3/3)'
                                    : 'Bilder hinzufügen ($totalPicturesCount/3)',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                            if (_existingImageUrls.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildExistingThumbnails(
                                canDelete: canDeleteExisting,
                              ),
                            ],
                            if (_selectedImages.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildImageThumbnails(),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submitSpot,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.queuedSpotId != null
                                    ? 'Entwurf speichern'
                                    : widget.existingSpot != null
                                    ? 'Spot speichern'
                                    : 'Spot hinzufügen',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateUserPosition() {
    if (widget.userPosition?.latitude != null &&
        widget.userPosition?.longitude != null) {
      setState(() {
        _latController.text = widget.userPosition!.latitude.toString();
        _longController.text = widget.userPosition!.longitude.toString();
      });
      showSnackBar(
        context,
        'Position aktualisiert!',
        Colors.green,
        Duration(seconds: 2),
      );
    } else {
      showSnackBar(
        context,
        'Aktuelle Position nicht verfügbar',
        Colors.red,
        Duration(seconds: 3),
      );
    }
  }
}

class _FormCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
