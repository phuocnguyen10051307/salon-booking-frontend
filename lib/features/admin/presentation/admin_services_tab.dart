import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/cloudinary_service.dart';
import '../../store/data/models/service_model.dart';
import '../../store/provider/service_provider.dart';

class AdminServicesTab extends StatefulWidget {
  const AdminServicesTab({super.key});

  @override
  State<AdminServicesTab> createState() => _AdminServicesTabState();
}

class _AdminServicesTabState extends State<AdminServicesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'd');

    return Consumer<ServiceProvider>(
      builder: (context, provider, child) {
        return ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Services',
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (provider.error != null)
              _StateText(text: 'Can not load services.')
            else if (provider.services.isEmpty)
              _StateText(text: 'No services yet.')
            else
              ...provider.services.map(
                (service) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service.durationMinutes} mins  ${formatter.format(service.price)}',
                              style: GoogleFonts.openSans(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: service.isActive ? const Color(0xFF00695C) : Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openForm(context, service: service),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _delete(context, service),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, ServiceModel service) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete service'),
        content: Text('Delete ${service.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<ServiceProvider>().deleteService(service.id);
  }

  void _openForm(BuildContext context, {ServiceModel? service}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ServiceForm(service: service),
    );
  }
}

class _ServiceForm extends StatefulWidget {
  final ServiceModel? service;

  const _ServiceForm({this.service});

  @override
  State<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _cloudinaryService = CloudinaryService();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _categoryId;
  late bool _isActive;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _name = TextEditingController(text: service?.name ?? '');
    _price = TextEditingController(text: service?.price.toString() ?? '');
    _duration = TextEditingController(text: service?.durationMinutes.toString() ?? '');
    _description = TextEditingController(text: service?.description ?? '');
    _imageUrl = TextEditingController(text: service?.imageUrl ?? '');
    _categoryId = TextEditingController(text: service?.categoryId ?? '');
    _isActive = service?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    _imageUrl.dispose();
    _categoryId.dispose();
    super.dispose();
  }

  Future<void> _uploadImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);
      final imageUrl = await _cloudinaryService.uploadImage(pickedFile);
      _imageUrl.text = imageUrl;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded image to Cloudinary successfully.')),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<ServiceProvider>().saveService(
          existing: widget.service,
          name: _name.text.trim(),
          price: double.parse(_price.text.trim()),
          durationMinutes: int.parse(_duration.text.trim()),
          description: _emptyToNull(_description.text),
          imageUrl: _emptyToNull(_imageUrl.text),
          categoryId: _emptyToNull(_categoryId.text),
          isActive: _isActive,
        );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      return;
    }

    final error = context.read<ServiceProvider>().error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service == null ? 'Add service' : 'Edit service',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _Field(controller: _name, label: 'Name', validator: _required),
              _Field(controller: _price, label: 'Price', keyboardType: TextInputType.number, validator: _number),
              _Field(controller: _duration, label: 'Duration minutes', keyboardType: TextInputType.number, validator: _integer),
              _Field(controller: _description, label: 'Description'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Service image',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Cloudinary'),
                  ),
                ],
              ),
              if (!_cloudinaryService.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Missing Cloudinary config in .env. Fill CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET first.',
                    style: GoogleFonts.openSans(color: Colors.orange.shade800, fontSize: 12),
                  ),
                ),
              if (_imageUrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrl.text.trim(),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 160,
                        color: const Color(0xFFF7FAFA),
                        alignment: Alignment.center,
                        child: const Text('Preview unavailable'),
                      ),
                    ),
                  ),
                ),
              _Field(controller: _imageUrl, label: 'Image URL'),
              _Field(controller: _categoryId, label: 'Category ID'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                title: Text('Active', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  String? _number(String? value) => double.tryParse(value?.trim() ?? '') == null ? 'Invalid number' : null;
  String? _integer(String? value) => int.tryParse(value?.trim() ?? '') == null ? 'Invalid number' : null;
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({required this.controller, required this.label, this.keyboardType, this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7FAFA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}

class _StateText extends StatelessWidget {
  final String text;

  const _StateText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text, style: GoogleFonts.openSans(color: Colors.grey.shade600))),
    );
  }
}
