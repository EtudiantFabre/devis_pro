import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';  // Temporairement désactivé
import '../services/audio_recording_service.dart';
import '../theme/app_theme.dart';
import 'create_quote_screen.dart';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  final AudioRecordingService _audioService = AudioRecordingService();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  bool _isLoading = false;
  Duration _recordingDuration = Duration.zero;
  List<AudioFile> _recordings = [];
  String? _currentPlayingPath;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recordings = await _getStoredRecordings();
      setState(() {
        _recordings = recordings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<List<AudioFile>> _getStoredRecordings() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory audioDir = Directory('${appDir.path}/recordings');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
      return [];
    }

    final List<FileSystemEntity> files = await audioDir.list().toList();
    final List<AudioFile> recordings = [];

    for (final file in files) {
      if (file is File && file.path.endsWith('.m4a')) {
        final stat = await file.stat();
        recordings.add(AudioFile(
          path: file.path,
          name: file.path.split('/').last,
          dateCreated: stat.modified,
          size: stat.size,
        ));
      }
    }

    recordings.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
    return recordings;
  }

  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final file = await _audioService.stopRecording();
      if (file != null) {
        await _saveRecording(file);
        setState(() {
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _loadRecordings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _saveRecording(File file) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory audioDir = Directory('${appDir.path}/recordings');

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    final String fileName =
        'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final String newPath = '${audioDir.path}/$fileName';

    await file.copy(newPath);
    await file.delete(); // Supprimer le fichier temporaire
  }

  Future<void> _togglePlay(AudioFile recording) async {
    try {
      if (_currentPlayingPath != recording.path) {
        await _player.setFilePath(recording.path);
        _currentPlayingPath = recording.path;
        await _player.play();
        setState(() {
          _isPlaying = true;
        });
        _player.playerStateStream.listen((state) {
          if (!mounted) return;
          final playing = state.playing;
          final completed = state.processingState == ProcessingState.completed;
          setState(() {
            _isPlaying = playing && !completed;
            if (completed) {
              _player.seek(Duration.zero);
              _currentPlayingPath = null;
            }
          });
        });
      } else {
        if (_isPlaying) {
          await _player.pause();
          setState(() {
            _isPlaying = false;
          });
        } else {
          await _player.play();
          setState(() {
            _isPlaying = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de lecture: $e')),
        );
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration =
              Duration(seconds: _recordingDuration.inSeconds + 1);
        });
        _startTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _shareRecording(AudioFile recording) async {
    try {
      final file = XFile(recording.path);
      await Share.shareXFiles(
        [file],
        text: 'Enregistrement audio - ${recording.name}',
        subject: 'Enregistrement audio DevisPro',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecording(AudioFile recording) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'enregistrement'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cet enregistrement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final file = File(recording.path);
        await file.delete();
        _loadRecordings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enregistrement supprimé')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  Future<void> _processWithAI(AudioFile recording) async {
    // TODO: Implémenter le traitement IA
    // Pour l'instant, on simule le processus
    setState(() {
      _isLoading = true;
    });

    // Simulation du traitement IA
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      // Afficher le texte transcrit (simulé)
      final transcribedText = await _showTranscriptionDialog(recording);

      if (transcribedText != null && transcribedText.isNotEmpty) {
        // Naviguer vers la création de devis avec le texte
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateQuoteScreen(
              initialText: transcribedText,
            ),
          ),
        );
      }
    }
  }

  Future<String?> _showTranscriptionDialog(AudioFile recording) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Texte transcrit'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Voici le texte transcrit de votre enregistrement :',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Client: Restaurant Le Gourmet\n'
                  'Adresse: 123 Rue de la Paix, Paris\n'
                  'Email: contact@legourmet.fr\n\n'
                  'Services demandés:\n'
                  '- Équipement de cuisine complet\n'
                  '- Installation et formation\n'
                  '- Maintenance 1 an\n\n'
                  'Budget estimé: 15 000€\n'
                  'Délai souhaité: 2 mois',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              'Client: Restaurant Le Gourmet\n'
              'Adresse: 123 Rue de la Paix, Paris\n'
              'Email: contact@legourmet.fr\n\n'
              'Services demandés:\n'
              '- Équipement de cuisine complet\n'
              '- Installation et formation\n'
              '- Maintenance 1 an\n\n'
              'Budget estimé: 15 000€\n'
              'Délai souhaité: 2 mois',
            ),
            child: const Text('Créer le devis'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrement Audio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Section d'enregistrement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Bouton d'enregistrement
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statut et durée
                Text(
                  _isRecording
                      ? 'Enregistrement en cours...'
                      : 'Appuyez pour enregistrer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),

                if (_isRecording) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Liste des enregistrements
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _recordings.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _recordings.length,
                        itemBuilder: (context, index) {
                          final recording = _recordings[index];
                          return _buildRecordingCard(recording);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun enregistrement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par enregistrer votre première discussion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard(AudioFile recording) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.black.withOpacity(0.1),
          width: 1.0,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.audiotrack,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(recording.dateCreated),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatFileSize(recording.size),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _togglePlay(recording),
                    icon: Icon(
                      (_currentPlayingPath == recording.path && _isPlaying)
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: const Text(''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareRecording(recording),
                    icon: const Icon(Icons.share),
                    label: const Text(''),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processWithAI(recording),
                    icon: const Icon(Icons.psychology),
                    label: const Text(''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteRecording(recording),
                  icon: const Icon(Icons.delete),
                  color: AppTheme.errorColor,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AudioFile {
  final String path;
  final String name;
  final DateTime dateCreated;
  final int size;

  AudioFile({
    required this.path,
    required this.name,
    required this.dateCreated,
    required this.size,
  });
}
