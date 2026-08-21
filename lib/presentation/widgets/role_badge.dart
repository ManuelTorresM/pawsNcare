import 'package:flutter/material.dart';
import '../../data/models/pet_role.dart';

class RoleBadge extends StatelessWidget {
  final PetRole role;
  final bool isCompact;

  const RoleBadge({
    super.key,
    required this.role,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: role.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: role.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role.icon,
            size: isCompact ? 12 : 14,
            color: role.color,
          ),
          const SizedBox(width: 4),
          Text(
            role.displayName,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 10 : 12,
              color: role.color,
            ),
          ),
        ],
      ),
    );
  }
}
