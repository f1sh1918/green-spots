import 'package:flutter/material.dart';

class OutlinedButtonSpinner extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String buttonText;
  const OutlinedButtonSpinner({super.key, required this.isLoading, required this.onPressed, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: !isLoading ? onPressed : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(buttonText),
          if (isLoading) ...[
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
