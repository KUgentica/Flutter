import 'package:flutter/material.dart';

class AgePickerDialog extends StatefulWidget {
  final int initialAge;
  final void Function(int) onSelected;

  const AgePickerDialog({
    super.key,
    required this.initialAge,
    required this.onSelected,
  });

  @override
  State<AgePickerDialog> createState() => _AgePickerDialogState();
}

class _AgePickerDialogState extends State<AgePickerDialog> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialAge - 14);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '나이 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 42, // 정확한 한 칸 높이
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => setState(() {}),
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final age = index + 14;
                  return Center(
                    child: Text(
                      '$age세',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        height: 1.2, // 높이 조정
                      ),
                      textAlign: TextAlign.center,
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  );
                },
                childCount: 87, // 14~100
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              widget.onSelected(_controller.selectedItem + 14);
              Navigator.pop(context);
            },
            child: const Text(
              '선택 완료',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
