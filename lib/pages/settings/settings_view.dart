import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'settings.dart';

class SettingsView extends StatelessWidget {
  final SettingsController controller;

  const SettingsView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final showChatBackupBanner = controller.showChatBackupBanner;
    return Scaffold(
      // appBar: AppBar(
      //   leading: Center(
      //     child: CloseButton(
      //       onPressed: () => context.go('/rooms'),
      //     ),
      //   ),
      //   title: Text(L10n.of(context)!.settings),
      //   // actions: [
      //   //   TextButton.icon(
      //   //     onPressed: controller.logoutAction,
      //   //     label: Text(L10n.of(context)!.logout),
      //   //     icon: const Icon(Icons.logout_outlined),
      //   //   ),
      //   // ],
      // ),
      body: ListTileTheme(
        iconColor: Theme.of(context).colorScheme.onSurface,
        child: ListView(
          key: const Key('SettingsListViewContent'),
          children: <Widget>[
            FutureBuilder<Profile>(
              future: controller.profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final mxid =
                    Matrix.of(context).client.userID ?? L10n.of(context)!.user;
                final displayname =
                    profile?.displayName ?? mxid.localpart ?? mxid;
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          Material(
                            elevation: Theme.of(context)
                                    .appBarTheme
                                    .scrolledUnderElevation ??
                                4,
                            shadowColor:
                                Theme.of(context).appBarTheme.shadowColor,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(
                                Avatar.defaultSize * 2.5,
                              ),
                            ),
                            child: Avatar(
                              mxContent: profile?.avatarUrl,
                              name: displayname,
                              size: Avatar.defaultSize * 2.5,
                            ),
                          ),
                          if (profile != null)
                            Positioned(
                              bottom: -5,
                              right: -5,
                              child: InkWell(
                                // onLongPress: () {
                                //   controller.changeTeacherStatus();
                                // },
                                child: FloatingActionButton.small(
                                  shape: const CircleBorder(),
                                  onPressed: controller.setAvatarAction,
                                  heroTag: null,
                                  child: const Icon(Icons.camera_alt_outlined),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayname,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            //  style: const TextStyle(fontSize: 18),
                          ),
                          // TextButton.icon(
                          //   onPressed: () => FluffyShare.share(mxid, context),
                          //   icon: const Icon(
                          //     Icons.copy_outlined,
                          //     size: 14,
                          //   ),
                          //   style: TextButton.styleFrom(
                          //     foregroundColor:
                          //         Theme.of(context).colorScheme.secondary,
                          //   ),
                          //   label: Text(
                          //     mxid,
                          //     maxLines: 1,
                          //     overflow: TextOverflow.ellipsis,
                          //     //    style: const TextStyle(fontSize: 12),
                          //   ),
                          // ),
                          AppConfig.isTeacher
                              ? TextButton.icon(
                                  onPressed: () =>
                                      FluffyShare.share(mxid, context),
                                  icon: const Icon(
                                    Icons.copy_outlined,
                                    size: 14,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  label: Text(
                                    mxid,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    //    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              : const SizedBox(
                                  height: 10,
                                ),
                          Row(
                            children: [
                              if (AppConfig.isTeacher)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Container(
                                    width: 30.0,
                                    height: 30.0,
                                    decoration: const BoxDecoration(
                                      color: Color.fromARGB(229, 232, 212, 253),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.school,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              if (displayname.contains('(E)'))
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(229, 232, 212, 253),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.family_restroom_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              if (!displayname.contains('(E') &&
                                  displayname.contains(')'))
                                Container(
                                  width: 30.0,
                                  height: 30.0,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(229, 232, 212, 253),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.account_circle_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              if (displayname.contains('(E)'))
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Elternkonto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if (!displayname.contains('(E') &&
                                  displayname.contains(')'))
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'Hermannkind',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: FloatingActionButton.extended(
                backgroundColor: const Color.fromARGB(255, 223, 50, 50),
                foregroundColor: Colors.white,
                onPressed: controller.logoutAction,
                label: Text(
                  L10n.of(context)!.logout.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            if (showChatBackupBanner == null)
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: Text(L10n.of(context)!.chatBackup),
                trailing: const CircularProgressIndicator.adaptive(),
              )
            else
              SwitchListTile.adaptive(
                controlAffinity: ListTileControlAffinity.trailing,
                value: controller.showChatBackupBanner == false,
                secondary: const Icon(Icons.backup_outlined),
                title: Text(L10n.of(context)!.chatBackup),
                onChanged: controller.firstRunBootstrapAction,
              ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            ListTile(
              leading: const Icon(Icons.format_paint_outlined),
              title: Text(L10n.of(context)!.changeTheme),
              onTap: () => context.go('/rooms/settings/style'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(L10n.of(context)!.notifications),
              onTap: () => context.go('/rooms/settings/notifications'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.devices_outlined),
              title: Text(L10n.of(context)!.devices),
              onTap: () => context.go('/rooms/settings/devices'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            AppConfig.isTeacher == true
                ? ListTile(
                    leading: const Icon(Icons.forum_outlined),
                    title: Text(L10n.of(context)!.chat),
                    onTap: () => context.go('/rooms/settings/chat'),
                    trailing: const Icon(Icons.chevron_right_outlined),
                  )
                : const SizedBox.shrink(),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(L10n.of(context)!.security),
              onTap: () => context.go('/rooms/settings/security'),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_outlined),
              title: Text(L10n.of(context)!.help),
              onTap: () => launchUrlString(AppConfig.supportUrl),
              trailing: const Icon(Icons.open_in_new_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.shield_sharp),
              title: Text(L10n.of(context)!.privacy),
              onTap: () => launchUrlString(AppConfig.privacyUrl),
              trailing: const Icon(Icons.open_in_new_outlined),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(L10n.of(context)!.about),
              onTap: () => PlatformInfos.showDialog(context),
              trailing: const Icon(Icons.chevron_right_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
