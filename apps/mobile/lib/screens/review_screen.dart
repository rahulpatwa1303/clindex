import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> scanData;
  final String imageUrl;
  final String scanId;
  final Map<String, dynamic>? scanMeta;
  final ApiService apiService;

  const ReviewScreen({
    super.key,
    required this.scanData,
    required this.imageUrl,
    required this.scanId,
    this.scanMeta,
    required this.apiService,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<Map<String, dynamic>> _records;
  bool _isSaving = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.scanData['records'] as List<dynamic>? ?? [];
    _records = raw.map((r) => _copyRecord(r as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _copyRecord(Map<String, dynamic> r) {
    return r.map((k, v) {
      if (v is Map) return MapEntry(k, Map<String, dynamic>.from(v as Map));
      return MapEntry(k, v);
    });
  }

  dynamic _val(dynamic field) {
    if (field is Map && field.containsKey('value')) return field['value'];
    return field ?? '';
  }

  double _confidence(Map<String, dynamic> record) {
    double sum = 0;
    int count = 0;
    for (final key in ['patient_name', 'treatment', 'amount', 'mode']) {
      if (record[key] is Map && record[key]['confidence'] != null) {
        sum += (record[key]['confidence'] as num).toDouble();
        count++;
      }
    }
    return count > 0 ? sum / count : 1.0;
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
        return 'Verified';
      case 'processing':
      case 'pending':
        return 'Processing';
      case 'review_needed':
      case 'needs_review':
        return 'Needs Review';
      case 'rejected':
      case 'failed':
        return 'Rejected';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'review_needed':
      case 'needs_review':
        return const Color(0xFF3B82F6);
      case 'rejected':
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  void _setField(int idx, String field, dynamic value) {
    setState(() {
      final rec = _records[idx];
      if (rec[field] is Map) {
        (rec[field] as Map)['value'] = value;
      } else {
        rec[field] = {'value': value, 'confidence': 1.0};
      }
    });
  }

  // ── Bottom sheet: edit a single record ──────────────────────────────────────

  void _showEditSheet(int recordIndex) {
    final rec = _records[recordIndex];
    final nameCtrl =
        TextEditingController(text: _val(rec['patient_name']).toString());
    final treatmentCtrl =
        TextEditingController(text: _val(rec['treatment']).toString());
    final amountCtrl =
        TextEditingController(text: _val(rec['amount']).toString());
    String mode = _val(rec['mode']).toString();
    if (mode != 'Cash' && mode != 'Online') mode = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dragHandle(),
              const SizedBox(height: 16),
              Text(
                'Edit Record #${recordIndex + 1}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _sheetField('Patient Name', nameCtrl),
              const SizedBox(height: 12),
              _sheetField('Treatment', treatmentCtrl),
              const SizedBox(height: 12),
              _sheetField('Amount', amountCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _modeDropdown(mode, (val) => setSheet(() => mode = val!)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _setField(recordIndex, 'patient_name',
                        nameCtrl.text.trim());
                    _setField(recordIndex, 'treatment',
                        treatmentCtrl.text.trim());
                    _setField(
                        recordIndex,
                        'amount',
                        double.tryParse(amountCtrl.text.trim()) ?? 0);
                    _setField(recordIndex, 'mode', mode);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom sheet: add new record ────────────────────────────────────────────

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String mode = 'Cash';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dragHandle(),
              const SizedBox(height: 16),
              const Text(
                'Add New Record',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _sheetField('Patient Name', nameCtrl),
              const SizedBox(height: 12),
              _sheetField('Treatment', treatmentCtrl),
              const SizedBox(height: 12),
              _sheetField('Amount', amountCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _modeDropdown(mode, (val) => setSheet(() => mode = val!)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _records.add({
                        'patient_name': {
                          'value': nameCtrl.text.trim(),
                          'confidence': 1.0
                        },
                        'treatment': {
                          'value': treatmentCtrl.text.trim(),
                          'confidence': 1.0
                        },
                        'amount': {
                          'value': double.tryParse(amountCtrl.text.trim()) ?? 0,
                          'confidence': 1.0
                        },
                        'mode': {'value': mode, 'confidence': 1.0},
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Full-screen edit all records ─────────────────────────────────────────────

  void _showEditAll() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EditAllSheet(
        records: _records,
        onSave: (updated) => setState(() => _records = updated),
      ),
    );
  }

  // ── Verify & Save ────────────────────────────────────────────────────────────

  Future<void> _handleVerify() async {
    setState(() => _isSaving = true);
    try {
      final verifiedData = Map<String, dynamic>.from(widget.scanData)
        ..['records'] = _records;
      await widget.apiService.verifyScan(widget.scanId, verifiedData);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────────

  Future<void> _handleReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Scan'),
        content: const Text(
            'Mark this scan as failed? It can be retried later from the dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isRejecting = true);
    try {
      await widget.apiService.rejectScan(widget.scanId);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  // ── View full image ───────────────────────────────────────────────────────────

  void _viewFullImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullImageScreen(imageUrl: widget.imageUrl),
      ),
    );
  }

  // ── Shared sheet widgets ──────────────────────────────────────────────────────

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _sheetField(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _modeDropdown(String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mode',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const [
            DropdownMenuItem(value: 'Cash', child: Text('Cash')),
            DropdownMenuItem(value: 'Online', child: Text('Online')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.scanMeta?['status'] as String? ?? 'processing';
    final statusColor = _statusColor(status);
    final batchId = widget.scanId
        .substring(
            0,
            widget.scanId.length > 12 ? 12 : widget.scanId.length)
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Scan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // ── Header card ──────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.scanData['title'] as String? ??
                              'Register Scan',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.tag_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Batch ID: $batchId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Image card ───────────────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.imageUrl.isNotEmpty
                    ? Image.network(
                        widget.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(theme),
                      )
                    : _imagePlaceholder(theme),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4361EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'AI SCANNED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _viewFullImage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'View Full',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Records card ─────────────────────────────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4361EE).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.table_rows_rounded,
                            color: Color(0xFF4361EE), size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Extracted Records (${_records.length})',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: _showEditAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF4361EE),
                        ),
                        child: const Text('Edit All',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

                // Column headers
                Container(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text('ID',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            )),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('PATIENT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            )),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('DOCTOR / TREATMENT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            )),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),

                // Record rows
                ..._records.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final record = entry.value;
                  final conf = _confidence(record);
                  final isLow = conf < 0.6;
                  final patientName =
                      _val(record['patient_name']).toString();
                  final treatment = _val(record['treatment']).toString();

                  return Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Row(
                                children: [
                                  Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isLow
                                          ? const Color(0xFFF59E0B)
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isLow)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 2),
                                      child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 12,
                                          color: Color(0xFFF59E0B)),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                patientName.isNotEmpty
                                    ? patientName
                                    : '—',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                treatment.isNotEmpty ? treatment : '—',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 16,
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                              onPressed: () => _showEditSheet(idx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),

                // Footer
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: [
                      Text(
                        '${_records.length} records found',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showAddSheet,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Record'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF4361EE),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Sticky action bar ───────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      (_isSaving || _isRejecting) ? null : _handleReject,
                  child: _isRejecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      (_isSaving || _isRejecting) ? null : _handleVerify,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.image_rounded,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
    );
  }
}

// ── Edit All Sheet ─────────────────────────────────────────────────────────────

class _EditAllSheet extends StatefulWidget {
  final List<Map<String, dynamic>> records;
  final void Function(List<Map<String, dynamic>> updated) onSave;

  const _EditAllSheet({required this.records, required this.onSave});

  @override
  State<_EditAllSheet> createState() => _EditAllSheetState();
}

class _EditAllSheetState extends State<_EditAllSheet> {
  late List<_RecordControllers> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.records.map((r) {
      dynamic val(String k) {
        final f = r[k];
        if (f is Map && f.containsKey('value')) return f['value'];
        return f ?? '';
      }

      String mode = val('mode').toString();
      if (mode != 'Cash' && mode != 'Online') mode = 'Cash';

      return _RecordControllers(
        name: TextEditingController(text: val('patient_name').toString()),
        treatment: TextEditingController(text: val('treatment').toString()),
        amount: TextEditingController(text: val('amount').toString()),
        mode: mode,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.name.dispose();
      c.treatment.dispose();
      c.amount.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updated = List.generate(widget.records.length, (i) {
      final rec = Map<String, dynamic>.from(widget.records[i].map(
        (k, v) => v is Map
            ? MapEntry(k, Map<String, dynamic>.from(v as Map))
            : MapEntry(k, v),
      ));
      final ctrl = _controllers[i];

      void set(String field, dynamic value) {
        if (rec[field] is Map) {
          (rec[field] as Map)['value'] = value;
        } else {
          rec[field] = {'value': value, 'confidence': 1.0};
        }
      }

      set('patient_name', ctrl.name.text.trim());
      set('treatment', ctrl.treatment.text.trim());
      set('amount', double.tryParse(ctrl.amount.text.trim()) ?? 0);
      set('mode', ctrl.mode);
      return rec;
    });

    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Edit All Records',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: _save,
                      child: const Text('Save All'),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          // Scrollable records
          Expanded(
            child: ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: _controllers.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (ctx, i) {
                final ctrl = _controllers[i];
                return StatefulBuilder(
                  builder: (ctx, setRow) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Record #${i + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 10),
                      _field('Patient Name', ctrl.name),
                      const SizedBox(height: 10),
                      _field('Treatment', ctrl.treatment),
                      const SizedBox(height: 10),
                      _field('Amount', ctrl.amount,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mode',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: ctrl.mode,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(
                                  value: 'Online', child: Text('Online')),
                            ],
                            onChanged: (val) =>
                                setRow(() => ctrl.mode = val!),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _RecordControllers {
  final TextEditingController name;
  final TextEditingController treatment;
  final TextEditingController amount;
  String mode;

  _RecordControllers({
    required this.name,
    required this.treatment,
    required this.amount,
    required this.mode,
  });
}

// ── Full Image Screen ──────────────────────────────────────────────────────────

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const _FullImageScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Full Image'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
