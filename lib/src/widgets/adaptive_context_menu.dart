import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../platform/platform_info.dart';

/// A context menu action item
class AdaptiveContextMenuAction {
  /// Creates a context menu action
  const AdaptiveContextMenuAction({
    required this.title,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
    this.isDisabled = false,
  });

  /// The title of the action
  final String title;

  /// Callback when the action is pressed
  final VoidCallback onPressed;

  /// Icon for the action (iOS 26+: SF Symbol string, iOS <26/Android: IconData)
  final dynamic icon;

  /// Whether this is a destructive action (shown in red)
  final bool isDestructive;

  /// Whether this action is disabled
  final bool isDisabled;
}

/// An adaptive context menu that renders platform-specific styles
///
/// On iOS 26+: Uses native UIContextMenu with Liquid Glass effects
/// On iOS <26: Uses CupertinoContextMenu
/// On Android: Uses PopupMenuButton with Material Design
class AdaptiveContextMenu extends StatefulWidget {
  /// Creates an adaptive context menu
  const AdaptiveContextMenu({
    super.key,
    required this.child,
    required this.actions,
    this.previewBuilder,
    this.onOpened,
    this.onDismiss,
  });

  /// The widget to wrap with context menu
  final Widget child;

  /// List of actions to show in the context menu
  final List<AdaptiveContextMenuAction> actions;

  /// Optional preview builder for iOS (shows preview when long pressing)
  final Widget Function(BuildContext)? previewBuilder;

  /// Callback when the context menu is fully opened
  final VoidCallback? onOpened;

  /// Callback when the context menu preview is dismissed
  /// This is called when the menu is closed without selecting an action
  final VoidCallback? onDismiss;

  @override
  State<AdaptiveContextMenu> createState() => _AdaptiveContextMenuState();
}

class _AdaptiveContextMenuState extends State<AdaptiveContextMenu> {
  double _lastAnimationValue = 0.0;
  bool _hasCalledOnOpened = false;
  bool _hasCalledOnDismiss = true; // Start as true so we don't call onDismiss on initial build
  bool _pendingOpenedCallback = false;
  bool _pendingDismissCallback = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _onAnimationUpdate(double value) {
    // Debug logging - remove after testing
    debugPrint('Animation value: $value, lastValue: $_lastAnimationValue, hasCalledOnOpened: $_hasCalledOnOpened, hasCalledOnDismiss: $_hasCalledOnDismiss');
    
    // When animation reaches 1.0, the menu is fully opened
    if (!_hasCalledOnOpened && !_pendingOpenedCallback && value >= 1.0 && widget.onOpened != null) {
      _pendingOpenedCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingOpenedCallback) {
          _pendingOpenedCallback = false;
          _hasCalledOnOpened = true;
          _hasCalledOnDismiss = false;
          debugPrint('>>> Calling onOpened');
          widget.onOpened!();
        }
      });
    }
    
    // When animation returns to 0.0, the menu is dismissed
    // IMPORTANT: Only trigger if we're seeing a natural transition (last value was between 0 and 1)
    // This prevents false triggers when two different animations call the builder
    // (route animation at 1.0 vs hidden widget animation reset to 0.0)
    final bool isNaturalTransition = _lastAnimationValue > 0.0 && _lastAnimationValue < 1.0;
    if (_hasCalledOnOpened && !_hasCalledOnDismiss && !_pendingDismissCallback && value == 0.0 && isNaturalTransition && widget.onDismiss != null) {
      _pendingDismissCallback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pendingDismissCallback) {
          _pendingDismissCallback = false;
          _hasCalledOnDismiss = true;
          _hasCalledOnOpened = false;
          debugPrint('>>> Calling onDismiss');
          widget.onDismiss!();
        }
      });
    }
    
    _lastAnimationValue = value;
  }

  @override
  Widget build(BuildContext context) {
    // iOS 26+ - Use CupertinoContextMenu
    // Note: Native iOS 26 UIContextMenu could be implemented with platform view for enhanced visuals
    if (PlatformInfo.isIOS26OrHigher()) {
      return _buildCupertinoContextMenu(context);
    }

    // iOS <26 - Use CupertinoContextMenu
    if (PlatformInfo.isIOS) {
      return _buildCupertinoContextMenu(context);
    }

    // Android - Use PopupMenuButton
    return _buildAndroidContextMenu(context);
  }

  Widget _buildCupertinoContextMenu(BuildContext context) {
    return CupertinoContextMenu.builder(
      actions: widget.actions.map((action) {
        return CupertinoContextMenuAction(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            Future.microtask(() => action.onPressed());
          },
          isDestructiveAction: action.isDestructive,
          trailingIcon: action.icon is IconData
              ? action.icon as IconData
              : null,
          child: Text(action.title),
        );
      }).toList(),
      builder: (context, animation) {
        // Track animation value to detect when menu opens
        _onAnimationUpdate(animation.value);
        return widget.child;
      },
    );
  }

  Widget _buildAndroidContextMenu(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        _showAndroidMenu(context);
      },
      child: widget.child,
    );
  }

  void _showAndroidMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Call onOpened callback when menu is shown
    if (widget.onOpened != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onOpened!();
        }
      });
    }

    showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy,
      ),
      items: widget.actions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;

        return PopupMenuItem<int>(
          value: index,
          enabled: !action.isDisabled,
          child: Row(
            children: [
              if (action.icon != null && action.icon is IconData) ...[
                Icon(
                  action.icon as IconData,
                  size: 20,
                  color: action.isDestructive
                      ? Colors.red
                      : (action.isDisabled ? Colors.grey : null),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  action.title,
                  style: TextStyle(
                    color: action.isDestructive
                        ? Colors.red
                        : (action.isDisabled ? Colors.grey : null),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedIndex) {
      if (selectedIndex != null) {
        widget.actions[selectedIndex].onPressed();
      } else if (widget.onDismiss != null) {
        // Menu was dismissed without selection
        widget.onDismiss!();
      }
    });
  }
}
