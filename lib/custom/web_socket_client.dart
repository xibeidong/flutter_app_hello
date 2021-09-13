
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
  late RTCPeerConnection _peerConnectionSub;
  late RTCPeerConnection _peerConnectionPub;
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
                channel.sink.add(const JsonEncoder().convert({
                  'event':'pttBegin',
                }));
              },
              child: const Text('pttBegin'),

            ),
            ElevatedButton(
              onPressed: () {
                log('click pttEnd');
                pttEndHandle();
              },
              child: const Text('pttEnd'),

            ),
            ElevatedButton(
              onPressed: _clickClose,
              child: const Text('close'),
              style: const ButtonStyle(alignment: Alignment.center),
            ),

          ],

        ),
      )
    );
  }
  void _clickClose() async{
    debugPrint('click Close()');
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
    debugPrint('click Connect');
    channel = IOWebSocketChannel.connect('ws://192.168.10.235:7001/ws');
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
        'sid':'1',
        'uid':'321'
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
      debugPrint('sub.onAddStream');
    };
    _peerConnectionSub.onTrack = (track){
      debugPrint('sub.onTrack');
    };
    _peerConnectionSub.onRemoveTrack = (stream,track){
      debugPrint('sub.onRemoveTrack');
    };
    _peerConnectionSub.onRemoveStream = (stream){
      debugPrint('sub.onRemoveStream');
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
      debugPrint('pub.onAddTrack');
      //track.setVolume(0.0);

    };
    _peerConnectionPub.onAddStream = (stream){
      debugPrint('pub.onAddStream');
    };
    _peerConnectionPub.onTrack = (track){
      debugPrint('pub.onTrack');
    };
    _peerConnectionPub.onRemoveTrack = (stream,track){
      debugPrint('pub.onRemoveTrack');
    };
    _peerConnectionPub.onRemoveStream = (stream){
      debugPrint('pub.onRemoveStream');
    };

    var localStream = await navigator.mediaDevices.getUserMedia({
      'audio':true,
      'video':false
    });

    try{
      debugPrint('pub. addTransceiver');
      // await _peerConnectionPub.addTransceiver(
      //  // track: localStream.getAudioTracks()[0],
      //   kind:RTCRtpMediaType.RTCRtpMediaTypeAudio,
      //   init: RTCRtpTransceiverInit(
      //     direction: TransceiverDirection.SendOnly,
      //    // streams: [localStream]
      //   )
      // );

    }catch(e){
      debugPrint(e.toString());
    }

    // var transceiverPub = await _peerConnectionPub.addTransceiver(
    //     kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //     init: RTCRtpTransceiverInit(direction:TransceiverDirection.SendOnly )
    // );

  }
  void _parseMsg(String raw) async{

    Map<String, dynamic> msg = jsonDecode(raw);

    switch(msg['event']){
      case 'offer':
        debugPrint('sub. receive offer');

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
        debugPrint('pub. receive answer');
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
          debugPrint('pttBegin is ok');
        }else{
          debugPrint('pttBegin is fail');
          return;
        }
        pttBeginHandle();

        break;
      case 'pttEnd':
        if(msg['data'] == "ok"){
          debugPrint('pttEnd is ok');
        }else{
          debugPrint('pttEnd is fail');
        }
        break;
      case 'err':
        debugPrint(msg['data']);
        break;
      default:
        debugPrint('unknown event');
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
        debugPrint('pub.addTrack');
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
    debugPrint('pub send offer len = ${dataOffer.length}');
    //debugPrint('pub send offer => $dataOffer');
    channel.sink.add(dataOffer);
  }
  @override
  void dispose(){
    log('dispose');
    super.dispose();
    _controllerSessionId.dispose();
    _controllerUserId.dispose();
    _clickClose();
   // channel.sink.close();
  }
}
