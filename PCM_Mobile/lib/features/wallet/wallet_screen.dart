import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String? _selectedTypeFilter; // null = all, 'Deposit', 'Booking', 'Refund'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(walletProvider.notifier).loadTransactions();
    });
  }

  List<dynamic> get _filteredTransactions {
    final allTransactions = ref.watch(walletProvider).transactions;

    return allTransactions.where((tx) {
      // Type filter
      if (_selectedTypeFilter != null) {
        final txTypeName = _getTransactionTypeName(tx.type);
        if (!txTypeName.contains(_selectedTypeFilter!)) {
          return false;
        }
      }

      // Date range filter
      if (_filterStartDate != null &&
          tx.createdDate.isBefore(_filterStartDate!)) {
        return false;
      }
      if (_filterEndDate != null &&
          tx.createdDate.isAfter(
            _filterEndDate!.add(const Duration(days: 1)),
          )) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    await ref.read(walletProvider.notifier).loadTransactions();
  }

  Future<void> _showFilterDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lọc giao dịch',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Transaction Type Filter
              const Text(
                'Loại giao dịch:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedTypeFilter == null,
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedTypeFilter = null;
                      });
                      setState(() {});
                    },
                  ),
                  FilterChip(
                    label: const Text('Nạp tiền'),
                    selected: _selectedTypeFilter == 'Nạp',
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedTypeFilter = selected ? 'Nạp' : null;
                      });
                      setState(() {});
                    },
                  ),
                  FilterChip(
                    label: const Text('Đặt sân'),
                    selected: _selectedTypeFilter == 'Đặt',
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedTypeFilter = selected ? 'Đặt' : null;
                      });
                      setState(() {});
                    },
                  ),
                  FilterChip(
                    label: const Text('Hoàn tiền'),
                    selected: _selectedTypeFilter == 'Hoàn',
                    onSelected: (selected) {
                      setModalState(() {
                        _selectedTypeFilter = selected ? 'Hoàn' : null;
                      });
                      setState(() {});
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Date Range Filter
              const Text(
                'Khoảng thời gian:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filterStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            _filterStartDate = date;
                          });
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _filterStartDate != null
                            ? DateFormat('dd/MM/yyyy').format(_filterStartDate!)
                            : 'Từ ngày',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filterEndDate ?? DateTime.now(),
                          firstDate: _filterStartDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setModalState(() {
                            _filterEndDate = date;
                          });
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _filterEndDate != null
                            ? DateFormat('dd/MM/yyyy').format(_filterEndDate!)
                            : 'Đến ngày',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedTypeFilter = null;
                          _filterStartDate = null;
                          _filterEndDate = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final member = authState.member;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.successGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Text(
                            'Số dư hiện tại',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedCounter(
                            value: member?.walletBalance ?? 0,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            suffix: ' VNĐ',
                            decimals: 0,
                          ),
                          const SizedBox(height: 24),
                          GlassButton(
                            text: 'Nạp tiền',
                            icon: Icons.add_circle_outline,
                            onPressed: () => context.push('/wallet/deposit'),
                            height: 50,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch sử giao dịch',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _showFilterDialog,
                          icon: Badge(
                            isLabelVisible:
                                _selectedTypeFilter != null ||
                                _filterStartDate != null,
                            child: const Icon(Icons.filter_list),
                          ),
                          tooltip: 'Lọc giao dịch',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Transactions List
                    if (walletState.isLoading &&
                        walletState.transactions.isEmpty)
                      ...List.generate(
                        5,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: Color(0xFFE0E0E0),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (_filteredTransactions.isEmpty)
                      const EmptyTransactionsState()
                    else
                      ..._filteredTransactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getTransactionTypeColor(
                                      transaction.type,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getTransactionTypeIcon(transaction.type),
                                    color: _getTransactionTypeColor(
                                      transaction.type,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getTransactionTypeName(
                                          transaction.type,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(transaction.createdDate),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (transaction.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          transaction.description!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${transaction.amount > 0 ? '+' : ''}${transaction.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: transaction.amount > 0
                                            ? AppTheme.successGreen
                                            : AppTheme.errorRed,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          transaction.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            transaction.status,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _getStatusText(transaction.status),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            transaction.status,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionTypeIcon(dynamic type) {
    final typeIndex = type.index ?? 0;
    switch (typeIndex) {
      case 0:
        return Icons.add_circle;
      case 1:
        return Icons.sports_tennis;
      case 2:
        return Icons.replay;
      case 3:
        return Icons.emoji_events;
      case 4:
        return Icons.military_tech;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionTypeColor(dynamic type) {
    final typeIndex = type.index ?? 0;
    switch (typeIndex) {
      case 0:
        return AppTheme.successGreen;
      case 1:
        return AppTheme.primaryBlue;
      case 2:
        return AppTheme.warningOrange;
      case 3:
        return AppTheme.secondaryPink;
      case 4:
        return AppTheme.accentOrange;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeName(dynamic type) {
    final typeIndex = type.index ?? 0;
    switch (typeIndex) {
      case 0:
        return 'Nạp tiền';
      case 1:
        return 'Đặt sân';
      case 2:
        return 'Hoàn tiền';
      case 3:
        return 'Tham gia giải';
      case 4:
        return 'Tiền thưởng';
      default:
        return 'Giao dịch';
    }
  }

  Color _getStatusColor(dynamic status) {
    final statusIndex = status.index ?? 0;
    switch (statusIndex) {
      case 0:
        return AppTheme.warningOrange;
      case 1:
        return AppTheme.successGreen;
      case 2:
        return AppTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(dynamic status) {
    final statusIndex = status.index ?? 0;
    switch (statusIndex) {
      case 0:
        return 'Chờ duyệt';
      case 1:
        return 'Thành công';
      case 2:
        return 'Thất bại';
      default:
        return 'Unknown';
    }
  }
}

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(walletProvider.notifier)
          .requestDeposit(
            amount: double.parse(_amountController.text),
            proofImageUrl: _imageUrlController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yêu cầu nạp tiền đã được gửi'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nạp tiền'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.successGreen.withOpacity(0.1),
              AppTheme.primaryBlue.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Info Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.infoBlue,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Vui lòng chuyển khoản theo thông tin bên dưới và đính kèm ảnh chứng từ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bank Info Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Thông tin chuyển khoản',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow('Ngân hàng:', 'Vietcombank'),
                        _buildInfoRow('Số tài khoản:', '1234567890'),
                        _buildInfoRow('Chủ tài khoản:', 'VỢT THỦ PHÔ NÚI'),
                        _buildInfoRow(
                          'Nội dung:',
                          'NAP TIEN [SoDienThoai]',
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền (VNĐ)',
                      prefixIcon: const Icon(Icons.payments),
                      suffixText: 'VNĐ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số tiền';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Số tiền không hợp lệ';
                      }
                      if (amount < 10000) {
                        return 'Số tiền tối thiểu 10,000 VNĐ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Image URL Field
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Link ảnh chứng từ',
                      prefixIcon: Icon(Icons.image),
                      hintText: 'https://example.com/proof.jpg',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập link ảnh';
                      }
                      if (!value.startsWith('http')) {
                        return 'Link không hợp lệ';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  GlassButton(
                    text: 'Gửi yêu cầu nạp tiền',
                    icon: Icons.send,
                    onPressed: _handleDeposit,
                    isLoading: _isLoading,
                    height: 56,
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                color: isHighlight ? AppTheme.primaryBlue : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
