import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareAppButton extends StatelessWidget {
  final String appLink = 'https://www.app.fixcars.ro/download/';

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFC8CADE),
            borderRadius: BorderRadius.circular(16),

          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final box = context.findRenderObject() as RenderBox?;

                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: '🚗 FIXCARS - Găsește mecanici, programează reparații și solicită asistență rutieră! Descarcă: $appLink',
                      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                    ),
                  );
                } catch (e) {
                  print('Share error: $e');
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      color: Color(0xFF2A3B4F),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Distribuie aplicația',
                      style: TextStyle(
                        color: Color(0xFF2A3B4F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}