import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
//import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:qr_flutter/qr_flutter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/new_private_chat/new_private_chat.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';

import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';
import 'package:fluffychat/widgets/matrix.dart';

import 'package:pretty_qr_code/pretty_qr_code.dart';

class NewPrivateChatView extends StatelessWidget {
  final NewPrivateChatController controller;

  const NewPrivateChatView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    if (controller.qrData == '') controller.generateQrData();
    final searchResponse = controller.searchResponse;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: const Center(child: BackButton()),
        title: Text(L10n.of(context)!.newChat),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          if (AppConfig.isTeacher == true)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => context.go('/newgroup'),
                child: Text(
                  L10n.of(context)!.createGroup,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            ),
        ],
      ),
      body: MaxWidthBody(
        withScrolling: false,
        innerPadding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // const SizedBox(
            //   height: 20,
            // ),
            FutureBuilder<Profile>(
              future: controller.profileFuture(),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final mxid =
                    Matrix.of(context).client.userID ?? L10n.of(context)!.user;
                final displayname =
                    profile?.displayName ?? mxid.localpart ?? mxid;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 8,
                        bottom: 16,
                      ),
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
                                Avatar.defaultSize * 4,
                              ),
                            ),
                            child: Avatar(
                              mxContent: profile?.avatarUrl,
                              name: displayname,
                              size: Avatar.defaultSize * 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      displayname,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      //  style: const TextStyle(fontSize: 18),
                    ),
                  ],
                );
              },
            ),

            Expanded(
              child: AnimatedCrossFade(
                duration: FluffyThemes.animationDuration,
                crossFadeState: searchResponse == null
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: ListView(
                  children: [
                    if (AppConfig.isTeacher)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0),
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: L10n.of(context)!.yourGlobalUserIdIs,
                              ),
                              TextSpan(
                                text: Matrix.of(context).client.userID,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 64.0,
                          right: 64.0,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 256),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            elevation: 10,
                            color: Colors.white,
                            shadowColor:
                                Theme.of(context).appBarTheme.shadowColor,
                            clipBehavior: Clip.hardEdge,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FutureBuilder<String>(
                                future: controller.generateQrData(),
                                builder: (context, snapshot) {
                                  return PrettyQrView.data(
                                    data: controller.encryptedInvitation,
                                    decoration: PrettyQrDecoration(
                                      shape: PrettyQrSmoothSymbol(
                                        roundFactor: 1,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (AppConfig.isTeacher)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          child: const Icon(Icons.group_add_outlined),
                        ),
                        title: Text(L10n.of(context)!.createGroup),
                        onTap: () => context.go('/rooms/newgroup'),
                      ),
                    if (PlatformInfos.isMobile)
                      // FloatingActionButton.extended(
                      //   backgroundColor: Theme.of(context).colorScheme.primary,
                      //   foregroundColor:
                      //       Theme.of(context).colorScheme.onPrimary,
                      //   onPressed: () => controller.openScannerAction,
                      //   label: const Row(
                      //     children: [
                      //       Icon(Icons.qr_code_scanner_outlined),
                      //       SizedBox(width: 8),
                      //       Text(
                      //         'QR',
                      //         style: TextStyle(
                      //           fontWeight: FontWeight.bold,
                      //           fontSize: 18,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      //   icon: const Icon(Icons.groups_2_rounded),
                      // ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: () => controller.openScannerAction(),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'ODER SCANNEN',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.qr_code_scanner_outlined),
                            ],
                          ),
                        ),
                      ),
                    // ListTile(
                    //   leading: Center(
                    //     child: CircleAvatar(
                    //       backgroundColor:
                    //           Theme.of(context).colorScheme.primaryContainer,
                    //       foregroundColor:
                    //           Theme.of(context).colorScheme.onPrimaryContainer,
                    //       child: const Icon(Icons.qr_code_scanner_outlined),
                    //     ),
                    //   ),
                    //   title: Text(L10n.of(context)!.scanQrCode),
                    //   onTap: controller.openScannerAction,
                    // ),
                  ],
                ),
                secondChild: FutureBuilder(
                  future: searchResponse,
                  builder: (context, snapshot) {
                    final result = snapshot.data;
                    final error = snapshot.error;
                    if (error != null) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            error.toLocalizedString(context),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: controller.searchUsers,
                            icon: const Icon(Icons.refresh_outlined),
                            label: Text(L10n.of(context)!.tryAgain),
                          ),
                        ],
                      );
                    }
                    if (result == null) {
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    }
                    if (result.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_outlined, size: 86),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              L10n.of(context)!.noUsersFoundWithQuery(
                                controller.controller.text,
                              ),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      itemCount: result.length,
                      itemBuilder: (context, i) {
                        final contact = result[i];
                        final displayname = contact.displayName ??
                            contact.userId.localpart ??
                            contact.userId;
                        return ListTile(
                          leading: Avatar(
                            name: displayname,
                            mxContent: contact.avatarUrl,
                            presenceUserId: contact.userId,
                          ),
                          title: Text(displayname),
                          subtitle: Text(contact.userId),
                          onTap: () => controller.openUserModal(contact),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const Center(
              child: Text(
                'oder suche nach einem Kontakt der Hermannschule',
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: FloatingActionButton.extended(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () => controller.openContactsRoom(),
                label: const Text(
                  'KONTAKTE HERMANNSCHULE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                icon: const Icon(Icons.groups_2_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
