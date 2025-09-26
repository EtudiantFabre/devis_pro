import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/devis.dart';
import '../models/entreprise.dart';
import '../models/item_devis.dart';

enum PdfTemplateStyle { autoEntrepreneur, services, batiment }

class PdfService {
  Future<File> generateQuotePDF(
    Devis devis,
    List<ItemDevis> items, {
    Entreprise? entreprise,
    PdfTemplateStyle? style,
  }) async {
    final pdf = pw.Document();

    // Créer le PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final resolved = style ?? _resolveStyleFromTemplate(devis.templateType);
          switch (resolved) {
            case PdfTemplateStyle.autoEntrepreneur:
              return _buildAutoEntrepreneur(devis, items, entreprise);
            case PdfTemplateStyle.services:
              return _buildServices(devis, items, entreprise);
            case PdfTemplateStyle.batiment:
              return _buildBatiment(devis, items, entreprise);
          }
        },
      ),
    );

    // Sauvegarder le fichier
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/devis_${devis.numero}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  String _formatCurrency(num value, {String symbol = '€'}) {
    final f = NumberFormat.currency(locale: 'fr_FR', symbol: symbol);
    String out = f.format(value);
    // Remove trailing ,00 or .00
    out = out.replaceAll(RegExp(r'(,|\.)00(?=\s|$)'), '');
    return out;
  }

  PdfTemplateStyle _resolveStyleFromTemplate(String? templateType) {
    switch (templateType) {
      case 'auto_entrepreneur':
        return PdfTemplateStyle.autoEntrepreneur;
      case 'batiment':
        return PdfTemplateStyle.batiment;
      case 'services':
      default:
        return PdfTemplateStyle.services;
    }
  }

  // ======= Templates =======
  pw.Widget _buildAutoEntrepreneur(Devis devis, List<ItemDevis> items, Entreprise? ent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeaderWithEntreprise(ent),
        pw.SizedBox(height: 16),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildClientInfo(devis)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _buildQuoteInfo(devis)),
          ],
        ),
        pw.SizedBox(height: 16),
        _buildItemsTable(items),
        pw.SizedBox(height: 16),
        _buildTotalsWithTva(devis, items, noteAETva: true),
        if (devis.notes != null && devis.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          _buildNotes(devis.notes!),
        ],
        pw.SizedBox(height: 12),
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildServices(Devis devis, List<ItemDevis> items, Entreprise? ent) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bandeau haut: entreprise à gauche, bloc DEVIS à droite
        _buildHeaderWithEntreprise(ent),

        pw.SizedBox(height: 16),

        // Ligne: Client à gauche, infos du devis (date, référence, validité) à droite dans un encadré
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Client :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 6),
                    pw.Text(devis.client?.nom ?? 'Client inconnu', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (devis.client?.adresse != null) pw.Text(devis.client!.adresse!, style: const pw.TextStyle(fontSize: 10)),
                    if (devis.client?.telephone != null) pw.Text(devis.client!.telephone!, style: const pw.TextStyle(fontSize: 10)),
                    if (devis.client?.email != null) pw.Text(devis.client!.email!, style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(
              width: 230,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: _buildQuoteInfoBox(devis),
            ),
          ],
        ),

        pw.SizedBox(height: 22),

        // Informations additionnelles (utilise notes si présentes)
        _buildAdditionalInfo(devis),

        pw.SizedBox(height: 10),

        // Tableau des lignes avec colonnes détaillées
        _buildItemsTableServices(devis, items),

        pw.SizedBox(height: 10),

        // Totaux
        _buildTotalsServices(devis, items),

        pw.SizedBox(height: 16),

        // Zone signature
        _buildSignatureBox(),

        pw.SizedBox(height: 16),

        // Pied de page détaillé
        _buildFooterDetailed(ent),
      ],
    );
  }

  pw.Widget _buildBatiment(Devis devis, List<ItemDevis> items, Entreprise? ent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeaderWithEntreprise(ent),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(child: _buildClientInfo(devis)),
              pw.SizedBox(width: 12),
              pw.Expanded(child: _buildQuoteInfo(devis)),
            ],
          ),
          pw.SizedBox(height: 12),
          _buildItemsTable(items),
          pw.SizedBox(height: 12),
          _buildTotalsWithTva(devis, items),
          if (devis.notes != null && devis.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _buildNotes(devis.notes!),
          ],
          pw.SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  pw.Widget _buildHeaderWithEntreprise(Entreprise? ent) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ent?.nom ?? 'Votre entreprise',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                if (ent?.adresse != null) pw.Text(ent!.adresse!, style: const pw.TextStyle(fontSize: 10)),
                if (ent?.telephone != null) pw.Text(ent!.telephone!, style: const pw.TextStyle(fontSize: 10)),
                if (ent?.email != null) pw.Text(ent!.email!, style: const pw.TextStyle(fontSize: 10)),
                if (ent?.siret != null) pw.Text('SIRET: ${ent!.siret!}', style: const pw.TextStyle(fontSize: 10)),
                if (ent?.tvaIntracom != null) pw.Text('TVA: ${ent!.tvaIntracom!}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
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
                    _formatCurrency(item.prixUnitaire),
                    style: pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    _formatCurrency(item.total),
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

  pw.Widget _buildTotalsWithTva(Devis devis, List<ItemDevis> items, {bool noteAETva = false}) {
    final totalHT = items.fold<double>(0.0, (sum, i) => sum + i.total);
    final applyTva = devis.tvaApplicable && (devis.tvaRate ?? 0) > 0;
    final tva = applyTva ? totalHT * (devis.tvaRate! / 100.0) : 0.0;
    final totalTTC = totalHT + tva;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Sous-total HT: ', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(width: 8),
              pw.Text(_formatCurrency(totalHT), style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          if (applyTva) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('TVA (${devis.tvaRate!.toStringAsFixed(2)}%): ', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(width: 8),
                pw.Text(_formatCurrency(tva), style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ],
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(applyTva ? 'Total TTC: ' : 'Total: ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 8),
              pw.Text(_formatCurrency(applyTva ? totalTTC : totalHT), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            ],
          ),
          if (noteAETva && !applyTva) ...[
            pw.SizedBox(height: 6),
            pw.Text('TVA non applicable, art. 293 B du CGI', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ],
      ),
    );
  }

  // ======= Services-specific building blocks =======
  pw.Widget _buildQuoteInfoBox(Devis devis) {
    final date = DateFormat('dd.MM.yyyy').format(devis.dateCreation);
    final valid = DateFormat('dd.MM.yyyy').format(devis.dateEcheance);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date du devis :', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(date, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Référence du devis :', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(devis.numero, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date de validité :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(valid, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAdditionalInfo(Devis devis) {
    final hasNotes = devis.notes != null && devis.notes!.trim().isNotEmpty;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Informations additionnelles :', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          hasNotes ? devis.notes!.trim() : 'Service après-vente - Garantie : 1 an.\nDate de début de la prestation : ${DateFormat('dd/MM/yyyy').format(devis.dateCreation)}',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: PdfColors.grey500),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildItemsTableServices(Devis devis, List<ItemDevis> items) {
    final rate = (devis.tvaApplicable ? (devis.tvaRate ?? 0) : 0).toDouble();

    pw.TableRow headerCell(String label) => pw.TableRow(
      decoration: pw.BoxDecoration(color: PdfColors.orange300),
      children: [
        for (final text in [label]) pw.SizedBox.shrink(),
      ],
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(2),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.orange300),
          children: [
            _cell('Description', bold: true),
            _cell('Quantité', bold: true, align: pw.TextAlign.center),
            _cell('Unité', bold: true, align: pw.TextAlign.center),
            _cell('Prix unitaire HT', bold: true, align: pw.TextAlign.right),
            _cell('% de TVA', bold: true, align: pw.TextAlign.center),
            _cell('Total TVA', bold: true, align: pw.TextAlign.right),
            _cell('Total TTC', bold: true, align: pw.TextAlign.right),
          ],
        ),
        ...items.map((it) {
          final totalHT = it.total; // existing total treated as HT
          final unitHT = it.prixUnitaire;
          final itTva = unitHT * it.quantite * (rate / 100.0);
          final itTTC = totalHT + itTva;
          return pw.TableRow(
            children: [
              _cell(it.nom + (it.description.isNotEmpty ? '\n${it.description}' : ''), align: pw.TextAlign.left),
              _cell(it.quantite.toStringAsFixed(0), align: pw.TextAlign.center),
              _cell(it.unite ?? '', align: pw.TextAlign.center),
              _cell(_formatCurrency(unitHT), align: pw.TextAlign.right),
              _cell(rate.toStringAsFixed(0) + ' %', align: pw.TextAlign.center),
              _cell(_formatCurrency(itTva), align: pw.TextAlign.right),
              _cell(_formatCurrency(itTTC), align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTotalsServices(Devis devis, List<ItemDevis> items) {
    final rate = (devis.tvaApplicable ? (devis.tvaRate ?? 0) : 0).toDouble();
    final totalHT = items.fold<double>(0.0, (s, i) => s + i.total);
    final totalTVA = totalHT * (rate / 100.0);
    final totalTTC = totalHT + totalTVA;
    final currency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    pw.Widget line(String label, String value, {bool bold = false}) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.SizedBox(width: 380),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: pw.Row(children: [
            pw.Text(label + ' ', style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.SizedBox(width: 8),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ]),
        ),
      ],
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        line('Total HT', _formatCurrency(totalHT)),
        line('Total TVA', _formatCurrency(totalTVA)),
        pw.SizedBox(height: 6),
        line('Total TTC', _formatCurrency(totalTTC), bold: true),
      ],
    );
  }

  pw.Widget _buildSignatureBox() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Signature du client (précédée de la mention « Bon pour accord »)',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _buildFooterDetailed(Entreprise? ent) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Siège social', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  if (ent?.adresse != null) pw.Text(ent!.adresse!, style: const pw.TextStyle(fontSize: 9)),
                  if (ent?.siret != null) pw.Text('N° SIREN ou Siret : ${ent!.siret!}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Coordonnées', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  if (ent?.nom != null) pw.Text(ent!.nom, style: const pw.TextStyle(fontSize: 9)),
                  if (ent?.telephone != null) pw.Text('Téléphone : ${ent!.telephone!}', style: const pw.TextStyle(fontSize: 9)),
                  if (ent?.email != null) pw.Text('E-mail : ${ent!.email!}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Détails bancaires', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Banque :', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('SWIFT/BIC :', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('IBAN :', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _cell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
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
