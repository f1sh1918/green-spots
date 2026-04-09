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
import 'package:spots/utils/date_format.dart';
import 'package:spots/constants/constants.dart';
import 'package:spots/utils/messenger_utils.dart';
import 'package:spots/widgets/delete_draft_dialog.dart';
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
    'kein Wasser',
    'stehendes Wasser',
    'fließendes Wasser',
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
  List<File> _selectedImages = [];

  // Form Values
  double _secure = 1.0;
  int _space = 1;
  bool _swim = false;
  bool _fire = false;
  String _waterquality = 'kein Wasser';
  bool _isLoading = false;

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
    } else {
      _titleController.text = widget.existingSpot?.title ?? widget.title ?? '';
      _noteController.text = widget.existingSpot?.note ?? '';
      _secure = widget.existingSpot?.secure ?? 1.0;
      _space = widget.existingSpot?.space.toInt() ?? 1;
      _fire = widget.existingSpot?.fire ?? false;
      _swim = widget.existingSpot?.swim ?? false;
      _waterquality = widget.existingSpot?.water ?? 'kein Wasser';
      _selectedSpecials.addAll(
        (widget.existingSpot?.specials ?? []).cast<String>(),
      );
      if (widget.existingSpot?.lastVisited != null) {
        _selectedDate = parseDateString(widget.existingSpot!.lastVisited!);
      }
    }
    _lastVisitedController.text = _formatDate(_selectedDate);
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
    return _titleController.text.isNotEmpty ||
        _noteController.text.isNotEmpty ||
        _latController.text.isNotEmpty ||
        _longController.text.isNotEmpty ||
        _selectedImages.isNotEmpty ||
        _selectedSpecials.isNotEmpty ||
        _secure != 1.0 ||
        _space != 1 ||
        _swim != false ||
        _fire != false ||
        _waterquality != 'kein Wasser';
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
          widget.existingSpot != null
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

  Widget _buildExistingThumbnails(List<dynamic>? images) {
    if (images == null || images.isEmpty) {
      return Container();
    }
    // Filter null values
    List<String> imageUrls = images
        .where((item) => item != null)
        .toList()
        .cast<String>();
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
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrls[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
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
        if (widget.queuedSpotId != null) {
          await spotsProvider.updateQueuedSpot(widget.queuedSpotId!, spotData);
        } else {
          await spotsProvider.enqueueSpot(spotData);
        }

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          showSnackBar(
            context,
            _selectedImages.isNotEmpty
                ? 'Spot gespeichert (ohne Bilder – du bist offline).'
                : 'Spot gespeichert – wird übertragen sobald du online bist.',
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
    final existingSpotImagesCount = widget.existingSpot?.imageIds?.length ?? 0;
    final totalPicturesCount = existingSpotImagesCount + _selectedImages.length;
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
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Allgemein',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),

                  // Notiz
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
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _lastVisitedController,
                    readOnly: true,
                    // prevents keyboard & manual edits
                    enableInteractiveSelection: false,
                    // disables long‑press selection
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
                  Divider(height: 50),
                  // Koordinaten
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Standort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          const SizedBox(width: 16),
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
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        onPressed: () => _updateUserPosition(),
                        icon: Icon(Icons.gps_fixed),
                        label: Text('Nutze aktuelle Position'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 50),
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Sicherheit Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 22),
                        child: Text(
                          'Sicherheit: ${_secure.toStringAsFixed(1)}/5 (${securityLabels[_secure.toInt()]})',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Slider(
                        value: _secure,
                        min: 1.0,
                        max: 5.0,
                        divisions: 8,
                        label: securityLabels[_secure.toInt()],
                        onChanged: (value) {
                          setState(() {
                            _secure = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Platz Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(horizontal: 22),
                        child: Text(
                          'Platz: $_space (Anzahl kleiner Zelte)',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      Slider(
                        value: _space.toDouble(),
                        min: 1,
                        max: 6,
                        divisions: 5,
                        label: _space.toString(),
                        onChanged: (value) {
                          setState(() {
                            _space = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Baden möglich'),
                    value: _swim,
                    onChanged: (value) {
                      setState(() {
                        _swim = value;
                      });
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Feuer erlaubt'),
                    value: _fire,
                    onChanged: (value) {
                      setState(() {
                        _fire = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Wasserqualität Dropdown
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
                    onChanged: (String? newValue) {
                      setState(() {
                        _waterquality = newValue ?? 'kein Wasser';
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Besonderheiten
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 50),
                      const Text(
                        'Besonderheiten',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: _availableSpecials.map((special) {
                          return CheckboxListTile(
                            visualDensity: const VisualDensity(
                              horizontal: 0,
                              vertical: -4,
                            ),
                            title: Text(special),
                            value: _selectedSpecials.contains(special),
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
                    ],
                  ),

                  // Bilder-Sektion
                  Divider(height: 50),
                  const Text(
                    'Bilder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (Provider.of<SpotsProvider>(
                    context,
                    listen: false,
                  ).isOffline) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 18,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bilder können im Offline-Modus nicht hinzugefügt werden.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          key: _imagesSectionKey,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: totalPicturesCount >= 3
                                ? null
                                : _pickImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: Text(
                              totalPicturesCount >= 3
                                  ? 'Maximum erreicht (3/3)'
                                  : 'Bilder hinzufügen ($totalPicturesCount/3)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.existingSpot != null) ...[
                      _buildExistingThumbnails(widget.existingSpot?.images),
                    ],
                    if (_selectedImages.isNotEmpty) ...[
                      _buildImageThumbnails(),
                    ],
                  ],
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitSpot,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.queuedSpotId != null
                                  ? 'Entwurf speichern'
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
    );
  }

  _updateUserPosition() {
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
