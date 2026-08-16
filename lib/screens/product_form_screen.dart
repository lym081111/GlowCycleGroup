import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../models/beauty_product.dart';
import '../models/product_scan_result.dart';
import '../services/glow_store.dart';
import '../services/product_scan_service.dart';
import '../theme/app_colors.dart';
import '../widgets/form_fields.dart';
import '../widgets/info_widgets.dart';

/// Add or edit a product, with optional AI-assisted field extraction.
///
/// Scan results are always shown for review before they touch the form, so a
/// misread never silently corrupts the user's data.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
    required this.onSave,
    required this.store,
    this.closeOnSave = true,
    this.onSaved,
  });

  final BeautyProduct? product;
  final Future<void> Function(BeautyProduct product) onSave;
  final GlowStore store;
  final bool closeOnSave;
  final VoidCallback? onSaved;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  /// Capture settings for every product photo.
  ///
  /// Ingredient lists, batch codes, and PAO marks are printed small, and both
  /// ML Kit OCR and Gemini read the same file the user picked, so 1200px/70%
  /// destroyed exactly the detail the scan depends on.
  ///
  /// These are a compromise, not a maximum. Each photo is also base64-encoded
  /// into the Gemini request, and at 2048px/92% a three-photo scan built a
  /// multi-megabyte upload that aborted mid-flight on mobile connections.
  static const _photoMaxWidth = 1600.0;
  static const _photoQuality = 85;

  /// Ceiling for a base64 photo stored inline on the product record.
  ///
  /// Only reached when the Firebase Storage upload failed, where the data URI
  /// would otherwise be written into a Firestore document and breach the 1 MB
  /// document limit.
  static const _maxInlinePhotoChars = 700 * 1024;

  /// Upper bound on photos per scan, so a multi-photo request stays within a
  /// sensible token budget.
  static const _maxScanPhotos = 4;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _expiryController;
  late final TextEditingController _notesController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _batchController;
  late final TextEditingController _priceController;
  late DateTime _purchaseDate;
  late DateTime _openingDate;
  DateTime? _manufactureDate;
  DateTime? _directExpiryDate;
  late String _category;
  late String _status;

  /// Every photo captured for this product.
  ///
  /// The first is kept as the product image; all of them are sent to the
  /// scanner together, so the front of the box can supply name and brand
  /// while the back supplies the ingredient list and batch code.
  final _scanPhotos = <_ScanPhoto>[];

  /// Image already saved on the product being edited, shown until the user
  /// captures new ones. May be a download URL or an inline data URI.
  var _existingImagePath = '';

  var _scanning = false;
  var _saving = false;
  var _scanConfidence = 0.0;
  var _scanSource = 'manual';

  /// Bytes for the large preview: the first new photo, else whatever was
  /// already saved on the product.
  Uint8List? get _previewBytes => _scanPhotos.isNotEmpty
      ? _scanPhotos.first.bytes
      : decodeProductImage(_existingImagePath);

  /// What gets written to [BeautyProduct.imagePath] on save.
  String get _storedImagePath =>
      _scanPhotos.isNotEmpty ? _scanPhotos.first.dataUri : _existingImagePath;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _expiryController = TextEditingController(
      text: (product?.expiryMonths ?? 12).toString(),
    );
    _existingImagePath = product?.imagePath ?? '';
    _notesController = TextEditingController(text: product?.notes ?? '');
    _ingredientsController = TextEditingController(
      text: product?.ingredients.join(', ') ?? '',
    );
    _batchController = TextEditingController(text: product?.batchNumber ?? '');
    _priceController = TextEditingController(
      text: product?.price == null ? '' : product!.price!.toStringAsFixed(2),
    );
    _purchaseDate = product?.purchaseDate ?? DateTime.now();
    _openingDate = product?.openingDate ?? DateTime.now();
    _manufactureDate = product?.manufactureDate;
    _directExpiryDate = product?.directExpiryDate;
    _scanConfidence = product?.scanConfidence ?? 0;
    _scanSource = product?.scanSource ?? 'manual';
    _category = product?.category ?? 'Skincare';
    _status = editableStatuses.contains(product?.status)
        ? product!.status
        : 'Opened';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _expiryController.dispose();
    _notesController.dispose();
    _ingredientsController.dispose();
    _batchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final selectedExpiry = int.tryParse(_expiryController.text.trim());
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Text(
              isEditing ? 'Refresh product details' : 'Add New Product',
              style: const TextStyle(
                color: ink,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Track its opening date, PAO, and lifecycle status in one place.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.64),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F4), Color(0xFFE7F2E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.1,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                            child: _previewBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: primary.withValues(alpha: 0.9),
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Photo',
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  )
                                : Image.memory(
                                    _previewBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                        ),
                        if (_scanPhotos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _ScanPhotoStrip(
                            photos: _scanPhotos,
                            onRemove: (index) =>
                                setState(() => _scanPhotos.removeAt(index)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _pickProductPhoto(ImageSource.camera),
                                child: const Icon(Icons.photo_camera_outlined),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _pickProductPhoto(ImageSource.gallery),
                                child: const Icon(Icons.photo_library_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _scanning ? null : _scanPhotoWithAi,
                          icon: _scanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _scanning
                                ? 'Scanning...'
                                : _scanPhotos.isEmpty
                                ? 'AI scan'
                                : 'Extract from ${_scanPhotos.length} photo${_scanPhotos.length == 1 ? '' : 's'}',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Smart Fill',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _scanSource == 'manual'
                              ? 'Scan packaging text to auto-fill ingredients, dates, batch number, and category.'
                              : 'Last scan confidence: ${(_scanConfidence * 100).round()}%',
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.66),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final months in [6, 12, 18, 24])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${months}M',
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FormPanel(
              title: 'Product Identity',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      prefixIcon: Icon(Icons.spa_outlined),
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: productCategories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      final category = value ?? 'Skincare';
                      setState(() {
                        _category = category;
                        _expiryController.text =
                            (categoryExpiryMonths[category] ?? 12).toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormPanel(
              title: 'Lifecycle',
              child: Column(
                children: [
                  DatePickerTile(
                    label: 'Purchase date',
                    date: _purchaseDate,
                    onPick: (date) => setState(() => _purchaseDate = date),
                  ),
                  const SizedBox(height: 10),
                  DatePickerTile(
                    label: 'Opening date',
                    date: _openingDate,
                    onPick: (date) => setState(() => _openingDate = date),
                  ),
                  const SizedBox(height: 10),
                  OptionalDatePickerTile(
                    label: 'Manufacturing date',
                    date: _manufactureDate,
                    onPick: (date) => setState(() => _manufactureDate = date),
                    onClear: () => setState(() => _manufactureDate = null),
                  ),
                  const SizedBox(height: 10),
                  OptionalDatePickerTile(
                    label: 'Printed expiry date',
                    date: _directExpiryDate,
                    onPick: (date) => setState(() => _directExpiryDate = date),
                    onClear: () => setState(() => _directExpiryDate = null),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PAO duration',
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final months in [3, 6, 12, 18, 24])
                        ChoiceChip(
                          selected: selectedExpiry == months,
                          label: Text('${months}M'),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _expiryController.text = months.toString(),
                              );
                            }
                          },
                          selectedColor: primaryContainer,
                          backgroundColor: surfaceLow,
                          labelStyle: TextStyle(
                            color: selectedExpiry == months
                                ? primary
                                : ink.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom expiry months',
                      prefixIcon: Icon(Icons.event_repeat_outlined),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid number of months';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    items: editableStatuses
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'Opened'),
                    decoration: const InputDecoration(
                      labelText: 'Product status',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormPanel(
              title: 'Optional Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _ingredientsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch number',
                      prefixIcon: Icon(Icons.qr_code_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Estimated price (RM)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(text);
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: ink.withValues(alpha: 0.06))),
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(
              _saving
                  ? 'Saving...'
                  : (isEditing ? 'Save Changes' : 'Add to Shelf'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Adds a photo to [_scanPhotos].
  ///
  /// Photos accumulate rather than replace, so the user can shoot the front
  /// of the package and then the ingredient panel on the back.
  Future<void> _pickProductPhoto(ImageSource source) async {
    if (_scanPhotos.length >= _maxScanPhotos) {
      _showFormMessage('You can attach up to $_maxScanPhotos photos.');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: _photoMaxWidth,
        imageQuality: _photoQuality,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        return;
      }
      setState(() {
        _scanPhotos.add(
          _ScanPhoto(
            path: picked.path,
            dataUri: 'data:image/jpeg;base64,${base64Encode(bytes)}',
            bytes: bytes,
          ),
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open photo picker: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Reads every attached photo in one pass.
  ///
  /// Both outcomes of the review sheet fill the form; the difference is only
  /// the follow-up message. Discarding a scan means dismissing the sheet, so
  /// the extracted values are never silently thrown away.
  Future<void> _scanPhotoWithAi() async {
    if (_scanPhotos.isEmpty) {
      await _pickProductPhoto(ImageSource.camera);
      if (_scanPhotos.isEmpty) {
        return;
      }
    }

    try {
      setState(() => _scanning = true);
      final result = await ProductScanService(store: widget.store).scan(
        photos: [
          for (final photo in _scanPhotos)
            (path: photo.path, dataUri: photo.dataUri),
        ],
      );
      if (!mounted) {
        return;
      }
      final choice = await _showScanReview(result);
      if (choice == null || !mounted) {
        return;
      }
      _applyScanResult(result);
      _showFormMessage(
        choice == _ScanReviewChoice.edit
            ? 'Details filled in below. Change anything the scan got wrong.'
            : 'Scan applied. Please check every field before saving.',
      );
    } catch (error) {
      _showFormMessage('Unable to scan product details: $error');
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _applyScanResult(ProductScanResult result) {
    setState(() {
      if (result.productName.isNotEmpty) {
        _nameController.text = result.productName;
      }
      if (result.brand.isNotEmpty) {
        _brandController.text = result.brand;
      }
      if (productCategories.contains(result.category)) {
        _category = result.category;
      }
      if (result.ingredients.isNotEmpty) {
        _ingredientsController.text = result.ingredients.join(', ');
      }
      if (result.batchNumber.isNotEmpty) {
        _batchController.text = result.batchNumber;
      }
      if (result.manufactureDate != null) {
        _manufactureDate = result.manufactureDate;
      }
      if (result.expiryDate != null) {
        _directExpiryDate = result.expiryDate;
      }
      if (result.paoMonths != null && result.paoMonths! > 0) {
        _expiryController.text = result.paoMonths.toString();
      }
      _scanConfidence = result.confidence;
      _scanSource = result.source;
    });
    // Raw OCR text is deliberately not written into Notes. Notes are sent to
    // Glow Assistant via BeautyProduct.toAssistantJson(), so garbled scan text
    // would become context the chatbot reasons over, and it stacked up with
    // every rescan. The user reviews that text in the scan sheet instead.
  }

  Future<_ScanReviewChoice?> _showScanReview(ProductScanResult result) {
    return showModalBottomSheet<_ScanReviewChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review scan result',
              style: TextStyle(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            DetailRow(label: 'Name', value: result.productName),
            DetailRow(label: 'Brand', value: result.brand),
            DetailRow(label: 'Category', value: result.category),
            DetailRow(
              label: 'Ingredients',
              value: result.ingredients.isEmpty
                  ? 'Not detected'
                  : result.ingredients.take(8).join(', '),
            ),
            DetailRow(
              label: 'Expiry',
              value: result.expiryDate == null
                  ? 'Not detected'
                  : dateFormat.format(result.expiryDate!),
            ),
            DetailRow(
              label: 'Confidence',
              value: '${(result.confidence * 100).round()}%',
            ),
            DetailRow(
              label: 'Read by',
              value: result.source == 'gemini-vision'
                  ? 'Gemini vision'
                  : 'On-device OCR only',
            ),
            DetailRow(label: 'Text read', value: result.rawTextPreview),
            if (result.source != 'gemini-vision') ...[
              const SizedBox(height: 8),
              const Text(
                'Gemini could not be reached, so these fields came from '
                'on-device text matching alone. Expect gaps, and check every '
                'value before saving.',
                style: TextStyle(color: secondary, fontWeight: FontWeight.w700),
              ),
            ] else if (result.confidence < 0.72) ...[
              const SizedBox(height: 8),
              const Text(
                'Some packaging text was unclear. Check the photo and edit any field that looks wrong.',
                style: TextStyle(color: secondary, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Both options fill the form and nothing is saved yet, so every '
              'field stays editable. Swipe this sheet down to discard the scan.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.62),
                height: 1.3,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ScanReviewChoice.edit),
                    child: const Text('Edit manually'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_ScanReviewChoice.apply),
                    child: const Text('Apply scan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFormMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _showFormMessage(
        'Please complete Product name, Brand, and expiry months.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.product;
      final id = existing?.id ?? now.microsecondsSinceEpoch.toString();
      final inlinePhoto = _storedImagePath.trim();
      final uploadedImagePath = await widget.store.uploadProductPhoto(
        productId: id,
        dataUri: inlinePhoto,
      );
      // Scan-quality captures produce large data URIs. When the Storage upload
      // gave us no URL, only keep the photo inline while it is small enough to
      // fit inside a Firestore document.
      final photoDropped =
          uploadedImagePath.isEmpty &&
          inlinePhoto.length > _maxInlinePhotoChars;
      if (photoDropped) {
        _showFormMessage(
          'Photo was too large to store offline, so it was not saved. '
          'Product details were kept.',
        );
      }
      final product = BeautyProduct(
        id: id,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _category,
        purchaseDate: _purchaseDate,
        openingDate: _openingDate,
        expiryMonths: int.parse(_expiryController.text.trim()),
        status: _status,
        imagePath: uploadedImagePath.isNotEmpty
            ? uploadedImagePath
            : (photoDropped ? '' : inlinePhoto),
        notes: _notesController.text.trim(),
        ingredients: parseIngredients(_ingredientsController.text),
        manufactureDate: _manufactureDate,
        directExpiryDate: _directExpiryDate,
        batchNumber: _batchController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? null
            : double.parse(_priceController.text.trim()),
        scanConfidence: _scanConfidence,
        scanSource: _scanSource,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await widget.onSave(product);
      if (!mounted) {
        return;
      }
      if (widget.closeOnSave && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        widget.onSaved?.call();
        _showFormMessage('${product.name} added to your beauty shelf.');
      }
    } catch (error) {
      _showFormMessage('Unable to save product: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// White card grouping a set of related form fields.
class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// One captured photo, held in memory until the product is saved.
class _ScanPhoto {
  const _ScanPhoto({
    required this.path,
    required this.dataUri,
    required this.bytes,
  });

  /// On-device file path, used by ML Kit for on-device OCR.
  final String path;

  /// Inline `data:image/jpeg;base64,...` form, sent to Gemini and stored on
  /// the product when it is the first photo.
  final String dataUri;

  final Uint8List bytes;
}

/// What the user chose in the scan review sheet.
///
/// Both values fill the form. Dismissing the sheet returns null, which is the
/// only way to discard a scan.
enum _ScanReviewChoice { apply, edit }

/// Thumbnails of every attached photo, each removable.
class _ScanPhotoStrip extends StatelessWidget {
  const _ScanPhotoStrip({required this.photos, required this.onRemove});

  final List<_ScanPhoto> photos;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  photos[index].bytes,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ink.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: ink.withValues(alpha: 0.55),
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: const Text(
                      'Main',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
