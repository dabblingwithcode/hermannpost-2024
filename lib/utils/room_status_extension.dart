import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

import '../config/app_config.dart';

extension RoomStatusExtension on Room {
  String getLocalizedTypingText(BuildContext context) {
    var typingText = '';
    final typingUsers = this.typingUsers;
    typingUsers.removeWhere((User u) => u.id == client.userID);

    if (AppConfig.hideTypingUsernames) {
      typingText = L10n.of(context)!.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText =
            L10n.of(context)!.numUsersTyping(typingUsers.length.toString());
      }
    } else if (typingUsers.length == 1) {
      typingText = L10n.of(context)!.isTyping;
      if (typingUsers.first.id != directChatMatrixID) {
        typingText =
            L10n.of(context)!.userIsTyping(typingUsers.first.calcDisplayname());
      }
    } else if (typingUsers.length == 2) {
      typingText = L10n.of(context)!.userAndUserAreTyping(
        typingUsers.first.calcDisplayname(),
        typingUsers[1].calcDisplayname(),
      );
    } else if (typingUsers.length > 2) {
      typingText = L10n.of(context)!.userAndOthersAreTyping(
        typingUsers.first.calcDisplayname(),
        (typingUsers.length - 1).toString(),
      );
    }
    return typingText;
  }

  List<Receipt> getSeenByUsers(Timeline timeline, {String? eventId}) {
    if (timeline.events.isEmpty) return [];
    final List<Event> seenEvents = [];
    for (final event in timeline.events) {
      if (!event.isState) {
        seenEvents.add(event);
      }
    }
    if (seenEvents.isNotEmpty) {
      eventId ??= seenEvents.first.eventId;
    }
    final lastReceipts = <User>{};
    final seenReceipts = <Receipt>{};
    // now we iterate the timeline events until we hit the first rendered event

    for (final event in timeline.events) {
      lastReceipts.addAll(event.receipts.map((r) => r.user));
      seenReceipts.addAll(event.receipts);
      if (event.receipts.isNotEmpty) {
        for (final receipt in event.receipts) {
          debugPrint(
            'seen by ${receipt.user.displayName}  at ${receipt.time.toString()}',
          );
        }
      }

      if (event.eventId == eventId) {
        break;
      }
    }
    lastReceipts.removeWhere(
      (user) =>
          user.id == client.userID ||
          user.id == timeline.events.first.senderId ||
          user.displayName == null,
    );
    seenReceipts.removeWhere(
      (element) =>
          element.user.id == client.userID ||
          element.user.id == timeline.events.first.senderId ||
          element.user.displayName == null,
    );
    //return lastReceipts.toList();
    final sortedReceipts = seenReceipts.toList();
    sortedReceipts.sort((item1, item2) => item1.time.compareTo(item2.time));
    return sortedReceipts;
  }
}
