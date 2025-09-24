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
                  style: style,
                );
                await pdfService.sharePDF(pdfFile, '');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF généré, choisissez une option de partage')),
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
              pdfFileName: 'devis_${quote.numero}_${_getStyleName(style).toLowerCase()}.pdf',
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
                label: const Text('Utiliser ce modèle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStyleName(PdfTemplateStyle style) {
    switch (style) {
      case PdfTemplateStyle.classique:
        return 'Classique';
      case PdfTemplateStyle.minimal:
        return 'Minimal';
      case PdfTemplateStyle.moderne:
        return 'Moderne';
    }
  }

  String _getStyleDescription(PdfTemplateStyle style) {
    switch (style) {
      case PdfTemplateStyle.classique:
        return 'Design traditionnel avec en-tête coloré et mise en page structurée';
      case PdfTemplateStyle.minimal:
        return 'Style épuré et moderne, parfait pour une approche professionnelle simple';
      case PdfTemplateStyle.moderne:
        return 'Design contemporain avec bordures et espacement optimisés';
    }
  }

  Future<Uint8List> _generatePreviewPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          switch (style) {
            case PdfTemplateStyle.classique:
              return _buildQuoteContentClassique(quote, items);
            case PdfTemplateStyle.minimal:
              return _buildQuoteContentMinimal(quote, items);
            case PdfTemplateStyle.moderne:
              return _buildQuoteContentModerne(quote, items);
          }
        },
      ),
    );

    return pdf.save();
  }

  // Copie des méthodes de PdfService pour l'aperçu
  pw.Widget _buildQuoteContentClassique(Devis devis, List<ItemDevis> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        pw.SizedBox(height: 30),
        _buildQuoteInfo(devis),
        pw.SizedBox(height: 30),
        _buildClientInfo(devis),
        pw.SizedBox(height: 30),
        _buildItemsTable(items),
        pw.SizedBox(height: 30),
        _buildTotal(devis),
        if (devis.notes != null && devis.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 30),
          _buildNotes(devis.notes!),
        ],
        pw.SizedBox(height: 30),
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildQuoteContentMinimal(Devis devis, List<ItemDevis> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Devis', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
            pw.Text(devis.numero, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildClientInfo(devis)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _buildQuoteInfo(devis)),
          ],
        ),
        pw.SizedBox(height: 20),
        _buildItemsTable(items),
        pw.SizedBox(height: 20),
        _buildTotal(devis),
        if (devis.notes != null && devis.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _buildNotes(devis.notes!),
        ],
      ],
    );
  }

  pw.Widget _buildQuoteContentModerne(Devis devis, List<ItemDevis> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(child: _buildClientInfo(devis)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildQuoteInfo(devis)),
            ],
          ),
          pw.SizedBox(height: 16),
          _buildItemsTable(items),
          pw.SizedBox(height: 16),
          _buildTotal(devis),
          if (devis.notes != null && devis.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildNotes(devis.notes!),
          ],
          pw.SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  // Méthodes de construction des éléments (simplifiées pour l'aperçu)
  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DevisPro',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Générateur de devis professionnels',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue600,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'DEVIS',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildQuoteInfo(Devis devis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Numéro: ${devis.numero}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date: ${devis.dateCreation.day}/${devis.dateCreation.month}/${devis.dateCreation.year}',
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Échéance: ${devis.dateEcheance.day}/${devis.dateEcheance.month}/${devis.dateEcheance.year}',
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientInfo(Devis devis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Client:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            devis.client?.nom ?? 'Client inconnu',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (devis.client?.email != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              devis.client!.email!,
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<ItemDevis> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Articles',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Description', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Qté', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Prix', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            ...items.take(3).map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(item.nom, style: pw.TextStyle(fontSize: 12)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${item.quantite}', style: pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${item.prixUnitaire.toStringAsFixed(2)}€', style: pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.right),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${item.total.toStringAsFixed(2)}€', style: pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.right),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotal(Devis devis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Total: ${devis.total.toStringAsFixed(2)}€',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotes(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(notes, style: pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        'Merci pour votre confiance !',
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }
}
