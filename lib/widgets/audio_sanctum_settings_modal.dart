import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../theme/mood_stage_theme.dart';
import 'living_audio_bars.dart';

/// Interactive modal allowing users to customize their Audio Sanctum experience:
/// voice personas, ambient cathedral soundscapes, and contemplative pacing.
class AudioSanctumSettingsModal extends StatelessWidget {
  final StagePalette palette;

  const AudioSanctumSettingsModal({
    super.key,
    required this.palette,
  });

  /// Displays the Audio Sanctum settings modal dialog (desktop) or bottom sheet (mobile).
  static Future<void> show(
    BuildContext context, {
    required StagePalette palette,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 900) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
                  child: AudioSanctumSettingsModal(palette: palette),
                ),
              ),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return AudioSanctumSettingsModal(palette: palette);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tts = TtsService();
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isFloatingDialog = screenWidth >= 900;
    final isShort = screenHeight < 680;
    final modalHeight = screenHeight * (isShort ? 0.94 : 0.88);

    return Container(
      constraints: isFloatingDialog ? null : BoxConstraints(maxHeight: modalHeight),
      decoration: BoxDecoration(
        color: isFloatingDialog
            ? palette.cardSurface.withValues(alpha: palette.isDarkPalette ? 0.82 : 0.92)
            : palette.cardSurface,
        borderRadius: isFloatingDialog
            ? BorderRadius.circular(28.0)
            : const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(
          color: palette.cardBorder.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle for mobile
                if (!isFloatingDialog)
                  Center(
                    child: Container(
                      width: 40.0,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: palette.secondaryText.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),

                // Header: Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 20.0,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Audio Sanctum',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w700,
                                    color: palette.primaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'Contemplative voices & sacred ambient resonance',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: palette.secondaryText,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: palette.secondaryText,
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 20.0,
                    ),
                  ],
                ),

                const SizedBox(height: 20.0),

                // Section 1: Voice Persona
                _buildSectionHeader('VOICE PERSONA', palette),
                const SizedBox(height: 8.0),
                ValueListenableBuilder<VoicePersona>(
                  valueListenable: tts.personaNotifier,
                  builder: (context, currentPersona, _) {
                    return Column(
                      children: [
                        _buildPersonaOption(
                          persona: VoicePersona.seraph,
                          title: 'Seraph',
                          subtitle: 'Gentle & warm contemplative voice',
                          glyph: '🕊️',
                          isSelected: currentPersona == VoicePersona.seraph,
                          palette: palette,
                          onTap: () => tts.setPersona(VoicePersona.seraph),
                        ),
                        const SizedBox(height: 8.0),
                        _buildPersonaOption(
                          persona: VoicePersona.shepherd,
                          title: 'Shepherd',
                          subtitle: 'Deep & reverent baritone tone',
                          glyph: '🌿',
                          isSelected: currentPersona == VoicePersona.shepherd,
                          palette: palette,
                          onTap: () => tts.setPersona(VoicePersona.shepherd),
                        ),
                        const SizedBox(height: 8.0),
                        _buildPersonaOption(
                          persona: VoicePersona.system,
                          title: 'System Natural',
                          subtitle: 'Device native synthetic voice pack',
                          glyph: '⚙️',
                          isSelected: currentPersona == VoicePersona.system,
                          palette: palette,
                          onTap: () => tts.setPersona(VoicePersona.system),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20.0),

                // Section 2: Cathedral Ambient Pad
                _buildSectionHeader('AMBIENT SOUNDSCAPE', palette),
                const SizedBox(height: 8.0),
                ValueListenableBuilder<bool>(
                  valueListenable: tts.ambientPadNotifier,
                  builder: (context, padEnabled, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: palette.cardSurface.withValues(alpha: palette.isDarkPalette ? 0.6 : 0.8),
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: padEnabled
                              ? palette.accent.withValues(alpha: 0.35)
                              : palette.cardBorder.withValues(alpha: 0.5),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.surround_sound_rounded,
                              size: 20.0,
                              color: palette.accent,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cathedral Ambient Pad',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: palette.primaryText,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Soft warm sanctuary tone layered under Scripture',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: palette.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: padEnabled,
                            activeColor: palette.accent,
                            onChanged: (val) => tts.setAmbientPadEnabled(val),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20.0),

                // Section 3: Contemplative Pace
                _buildSectionHeader('CONTEMPLATIVE PACE', palette),
                const SizedBox(height: 8.0),
                ValueListenableBuilder<double>(
                  valueListenable: tts.cadenceRateNotifier,
                  builder: (context, currentPace, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildPacePill(
                            rate: 0.75,
                            label: 'Meditative',
                            multiplier: '0.75x',
                            isSelected: (currentPace - 0.75).abs() < 0.04,
                            palette: palette,
                            onTap: () => tts.setCadenceRate(0.75),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildPacePill(
                            rate: 0.85,
                            label: 'Serene',
                            multiplier: '0.85x',
                            isSelected: (currentPace - 0.85).abs() < 0.04,
                            palette: palette,
                            onTap: () => tts.setCadenceRate(0.85),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _buildPacePill(
                            rate: 1.0,
                            label: 'Standard',
                            multiplier: '1.0x',
                            isSelected: (currentPace - 1.0).abs() < 0.04,
                            palette: palette,
                            onTap: () => tts.setCadenceRate(1.0),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24.0),

                // Section 4: Preview Sanctum Voice Button
                ValueListenableBuilder<String?>(
                  valueListenable: tts.currentlySpeakingId,
                  builder: (context, speakingId, _) {
                    final isPreviewing = speakingId == 'preview_sanctum_sample';
                    return InkWell(
                      onTap: () => tts.previewSanctumVoice(),
                      borderRadius: BorderRadius.circular(18.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: isPreviewing
                              ? palette.accent.withValues(alpha: 0.16)
                              : palette.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            color: palette.accent.withValues(alpha: isPreviewing ? 0.7 : 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isPreviewing) ...[
                                LivingAudioBars(
                                  color: palette.accent,
                                  isPlaying: true,
                                ),
                                const SizedBox(width: 10.0),
                                Text(
                                  'Playing Preview... (Tap to stop)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: palette.accent,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 20.0,
                                  color: palette.accent,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'Preview Sanctum Voice',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: palette.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, StagePalette palette) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: palette.accent.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildPersonaOption({
    required VoicePersona persona,
    required String title,
    required String subtitle,
    required String glyph,
    required bool isSelected,
    required StagePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.12)
              : palette.cardSurface.withValues(alpha: palette.isDarkPalette ? 0.5 : 0.7),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? palette.accent
                : palette.cardBorder.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              glyph,
              style: const TextStyle(fontSize: 20.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? palette.accent : palette.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: palette.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20.0,
                color: palette.accent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPacePill({
    required double rate,
    required String label,
    required String multiplier,
    required bool isSelected,
    required StagePalette palette,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.15)
              : palette.cardSurface.withValues(alpha: palette.isDarkPalette ? 0.5 : 0.7),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected
                ? palette.accent
                : palette.cardBorder.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? palette.accent : palette.primaryText,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                multiplier,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected ? palette.accent : palette.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
