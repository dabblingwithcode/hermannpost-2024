import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:fluffychat/utils/custom_encrypter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:fluffychat/pages/new_private_chat/qr_scanner_modal.dart';
import 'package:fluffychat/pages/user_bottom_sheet/user_bottom_sheet.dart';
import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/utils/fluffy_share.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';

class NewPrivateChat extends StatefulWidget {
  const NewPrivateChat({super.key});

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends State<NewPrivateChat> {
  final TextEditingController controller = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();
  String schoolDirectoryRoomId = '!gqnnuXGiaupQKSwCWB:hermannschule.de';
  String encryptedInvitation = '';

  Future<Profile>? profileFuture() {
    final client = Matrix.of(context).client;
    return client.getProfileFromUserId(
      client.userID!,
      cache: true,
      getFromRooms: true,
    );
  }

  Future<List<Profile>>? searchResponse;

  Timer? _searchCoolDown;
  String qrData = '';
  static const Duration _coolDown = Duration(milliseconds: 500);

  void searchUsers([String? input]) async {
    final searchTerm = input ?? controller.text;
    if (searchTerm.isEmpty) {
      _searchCoolDown?.cancel();
      setState(() {
        searchResponse = _searchCoolDown = null;
      });
      return;
    }

    _searchCoolDown?.cancel();
    _searchCoolDown = Timer(_coolDown, () {
      setState(() {
        searchResponse = _searchUser(searchTerm);
      });
    });
  }

  Future<List<Profile>> _searchUser(String searchTerm) async {
    final result =
        await Matrix.of(context).client.searchUserDirectory(searchTerm);
    final profiles = result.results;

    if (searchTerm.isValidMatrixId &&
        searchTerm.sigil == '@' &&
        !profiles.any((profile) => profile.userId == searchTerm)) {
      profiles.add(Profile(userId: searchTerm));
    }

    return profiles;
  }

  void inviteAction() => FluffyShare.shareInviteLink(context);

  void openScannerAction() async {
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
    final qrScanResult = await BarcodeScanner.scan();
    if (qrScanResult.rawContent == '') return;
    useInvitation(qrScanResult.rawContent);
    // await showAdaptiveBottomSheet(
    //   context: context,
    //   builder: (_) => QrScannerModal(
    //     onScan: (link) => UrlLauncher(context, link).openMatrixToUrl(),
    //   ),
    // );
  }

  void useInvitation(encryptedScan) async {
    final keyutf8 = await rootBundle.loadString('assets/keys/keyaes256cbc.txt');
    final ivutf8 = await rootBundle.loadString('assets/keys/ivaes256cbc.txt');
    String decryptedString = customEncrypter.decrypt(
      encryptedString: encryptedScan,
      keyUtf8: keyutf8,
      ivUtf8: ivutf8,
    );

    if (decryptedString.startsWith('1')) {
      decryptedString = decryptedString.substring(1);
    }
    int starIndex = decryptedString.indexOf(':');
    if (starIndex != -1) {
      decryptedString = decryptedString.substring(0, starIndex);
    }
    UrlLauncher(
            context, 'https://matrix.to/#/@$decryptedString:hermannschule.de')
        .openMatrixToUrl();
  }

  Future<void> openContactsRoom([_]) async {
    UrlLauncher(context, 'https://matrix.to/#/#kontakte:hermannschule.de')
        .openMatrixToUrl();
  }

  Future<String> generateQrData() async {
    final userID = Matrix.of(context).client.userID;
    final inviteLink = 'https://matrix.to/#/$userID';
    final keyutf8 = await rootBundle.loadString('assets/keys/keyaes256cbc.txt');
    final ivutf8 = await rootBundle.loadString('assets/keys/ivaes256cbc.txt');
    final String inviteLinkEncrypted = customEncrypter.encrypt(
      nonEncryptedString: inviteLink,
      keyUtf8: keyutf8,
      ivUtf8: ivutf8,
    );
    setState(() {
      qrData = inviteLinkEncrypted;
    });
    return inviteLinkEncrypted;
  }

  void copyUserId() async {
    await Clipboard.setData(
      ClipboardData(text: Matrix.of(context).client.userID!),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L10n.of(context)!.copiedToClipboard)),
    );
  }

  void openUserModal(Profile profile) => showAdaptiveBottomSheet(
        context: context,
        builder: (c) => UserBottomSheet(
          profile: profile,
          outerContext: context,
        ),
      );

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
