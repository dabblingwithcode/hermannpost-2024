import 'dart:async';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/qr_auth_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:fluffychat/widgets/matrix.dart';

import 'package:encrypt/encrypt.dart' as enc;

extension QrUiaRequestManager on MatrixState {
  Future qrUiaRequestHandler(UiaRequest uiaRequest) async {
    final l10n = L10n.of(context)!;
    try {
      if (uiaRequest.state != UiaRequestState.waitForUser ||
          uiaRequest.nextStages.isEmpty) {
        Logs().d('Uia Request Stage: ${uiaRequest.state}');
        return;
      }
      final stage = uiaRequest.nextStages.first;
      Logs().d('Uia Request Stage: $stage');
      switch (stage) {
        case AuthenticationTypes.password:
          final keyutf8 =
              await rootBundle.loadString('assets/keys/keyaes256cbc.txt');
          final ivutf8 =
              await rootBundle.loadString('assets/keys/ivaes256cbc.txt');
          final key = enc.Key.fromUtf8(keyutf8);
          final iv = enc.IV.fromUtf8(ivutf8);
          if (PlatformInfos.isAndroid) {
            final info = await DeviceInfoPlugin().androidInfo;
            if (info.version.sdkInt < 21) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    L10n.of(context)!.unsupportedAndroidVersionLong,
                  ),
                ),
              );
              return;
            }
          }
          final qrKeyEncrypted = await showModalBottomSheet<String>(
            isScrollControlled: false,
            isDismissible: false,
            context: context,
            builder: (_) => const QrAuthModal(),
          );
          final encryptedLoginID = enc.Encrypted.fromBase64(qrKeyEncrypted!);
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
          final myloginID = encrypter.decrypt(encryptedLoginID, iv: iv);
          final qrKey = myloginID.split('*').last.trim().substring(0, 8);

          final pin = cachedPassword ??
              (await showTextInputDialog(
                context: context,
                title: l10n.pleaseEnterYourPassword,
                okLabel: l10n.ok,
                cancelLabel: l10n.cancel,
                textFields: [
                  const DialogTextField(
                    minLines: 1,
                    maxLines: 1,
                    obscureText: true,
                    hintText: '******',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ))
                  ?.single;
          if (pin == null || pin.isEmpty || qrKey.isEmpty) {
            return uiaRequest.cancel();
          }
          final password = qrKey + pin;
          return uiaRequest.completeStage(
            AuthenticationPassword(
              session: uiaRequest.session,
              password: password,
              identifier: AuthenticationUserIdentifier(user: client.userID!),
            ),
          );

        default:
          final url = Uri.parse(
            '${client.homeserver}/_matrix/client/r0/auth/$stage/fallback/web?session=${uiaRequest.session}',
          );
          launchUrlString(url.toString());
          if (OkCancelResult.ok ==
              await showOkCancelAlertDialog(
                useRootNavigator: false,
                message: l10n.pleaseFollowInstructionsOnWeb,
                context: context,
                okLabel: l10n.next,
                cancelLabel: l10n.cancel,
              )) {
            return uiaRequest.completeStage(
              AuthenticationData(session: uiaRequest.session),
            );
          } else {
            return uiaRequest.cancel();
          }
      }
    } catch (e, s) {
      Logs().e('Error while background UIA', e, s);
      return uiaRequest.cancel(e is Exception ? e : Exception(e));
    }
  }
}

class UiaException implements Exception {
  final String reason;

  UiaException(this.reason);

  @override
  String toString() => reason;
}
