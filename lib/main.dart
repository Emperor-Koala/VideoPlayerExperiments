import 'package:flutter/material.dart';
import 'package:video_player_test/video_player.dart';
import 'package:video_player_test/vlc_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Video Player Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool loading = true;

  @override
  void initState() {
    super.initState();
    getInfo();
  }

  void getInfo() async {

  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: TabBar(
            tabs: [Tab(text: 'video_player'), Tab(text: 'vlc')],
          ),
        ),
        body: TabBarView(
          children: [
            Center(
              child: Player(
                url: 'http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4',
                aspectRatio: 16/9,
                placeholder: Image.network('https://i.ytimg.com/vi/-moxxEjz5x4/mqdefault.jpg'),
              )
            ),
            Center(
                child: VlcVideo(
                  url: 'http://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_20mb.mp4',
                  aspectRatio: 16/9,
                  placeholder: Image.network('https://i.ytimg.com/vi/-moxxEjz5x4/mqdefault.jpg'),
                )
            ),
          ],
        ),
      ),
    );
  }
}

class VData {
  String url;
  String title;
}
