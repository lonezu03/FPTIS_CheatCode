import 'package:flutter/material.dart';

import 'catalog_screen.dart';

Future<List<Map<String, dynamic>>?> showCatalogExercisePicker(
  BuildContext context, {
  bool multiple = false,
}) => showModalBottomSheet<List<Map<String, dynamic>>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => SizedBox(
    height: MediaQuery.sizeOf(sheetContext).height * .9,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Chọn bài tập',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Expanded(
          child: CatalogBrowser(
            kind: 'EXERCISE',
            multiple: multiple,
            onSelected: (value) => Navigator.pop(sheetContext, value),
          ),
        ),
      ],
    ),
  ),
);
