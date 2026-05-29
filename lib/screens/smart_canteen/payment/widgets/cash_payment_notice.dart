import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

class CashPaymentNotice extends StatelessWidget {
  const CashPaymentNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('cash-payment-notice'),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFDDC5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.payments_outlined,
                size: 23,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vui lòng thanh toán tại quầy khi nhận món',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Chuẩn bị đúng số tiền để quá trình nhận món nhanh hơn.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
