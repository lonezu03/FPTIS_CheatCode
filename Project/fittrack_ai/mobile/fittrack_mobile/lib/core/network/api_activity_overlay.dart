import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api_activity_controller.dart';

class ApiActivityOverlay extends StatelessWidget {
  const ApiActivityOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final activity = context.watch<ApiActivityController>();
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        // Không hiện thanh tải chung cho request đọc: các lần tự làm mới chạy
        // ngầm (thông báo, phiên tập trung) làm thanh này chạy gần như liên tục.
        // Mỗi màn đã có trạng thái tải riêng.
        if (activity.isMutating) ...[
          const ModalBarrier(dismissible: false, color: Color(0x330F172A)),
          Center(
            child: Semantics(
              liveRegion: true,
              label: 'Đang xử lý yêu cầu',
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đang xử lý...',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Đợ 1 chúc',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
