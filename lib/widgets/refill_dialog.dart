import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';

class RefillStockDialog extends StatefulWidget {
  final Medicine medicine;
  final Function(int newTotal) onConfirm;

  const RefillStockDialog({
    super.key,
    required this.medicine,
    required this.onConfirm,
  });

  @override
  State<RefillStockDialog> createState() => _RefillStockDialogState();
}

class _RefillStockDialogState extends State<RefillStockDialog> {
  late TextEditingController _controller;
  int _currentStock = 0;

  @override
  void initState() {
    super.initState();
    _currentStock = widget.medicine.totalPills;
    _controller = TextEditingController(text: '$_currentStock');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAmount(int amount) {
    setState(() {
      _currentStock += amount;
      _controller.text = '$_currentStock';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = widget.medicine.unitLabel;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(widget.medicine.colorValue)
                .withValues(alpha: 0.15),
            child: Icon(
              Icons.add_shopping_cart,
              color: Color(widget.medicine.colorValue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  Ar.refillDialogTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.medicine.name,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(Ar.currentStockPrefix),
                  Text(
                    '${widget.medicine.totalPills} $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.medicine.isLowStock
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              Ar.quickAddPillsTitle,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addAmount(10),
                    child: Text(Ar.quickAddAmount(10, unit)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addAmount(20),
                    child: Text(Ar.quickAddAmount(20, unit)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addAmount(30),
                    child: Text(Ar.quickAddAmount(30, unit)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: Ar.newTotalStockLabel(unit),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null) {
                  _currentStock = parsed;
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(Ar.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final parsed = int.tryParse(_controller.text) ?? _currentStock;
            widget.onConfirm(parsed);
            Navigator.pop(context);
          },
          child: const Text(Ar.saveStockBtn),
        ),
      ],
    );
  }
}
