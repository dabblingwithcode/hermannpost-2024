import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/widgets/layouts/login_scaffold.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../config/themes.dart';
import '../../widgets/mxc_image.dart';
import 'homeserver_app_bar.dart';
import 'homeserver_picker.dart';

class HomeserverPickerView extends StatelessWidget {
  final HomeserverPickerController controller;

  const HomeserverPickerView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final identityProviders = controller.identityProviders;
    final errorText = controller.error;
    final publicHomeserver = controller.cachedHomeservers?.singleWhereOrNull(
      (homeserver) =>
          homeserver.name ==
          controller.homeserverController.text.trim().toLowerCase(),
    );
    final regLink = publicHomeserver?.regLink;
    return LoginScaffold(
      enforceMobileMode: Matrix.of(context).client.isLogged(),
      // appBar: AppBar(
      //   titleSpacing: 12,
      //   automaticallyImplyLeading: false,
      //   surfaceTintColor: Theme.of(context).colorScheme.surface,
      //   title: HomeserverAppBar(controller: controller),
      // ),
      body: Column(
        children: [
          // display a prominent banner to import session for TOR browser
          // users. This feature is just some UX sugar as TOR users are
          // usually forced to logout as TOR browser is non-persistent
          AnimatedContainer(
            height: controller.isTorBrowser ? 64 : 0,
            duration: FluffyThemes.animationDuration,
            curve: FluffyThemes.animationCurve,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: Material(
              clipBehavior: Clip.hardEdge,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(8)),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                leading: const Icon(Icons.vpn_key),
                title: Text(L10n.of(context)!.hydrateTor),
                subtitle: Text(L10n.of(context)!.hydrateTorLong),
                trailing: const Icon(Icons.chevron_right_outlined),
                onTap: controller.restoreBackup,
              ),
            ),
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : ListView(
                    children: [
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            errorText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            L10n.of(context)!
                                .pleaseTryAgainLaterOrChooseDifferentServer,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                      ] else
                        Column(
                          children: [
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 0.0,
                                right: 8.0,
                                left: 8.0,
                                bottom: 16.0,
                              ),
                              child: Image.asset(
                                'assets/hermannpost-banner.png',
                              ),
                            ),
                          ],
                        ),
                      // if (identityProviders != null) ...[
                      //   ...identityProviders.map(
                      //     (provider) => _LoginButton(
                      //       icon: provider.icon == null
                      //           ? const Icon(
                      //               Icons.open_in_new_outlined,
                      //               size: 16,
                      //             )
                      //           : Material(
                      //               borderRadius: BorderRadius.circular(
                      //                 AppConfig.borderRadius,
                      //               ),
                      //               clipBehavior: Clip.hardEdge,
                      //               child: MxcImage(
                      //                 placeholder: (_) => const Icon(
                      //                   Icons.open_in_new_outlined,
                      //                   size: 16,
                      //                 ),
                      //                 uri: Uri.parse(provider.icon!),
                      //                 width: 24,
                      //                 height: 24,
                      //                 isThumbnail: false,
                      //                 //isThumbnail: false,
                      //               ),
                      //             ),
                      //       label: L10n.of(context)!.signInWith(
                      //         provider.name ??
                      //             provider.brand ??
                      //             L10n.of(context)!.singlesignon,
                      //       ),
                      //       onPressed: () =>
                      //           controller.ssoLoginAction(provider.id),
                      //     ),
                      //   ),
                      // ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: controller.qrLogin,
                          onLongPress: controller.login,
                          icon: const Icon(Icons.login_outlined),
                          label: Text(L10n.of(context)!.login),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: controller.restoreBackup,
                          child: Text(L10n.of(context)!.hydrate),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final Widget? icon;
  final String label;
  final void Function() onPressed;
  final void Function() onLongPressed;
  final bool withBorder;

  const _LoginButton({
    this.icon,
    required this.label,
    required this.onPressed,
    required this.onLongPressed,
    this.withBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: FluffyThemes.isColumnMode(context)
                ? BorderSide.none
                : BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(99),
            ),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: withBorder
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
          ),
          onPressed: onPressed,
          label: Text(label),
          icon: icon ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
