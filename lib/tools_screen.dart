import 'package:flutter/material.dart';

class ToolsScreen extends StatelessWidget {
  final VoidCallback onPickFile;

  const ToolsScreen({
    super.key, 
    required this.onPickFile,
  });

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Yakında eklenecek! 🚀'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'icon': Icons.edit,
        'name': 'PDF Düzenle',
        'color': const Color(0xFFFFEBEE),
        'onTap': () => _showComingSoon(context, 'PDF Düzenleme')
      },
      {
        'icon': Icons.volume_up,
        'name': 'Sesli okuma',
        'color': const Color(0xFFF3E5F5),
        'onTap': () => _showComingSoon(context, 'Sesli Okuma')
      },
      {
        'icon': Icons.edit_document,
        'name': 'PDF Doldur & İmzala',
        'color': const Color(0xFFE8F5E8),
        'onTap': () => _showComingSoon(context, 'PDF Doldur & İmzala')
      },
      {
        'icon': Icons.picture_as_pdf,
        'name': 'PDF Oluştur',
        'color': const Color(0xFFE3F2FD),
        'onTap': onPickFile // Ana sayfadan gelen fonksiyonu tetikler
      },
      {
        'icon': Icons.layers,
        'name': 'Sayfaları organize et',
        'color': const Color(0xFFFFF3E0),
        'onTap': () => _showComingSoon(context, 'Sayfa Organizasyonu')
      },
      {
        'icon': Icons.merge,
        'name': 'Dosyaları birleştirme',
        'color': const Color(0xFFE0F2F1),
        'onTap': () => _showComingSoon(context, 'Dosya Birleştirme')
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: tool['onTap'] as Function(),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tool['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tool['icon'] as IconData, color: const Color(0xFFD32F2F), size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tool['name'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: Color(0xFFD32F2F),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
