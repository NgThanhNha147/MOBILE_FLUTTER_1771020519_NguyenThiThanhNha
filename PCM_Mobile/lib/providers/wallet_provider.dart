import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/wallet_service.dart';
import '../models/wallet_transaction.dart';

final walletServiceProvider = Provider((ref) => WalletService());

class WalletState {
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;

  WalletState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletService _walletService;

  WalletNotifier(this._walletService) : super(WalletState());

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _walletService.getMyTransactions();
      state = state.copyWith(transactions: transactions, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> requestDeposit({
    required double amount,
    required String proofImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _walletService.requestDeposit(
        amount: amount,
        proofImageUrl: proofImageUrl,
      );
      await loadTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  return WalletNotifier(ref.watch(walletServiceProvider));
});
