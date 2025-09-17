import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Devise'),
            subtitle: Text('Choisissez la devise utilisée dans l\'application'),
          ),
          RadioListTile<String>(
            value: 'XOF',
            groupValue: settings.currencyCode,
            onChanged: (v) => settings.setCurrency(v!),
            title: const Text('Franc CFA (FCFA)'),
          ),
          RadioListTile<String>(
            value: 'EUR',
            groupValue: settings.currencyCode,
            onChanged: (v) => settings.setCurrency(v!),
            title: const Text('Euro (€)'),
          ),
          RadioListTile<String>(
            value: 'USD',
            groupValue: settings.currencyCode,
            onChanged: (v) => settings.setCurrency(v!),
            title: const Text('Dollar (\$)'),
          ),
        ],
      ),
    );
  }
}


