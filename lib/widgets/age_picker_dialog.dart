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
  late TextEditingController _controller;
  late int _selectedAge;

  @override
  void initState() {
    super.initState();
    _selectedAge = widget.initialAge;
    _controller = TextEditingController(text: widget.initialAge.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        '나이 설정',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '나이를 입력해주세요',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '나이',
              suffixText: '세',
            ),
            onChanged: (value) {
              final age = int.tryParse(value);
              if (age != null && age >= 1 && age <= 120) {
                setState(() {
                  _selectedAge = age;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            final age = int.tryParse(_controller.text);
            if (age != null && age >= 1 && age <= 120) {
              widget.onSelected(age);
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('올바른 나이를 입력해주세요 (1-120세)')),
              );
            }
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
