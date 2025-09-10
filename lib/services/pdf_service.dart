import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/devis.dart';
import '../models/item_devis.dart';

class PdfService {
  Future<File> generateQuotePDF(Devis devis, List<ItemDevis> items) async {
    final pdf = pw.Document();

    // Créer le PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildQuoteContent(devis, items);
        },
      ),
    );

    // Sauvegarder le fichier
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/devis_${devis.numero}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildQuoteContent(Devis devis, List<ItemDevis> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête
        _buildHeader(),
        
        pw.SizedBox(height: 30),
        
        // Informations du devis
        _buildQuoteInfo(devis),
        
        pw.SizedBox(height: 30),
        
        // Informations du client
        _buildClientInfo(devis),
        
        pw.SizedBox(height: 30),
        
        // Table des articles
        _buildItemsTable(items),
        
        pw.SizedBox(height: 30),
        
        // Total
        _buildTotal(devis),
        
        pw.SizedBox(height: 30),
        
        // Notes
        if (devis.notes != null && devis.notes!.isNotEmpty)
          _buildNotes(devis.notes!),
        
        pw.SizedBox(height: 30),
        
        // Pied de page
        _buildFooter(),
      ],
    );
  }

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
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Numéro de devis:',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                devis.numero,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date de création:',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(devis.dateCreation),
                style: pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date d\'échéance:',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(devis.dateEcheance),
                style: pw.TextStyle(fontSize: 14),
              ),
            ],
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
            'Facturé à:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
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
          if (devis.client?.telephone != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              devis.client!.telephone!,
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
          if (devis.client?.adresse != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              devis.client!.adresse!,
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
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
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
            // En-tête du tableau
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Description',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Qté',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Prix unit.',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            // Lignes des articles
            ...items.map((item) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item.nom,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      if (item.description.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          item.description,
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    '${item.quantite}${item.unite != null ? ' ${item.unite}' : ''}',
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.prixUnitaire),
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(item.total),
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
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
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total TTC:',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(devis.total),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
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
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: pw.TextStyle(fontSize: 12),
          ),
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
      child: pw.Column(
        children: [
          pw.Text(
            'Merci pour votre confiance !',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Ce devis a été généré automatiquement par DevisPro',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sharePDF(File pdfFile, String email) async {
    try {
      // Utiliser share_plus pour partager le fichier
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Devis généré par DevisPro',
        subject: 'Devis professionnel',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage du PDF: $e');
    }
  }

  Future<void> printPDF(File pdfFile) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfFile.readAsBytes(),
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'impression: $e');
    }
  }
}
