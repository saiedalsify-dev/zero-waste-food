import 'package:flutter/material.dart';

import '../../models/donation.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final DonationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      DonationStatus.pending => (
        const Color(0xFFFFE08A),
        const Color(0xFF5A3A00),
      ),
      DonationStatus.accepted => (
        const Color(0xFFC9F2D3),
        const Color(0xFF0B5D2A),
      ),
      DonationStatus.rejected => (
        const Color(0xFFFFD2D2),
        const Color(0xFF8A1C1C),
      ),
      DonationStatus.completed => (
        const Color(0xFFD7E7FF),
        const Color(0xFF12427A),
      ),
    };

    return Chip(
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.$1,
      labelStyle: TextStyle(color: colors.$2, fontWeight: FontWeight.w700),
      side: BorderSide(color: colors.$2.withAlpha(42)),
    );
  }
}
