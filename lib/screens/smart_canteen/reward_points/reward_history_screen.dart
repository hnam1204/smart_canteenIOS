import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';
import 'reward_model.dart';
import 'widgets/reward_history_widgets.dart';

class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key, required this.history});

  final List<RewardHistoryModel> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 9, 18, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Lịch sử điểm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 46),
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có lịch sử giao dịch',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: history.length,
                      itemBuilder: (context, index) =>
                          RewardHistoryItem(history: history[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
