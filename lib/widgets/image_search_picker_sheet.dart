import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageSearchResult {
  final String title;
  final String imageUrl;
  final String previewUrl;

  const ImageSearchResult({
    required this.title,
    required this.imageUrl,
    required this.previewUrl,
  });
}

class ImageSearchPickerSheet extends StatefulWidget {
  final String? initialQuery;

  const ImageSearchPickerSheet({super.key, this.initialQuery});

  @override
  State<ImageSearchPickerSheet> createState() => _ImageSearchPickerSheetState();
}

class _ImageSearchPickerSheetState extends State<ImageSearchPickerSheet> {
  final TextEditingController _queryController = TextEditingController();
  bool _loading = false;
  List<ImageSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _queryController.text = (widget.initialQuery ?? '').trim();
    if (_queryController.text.isNotEmpty) {
      _search();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
    });
    try {
      final results = await _searchCommons(query);
      if (!mounted) return;
      setState(() {
        _results = results;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<List<ImageSearchResult>> _searchCommons(String query) async {
    final uri = Uri.https('commons.wikimedia.org', '/w/api.php', {
      'action': 'query',
      'format': 'json',
      'origin': '*',
      'generator': 'search',
      'gsrsearch': '$query food',
      'gsrnamespace': '6',
      'gsrlimit': '24',
      'prop': 'imageinfo',
      'iiprop': 'url',
      'iiurlwidth': '720',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return const [];
    final data = jsonDecode(response.body);
    final queryNode = data['query'];
    if (queryNode is! Map<String, dynamic>) return const [];
    final pagesNode = queryNode['pages'];
    if (pagesNode is! Map<String, dynamic>) return const [];

    final results = <ImageSearchResult>[];
    for (final value in pagesNode.values) {
      if (value is! Map<String, dynamic>) continue;
      final imageInfo = value['imageinfo'];
      if (imageInfo is! List || imageInfo.isEmpty) continue;
      final first = imageInfo.first;
      if (first is! Map<String, dynamic>) continue;

      final imageUrl = first['url'] as String?;
      final thumbUrl = (first['thumburl'] as String?) ?? imageUrl;
      final title = (value['title'] as String?) ?? 'Imagen';
      if (imageUrl == null || thumbUrl == null) continue;

      final lower = imageUrl.toLowerCase();
      final thumbLower = thumbUrl.toLowerCase();
      final allowed =
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp');
      if (!allowed || thumbLower.endsWith('.svg')) continue;

      results.add(
        ImageSearchResult(
          title: title,
          imageUrl: imageUrl,
          previewUrl: thumbUrl,
        ),
      );
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withAlpha(70),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.image_search_rounded,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Buscar imagen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Ej: pasta, pizza, ensalada',
                filled: true,
                fillColor: const Color(0xFFF8F6FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3DCF3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE3DCF3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple),
                ),
                suffixIcon: IconButton(
                  onPressed: _loading ? null : _search,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Escribe algo y elige una imagen',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : GridView.builder(
                      itemCount: _results.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return _ImageResultTile(
                          item: item,
                          onSelected: (url) => Navigator.pop(context, url),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageResultTile extends StatefulWidget {
  final ImageSearchResult item;
  final ValueChanged<String> onSelected;

  const _ImageResultTile({required this.item, required this.onSelected});

  @override
  State<_ImageResultTile> createState() => _ImageResultTileState();
}

class _ImageResultTileState extends State<_ImageResultTile> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _hasError ? null : () => widget.onSelected(widget.item.previewUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFFF0ECF8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.item.previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  if (!_hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                        });
                      }
                    });
                  }
                  return Container(
                    color: const Color(0xFFECE6F8),
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF7A66A5),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No disponible',
                          style: TextStyle(
                            color: Color(0xFF7A66A5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: _hasError ? Colors.black38 : Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    _hasError ? 'No disponible' : widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
