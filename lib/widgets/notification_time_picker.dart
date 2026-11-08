import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/mood_stage_theme.dart';

/// Modal bottom sheet allowing the user to select or disable their daily contemplative reminder.
class NotificationTimePickerModal extends StatefulWidget {
  final StagePalette palette;

  const NotificationTimePickerModal({
    super.key,
    required this.palette,
  });

  static Future<void> show(BuildContext context, StagePalette palette) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NotificationTimePickerModal(palette: palette),
    );
  }

  @override
  State<NotificationTimePickerModal> createState() =>
      _NotificationTimePickerModalState();
}

class _NotificationTimePickerModalState
    extends State<NotificationTimePickerModal> {
  final NotificationService _service = NotificationService();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final savedTime = await _service.getSavedReminderTime();
    if (mounted) {
      setState(() {
        if (savedTime != null) {
          _selectedTime = savedTime;
          _isEnabled = true;
        } else {
          _isEnabled = false;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isEnabled) {
      await _service.scheduleDailyReminder(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
    } else {
      await _service.cancelDailyReminder();
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnabled
                ? 'Gentle reminder set for ${_selectedTime.format(context)}'
                : 'Daily reminder turned off',
            style: TextStyle(color: widget.palette.primaryText),
          ),
          backgroundColor: widget.palette.cardSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: widget.palette.cardBorder.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border(
          top: BorderSide(
            color: palette.cardBorder.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24.0,
        16.0,
        24.0,
        MediaQuery.of(context).viewInsets.bottom + 28.0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 38.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: palette.secondaryText.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),

                const SizedBox(height: 18.0),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 20.0,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Daily Sanctuary Reminder',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            color: palette.primaryText,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isEnabled,
                      thumbColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return palette.accent;
                        }
                        return null;
                      }),
                      trackColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return palette.accent.withValues(alpha: 0.45);
                        }
                        return null;
                      }),
                      onChanged: (val) {
                        setState(() => _isEnabled = val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),

                Text(
                  'Receive a quiet, peaceful invitation each day to pause with Scripture and quote.',
                  style: TextStyle(
                    fontSize: 13.0,
                    height: 1.4,
                    color: palette.secondaryText,
                  ),
                ),

                const SizedBox(height: 20.0),

                if (_isEnabled) ...[
                  // Time Selector Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (picked != null && mounted) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(18.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: palette.bgTop.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            color: palette.cardBorder.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reminder Time',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: palette.primaryText,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14.0,
                                vertical: 6.0,
                              ),
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                _selectedTime.format(context),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Reminder',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
