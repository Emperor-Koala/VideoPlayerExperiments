import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class VlcVideo extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final Widget placeholder;
  final Duration startAt;

  const VlcVideo({
    @required this.url,
    this.aspectRatio = 16/9,
    this.placeholder,
    this.startAt,
  }) : assert(url != null, 'URL must be provided');

  @override
  _VlcVideoState createState() => _VlcVideoState();
}

class _VlcVideoState extends State<VlcVideo> {

  VlcPlayerController controller;
  VlcPlayerValue lastValue;

  bool validPos = false;
  double sliderVal = 0;

  bool playbackStarted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initialize();
  }

  void _initialize() async {
    controller = VlcPlayerController.network(
      widget.url,
      autoPlay: false,
      autoInitialize: false,
      onInit: () async {
        await controller.startRendererScanning();
      },
      onRendererHandler: (_, __, ___) {},
      options: VlcPlayerOptions(),
    );

    controller.addListener(newVal);
    controller.initialize().then((_) async {
      if (widget.startAt != null)
        await controller.seekTo(widget.startAt);

      lastValue = controller.value;

      setState(() {});
    });
  }

  void newVal() {
    lastValue = controller?.value;
    if (lastValue == null) return;

    if (lastValue.isEnded) {
      // TODO send complete api point
    }

    if (lastValue.position != null && lastValue.duration != null) {
      validPos = lastValue.duration.compareTo(lastValue.position) >= 0;
      sliderVal = validPos ? lastValue.position.inSeconds.toDouble() : 0;
    }

    if (lastValue.position.inSeconds % 300 == 0) {
      // TODO progress api point
    }

    setState((){});

  }

  @override
  void dispose() async {
    super.dispose();
    controller?.removeListener(newVal);
    await controller?.stopRendererScanning();
    await controller?.dispose();
  }

  String formatDuration(Duration duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? twoDigits(duration.inHours) + ':' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        VlcPlayer(
          controller: controller,
          aspectRatio: widget.aspectRatio ?? 16/9,
          placeholder: widget.placeholder ?? Center(child: CircularProgressIndicator()),
        ),

        Container(
          margin: EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: lastValue?.isInitialized == true ? [

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [

                    Expanded(
                      flex: 2,
                      child: Text(
                        formatDuration(lastValue?.position),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    Expanded(
                      flex: 9,
                      // child: Container(
                      //   height: 10,
                      //   child: VideoScrubberBar(controller),
                      // ),
                      child: Slider(
                        min: 0,
                        max: (!validPos && lastValue?.duration == null) ? 1
                            : lastValue.duration.inSeconds.toDouble(),
                        value: sliderVal,
                        onChanged: !validPos ? null : (v) {
                          // TODO
                        },
                      ),
                    ),

                    Expanded(
                      flex: 2,
                      child: Text(
                        formatDuration(lastValue?.duration),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  IconButton(
                    icon: Icon(Icons.replay_10),
                    onPressed: () {
                      controller?.seekTo(lastValue.position-Duration(seconds: 10));
                    },
                    color: Colors.white,
                  ),

                  IconButton(
                    icon: Icon(lastValue?.isPlaying == true ? Icons.pause : Icons.play_arrow),
                    onPressed: () async {
                      if (lastValue?.isPlaying == true)
                        controller?.pause();
                      else {
                        if (lastValue?.isEnded == true)
                          controller?.seekTo(Duration());

                        controller?.play()?.then((value) => setState(() => playbackStarted = true));
                      }
                    },
                    color: Colors.white,
                  ),

                  IconButton(
                    icon: Icon(Icons.forward_10),
                    onPressed: () {
                      controller?.seekTo(lastValue.position+Duration(seconds: 10));
                    },
                    color: Colors.white,
                  ),

                ],
              ),
            ] : [Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
              )),
            )],
          ),
        ),

      ],
    );
  }
}

