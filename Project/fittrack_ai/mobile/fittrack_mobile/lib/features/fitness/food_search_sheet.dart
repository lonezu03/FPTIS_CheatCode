import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

/// Server-backed picker: only one page is held, not the entire food catalog.
class FoodSearchSheet extends StatefulWidget {
  const FoodSearchSheet({super.key});
  @override
  State<FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<FoodSearchSheet> {
  String keyword = '';
  int page = 0, totalPages = 0, version = 0;
  List<Map<String, dynamic>> items = [];
  Timer? debounce;
  bool loading = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load(0));
  }

  @override
  void dispose() {
    version++;
    debounce?.cancel();
    super.dispose();
  }

  Future<void> load(int next) async {
    final current = ++version;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final raw = await context.read<ApiClient>().get(
        '/nutrition/foods/page',
        queryParameters: {'keyword': keyword, 'page': next, 'size': 20},
      );
      if (!mounted || current != version) return;
      setState(() {
        page = next;
        totalPages = (raw['totalPages'] as num).toInt();
        items = (raw['content'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (mounted && current == version) setState(() => error = e);
    } finally {
      if (mounted && current == version) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tìm món tương ứng',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                keyword = value;
                version++;
                debounce?.cancel();
                debounce = Timer(
                  const Duration(milliseconds: 350),
                  () => load(0),
                );
              },
            ),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              TextButton(
                onPressed: () => load(page),
                child: Text('Thử lại: ${displayError(error!)}'),
              ),
            Expanded(
              child: ListView(
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(item['name'].toString()),
                      subtitle: Text(
                        '${item['unit']} · ${item['calories']} kcal',
                      ),
                      onTap: loading
                          ? null
                          : () => Navigator.pop(context, item),
                    ),
                  if (!loading && items.isEmpty && error == null)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Không tìm thấy món phù hợp.'),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: loading || page == 0 ? null : () => load(page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${totalPages == 0 ? 0 : page + 1}/$totalPages'),
                IconButton(
                  onPressed: loading || page + 1 >= totalPages
                      ? null
                      : () => load(page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
