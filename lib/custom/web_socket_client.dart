
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
  final  _controllerSessionId =  TextEditingController(text:'1');
  final _controllerUserId = TextEditingController(text: '666');
  final _controllerWS = TextEditingController(text: 'ws://192.168.8.107:7001/ws');
  final _controllerLog = TextEditingController(text: 'log =>');
  late RTCPeerConnection _peerConnectionSub;
  late RTCPeerConnection _peerConnectionPub;
  var count = 1;
  //late MediaStream localStream;
  //late RTCRtpTransceiver transceiverPub;
  //final List<RTCVideoRenderer> _remoteRenderers = [];
  //late MediaStreamTrack _remoteTrack;

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
             // onTap: (){_controllerLog.clear();},
            )),
            Form( child: TextFormField(
              controller: _controllerUserId,
              decoration: const InputDecoration(labelText: 'user id'),
            ),),
            Form( child: TextFormField(
              controller: _controllerWS,
              decoration: const InputDecoration(labelText: 'WS address'),
            ),),

            ElevatedButton(
              onPressed:  _clickConnect,
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: (){
                _log('click pttBegin');
                channel.sink.add(const JsonEncoder().convert({
                  'event':'pttBegin',
                }));
              },
              child: const Text('pttBegin'),

            ),
            ElevatedButton(
              onPressed: () {
                _log('click pttEnd');
                pttEndHandle();
              },
              child: const Text('pttEnd'),

            ),
            ElevatedButton(
              onPressed: _clickClose,
              child: const Text('close'),
              style: const ButtonStyle(alignment: Alignment.center),
            ),
            TextField(
              controller: _controllerLog,
              readOnly: true,
              maxLines: 10,

            ),
          ],

        ),
      )
    );
  }
  @override
  void initState()  {
    super.initState();
    setState(() {
      //_controllerUserId.text = 'iop';

    });
  }
  void _log(String msg){
    _controllerLog.text ='${count++}. '+ msg +'\n' + _controllerLog.text;
    debugPrint(msg);
  }
  void _clickClose() async{
    _log('click Close()');
    channel.sink.close();

    // List<RTCRtpReceiver> receivers = await _peerConnection.getReceivers();
    // for (var element in receivers) {
    //   element.track?.stop();
    // }

    // List<MediaStream?> streams =  _peerConnection.getRemoteStreams();
    // for (var element in streams) {
    //   element?.removeTrack(_remoteTrack);
    // }

    _peerConnectionSub.close();
    _peerConnectionPub.close();
   // _peerConnection.dispose();
    //_remoteRenderers.map((element) {element.dispose() ;});
  }
  void _clickConnect() async{
    _controllerLog.clear();
    count = 0;
    _log('click Connect');
    channel = IOWebSocketChannel.connect(_controllerWS.text);
    //channel = IOWebSocketChannel.connect('ws://124.207.164.210:8431/ws');
    channel.stream.listen((message)  {  _parseMsg(message.toString());},
      onError: (e){log('err:'+e.toString());},
      onDone: (){log('webSocket done');},
      //cancelOnError: false,
    );
    await _readySub();
    await _readyPub();
    //send join
    channel.sink.add(const JsonEncoder().convert({
      'event':'join',
      'data': const JsonEncoder().convert({
        'sid':_controllerSessionId.text,
        'uid':_controllerUserId.text
      })
    }));
  }
  Future<void> _readySub() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': "turn:124.207.164.210:8442",
          'username':"pion",
          'credential':"ion",
          'credentialType':"password",
        }
      ]
      // 'iceServers': [
      //   {'url': 'stun:stun.l.google.com:19302'},
      // ],
      // 'sdpSemantics': sdpSemantics
    };
    _peerConnectionSub = await createPeerConnection(configuration,{});
    _peerConnectionSub.onRenegotiationNeeded = (){
      debugPrint('sub.onRenegotiationNeeded');
    };
    _peerConnectionSub.onIceCandidate = (candidate){
      debugPrint("sub. My Candidate -->");

      var data = const JsonEncoder().convert({
        'event':'candidate',
        'target':'sub',
        'data':const JsonEncoder().convert({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        })
      });
      debugPrint('sub. '+data);
      channel.sink.add(data);
    };
    _peerConnectionSub.onTrack = (event) async{
      debugPrint("sub.onTrack");
      if(event.track.kind=='audio' && event.streams.isNotEmpty){
       // _remoteTrack = event.track;
        //var render = RTCVideoRenderer();
        //await render.initialize();
      // render.srcObject = event.streams[0];
      // _remoteRenderers.add(render);
        // setState(() {
        //
        // });
      }
    };
    _peerConnectionSub.onAddTrack = (stream,track){
      debugPrint('sub.onAddTrack');
      track.setVolume(0.0);

    };
    _peerConnectionSub.onAddStream = (stream){
      _log('sub.onAddStream');
    };
    _peerConnectionSub.onTrack = (track){
      _log('sub.onTrack');
    };
    _peerConnectionSub.onRemoveTrack = (stream,track){
      _log('sub.onRemoveTrack');
    };
    _peerConnectionSub.onRemoveStream = (stream){
      _log('sub.onRemoveStream');
    };
    _peerConnectionSub.onConnectionState = (state){
      _log('sub.'+state.toString());
    };
  }
  Future<void> _readyPub() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': "turn:124.207.164.210:8442",
          'username':"pion",
          'credential':"ion",
          'credentialType':"password",
        }
      ],
      // 'iceServers': [
      //   {'url': 'stun:stun.l.google.com:19302'},
      // ],
      'sdpSemantics': 'unified-plan'
    };
    _peerConnectionPub = await createPeerConnection(configuration,{});
    _peerConnectionPub.onRenegotiationNeeded = () {
      debugPrint('pub.onRenegotiationNeeded');
      _negotiationPub();
    };
    _peerConnectionPub.onIceCandidate = (candidate){
      debugPrint("pub. My Candidate -->");

      var data = const JsonEncoder().convert({
        'event':'candidate',
        'target':'pub',
        'data':const JsonEncoder().convert({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        })
      });
      debugPrint("pub. "+data);
      channel.sink.add(data);
    };
    // _peerConnectionPub.onTrack = (event) async{
    //   debugPrint("onTrack");
    //   if(event.track.kind=='audio' && event.streams.isNotEmpty){
    //     // _remoteTrack = event.track;
    //     //var render = RTCVideoRenderer();
    //     //await render.initialize();
    //     // render.srcObject = event.streams[0];
    //     // _remoteRenderers.add(render);
    //     // setState(() {
    //     //
    //     // });
    //   }
    // };
    _peerConnectionPub.onAddTrack = (stream,track){
      _log('pub.onAddTrack');
      //track.setVolume(0.0);

    };
    _peerConnectionPub.onAddStream = (stream){
      _log('pub.onAddStream');
    };
    _peerConnectionPub.onTrack = (track){
      _log('pub.onTrack');
    };
    _peerConnectionPub.onRemoveTrack = (stream,track){
      _log('pub.onRemoveTrack');
    };
    _peerConnectionPub.onRemoveStream = (stream){
      _log('pub.onRemoveStream');
    };
    _peerConnectionPub.onConnectionState = (state){
      _log('pub.'+state.toString());
    };
    var localStream = await navigator.mediaDevices.getUserMedia({
      'audio':true,
      'video':false
    });

    // try{
    //   debugPrint('pub. addTransceiver');
    //   // await _peerConnectionPub.addTransceiver(
    //   //  // track: localStream.getAudioTracks()[0],
    //   //   kind:RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //   //   init: RTCRtpTransceiverInit(
    //   //     direction: TransceiverDirection.SendOnly,
    //   //    // streams: [localStream]
    //   //   )
    //   // );
    //
    // }catch(e){
    //   debugPrint(e.toString());
    // }

    // var transceiverPub = await _peerConnectionPub.addTransceiver(
    //     kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //     init: RTCRtpTransceiverInit(direction:TransceiverDirection.SendOnly )
    // );

  }
  void _parseMsg(String raw) async{

    Map<String, dynamic> msg = jsonDecode(raw);

    switch(msg['event']){
      case 'offer':
        _log('sub. receive offer');

        Map<String,dynamic> offer = jsonDecode(msg['data']);
        await _peerConnectionSub.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
        RTCSessionDescription answer = await _peerConnectionSub.createAnswer({});
        await _peerConnectionSub.setLocalDescription(answer);
        //send answer
        channel.sink.add(const JsonEncoder().convert({
          'event':'answer',
          'target':'sub',
          'data': const JsonEncoder().convert(answer.toMap())
        }));
        break;
      case 'answer':
        _log('pub. receive answer');
        Map<String,dynamic> answer = jsonDecode(msg['data']);
        await _peerConnectionPub.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));

        break;
      case 'candidate':
        debugPrint("receive candidate --> ${msg['target']}");
        Map<String,dynamic> parsed = jsonDecode(msg['data']);
        log(parsed.toString());
        if(msg['target'] == 'sub'){
          try{
            //RTCSessionDescription? remoteDSP = await _peerConnectionSub.getRemoteDescription();
            // if( remoteDSP == null){
            //   debugPrint('getRemoteDescription is null');
            //   return;
            // }
           // debugPrint(parsed['candidate']);
            //参数是string类型的不要写null
            debugPrint('sub addCandidate');
            _peerConnectionSub.addCandidate(RTCIceCandidate(parsed['candidate'], '', 0));
          }on Exception catch(e){
            debugPrint('sub.addCandidate '+e.toString());
          }
        }else if(msg['target'] == 'pub'){
          try{
            //debugPrint(parsed['candidate']);
            //参数是string类型的不要写null
            debugPrint('pub addCandidate');
            _peerConnectionPub.addCandidate(RTCIceCandidate(parsed['candidate'], '', 0));
          }on Exception catch(e){
            debugPrint('pub.addCandidate '+ e.toString());
          }
        }
        break;
      case 'join':
        break;
      case 'pttBegin':
        if(msg['data'] == "ok"){
          _log('pttBegin is ok');
        }else{
          _log('pttBegin is fail');
          return;
        }
        pttBeginHandle();

        break;
      case 'pttEnd':
        if(msg['data'] == "ok"){
          _log('pttEnd is ok');
        }else{
          _log('pttEnd is fail');
        }
        break;
      case 'err':
        _log('err: '+msg['data']);
        break;
      default:
        _log('unknown event');
        break;
    }
  }
  void pttBeginHandle() async{

    var senders = await _peerConnectionPub.getSenders();
    debugPrint('before pub. senders len  = '+senders.length.toString());

    var localStream = await navigator.mediaDevices.getUserMedia({
      'audio':true,
      'video':false
    });
    var tracks = localStream.getAudioTracks();
    debugPrint('audio tracks len = '+tracks.length.toString());

    if(senders.isNotEmpty){
      //senders[0].track!.setMicrophoneMute(false);
      // senders[0].track!.enabled = true;

       var trans = await _peerConnectionPub.getTransceivers();
       await trans[0].setDirection(TransceiverDirection.SendRecv);
       await senders[0].replaceTrack(tracks[0]);
    }else{
      try{
        _log('pub.addTrack');
        var sender = await _peerConnectionPub.addTrack(tracks[0],localStream);
      } catch(e){
        debugPrint('Pub.addTrack err'+e.toString());
      }
    }


    senders = await _peerConnectionPub.getSenders();
    debugPrint('after pub. senders len = '+senders.length.toString());
  }
  void pttEndHandle() async{
    // var senders = await _peerConnectionPub.getSenders();
    // for (var element in senders) {
    //   if(element.track!=null){
    //     _peerConnectionPub.removeTrack(element);
    //     //element.track!.enableSpeakerphone(false);
    //     //element.track!.setMicrophoneMute(true);
    //     //element.track!.enabled = false;
    //
    //   }
    // }
    var trans = await _peerConnectionPub.getTransceivers();
    var direction = await trans[0].getCurrentDirection();
    debugPrint('===== CurrentDirection = $direction');
    await trans[0].setDirection(TransceiverDirection.RecvOnly);
    channel.sink.add(const JsonEncoder().convert({
      'event':'pttEnd',
    }));
  }
  void _negotiationPub() async{
    RTCSessionDescription offer = await _peerConnectionPub.createOffer({
      //'voiceActivityDetection':true,
      //'iceRestart':true
    });
    await _peerConnectionPub.setLocalDescription(offer);

    var dataOffer = const JsonEncoder().convert({
      'event':'offer',
      'target':'pub',
      'data': const JsonEncoder().convert(offer.toMap())
    });
    _log('pub send offer len = ${dataOffer.length}');
    //debugPrint('pub send offer => $dataOffer');
    channel.sink.add(dataOffer);
  }
  @override
  void dispose(){
    log('dispose');
    super.dispose();
    _controllerSessionId.dispose();
    _controllerUserId.dispose();
    _controllerWS.dispose();
    _controllerLog.dispose();
    _clickClose();
   // channel.sink.close();
  }
}
