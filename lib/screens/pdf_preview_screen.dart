import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../services/pdf_service.dart';
import '../models/devis.dart';
import '../models/item_devis.dart';
import '../theme/app_theme.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Devis quote;
  final List<ItemDevis> items;
  final PdfTemplateStyle style;

  const PdfPreviewScreen({
    super.key,
    required this.quote,
    required this.items,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aperçu - ${_getStyleName(style)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                final pdfService = PdfService();
                final pdfFile = await pdfService.generateQuotePDF(
                  quote,
                  items,
                  entreprise: null,
                  style: style,
                );
                await pdfService.sharePDF(pdfFile, '');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'PDF généré, choisissez une option de partage')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            tooltip: 'Partager',
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations sur le style
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  _getStyleName(style),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getStyleDescription(style),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Aperçu PDF
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePreviewPDF(),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName:
                  'devis_${quote.numero}_${_getStyleName(style).toLowerCase()}.pdf',
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final pdfService = PdfService();
                    final pdfFile = await pdfService.generateQuotePDF(
                      quote,
                      items,
                      entreprise: null,
                      style: style,
                    );
                    await pdfService.sharePDF(pdfFile, '');
                    if (context.mounted) {
                      Navigator.pop(context, style);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Utiliser'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleName(PdfTemplateStyle style) {
    switch (style) {
      case PdfTemplateStyle.autoEntrepreneur:
        return 'Auto-Entrepreneur';
      case PdfTemplateStyle.batiment:
        return 'Bâtiment';
      case PdfTemplateStyle.services:
        return 'Prestataire de services';
    }
  }

  String _getStyleDescription(PdfTemplateStyle style) {
    switch (style) {
      case PdfTemplateStyle.autoEntrepreneur:
        return 'Auto-entrepreneur sans TVA (article 293B), en-tête entreprise à gauche.';
      case PdfTemplateStyle.services:
        return 'Prestataire de services, disposition client à gauche, infos devis à droite.';
      case PdfTemplateStyle.batiment:
        return 'Devis bâtiment, bloc encadré, totaux et TVA adaptés.';
    }
  }

  Future<Uint8List> _generatePreviewPDF() async {
    // Use PdfService to ensure preview matches final renderer
    final service = PdfService();
    final file = await service.generateQuotePDF(
      quote,
      items,
      entreprise: null,
      style: style,
    );
    return file.readAsBytes();
  }
}
