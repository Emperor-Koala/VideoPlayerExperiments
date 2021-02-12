import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class Player extends StatefulWidget {

  final String url;
  final double aspectRatio;
  final Widget placeholder;
  final Duration startAt;

  const Player({
    @required this.url,
    this.aspectRatio = 16/9,
    this.placeholder,
    this.startAt,
  }) : assert(url != null, 'URL must be provided');

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {

  VideoPlayerController controller;
  bool playbackStarted = false;

  VideoPlayerValue lastValue;

  bool complete = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    controller = VideoPlayerController.network(widget.url);

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

    complete = (lastValue.position ?? Duration.zero) >= (lastValue.duration ?? Duration.zero);

    if (complete) {
      // TODO send complete api point
    }

    if (lastValue.position.inSeconds % 300 == 0) {
      // TODO progress api point
    }

    setState((){});

  }

  @override
  void dispose() {
    controller?.removeListener(newVal);
    controller?.dispose();
    super.dispose();
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
        AspectRatio(
          aspectRatio: widget.aspectRatio ?? 16/9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (lastValue?.initialized == true && playbackStarted)
                VideoPlayer(controller)
              else if (widget.placeholder != null)
                widget.placeholder,

              if (lastValue?.hasError == true)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 42,
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80.0),
                      child: Text(
                        lastValue.errorDescription,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else if (lastValue?.isBuffering == true)
                Center(
                  child: CircularProgressIndicator()
                ),

            ],
          ),
        ),

        Container(
          margin: EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: lastValue?.initialized == true ? [

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
                      child: Container(
                        height: 10,
                        child: VideoScrubberBar(controller),
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
                        if (complete == true)
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

class ScrubberProgressColors {
  ScrubberProgressColors({
    Color playedColor = const Color.fromRGBO(255, 255, 255, 1.0),
    Color bufferedColor = const Color.fromRGBO(255, 255, 255, 0.6),
    Color handleColor = const Color.fromRGBO(255, 255, 255, 1.0),
    Color backgroundColor = const Color.fromRGBO(255, 255, 255, 0.3),
  })  : playedPaint = Paint()..color = playedColor,
        bufferedPaint = Paint()..color = bufferedColor,
        handlePaint = Paint()..color = handleColor,
        backgroundPaint = Paint()..color = backgroundColor;

  final Paint playedPaint;
  final Paint bufferedPaint;
  final Paint handlePaint;
  final Paint backgroundPaint;
}

class VideoScrubberBar extends StatefulWidget {
  VideoScrubberBar(
      this.controller, {
        ScrubberProgressColors colors,
        this.onDragEnd,
        this.onDragStart,
        this.onDragUpdate,
        Key key,
      })  : colors = colors ?? ScrubberProgressColors(),
        super(key: key);

  final VideoPlayerController controller;
  final ScrubberProgressColors colors;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

class _VideoProgressBarState extends State<VideoScrubberBar> {
  _VideoProgressBarState() {
    listener = () {
      if (!mounted) return;
      setState(() {});
    };
  }

  VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height / 2,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              controller.value,
              widget.colors,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.colors);

  VideoPlayerValue value;
  ScrubberProgressColors colors;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const height = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(size.width, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.backgroundPaint,
    );
    if (!value.initialized) {
      return;
    }
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart =
    playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (final DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromPoints(
            Offset(start, size.height / 2),
            Offset(end, size.height / 2 + height),
          ),
          const Radius.circular(4.0),
        ),
        colors.bufferedPaint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(0.0, size.height / 2),
          Offset(playedPart, size.height / 2 + height),
        ),
        const Radius.circular(4.0),
      ),
      colors.playedPaint,
    );
    canvas.drawCircle(
      Offset(playedPart, size.height / 2 + height / 2),
      height * 3,
      colors.handlePaint,
    );
  }
}