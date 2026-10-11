import 'package:flutter/material.dart';

// Dialog for editing one text value. Closes with the trimmed text when the
// value passes the validator, or with null when cancelled.
class EditFieldDialog extends StatefulWidget {
  const EditFieldDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.words,
  });

  final String title;
  final String initialValue;
  final String? Function(String value) validator;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends State<EditFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          validator: (value) => widget.validator((value ?? '').trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
