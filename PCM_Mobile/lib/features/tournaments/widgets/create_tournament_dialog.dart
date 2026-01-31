import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/enums.dart';
import '../../../models/tournament.dart';
import '../../../providers/tournament_provider.dart';

class CreateTournamentDialog extends ConsumerStatefulWidget {
  final TournamentType initialType;

  const CreateTournamentDialog({
    super.key,
    required this.initialType,
  });

  @override
  ConsumerState<CreateTournamentDialog> createState() =>
      _CreateTournamentDialogState();
}

class _CreateTournamentDialogState
    extends ConsumerState<CreateTournamentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _entryFeeController = TextEditingController(text: '0');

  late TournamentType _selectedType;
  TournamentFormat _selectedFormat = TournamentFormat.knockout;
  int _maxParticipants = 2;
  DateTime _startDate = DateTime.now().add(const Duration(hours: 2));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 4));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _maxParticipants = _selectedType == TournamentType.challenge1v1 ? 2 : 8;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedType == TournamentType.challenge1v1
                          ? 'Tạo Kèo 1v1'
                          : 'Tạo Giải Đấu Team',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tên
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên giải đấu *',
                          hintText: 'VD: Kèo solo 100k',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên giải đấu';
                          }
                          return null;
                        },
                        maxLength: 200,
                      ),

                      const SizedBox(height: 16),

                      // Mô tả
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Mô tả chi tiết về giải đấu',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),

                      const SizedBox(height: 16),

                      // Format
                      DropdownButtonFormField<TournamentFormat>(
                        value: _selectedFormat,
                        decoration: InputDecoration(
                          labelText: 'Thể thức thi đấu',
                          prefixIcon: const Icon(Icons.format_list_bulleted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TournamentFormat.knockout,
                            child: Text('Loại trực tiếp (Knockout)'),
                          ),
                          DropdownMenuItem(
                            value: TournamentFormat.roundRobin,
                            child: Text('Vòng tròn (Round Robin)'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedFormat = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Số người
                      if (_selectedType == TournamentType.challenge1v1)
                        TextFormField(
                          initialValue: '2',
                          decoration: InputDecoration(
                            labelText: 'Số người tham gia',
                            prefixIcon: const Icon(Icons.people),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabled: false,
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _maxParticipants,
                          decoration: InputDecoration(
                            labelText: 'Số người tối đa',
                            prefixIcon: const Icon(Icons.people),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 4, child: Text('4 người (2 đội)')),
                            DropdownMenuItem(value: 8, child: Text('8 người (4 đội)')),
                            DropdownMenuItem(value: 16, child: Text('16 người (8 đội)')),
                            DropdownMenuItem(value: 32, child: Text('32 người (16 đội)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _maxParticipants = value);
                            }
                          },
                        ),

                      const SizedBox(height: 16),

                      // Lệ phí
                      TextFormField(
                        controller: _entryFeeController,
                        decoration: InputDecoration(
                          labelText: 'Lệ phí tham gia (đ)',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixText: 'đ',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final fee = int.tryParse(value);
                          if (fee == null || fee < 0) {
                            return 'Lệ phí không hợp lệ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Thời gian bắt đầu
                      InkWell(
                        onTap: () => _selectStartDateTime(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Thời gian bắt đầu',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(_startDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Thời gian kết thúc
                      InkWell(
                        onTap: () => _selectEndDateTime(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Thời gian kết thúc',
                            prefixIcon: const Icon(Icons.event),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(_endDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Thông tin giải thưởng
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '💰 Giải thưởng dự kiến',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _calculatePrizePool(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(80% tổng lệ phí)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleCreate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Tạo giải đấu',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculatePrizePool() {
    final entryFee = int.tryParse(_entryFeeController.text) ?? 0;
    final prizePool = (entryFee * _maxParticipants * 0.8).round();
    return '${NumberFormat('#,###').format(prizePool)}đ';
  }

  Future<void> _selectStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
      );

      if (time != null) {
        setState(() {
          _startDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          // Auto update end date to 2 hours later
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 2));
          }
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (time != null) {
        setState(() {
          _endDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_endDate.isBefore(_startDate)) {
      _showError('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateTournamentRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _selectedType,
        format: _selectedFormat,
        startDate: _startDate,
        endDate: _endDate,
        maxParticipants: _maxParticipants,
        entryFee: double.tryParse(_entryFeeController.text) ?? 0,
      );

      await ref
          .read(tournamentNotifierProvider.notifier)
          .createTournament(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tạo giải đấu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Lỗi tạo giải đấu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
