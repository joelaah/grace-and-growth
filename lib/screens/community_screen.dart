import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/mood_stage_theme.dart';

/// Read-only contemplative community feed showing anonymously shared reflections.
class CommunityScreen extends StatefulWidget {
  final StagePalette palette;

  const CommunityScreen({
    super.key,
    required this.palette,
  });

  static Future<void> show(BuildContext context, StagePalette palette) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: palette.cardSurface,
            elevation: 0,
            title: Text(
              'Quiet Solidarity',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18.0,
                color: palette.primaryText,
              ),
            ),
            iconTheme: IconThemeData(color: palette.primaryText),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.bgTop, palette.bgBottom],
              ),
            ),
            child: CommunityScreen(palette: palette),
          ),
        ),
      ),
    );
  }

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _reflections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommunityReflections();
  }

  Future<void> _loadCommunityReflections() async {
    try {
      final List<dynamic> data = await _client
          .from('community_reflections')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _reflections = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (_) {
      // Graceful fallback when table hasn't been created yet
      if (mounted) {
        setState(() {
          _reflections = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
        ),
      );
    }

    if (_reflections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.spa_outlined,
                size: 48.0,
                color: palette.secondaryText.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Quiet Sanctuary',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 19.0,
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Anonymously shared moments from fellow wanderers will appear here. No likes, no comments—just quiet companionship.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: palette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18.0, 12.0, 18.0, 32.0),
      itemCount: _reflections.length,
      itemBuilder: (context, index) {
        final item = _reflections[index];
        final text = item['verse_text'] ?? item['content'] ?? '';
        final reflection = item['reflection'] ?? '';
        final moodIndex = item['mood_stage'] as int? ?? 0;
        final stage = (moodIndex >= 0 && moodIndex < MoodStage.values.length)
            ? MoodStage.values[moodIndex]
            : MoodStage.gloomy;
        final cardPalette = stage.palette;

        return Container(
          margin: const EdgeInsets.only(bottom: 14.0),
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: cardPalette.cardSurface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: cardPalette.cardBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7.0,
                        height: 7.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardPalette.accent,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        cardPalette.stageLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: cardPalette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Fellow Pilgrim',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontStyle: FontStyle.italic,
                      color: cardPalette.secondaryText.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Text(
                  '“$text”',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15.5,
                    height: 1.4,
                    color: cardPalette.primaryText,
                  ),
                ),
              ],
              if (reflection.isNotEmpty) ...[
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: cardPalette.bgTop.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    reflection,
                    style: TextStyle(
                      fontSize: 13.0,
                      height: 1.4,
                      color: cardPalette.primaryText.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
