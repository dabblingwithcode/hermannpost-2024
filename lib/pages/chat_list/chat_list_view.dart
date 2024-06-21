import 'package:fluffychat/pages/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:badges/badges.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:keyboard_shortcuts/keyboard_shortcuts.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/chat_list/navi_rail_item.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/unread_rooms_badge.dart';
import '../../widgets/matrix.dart';
import 'chat_list_body.dart';
import 'start_chat_fab.dart';

class ChatListView extends StatelessWidget {
  final ChatListController controller;

  const ChatListView(this.controller, {super.key});

  List<NavigationDestination> getNavigationDestinations(BuildContext context) {
    final badgePosition = BadgePosition.topEnd(top: -12, end: -8);
    return [
      NavigationDestination(
        icon: UnreadRoomsBadge(
          badgePosition: badgePosition,
          filter: controller.getRoomFilterByActiveFilter(ActiveFilter.allChats),
          child: Image.asset(
            'assets/hp_icon_border.png',
            scale: 8,
          ),
        ),
        selectedIcon: UnreadRoomsBadge(
          badgePosition: badgePosition,
          filter: controller.getRoomFilterByActiveFilter(ActiveFilter.allChats),
          child: Image.asset(
            'assets/hp_icon_border.png',
            scale: 5,
          ),
        ),
        label: L10n.of(context)!.messages,
      ),
      NavigationDestination(
        icon: Image.asset(
          'assets/hp-discover.png',
          scale: 6,
        ),
        selectedIcon: Image.asset(
          'assets/hp-discover.png',
          scale: 5,
        ),
        label: L10n.of(context)!.discover,
      ),
      NavigationDestination(
        icon: Image.asset(
          'assets/hp-settings.png',
          scale: 7,
        ),
        selectedIcon: Image.asset(
          'assets/hp-settings.png',
          scale: 6,
        ),
        label: L10n.of(context)!.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;

    return StreamBuilder<Object?>(
      stream: Matrix.of(context).onShareContentChanged.stream,
      builder: (_, __) {
        final selectMode = controller.selectMode;
        return PopScope(
          canPop: controller.selectMode == SelectMode.normal &&
              !controller.isSearchMode &&
              controller.activeFilter == (ActiveFilter.allChats),
          onPopInvoked: (pop) async {
            if (pop) return;
            final selMode = controller.selectMode;
            if (controller.isSearchMode) {
              controller.cancelSearch();
              return;
            }
            if (selMode != SelectMode.normal) {
              controller.cancelAction();
              return;
            }
            if (controller.activeFilter != ActiveFilter.allChats) {
              controller
                  .onDestinationSelected(AppConfig.separateChatTypes ? 1 : 0);
              controller.activeFilter = ActiveFilter.allChats;
              return;
            }
          },
          child: Row(
            children: [
              if (FluffyThemes.isColumnMode(context) &&
                  controller.widget.displayNavigationRail) ...[
                Builder(
                  builder: (context) {
                    final allSpaces =
                        client.rooms.where((room) => room.isSpace);
                    final rootSpaces = allSpaces
                        .where(
                          (space) => !allSpaces.any(
                            (parentSpace) => parentSpace.spaceChildren
                                .any((child) => child.roomId == space.id),
                          ),
                        )
                        .toList();
                    final destinations = getNavigationDestinations(context);

                    return SizedBox(
                      width: FluffyThemes.navRailWidth,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: rootSpaces.length + destinations.length,
                        itemBuilder: (context, i) {
                          if (i < destinations.length) {
                            return NaviRailItem(
                              isSelected: i == controller.selectedIndex,
                              onTap: () => controller.onDestinationSelected(i),
                              icon: destinations[i].icon,
                              selectedIcon: destinations[i].selectedIcon,
                              toolTip: destinations[i].label,
                            );
                          }
                          i -= destinations.length;
                          final isSelected = controller.activeFilter ==
                                  ActiveFilter.settings &&
                              rootSpaces[i].id == controller.activeSpaceId;
                          return NaviRailItem(
                            toolTip: rootSpaces[i].getLocalizedDisplayname(
                              MatrixLocals(L10n.of(context)!),
                            ),
                            isSelected: isSelected,
                            onTap: () =>
                                controller.setActiveSpace(rootSpaces[i].id),
                            icon: Avatar(
                              mxContent: rootSpaces[i].avatar,
                              name: rootSpaces[i].getLocalizedDisplayname(
                                MatrixLocals(L10n.of(context)!),
                              ),
                              size: 32,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Container(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: FocusManager.instance.primaryFocus?.unfocus,
                  excludeFromSemantics: true,
                  behavior: HitTestBehavior.translucent,
                  child: Scaffold(
                    body: controller.activeFilter == ActiveFilter.settings
                        ? const Settings()
                        : ChatListViewBody(controller),
                    bottomNavigationBar: controller.displayNavigationBar
                        ? NavigationBar(
                            height: 70,
                            labelBehavior:
                                NavigationDestinationLabelBehavior.alwaysShow,
                            indicatorColor: Colors.transparent,
                            shadowColor:
                                Theme.of(context).colorScheme.onSurface,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            surfaceTintColor:
                                Theme.of(context).colorScheme.surface,
                            selectedIndex: controller.selectedIndex,
                            onDestinationSelected:
                                controller.onDestinationSelected,
                            destinations: getNavigationDestinations(context),
                          )
                        : null,
                    floatingActionButton: KeyBoardShortcuts(
                      keysToPress: {
                        LogicalKeyboardKey.controlLeft,
                        LogicalKeyboardKey.keyN,
                      },
                      onKeysPressed: () => context.go('/rooms/newprivatechat'),
                      helpLabel: L10n.of(context)!.newChat,
                      child: selectMode == SelectMode.normal &&
                              !controller.isSearchMode &&
                              controller.activeFilter == ActiveFilter.allChats
                          ? StartChatFloatingActionButton(
                              activeFilter: controller.activeFilter,
                              roomsIsEmpty: false,
                              scrolledToTop: controller.scrolledToTop,
                              createNewSpace: controller.createNewSpace,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
