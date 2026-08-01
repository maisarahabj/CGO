import 'package:flutter/material.dart';

class HomeFloorSelector extends StatelessWidget {
  const HomeFloorSelector({
    required this.floors,
    required this.selectedFloor,
    required this.onFloorSelected,
    super.key,
  });

  final List<String> floors;
  final String selectedFloor;
  final ValueChanged<String> onFloorSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final floor in floors)
            _FloorButton(
              label: floor,
              isSelected: floor == selectedFloor,
              onPressed: () => onFloorSelected(floor),
            ),
        ],
      ),
    );
  }
}

class _FloorButton extends StatelessWidget {
  const _FloorButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
        child: Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A77B4) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
