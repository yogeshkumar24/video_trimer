import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:video_compress/video_compress.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Trimmer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: Center(
        child: Container(
          child: ElevatedButton(
            child: Text("LOAD VIDEO"),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.video,
                allowCompression: false,
              );
              if (result != null) {
                File file = File(result.files.single.path!);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return TrimmerView(file);
                  }),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class TrimmerView extends StatefulWidget {
  final File file;

  TrimmerView(this.file);

  @override
  _TrimmerViewState createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;
  late String filePath;

  bool isCompress = false;
  MediaInfo? info;


  void _loadVideo() async{

    final info1 = await compressVideo(widget.file.path);
    print("info ========1 ${info1.file}");
    _trimmer.loadVideo(videoFile: info1!.file);
    FileStat sts = await widget.file.stat();
    print("full video length   ++==========${sts.size}");
  }


  Future<String?> _saveVideo() async {
    setState(() {
      _progressVisibility = true;
    });

     _trimmer
        .saveTrimmedVideo(startValue: _startValue, endValue: _endValue)
        .then((value) {
      setState(() {
        _progressVisibility = false;
        filePath = value;
        print("========${value}");
      });
    });

    return filePath;
  }



  compressVideo(String? value)async{

    setState(() {
      isCompress = true;
    });
     info = await  VideoCompress.compressVideo(
      value!,
      quality: VideoQuality.LowQuality,
      deleteOrigin: false,
      includeAudio: true,
    );


     print("============ after compress${info!.file!.path}");

    setState(() {
      isCompress = false;
    });
    showDialog(context: context, builder: (child){
      return AlertDialog(title: Text("Compress"),
      content: Text("Video Compressed"),
      actions: [ElevatedButton(onPressed: (){Navigator.of(context).pop();}, child: Text("ok"))],);
    });

    FileStat stat = await info!.file!.stat();
    print("After compress video size is +======${stat.size}");

    return info;
  }


  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Video Trimmer"),
      ),
      body: isCompress!= false ? Center(child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Compressing"),
          SizedBox(width: 16,),
          CircularProgressIndicator(),
        ],
      ),):Builder(
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.only(bottom: 30.0),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Visibility(
                  visible: _progressVisibility,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.red,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                  ElevatedButton(
                    onPressed: _progressVisibility
                        ? null
                        : () async {
                      _saveVideo().then((outputPath) {
                        print('OUTPUT PATH: $outputPath');
                        final snackBar = SnackBar(
                            content: Text('Video Saved successfully'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          snackBar,
                        );
                      });
                    },
                    child: Text("SAVE"),
                  ),

                  ElevatedButton(onPressed: (){
                    compressVideo(widget.file.path);},
                      child:Text("Compress Video"))
                ],),
                Expanded(
                  child: VideoViewer(trimmer: _trimmer),
                ),
                Center(
                  child: TrimEditor(
                    trimmer: _trimmer,
                    viewerHeight: 50.0,
                    viewerWidth: MediaQuery.of(context).size.width,
                    maxVideoLength: Duration(seconds: 10),
                    onChangeStart: (value) {
                      _startValue = value;
                    },
                    onChangeEnd: (value) {
                      _endValue = value;
                    },
                    onChangePlaybackState: (value) {
                      setState(() {
                        _isPlaying = value;
                      });
                    },
                  ),
                ),
                TextButton(
                  child: _isPlaying
                      ? Icon(
                    Icons.pause,
                    size: 80.0,
                    color: Colors.white,
                  )
                      : Icon(
                    Icons.play_arrow,
                    size: 80.0,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    bool playbackState = await _trimmer.videPlaybackControl(
                      startValue: _startValue,
                      endValue: _endValue,
                    );
                    setState(() {
                      _isPlaying = playbackState;
                    });
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}