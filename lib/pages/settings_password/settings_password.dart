import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fluffychat/utils/custom_encrypter.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/qr_auth_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:go_router/go_router.dart';

import 'package:fluffychat/pages/settings_password/settings_password_view.dart';
import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class SettingsPassword extends StatefulWidget {
  const SettingsPassword({super.key});

  @override
  SettingsPasswordController createState() => SettingsPasswordController();
}

class SettingsPasswordController extends State<SettingsPassword> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPassword1Controller = TextEditingController();
  final TextEditingController newPassword2Controller = TextEditingController();

  String? oldPasswordError;
  String? newPassword1Error;
  String? newPassword2Error;

  bool loading = false;

  void changePassword() async {
    if (PlatformInfos.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt < 21) {
        showTopSnackBar(
          animationDuration: const Duration(milliseconds: 1600),
          displayDuration: const Duration(
            milliseconds: 80,
          ),
          snackBarPosition: SnackBarPosition.bottom,
          dismissDirection: [DismissDirection.horizontal],
          Overlay.of(context),
          CustomSnackBar.error(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
            message: L10n.of(context)!.unsupportedAndroidVersionLong,
            icon: const Icon(
              Icons.school,
              color: Color(0xffff5252),
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
    if (qrKeyEncrypted == null) return;
    final keyUtf8 = await rootBundle.loadString('assets/keys/keyaes256cbc.txt');
    final ivutf8 = await rootBundle.loadString('assets/keys/ivaes256cbc.txt');
    final myloginId = customEncrypter.decrypt(
      encryptedString: qrKeyEncrypted,
      keyUtf8: keyUtf8,
      ivUtf8: ivutf8,
    );
    final qrKey = myloginId.split('*').last.trim().substring(0, 8);
    final input = await showTextInputDialog(
      useRootNavigator: false,
      context: context,
      title: 'PIN ändern',
      okLabel: L10n.of(context)!.ok,
      cancelLabel: L10n.of(context)!.cancel,
      textFields: [
        const DialogTextField(
          hintText: 'Alte PIN eingeben',
          obscureText: true,
          keyboardType: TextInputType.number,
          minLines: 1,
          maxLines: 1,
        ),
        const DialogTextField(
          hintText: 'Neue PIN eingeben',
          obscureText: true,
          keyboardType: TextInputType.number,
          minLines: 1,
          maxLines: 1,
        ),
        const DialogTextField(
          hintText: 'Neue PIN wiederholen',
          obscureText: true,
          keyboardType: TextInputType.number,
          minLines: 1,
          maxLines: 1,
        ),
      ],
    );
    if (input == null) return;
    final oldPassword = qrKey + input[0];
    final newPassword = qrKey + input[1];
    final newPasswordRepeat = qrKey + input[2];
    if (newPassword != newPasswordRepeat) {
      showTopSnackBar(
        animationDuration: const Duration(milliseconds: 1600),
        displayDuration: const Duration(
          milliseconds: 80,
        ),
        snackBarPosition: SnackBarPosition.bottom,
        dismissDirection: [DismissDirection.horizontal],
        Overlay.of(context),
        const CustomSnackBar.error(
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          message: 'Die neuen PINs stimmen nicht überein',
          icon: Icon(
            Icons.school,
            color: Color(0xffff5252),
          ),
        ),
      );
    }

    final success = await showFutureLoadingDialog(
      context: context,
      future: () => Matrix.of(context)
          .client
          .changePassword(newPassword, oldPassword: oldPassword),
    );
    if (success.error == null) {
      showTopSnackBar(
        animationDuration: const Duration(milliseconds: 1600),
        displayDuration: const Duration(
          milliseconds: 80,
        ),
        snackBarPosition: SnackBarPosition.bottom,
        dismissDirection: [DismissDirection.horizontal],
        Overlay.of(context),
        CustomSnackBar.success(
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          message: L10n.of(context)!.passwordHasBeenChanged,
          icon: const Icon(
            Icons.school,
            color: Color(0xff00E676),
          ),
        ),
      );
    } else {
      showTopSnackBar(
        animationDuration: const Duration(milliseconds: 1600),
        displayDuration: const Duration(
          milliseconds: 80,
        ),
        snackBarPosition: SnackBarPosition.bottom,
        dismissDirection: [DismissDirection.horizontal],
        Overlay.of(context),
        const CustomSnackBar.error(
          textStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          message: 'Etwas ist schief gelaufen',
          icon: Icon(
            Icons.school,
            color: Color(0xffff5252),
          ),
        ),
      );
    }

    if (mounted) context.pop();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => SettingsPasswordView(this);
}
