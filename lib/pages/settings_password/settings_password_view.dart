import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

import 'package:fluffychat/pages/settings_password/settings_password.dart';
import 'package:fluffychat/widgets/layouts/max_width_body.dart';

class SettingsPasswordView extends StatelessWidget {
  final SettingsPasswordController controller;
  const SettingsPasswordView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context)!.changePassword),
        actions: [
          TextButton(
            child: Text(L10n.of(context)!.passwordRecoverySettings),
            onPressed: () => context.go('/rooms/settings/security/3pid'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Image.asset('assets/hermannkey.png'),
            const Text(
              'Bitte QR-Schlüssel bereit halten!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    controller.loading ? null : controller.changePassword,
                icon: const Icon(Icons.send_outlined),
                label: controller.loading
                    ? const LinearProgressIndicator()
                    : Text(L10n.of(context)!.changePassword),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
