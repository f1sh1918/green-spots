import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/settings/provider/spots_provider.dart';
import 'package:spots/spots/models/spot.dart';
import 'package:spots/spots/services/spot_service.dart';
import 'models/add_spot.dart';

class AddSpots extends StatefulWidget {
  final Position? userPosition;
  final LatLng? coordinates;
  const AddSpots({super.key, this.userPosition, this.coordinates});

  @override
  State<AddSpots> createState() => _AddSpotsState();
}

class _AddSpotsState extends State<AddSpots> {
  final _formKey = GlobalKey<FormState>();
  final _spotsService = SpotService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _latController = TextEditingController();
  final _longController = TextEditingController();
  final _specialController = TextEditingController();

  final List<String> _waterQualityOptions = ['kein Wasser', 'stehendes Wasser', 'fließendes Wasser', 'Trinkwasser'];

  final List<String> _availableSpecials = ['Unterstand', 'Tisch', 'Bank'];
  final List<String> _selectedSpecials = [];

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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.coordinates != null) {
      _latController.text = widget.coordinates!.latitude.toString();
      _longController.text = widget.coordinates!.longitude.toString();
    }
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
            specials: _selectedSpecials.isEmpty ? null : _selectedSpecials),
      );

      final token = Provider.of<SettingsModel>(context, listen: false).token;

      final success = await _spotsService.addSpot(spot, token, context);

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
              long: spot.acf.long,
              note: spot.acf.note,
              water: spot.acf.waterquality,
              specials: spot.acf.specials,
              id: 999);
          Provider.of<SpotsProvider>(context, listen: false).setActiveSpot(activeSpot);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Spot erfolgreich hinzugefügt!'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
          final spotsProvider = Provider.of<SpotsProvider>(context, listen: false);
          await spotsProvider.refresh(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Hinzufügen des Spots.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Spot hinzufügen'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(
                          labelText: 'Breitengrad *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d{1,3}\.?\d{0,6}$')),
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
                        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^-?\d{1,3}\.?\d{0,6}$')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Längengrad erforderlich';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(color: Colors.green, onPressed: () => _updateUserPosition(), icon: Icon(Icons.gps_fixed))
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Notiz',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Sicherheit Slider
                Text('Sicherheit: ${_secure.toStringAsFixed(1)} (1=sehr unsicher, 5=sehr sicher)'),
                Slider(
                  value: _secure,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  onChanged: (value) {
                    setState(() {
                      _secure = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Platz Slider
                Text('Platz: $_space (Anzahl kleiner Zelte)'),
                Slider(
                  value: _space.toDouble(),
                  min: 1.0,
                  max: 6.0,
                  divisions: 4,
                  onChanged: (value) {
                    setState(() {
                      _space = value.toInt();
                    });
                  },
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
                const SizedBox(height: 32),

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
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Besonderheiten',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoading ? null : _submitSpot,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Spot hinzufügen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _updateUserPosition() {
    if (widget.userPosition?.latitude != null && widget.userPosition?.longitude != null) {
      setState(() {
        _latController.text = widget.userPosition!.latitude.toString();
        _longController.text = widget.userPosition!.longitude.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Position aktualisiert!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktuelle Position nicht verfügbar'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
