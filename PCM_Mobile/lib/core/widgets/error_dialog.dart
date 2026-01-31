import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class ErrorAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  ErrorAction(this.label, this.onPressed, {this.isPrimary = false});
}

class ErrorDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? errorCode,
    List<ErrorAction>? actions,
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                color: AppTheme.errorRed,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorRed,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mã lỗi: $errorCode',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: actions != null && actions.isNotEmpty
            ? actions.map((action) {
                return action.isPrimary
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          action.onPressed?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(action.label),
                      )
                    : TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          action.onPressed?.call();
                        },
                        child: Text(action.label),
                      );
              }).toList()
            : [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đóng'),
                ),
              ],
      ),
    );
  }

  // Quick helper for network errors
  static Future<void> showNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    return show(
      context,
      title: 'Lỗi kết nối',
      message:
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet và thử lại.',
      errorCode: 'NETWORK_ERROR',
      icon: Icons.wifi_off,
      actions: [
        ErrorAction('Đóng', null),
        if (onRetry != null) ErrorAction('Thử lại', onRetry, isPrimary: true),
      ],
    );
  }

  // Quick helper for timeout errors
  static Future<void> showTimeoutError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    return show(
      context,
      title: 'Hết thời gian chờ',
      message: 'Yêu cầu mất quá nhiều thời gian. Vui lòng thử lại sau.',
      errorCode: 'TIMEOUT_ERROR',
      icon: Icons.hourglass_empty,
      actions: [
        ErrorAction('Đóng', null),
        if (onRetry != null) ErrorAction('Thử lại', onRetry, isPrimary: true),
      ],
    );
  }

  // Quick helper for unauthorized errors
  static Future<void> showUnauthorizedError(
    BuildContext context, {
    VoidCallback? onLogin,
  }) {
    return show(
      context,
      title: 'Phiên đăng nhập hết hạn',
      message: 'Vui lòng đăng nhập lại để tiếp tục sử dụng ứng dụng.',
      errorCode: 'UNAUTHORIZED',
      icon: Icons.lock_outline,
      actions: [
        ErrorAction('Đóng', null),
        if (onLogin != null) ErrorAction('Đăng nhập', onLogin, isPrimary: true),
      ],
    );
  }
}

// Success Dialog
class SuccessDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppTheme.successGreen,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successGreen,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClose?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Confirmation Dialog
class ConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDanger ? AppTheme.errorRed : AppTheme.warningOrange)
                    .withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDanger ? Icons.warning_amber : Icons.help_outline,
                color: isDanger ? AppTheme.errorRed : AppTheme.warningOrange,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDanger ? AppTheme.errorRed : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger
                  ? AppTheme.errorRed
                  : AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
