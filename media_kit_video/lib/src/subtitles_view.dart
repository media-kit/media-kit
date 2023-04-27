import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

class SubtitlesView extends StatefulWidget {

  final Player player;
  const SubtitlesView({super.key, required this.player});

  @override
  State<SubtitlesView> createState() => _SubtitlesViewState();

}

class _SubtitlesViewState extends State<SubtitlesView> {


  bool isDisabled = true;
  String? primarySubtitles;
  String? secondarySubtitles;

  final subscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    final player = widget.player;
    final platform = player.platform;
    if (platform is libmpvPlayer) {
      platform.setProperty("sub-visibility", "no");
      platform.setProperty("secondary-sub-visibility", "no");
    }
    subscriptions.addAll([
      player.streams.track.listen( (final event) {
        final isDisabled = event.subtitle == SubtitleTrack.no();
        if (isDisabled != this.isDisabled && mounted) {
          setState(() {
            this.isDisabled = isDisabled;
          });
        }
      }),
      player.streams.primarySubtitles.listen((final event) {
        if (!mounted || primarySubtitles == event) {
          return;
        }
        setState(() {
          primarySubtitles = event;
        });
      }),
      player.streams.secondarySubtitles.listen((final event) {
        if (!mounted || secondarySubtitles == event) {
          return;
        }
        setState(() {
          secondarySubtitles = event;
        });
      }),
    ]);
  }

  @override
  void dispose() {
    final player = widget.player;
    final platform = player.platform;
    if (platform is libmpvPlayer) {
      platform.setProperty("sub-visibility", "yes");
      platform.setProperty("secondary-sub-visibility", "yes");
    }
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !isDisabled,
      child: Column(
        children: [
          Text(secondarySubtitles ?? "",textAlign: TextAlign.center),
          const Spacer(),
          Text(primarySubtitles ?? "", textAlign: TextAlign.center),
        ],
      ),
    );
  }

}
