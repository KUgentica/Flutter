import 'package:flutter/material.dart';

class CountryCodePicker extends StatelessWidget {
  final String selectedCode;
  final void Function(String) onSelected;

  const CountryCodePicker({
    super.key,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const codes = {
      '+82': '대한민국',
      '+1': '미국',
      '+86': '중국',
      '+81': '일본',
    };

    return SimpleDialog(
      title: const Text('국가 코드 선택'),
      children: codes.entries.map((entry) {
        return SimpleDialogOption(
          onPressed: () {
            onSelected(entry.key);
            Navigator.pop(context);
          },
          child: Text('${entry.value} (${entry.key})'),
        );
      }).toList(),
    );
  }
}
