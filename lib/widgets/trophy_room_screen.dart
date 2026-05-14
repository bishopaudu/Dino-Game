import 'package:dino_game/models/run_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/dino_skin.dart';
import '../core/storage_service.dart';
import '../providers/game_provider.dart';

class TrophyRoomScreen extends StatefulWidget {
  const TrophyRoomScreen({super.key});

  @override
  State<TrophyRoomScreen> createState() => _TrophyRoomScreenState();
}

class _TrophyRoomScreenState extends State<TrophyRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Achievement> _achievements = [];
  List<RunRecord> _history = [];
  Set<String> _unlockedSkins = {'classic'};
  String _selectedSkinId = 'classic';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      StorageService.loadAchievements(),
      StorageService.loadRunHistory(),
      StorageService.loadUnlockedSkins(),
      StorageService.loadSelectedSkin(),
    ]);
    if (mounted) {
      setState(() {
        _achievements   = results[0] as List<Achievement>;
        _history        = results[1] as List<RunRecord>;
        _unlockedSkins  = results[2] as Set<String>;
        _selectedSkinId = results[3] as String;
        _loading        = false;
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'TROPHY ROOM',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            letterSpacing: 3,
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF7B7FCC),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontFamily: 'monospace', fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ACHIEVEMENTS'),
            Tab(text: 'SKINS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _AchievementsTab(achievements: _achievements),
                _SkinsTab(
                  unlockedSkins: _unlockedSkins,
                  selectedSkinId: _selectedSkinId,
                  onSkinSelected: _onSkinSelected,
                ),
                _HistoryTab(history: _history),
              ],
            ),
    );
  }

  Future<void> _onSkinSelected(DinoSkin skin) async {
    if (!_unlockedSkins.contains(skin.id)) return;
    setState(() => _selectedSkinId = skin.id);
    await context.read<GameProvider>().selectSkin(skin);
  }
}

// ── Achievements tab ───────────────────────────────────────────

class _AchievementsTab extends StatelessWidget {
  final List<Achievement> achievements;
  const _AchievementsTab({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievements.where((a) => a.isUnlocked).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unlocked / ${achievements.length} Unlocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: unlocked / achievements.length,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF7B7FCC)),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ...achievements.map((a) => _AchievementTile(achievement: a)),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  Color get _tierColor {
    switch (achievement.tier) {
      case AchievementTier.bronze: return const Color(0xFFCD7F32);
      case AchievementTier.silver: return const Color(0xFFC0C0C0);
      case AchievementTier.gold:   return const Color(0xFFFFD700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = !achievement.isUnlocked;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: locked
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked ? Colors.white12 : _tierColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // Emoji / lock icon
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                locked ? '🔒' : achievement.emoji,
                style: TextStyle(
                    fontSize: 24, color: locked ? null : null),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locked ? '???' : achievement.title,
                  style: TextStyle(
                    color: locked ? Colors.white38 : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  locked ? 'Keep playing to unlock' : achievement.description,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
                if (!locked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                    style: TextStyle(
                        color: _tierColor.withOpacity(0.7),
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),
          ),
          // Tier badge
          if (!locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _tierColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _tierColor.withOpacity(0.4)),
              ),
              child: Text(
                achievement.tier.name.toUpperCase(),
                style: TextStyle(
                  color: _tierColor,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ── Skins tab ──────────────────────────────────────────────────

class _SkinsTab extends StatelessWidget {
  final Set<String> unlockedSkins;
  final String selectedSkinId;
  final Function(DinoSkin) onSkinSelected;

  const _SkinsTab({
    required this.unlockedSkins,
    required this.selectedSkinId,
    required this.onSkinSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: DinoSkins.all
          .map((skin) => _SkinCard(
                skin: skin,
                isUnlocked: unlockedSkins.contains(skin.id),
                isSelected: skin.id == selectedSkinId,
                onTap: () => onSkinSelected(skin),
              ))
          .toList(),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final DinoSkin skin;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.isUnlocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? skin.bodyColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? skin.bodyColor
                : isUnlocked
                    ? Colors.white24
                    : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mini dino preview drawn with colored containers
            _MiniDinoPreview(skin: skin, locked: !isUnlocked),
            const SizedBox(height: 12),
            Text(
              skin.name,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked
                  ? (isSelected ? '✓ Active' : 'Tap to equip')
                  : '${skin.unlockScore} pts to unlock',
              style: TextStyle(
                color: isSelected
                    ? skin.bodyColor
                    : Colors.white38,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniDinoPreview extends StatelessWidget {
  final DinoSkin skin;
  final bool locked;

  const _MiniDinoPreview({required this.skin, required this.locked});

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.white12 : skin.bodyColor;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Body
        Container(
          width: 42,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
        // Head bump
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 18,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        // Eye
        if (!locked)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: skin.eyeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        // Lock icon
        if (locked)
          const Text('🔒', style: TextStyle(fontSize: 20)),
      ],
    );
  }
}

// ── History tab ────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<RunRecord> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🦕', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text(
              'No runs yet.\nStart playing!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) => _HistoryTile(
        record: history[i],
        rank: i + 1,
        isPersonalBest: i == 0 &&
            history.length > 1 &&
            history[0].score >= history.fold(0, (m, r) => r.score > m ? r.score : m),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final RunRecord record;
  final int rank;
  final bool isPersonalBest;

  const _HistoryTile({
    required this.record,
    required this.rank,
    required this.isPersonalBest,
  });

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final skin = DinoSkins.getById(record.skinId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPersonalBest
            ? const Color(0xFFFFD700).withOpacity(0.08)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPersonalBest
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank == 1
                    ? const Color(0xFFFFD700)
                    : Colors.white38,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Skin emoji
          Text(skin.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          // Score and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.score.toString().padLeft(5, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (isPersonalBest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PB',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${_formatDuration(record.durationSeconds)}  ·  ${_formatDate(record.playedAt)}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}