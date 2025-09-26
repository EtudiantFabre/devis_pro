import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/entreprise.dart';
import '../theme/app_theme.dart';

class EnterpriseScreen extends StatefulWidget {
  const EnterpriseScreen({super.key});

  @override
  State<EnterpriseScreen> createState() => _EnterpriseScreenState();
}

class _EnterpriseScreenState extends State<EnterpriseScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _adresse = TextEditingController();
  final _siret = TextEditingController();
  final _tvaIntracom = TextEditingController();

  Entreprise? _current;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _db.getAllEntreprises();
    if (list.isNotEmpty) {
      _current = list.first;
      _nom.text = _current!.nom;
      _email.text = _current!.email ?? '';
      _telephone.text = _current!.telephone ?? '';
      _adresse.text = _current!.adresse ?? '';
      _siret.text = _current!.siret ?? '';
      _tvaIntracom.text = _current!.tvaIntracom ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = Entreprise(
      id: _current?.id,
      nom: _nom.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      telephone: _telephone.text.trim().isEmpty ? null : _telephone.text.trim(),
      adresse: _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
      siret: _siret.text.trim().isEmpty ? null : _siret.text.trim(),
      tvaIntracom: _tvaIntracom.text.trim().isEmpty ? null : _tvaIntracom.text.trim(),
      dateCreation: _current?.dateCreation ?? DateTime.now(),
    );

    if (_current == null) {
      final id = await _db.insertEntreprise(data);
      _current = data.copyWith(id: id);
    } else {
      await _db.updateEntreprise(data);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entreprise enregistrée')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon entreprise'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.black.withOpacity(0.1),
                          width: 1.0,
                        ),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nom,
                              decoration: const InputDecoration(labelText: 'Nom de l\'entreprise *'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _telephone,
                              decoration: const InputDecoration(labelText: 'Téléphone'),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _adresse,
                              decoration: const InputDecoration(labelText: 'Adresse'),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _siret,
                              decoration: const InputDecoration(labelText: 'SIRET'),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _tvaIntracom,
                              decoration: const InputDecoration(labelText: 'TVA intracom (FRxx...)'),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _save,
                                icon: const Icon(Icons.save),
                                label: const Text('Enregistrer'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ces informations apparaîtront en en-tête de tous vos devis.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}


