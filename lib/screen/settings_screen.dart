import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../core/audio_service.dart';
import '../core/haptic_service.dart';
import '../core/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled   = true;
  bool _hapticsEnabled = true;
  int _totalGames      = 0;
  int _highScore       = 0;
  bool _loading        = true;

  final _audio   = AudioService();
  final _haptics = HapticService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sound   = await StorageService.loadSoundEnabled();
    final haptics = await StorageService.loadHapticsEnabled();
    final games   = await StorageService.loadTotalGamesPlayed();
    final hi      = await StorageService.loadHighScore();
    if (mounted) {
      setState(() {
        _soundEnabled   = sound;
        _hapticsEnabled = haptics;
        _totalGames     = games;
        _highScore      = hi;
        _loading        = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          //onTap: () => Navigator.pop(context),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _SectionHeader('Audio & Feedback'),
                _SettingsTile(
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Effects',
                  subtitle: 'Jump, die, milestone sounds',
                  value: _soundEnabled,
                  onChanged: (val) async {
                    setState(() => _soundEnabled = val);
                    await _audio.setSoundEnabled(val);
                    _haptics.lightTap();
                  },
                ),
                _SettingsTile(
                  icon: Icons.vibration_rounded,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibration on jump and collision',
                  value: _hapticsEnabled,
                  onChanged: (val) async {
                    setState(() => _hapticsEnabled = val);
                    await _haptics.setHapticsEnabled(val);
                    if (val) _haptics.lightTap();
                  },
                ),
                const SizedBox(height: 32),
                _SectionHeader('Your Stats'),
                _StatsCard(
                  highScore: _highScore,
                  totalGames: _totalGames,
                ),
                const SizedBox(height: 32),
                _SectionHeader('Data'),
                _DangerButton(
                  label: 'Reset High Score & Stats',
                  onTap: () => _confirmReset(context),
                ),
                const SizedBox(height: 40),
                // Version info
                Center(
                  child: Text(
                    'Dino Run  v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Reset Progress',
          style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
        ),
        content: const Text(
          'This will delete your high score and stats. This cannot be undone.',
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset',
                style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await StorageService.resetProgress();
      // Update the provider so the in-game HUD also reflects 0
      if (mounted) {
        context.read<GameProvider>().resetHighScore();
      }
      setState(() {
        _highScore  = 0;
        _totalGames = 0;
      });
      _haptics.mediumTap();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress reset.'),
          backgroundColor: Color(0xFF2D2D3E),
        ),
      );
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8888AA),
          fontSize: 11,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8888CC), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF7B7FCC),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int highScore;
  final int totalGames;

  const _StatsCard({required this.highScore, required this.totalGames});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(child: _StatItem(
            label: 'Best Score',
            value: highScore.toString().padLeft(5, '0'),
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFFD54F),
          )),
          Container(width: 1, height: 50, color: Colors.white12),
          Expanded(child: _StatItem(
            label: 'Games Played',
            value: totalGames.toString(),
            icon: Icons.sports_esports_rounded,
            color: const Color(0xFF7B7FCC),
          )),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace')),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFF5252),
              fontFamily: 'monospace',
              letterSpacing: 1,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// Settings sheet shown from pause menu
class SettingsSheet extends StatelessWidget {
  const SettingsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Settings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'monospace',
                  letterSpacing: 2)),
          SizedBox(height: 20),
          Text('Open full settings from the main menu.',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}