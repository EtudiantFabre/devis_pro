import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isMonthlySelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevisPro Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec illustration
            SizedBox(
              width: double.infinity,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16), // coins plus arrondis
                  side: BorderSide(
                      color: Colors.black.withOpacity(0.1), width: 1.0),
                ),
                elevation: 5,
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.star,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Passez à DevisPro Premium',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Débloquez toutes les fonctionnalités avancées pour optimiser votre gestion de devis',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Fonctionnalités premium
            Text(
              'Fonctionnalités Premium',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              icon: Icons.cloud_sync,
              title: 'Synchronisation Cloud',
              description:
                  'Sauvegardez et synchronisez vos devis sur tous vos appareils',
              isPremium: true,
            ),

            _buildFeatureCard(
              icon: Icons.analytics,
              title: 'Analytics Avancées',
              description:
                  'Tableaux de bord détaillés et statistiques de performance',
              isPremium: true,
            ),

            _buildFeatureCard(
              icon: Icons.palette,
              title: 'Personnalisation',
              description:
                  'Logos personnalisés, couleurs et templates de devis',
              isPremium: true,
            ),

            _buildFeatureCard(
              icon: Icons.integration_instructions,
              title: 'Intégrations',
              description: 'Connectez-vous à vos outils comptables et CRM',
              isPremium: true,
            ),

            _buildFeatureCard(
              icon: Icons.support_agent,
              title: 'Support Prioritaire',
              description:
                  'Assistance technique dédiée et formation personnalisée',
              isPremium: true,
            ),

            _buildFeatureCard(
              icon: Icons.backup,
              title: 'Sauvegarde Automatique',
              description: 'Sauvegarde automatique quotidienne de vos données',
              isPremium: true,
            ),

            const SizedBox(height: 24),

            // Plans d'abonnement
            Text(
              'Choisissez votre plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Sélecteur de période
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // coins plus arrondis
                side: BorderSide(
                    color: Colors.black.withOpacity(0.1), width: 1.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMonthlySelected = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isMonthlySelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isMonthlySelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            'Mensuel',
                            style: TextStyle(
                              color: _isMonthlySelected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMonthlySelected = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isMonthlySelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_isMonthlySelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Annuel',
                                style: TextStyle(
                                  color: !_isMonthlySelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!_isMonthlySelected)
                                Text(
                                  '-20%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Plan sélectionné
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // coins plus arrondis
                side: BorderSide(
                    color: Colors.black.withOpacity(0.1), width: 1.0),
              ),
              elevation: 5,
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plan Premium',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              _isMonthlySelected
                                  ? 'Facturation mensuelle'
                                  : 'Facturation annuelle',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _isMonthlySelected ? '19,99€' : '191,90€',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            if (!_isMonthlySelected)
                              Text(
                                'au lieu de 239,88€',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            Text(
                              _isMonthlySelected ? '/ mois' : '/ an',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showPaymentDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Commencer l\'essai gratuit',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '7 jours d\'essai gratuit, puis facturation automatique',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Fonctionnalités gratuites actuelles
            Text(
              'Fonctionnalités gratuites',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildFeatureCard(
              icon: Icons.description,
              title: 'Création de devis',
              description: 'Créez des devis professionnels illimités',
              isPremium: false,
            ),

            _buildFeatureCard(
              icon: Icons.people,
              title: 'Gestion clients',
              description: 'Gérez vos clients et produits de base',
              isPremium: false,
            ),

            _buildFeatureCard(
              icon: Icons.picture_as_pdf,
              title: 'Export PDF',
              description: 'Générez et partagez vos devis en PDF',
              isPremium: false,
            ),

            _buildFeatureCard(
              icon: Icons.offline_bolt,
              title: 'Mode hors ligne',
              description: 'Fonctionne sans connexion Internet',
              isPremium: false,
            ),

            const SizedBox(height: 24),

            // FAQ
            Text(
              'Questions fréquentes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildFAQItem(
              'Puis-je annuler mon abonnement à tout moment ?',
              'Oui, vous pouvez annuler votre abonnement à tout moment depuis les paramètres de votre compte. L\'accès aux fonctionnalités premium se terminera à la fin de votre période de facturation.',
            ),

            _buildFAQItem(
              'Mes données sont-elles sécurisées ?',
              'Absolument. Nous utilisons un chiffrement de niveau bancaire pour protéger vos données. Vos informations sont stockées de manière sécurisée et ne sont jamais partagées avec des tiers.',
            ),

            _buildFAQItem(
              'Que se passe-t-il si je n\'ai pas Internet ?',
              'L\'application fonctionne parfaitement hors ligne. Vous pouvez créer et gérer vos devis même sans connexion Internet. La synchronisation se fera automatiquement dès que vous retrouverez une connexion.',
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isPremium,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // coins plus arrondis
        side: BorderSide(color: Colors.black.withOpacity(0.1), width: 1.0),
      ),
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isPremium
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isPremium ? AppTheme.primaryColor : AppTheme.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fonctionnalité à venir'),
        content: const Text(
          'Le système de paiement sera bientôt disponible. '
          'En attendant, profitez de toutes les fonctionnalités gratuites de DevisPro !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
