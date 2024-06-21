import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrAuthModal extends StatefulWidget {
  const QrAuthModal({super.key});

  @override
  QrAuthModalState createState() => QrAuthModalState();
}

class QrAuthModalState extends State<QrAuthModal> {
  final GlobalKey qrAuthKey = GlobalKey(debugLabel: 'QRAuth');
  QRViewController? controller;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // leading: IconButton(
        //   icon: const Icon(Icons.close_outlined),
        //   onPressed: ,
        //   tooltip: L10n.of(context)!.close,
        // ),
        title: const Text('QR-KEY'),
      ),
      body: Stack(
        children: [
          QRView(
            key: qrAuthKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Theme.of(context).primaryColor,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
            ),
          ),
        ],
      ),
    );
  }

  _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    // Workaround for QR Scanner is started in Pause mode
    // https://github.com/juliuscanute/qr_code_scanner/issues/538#issuecomment-1133883828
    if (Platform.isAndroid) {
      controller.pauseCamera();
    }
    controller.resumeCamera();
    late StreamSubscription sub;
    sub = controller.scannedDataStream.listen((scanData) {
      sub.cancel();
      Navigator.of(context).pop(scanData.code);
      //UrlLauncher(context, scanData.code).openMatrixToUrl();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
