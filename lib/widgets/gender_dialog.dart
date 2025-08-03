import 'package:flutter/material.dart';

class GenderDialog extends StatelessWidget {
  final String selectedGender;
  final void Function(String) onSelected;

  const GenderDialog({
    super.key,
    required this.selectedGender,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('성별 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('남자'),
            value: '남',
            groupValue: selectedGender,
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<String>(
            title: const Text('여자'),
            value: '여',
            groupValue: selectedGender,
            onChanged: (value) {
              if (value != null) {
                onSelected(value);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('취소'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
