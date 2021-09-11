
part of 'my_custom.dart';

class MyWebSocketClient extends StatefulWidget{
  const MyWebSocketClient({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MyWebSocketClientState();
  }

}

class MyWebSocketClientState extends State<MyWebSocketClient>{

  late WebSocketChannel channel ;//= IOWebSocketChannel.connect('ws://192.168.10.235:7001');
  final  _controllerSessionId =  TextEditingController();
  final _controllerUserId = TextEditingController();
  late RTCPeerConnection _peerConnection;
  final List<RTCVideoRenderer> _remoteRenderers = [];
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocketClient')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Form(child: TextFormField(
              controller: _controllerSessionId,
              decoration: const InputDecoration(labelText: 'session id'),
            )),
            Form( child: TextFormField(
              controller: _controllerUserId,
              decoration: const InputDecoration(labelText: 'user id'),
            ),
            ),
            ElevatedButton(
              onPressed:  _clickConnect,
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: (){
                log('click pttBegin');
              },
              child: const Text('pttBegin'),
            ),
            ElevatedButton(
              onPressed: _clickClose,
              child: const Text('pttEnd'),

            ),
            ElevatedButton(
              onPressed: (){
                log('click close');
                channel.sink.close();
              },
              child: const Text('close'),
              style: const ButtonStyle(alignment: Alignment.center),
            ),

          ],

        ),
      )
    );
  }
  void _clickClose(){
    debugPrint('click pttEnd');
    channel.sink.close();
    _peerConnection.close();
    _remoteRenderers.map((element) {element.dispose() ;});
  }
  void _clickConnect() async{
    debugPrint('click Connect');
    channel = IOWebSocketChannel.connect('ws://192.168.10.235:7001/ws');
    channel.stream.listen((message)  {  _parseMsg(message.toString());},
      onError: (e){log('err:'+e.toString());},
      onDone: (){log('webSocket done');},
      //cancelOnError: false,
    );
    await _connectPC();
    //send join
    channel.sink.add(const JsonEncoder().convert({
      'event':'join',
      'data': const JsonEncoder().convert({
        'sid':'1',
        'uid':'321'
      })
    }));
  }
  Future<void> _connectPC() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ],
      // 'sdpSemantics': sdpSemantics
    };
    _peerConnection = await createPeerConnection(configuration,{});
    _peerConnection.onRenegotiationNeeded = (){
      debugPrint('onRenegotiationNeeded');
    };
    _peerConnection.onIceCandidate = (candidate){
      debugPrint("My Candidate -->");

      var data = const JsonEncoder().convert({
        'event':'candidate',
        'target':'sub',
        'data':const JsonEncoder().convert({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        })
      });
      debugPrint(data);
      channel.sink.add(data);
    };
    _peerConnection.onTrack = (event) async{
      debugPrint("onTrack");
      if(event.track.kind=='audio' && event.streams.isNotEmpty){
        //var render = RTCVideoRenderer();
        //await render.initialize();
      // render.srcObject = event.streams[0];
      // _remoteRenderers.add(render);
        // setState(() {
        //
        // });
      }
    };
  }
  void _parseMsg(String raw) async{

    Map<String, dynamic> msg = jsonDecode(raw);

    //log(msg.toString());
    switch(msg['event']){
      case 'offer':
        debugPrint('receive offer');
        //log(msg['data']);
        Map<String,dynamic> offer = jsonDecode(msg['data']);
        await _peerConnection.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
        RTCSessionDescription answer = await _peerConnection.createAnswer({});
        await _peerConnection.setLocalDescription(answer);
        //send answer
        channel.sink.add(const JsonEncoder().convert({
          'event':'answer',
          'target':'sub',
          'data': const JsonEncoder().convert(answer.toMap())
        }));
        break;
      case 'answer':
        debugPrint('receive answer');

        break;
      case 'candidate':
        debugPrint("receive candidate --> ${msg['target']}");
        if(msg['target'] == 'sub'){
          Map<String,dynamic> parsed = jsonDecode(msg['data']);
          log(parsed.toString());

          try{
            RTCSessionDescription? remoteDSP = await _peerConnection.getRemoteDescription();
            // if( remoteDSP == null){
            //   debugPrint('getRemoteDescription is null');
            //   return;
            // }
            debugPrint(parsed['candidate']);
            //参数是string类型的不要写null
            _peerConnection.addCandidate(RTCIceCandidate(parsed['candidate'], '', 0));
          }on Exception catch(e){
            debugPrint(e.toString());
          }


        }
        break;
      case 'join':
        break;
      case 'pttBegin':
        break;
      case 'pttEnd':
        break;
      case 'err':
        log(msg['data']);
        break;
      default:
        log('unknow switch');
        break;
    }
  }
  void myPrint(){

  }
  @override
  void dispose(){
    log('dispose');
    super.dispose();
    _controllerSessionId.dispose();
    _controllerUserId.dispose();
    channel.sink.close();
  }
}