
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
  //final _controllerWS = TextEditingController(text: 'ws://106.54.215.136:7001/ws');
  final _controllerWS = TextEditingController(text: 'ws://192.168.10.236:7001/ws');
  final _controllerTurn = TextEditingController(text: 'turn:192.168.10.236:1478');

  final _controllerLog = TextEditingController(text: 'log =>');
  //late RTCPeerConnection _peerConnectionSub;
  late RTCPeerConnection _peerConnection;
  var count = 1;
  var _trackNull;

  //var ptt_time = DateTime.now();

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
            Form( child: TextFormField(
              controller: _controllerTurn,
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

    //_peerConnectionSub.close();
    _peerConnection.close();
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
    //await _readySub();
    await _readyPeer();
    //send join
    channel.sink.add(const JsonEncoder().convert({
      'event':'join',
      'data': const JsonEncoder().convert({
        'sid':_controllerSessionId.text,
        'uid':_controllerUserId.text
      })
    }));
  }
  // Future<void> _readySub() async {
  //   var configuration = <String, dynamic>{
  //     'iceServers': [
  //       {
  //         'urls': _controllerTurn.text,
  //         'username':"pion",
  //         'credential':"ion",
  //         'credentialType':"password",
  //       },
  //     ],
  //     'sdpSemantics':'unified-plan'
  //     // 'iceServers': [
  //     //   {'url': 'stun:stun.l.google.com:19302'},
  //     // ],
  //     // 'sdpSemantics': sdpSemantics
  //   };
  //   _peerConnectionSub = await createPeerConnection(configuration,{});
  //   _peerConnectionSub.onRenegotiationNeeded = (){
  //     debugPrint('sub.onRenegotiationNeeded');
  //   };
  //   //debugPrint("sub. My getConfiguration -->" + _peerConnectionSub.getConfiguration.toString());
  //
  //   _peerConnectionSub.onIceCandidate = (candidate){
  //     debugPrint("sub. My Candidate -->");
  //
  //     var data = const JsonEncoder().convert({
  //       'event':'candidate',
  //       'target':'sub',
  //       'data':const JsonEncoder().convert({
  //         'sdpMLineIndex': candidate.sdpMlineIndex,
  //         'sdpMid': candidate.sdpMid,
  //         'candidate': candidate.candidate,
  //       })
  //     });
  //     debugPrint('sub. '+data);
  //     channel.sink.add(data);
  //   };
  //   _peerConnectionSub.onTrack = (event) async{
  //     debugPrint("sub.onTrack = " + event.track.id.toString());
  //     if(event.track.kind=='audio' && event.streams.isNotEmpty){
  //      // event.track.stop();
  //      // _remoteTrack = event.track;
  //       //var render = RTCVideoRenderer();
  //       //await render.initialize();
  //     // render.srcObject = event.streams[0];
  //     // _remoteRenderers.add(render);
  //       // setState(() {
  //       //
  //       // });
  //     }
  //   };
  //   _peerConnectionSub.onAddTrack = (stream,track){
  //     debugPrint('sub.onAddTrack');
  //     track.setVolume(0.0);
  //
  //   };
  //   _peerConnectionSub.onAddStream = (stream){
  //     _log('sub.onAddStream');
  //   };
  //   _peerConnectionSub.onTrack = (event){
  //     _log('sub.onTrack = '+event.track.id.toString());
  //   };
  //   _peerConnectionSub.onRemoveTrack = (stream,track){
  //     _log('sub.onRemoveTrack');
  //   };
  //   _peerConnectionSub.onRemoveStream = (stream){
  //     _log('sub.onRemoveStream');
  //   };
  //   _peerConnectionSub.onConnectionState = (state){
  //     _log('sub.'+state.toString());
  //   };
  // }
  Future<void> _readyPeer() async {
    var configuration = <String, dynamic>{
      'iceServers': [
        {
          'urls': _controllerTurn.text,
          'username':"pion",
          'credential':"ion",
          'credentialType':"password",
        }
      ],
      // 'iceServers': [
      //   {'url': 'stun:stun.l.google.com:19302'},
      // ],
      //'sdpSemantics': 'unified-plan'
      'sdpSemantics': 'plan-b'
    };


    _peerConnection = await createPeerConnection(configuration,{});

    _peerConnection.onRenegotiationNeeded = () {
      debugPrint('peer.onRenegotiationNeeded');
      _negotiation();
    };
    _peerConnection.onIceCandidate = (candidate){
      debugPrint("peer. My Candidate -->");

      var data = const JsonEncoder().convert({
        'event':'candidate',
        'target':'',
        'data':const JsonEncoder().convert({
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        })
      });
      debugPrint("peer. "+data);
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
    _peerConnection.onAddTrack = (stream,track){
      _log('peer.onAddTrack');
      //track.setVolume(0.0);

    };
    _peerConnection.onAddStream = (stream){
      _log('peer.onAddStream');
    };
    _peerConnection.onTrack = (track){
      _log('peer.onTrack');
    };
    _peerConnection.onRemoveTrack = (stream,track){
      _log('peer.onRemoveTrack');
    };
    _peerConnection.onRemoveStream = (stream){
      _log('peer.onRemoveStream');
    };
    _peerConnection.onConnectionState = (state){
      _log('peer.'+state.toString());
    };

    //  _peerConnection.addTransceiver(
    //     kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //     init: RTCRtpTransceiverInit(direction:TransceiverDirection.SendRecv )
    // );
    //  _peerConnection.addTransceiver(
    //     kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //     init: RTCRtpTransceiverInit(direction:TransceiverDirection.SendRecv )
    // );
    //  _peerConnection.addTransceiver(
    //     kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
    //     init: RTCRtpTransceiverInit(direction:TransceiverDirection.SendRecv )
    // );


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

    //  var localStream = await navigator.mediaDevices.getUserMedia({
    //   'audio':true,
    //   'video':false
    // });
    // //localStream.dispose()
    // var tracks = localStream.getAudioTracks();
    // _trackNull = tracks[0];
    //
    // //localStream.dispose();
    // //(_trackNull as MediaStreamTrack).enabled=false;
    // (_trackNull as MediaStreamTrack).stop();
  }
  void _parseMsg(String raw) async{

    Map<String, dynamic> msg = jsonDecode(raw);

    switch(msg['event']){
      // case 'offer':
      //   _log('sub. receive offer');
      //
      //   Map<String,dynamic> offer = jsonDecode(msg['data']);
      //   await _peerConnectionSub.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
      //   RTCSessionDescription answer = await _peerConnectionSub.createAnswer({});
      //   await _peerConnectionSub.setLocalDescription(answer);
      //   //send answer
      //   channel.sink.add(const JsonEncoder().convert({
      //     'event':'answer',
      //     'target':'sub',
      //     'data': const JsonEncoder().convert(answer.toMap())
      //   }));
      //   break;
      case 'answer':
        _log(' receive answer');
        _log(' receive answer len = ${msg['data'].length}');
        Map<String,dynamic> answer = jsonDecode(msg['data']);
        await _peerConnection.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
        // var trans = await _peerConnection.getTransceivers();
        // for(var i=0;i<trans.length;i++){
        //   var direct = await trans[i].getCurrentDirection();
        //   debugPrint("trans[$i] == $direct");
        // }
        break;
      case 'candidate':
        debugPrint("receive candidate --> ${msg['target']}");
        Map<String,dynamic> parsed = jsonDecode(msg['data']);
        log(parsed.toString());
        try{
          //debugPrint(parsed['candidate']);
          //参数是string类型的不要写null
          debugPrint('pub addCandidate');
          _peerConnection.addCandidate(RTCIceCandidate(parsed['candidate'], '', 0));
        }on Exception catch(e){
          debugPrint('addCandidate '+ e.toString());
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
    //ptt_time = DateTime.now();
     var senders = await _peerConnection.getSenders();
     debugPrint('before  senders len  = '+senders.length.toString());

     var receivers = await _peerConnection.getReceivers();
     debugPrint('before  receivers len  = '+receivers.length.toString());

    var localStream = await navigator.mediaDevices.getUserMedia({
      'audio':true,
      'video':false
    });
    //localStream.dispose()
    var tracks = localStream.getAudioTracks();
    debugPrint('audio tracks len = '+tracks.length.toString());
    await _peerConnection.addTrack(tracks[0],localStream);
    // if(senders.isNotEmpty){
    //   debugPrint('before replaceTrack,  senders len = '+senders.length.toString());
    //  await senders[0].replaceTrack(tracks[0]);
    //
    //   //await _peerConnection.addTrack(tracks[0],localStream);
    //
    // // debugPrint('after  senders len = '+senders.length.toString());
    // }else{

      //sender.replaceTrack(null);
      // receivers = await _peerConnection.getReceivers();
      // debugPrint('after addTrack, receivers len = '+receivers.length.toString());
    // }
  }
  void pttEndHandle() async{

    var streams = _peerConnection.getLocalStreams();
    debugPrint('streams len = '+streams.length.toString());
    var receivers = await _peerConnection.getReceivers();
    debugPrint('after  receivers len = '+receivers.length.toString());

    // if(streams.isNotEmpty){
    //
    //  // await streams[0]!.dispose();
    //   _peerConnection.removeStream((streams[0] as MediaStream));
    //
    // }


    var senders = await _peerConnection.getSenders();

    for (var element in senders) {
      if(element.track!=null){
        await _peerConnection.removeTrack(element);

        //element.track?.enabled = false;
       // element.replaceTrack((_trackNull as MediaStreamTrack));
        //element.track?.enableSpeakerphone(false);

        //element.track!.enableSpeakerphone(false);
        //element.track!.setMicrophoneMute(true);
        //element.track!.enabled = false;
      }
    }

    //var trans = await _peerConnection.getTransceivers();
    //await trans[0].setDirection(TransceiverDirection.RecvOnly);
    //trans[0].stop();
    channel.sink.add(const JsonEncoder().convert({
      'event':'pttEnd',
    }));
  }
  void _negotiation() async{
    RTCSessionDescription offer = await _peerConnection.createOffer({
      //'voiceActivityDetection':true,
      //'iceRestart':true
    });
    await _peerConnection.setLocalDescription(offer);

    var dataOffer = const JsonEncoder().convert({
      'event':'offer',
      'target':'',
      'data': const JsonEncoder().convert(offer.toMap())
    });
    _log(' send offer len = ${dataOffer.length}');
    debugPrint(' send offer len = ${dataOffer.length}');
    channel.sink.add(dataOffer);
  }
  @override
  void dispose(){
    log('dispose');
    super.dispose();
    _controllerSessionId.dispose();
    _controllerUserId.dispose();
    _controllerWS.dispose();
    _controllerTurn.dispose();
    _controllerLog.dispose();
    _clickClose();
   // channel.sink.close();
  }
}
