import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart' show BarcodeScanner;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:matrix/matrix.dart';
import 'package:encrypt/encrypt.dart' as enc;

import 'package:fluffychat/config/app_config.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import 'package:fluffychat/utils/localized_exception_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../config/setting_keys.dart';
import '../../utils/platform_infos.dart';

class QrLoginScreen extends StatefulWidget {
  const QrLoginScreen({super.key});

  @override
  QrLoginState createState() => QrLoginState();
}

class QrLoginState extends State<QrLoginScreen> {
  String? usernameError;
  String? passwordError;
  bool loading = false;
  late String base64encryptedLoginID;
  late String newloginID;
  late String myloginID;
  late String matrixID;
  late String username;
  late String password;
  late String passwordCode;
  late String homeserver;
  late String passwordPin;

  String loginScanMessage =
      'Scanne den QR-Code, den du von deiner Schule bekommen hast!';
  String loginScanImage = 'assets/hermannkey.png';

  void decrypt(BuildContext context) async {
    final keyutf8 = await rootBundle.loadString('assets/keys/keyaes256cbc.txt');
    final ivutf8 = await rootBundle.loadString('assets/keys/ivaes256cbc.txt');
    final key = enc.Key.fromUtf8(keyutf8);
    final iv = enc.IV.fromUtf8(ivutf8);
    final encryptedLoginID = enc.Encrypted.fromBase64(base64encryptedLoginID);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final newloginID = encrypter.decrypt(encryptedLoginID, iv: iv);

    myloginID = newloginID;

    if (myloginID[0] == '1') {
      myloginID = myloginID.substring(1);

      AppConfig.isTeacher = true;
      await Matrix.of(context).store.setBool(SettingKeys.isTeacher, true);
      if (kDebugMode) {
        print('Teacher mode ON');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Teacher mode is ON',
            ),
          ),
        );
      }
    } else {
      AppConfig.isTeacher = false;
      await Matrix.of(context).store.setBool(SettingKeys.isTeacher, false);
      if (kDebugMode) {
        print('Teacher mode OFF');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'Teacher mode is OFF',
            ),
          ),
        );
      }
    }

    matrixID = myloginID.split('*').first;
    password = myloginID.split('*').last;
    password = password.trim();
    password = password.substring(0, 8);
    homeserver = matrixID.split(':').last;
    username = matrixID.split(':').first;

    loginScanImage = 'assets/scansuccess.png';
    loginScanMessage = 'Scan erfolgreich!';
    checkHomeserverAction(homeserver, context);
  }

  void checkHomeserverAction(String homeserver, BuildContext context) async {
    checkPin(context);
  }

  void checkPin(BuildContext context) async {
    final pin = await enterText();
    if (pin == null) {
      loginScanImage = 'assets/wrongpin.png';
      loginScanMessage = 'Aktion abgebrochen!';
      return;
    }
    password = password + pin;
    login(context);
  }

  void login(BuildContext context) async {
    final matrix = Matrix.of(context);

    setState(() {
      //pr.show();
      const CircularProgressIndicator();
      usernameError = '';
      passwordError = '';
      loading = true;
      loginScanImage = 'assets/favicon.png';
      loginScanMessage = 'Deine Zugangsdaten werden geprüft... ';
    });
    try {
      await matrix.getLoginClient().login(
            LoginType.mLoginPassword,
            identifier: AuthenticationUserIdentifier(user: username),
            password: password,
            initialDeviceDisplayName: PlatformInfos.clientName,
          );
    } on MatrixException catch (exception) {
      setState(() {
        passwordError = exception.errorMessage;
        loginScanImage = 'assets/wrongpin.png';
        loginScanMessage = 'Bitte an Admin melden: $passwordError';
      });
      await _wrongPinDialog();
      return setState(() => loading = false);
    } catch (exception) {
      setState(() {
        passwordError = exception.toString();
        loginScanImage = 'assets/wrongpin.png';
        loginScanMessage = 'Bitte an Admin melden: $passwordError';
      });
      await _wrongPinDialog();
      return setState(() => loading = false);
    }

    if (mounted) setState(() => loading = false);
  }

  Timer? _coolDown;

  void checkWellKnownWithCoolDown(String userId, BuildContext context) async {
    _coolDown?.cancel();
    _coolDown = Timer(
      const Duration(seconds: 1),
      () => _checkWellKnown(userId),
    );
  }

  void _checkWellKnown(String userId) async {
    if (mounted) setState(() => usernameError = null);
    if (!userId.isValidMatrixId) return;
    final oldHomeserver = Matrix.of(context).getLoginClient().homeserver;
    try {
      var newDomain = Uri.https(userId.domain!, '');
      Matrix.of(context).getLoginClient().homeserver = newDomain;
      DiscoveryInformation? wellKnownInformation;
      try {
        wellKnownInformation =
            await Matrix.of(context).getLoginClient().getWellknown();
        if (wellKnownInformation.mHomeserver.baseUrl.toString().isNotEmpty) {
          newDomain = wellKnownInformation.mHomeserver.baseUrl;
        }
      } catch (_) {
        // do nothing, newDomain is already set to a reasonable fallback
      }
      if (newDomain != oldHomeserver) {
        await Matrix.of(context).getLoginClient().checkHomeserver(newDomain);

        if (Matrix.of(context).getLoginClient().homeserver == null) {
          Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
          // okay, the server we checked does not appear to be a matrix server
          Logs().v(
            '$newDomain is not running a homeserver, asking to use $oldHomeserver',
          );
          final dialogResult = await showOkCancelAlertDialog(
            context: context,
            useRootNavigator: false,
            message:
                L10n.of(context)!.noMatrixServer(newDomain, oldHomeserver!),
            okLabel: L10n.of(context)!.ok,
            cancelLabel: L10n.of(context)!.cancel,
          );
          if (dialogResult == OkCancelResult.ok) {
            if (mounted) setState(() => usernameError = null);
          } else {
            Navigator.of(context, rootNavigator: false).pop();
            return;
          }
        }
        usernameError = null;
        if (mounted) setState(() {});
      } else {
        Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      Matrix.of(context).getLoginClient().homeserver = oldHomeserver;
      usernameError = e.toLocalizedString(context);
      if (mounted) setState(() {});
    }
  }

  Future<bool> checkHomeserver(dynamic homeserver, Client client) async {
    await client.checkHomeserver(homeserver);
    return true;
  }

  Future<String?> enterText({
    String? titleText,
    String? confirmText,
    String? cancelText,
    String? hintText,
    String? labelText,
    String? prefixText,
    String? suffixText,
    bool password = true,
    bool multiLine = false,
  }) async {
    final textEditingController = TextEditingController();
    final controller = textEditingController;
    final input = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titleText ?? 'PIN-Eingabe'),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          onSubmitted: (s) {
            Navigator.of(c).pop(s);
          },
          minLines: multiLine ? 3 : 1,
          maxLines: multiLine ? 3 : 1,
          obscureText: password,
          textInputAction: multiLine ? TextInputAction.newline : null,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
            prefixText: prefixText,
            suffixText: suffixText,
            prefixStyle: TextStyle(color: Theme.of(context).primaryColor),
            suffixStyle: TextStyle(color: Theme.of(context).primaryColor),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              cancelText?.toUpperCase() ??
                  L10n.of(context)!.cancel.toUpperCase(),
              style: const TextStyle(color: Colors.blueGrey),
            ),
            onPressed: () => Navigator.of(c).pop(null),
          ),
          TextButton(
            child: Text(
              confirmText?.toUpperCase() ??
                  L10n.of(context)!.confirm.toUpperCase(),
            ),
            onPressed: () {
              Navigator.of(c).pop(controller.text);
            },
          ),
        ],
      ),
    );
    return input;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mit QR-Scan einloggen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Image.asset(loginScanImage),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                loginScanMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            if (loading == false)
              Hero(
                tag: 'loginwithScan',
                child: Container(
                  width: double.infinity,
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(74, 60, 144, 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: scan,
                    icon: const Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      L10n.of(context)!.scanQrCode.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Future scan() async {
    try {
      final barcode = await BarcodeScanner.scan();
      if (barcode.rawContent.isEmpty) {
        setState(() {
          loginScanMessage = 'Der Scan hat nicht geklappt!';
        });
        return;
      }
      setState(() {
        base64encryptedLoginID = barcode.rawContent;

        loginScanImage = 'assets/scansuccess.png';
        loginScanMessage = 'Scannen hat geklappt';
        if (kDebugMode) {
          print('Scannen hat geklappt, Ergbebnis: ${barcode.rawContent}');
        }
        decrypt(context);
      });
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(() {
          loginScanMessage =
              'Bitte erlaube zum Scannen den Zugriff auf die Kamera!';
        });
      } else {
        setState(() => loginScanMessage = 'Unknown error: $e');
      }
    } on FormatException {
      setState(
        () => loginScanMessage = 'NutzerIn hat den Scanvorgang abgebrochen!',
      );
    } catch (e) {
      setState(() => loginScanMessage = 'Der Scan hat nicht geklappt: $e');
    }
  }

  Future<void> _wrongPinDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('PIN stimmt nicht!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Die PIN-Nummer ist nicht richtig!'),
                Text(' '),
                Text('Versuche es nochmal oder melde dich beim Admin.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _badQrDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konto nicht vorhanden!'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Das Konto wurde wahrscheinlich deaktiviert.'),
                Text(' '),
                Text('Melde dich beim Admin.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
