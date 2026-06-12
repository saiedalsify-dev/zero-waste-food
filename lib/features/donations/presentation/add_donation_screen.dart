import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../models/donation.dart';

class AddDonationScreen extends ConsumerStatefulWidget {
  const AddDonationScreen({super.key});

  @override
  ConsumerState<AddDonationScreen> createState() => _AddDonationScreenState();
}

class _AddDonationScreenState extends ConsumerState<AddDonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _cityController = TextEditingController(text: AppConstants.defaultCity);
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _notesController = TextEditingController();
  String _unit = AppConstants.donationUnits.first;
  DateTime _expiryDate = DateTime.now().add(const Duration(hours: 12));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryDate),
    );
    if (time == null || !mounted) {
      return;
    }

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (selected.isBefore(DateTime.now())) {
      _showMessage('Expiry must be in the future.');
      return;
    }
    setState(() => _expiryDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (user == null) {
      _showMessage('Please sign in again.');
      return;
    }
    if (!user.isDonor) {
      _showMessage('Only donors can add donations.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final donation = Donation(
        id: '',
        donorId: user.id,
        donorName: user.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unit,
        expiryDate: _expiryDate,
        city: _cityController.text.trim(),
        latitude: _parseOptionalDouble(_latitudeController.text),
        longitude: _parseOptionalDouble(_longitudeController.text),
        status: DonationStatus.pending,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final created = await ref
          .read(donationServiceProvider)
          .createDonation(donation);
      try {
        await ref.read(notificationServiceProvider).notifyNewDonation(created);
      } catch (_) {
        _showMessage(
          'Donation saved. Notification delivery will retry after Firebase setup.',
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.donationDetails, arguments: created);
    } on AppException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to save donation. Please check the form and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  String? _optionalCoordinateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Enter a valid number';
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add donation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Donation title',
                    prefixIcon: Icon(Icons.restaurant_menu_outlined),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: 'Title'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.scale_outlined),
                        ),
                        validator: (value) => Validators.positiveNumber(
                          value,
                          fieldName: 'Quantity',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: AppConstants.donationUnits
                            .map(
                              (unit) => DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => _unit = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickExpiryDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Expiry: ${DateFormatters.dateTime(_expiryDate)}',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (value) =>
                      Validators.requiredText(value, fieldName: 'City'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Latitude',
                        ),
                        validator: _optionalCoordinateValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Longitude',
                        ),
                        validator: _optionalCoordinateValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Handling notes',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save donation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
