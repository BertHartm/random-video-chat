import mx.controls.Alert;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.events.Event;
import flash.events.NetStatusEvent;
import mx.rpc.http.HTTPService;
import mx.rpc.events.ResultEvent;
import mx.rpc.events.FaultEvent;
import mx.core.FlexGlobals;
import mx.utils.URLUtil;

private var nc:NetConnection;
private var sendStream:NetStream;
private var recvStream:NetStream;
private var service:HTTPService;
private var fullUrl:String;
private var baseUrl:String;

private function startup():void {
    const CumulusAddress:String = "rtmfp://INSERT_CIRRUS_SERVER";

    nc = new NetConnection();
    nc.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
    nc.connect(CumulusAddress);

    fullUrl = FlexGlobals.topLevelApplication.url;
    baseUrl = URLUtil.getProtocol(url) + "://" + URLUtil.getServerNameWithPort(url);
}

private function netConnectionHandler(event:NetStatusEvent):void {
    switch (event.info.code) {
    case "NetConnection.Connect.Success":
	// successful connection to rtmfp server
	setupStream();
	peerSearch();
	break;
    case "NetStream.Connect.Success":
	Alert.show("Peer connected.");
	break;
    default:
	Alert.show(event.info.code);
	break;
    }
}

private function setupStream():void {
    sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
    sendStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
    sendStream.publish("media");
    sendStream.attachAudio(Microphone.getMicrophone());
    sendStream.attachCamera(Camera.getCamera());
}

private function peerSearch():void {
    service = new HTTPService;
    service.url = baseUrl + "/chatPartner";
    service.method = "GET";
    service.resultFormat = "text";
    service.addEventListener(ResultEvent.RESULT, partnerResultHandler);
    service.addEventListener(FaultEvent.FAULT, faultHandler);
    var parameters:Object = new Object();
    parameters['farID'] = nc.nearID
    service.send(parameters);
}

private function partnerResultHandler(event:ResultEvent):void {
    var res:String = String(event.result);
    if (res == "") {
	// empty result from server, try again
	peerSearch();
    } else {
	connectToPeer(res);
    }
}

private function connectToPeer(farID:String):void {
    recvStream = new NetStream(nc, farID);
    recvStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
    videoDisplay.mx_internal::videoPlayer.attachNetStream(recvStream);
    videoDisplay.mx_internal::videoPlayer.visible=true;
    recvStream.receiveVideo(true);
    recvStream.receiveAudio(true);
    recvStream.play("media");
}

private function faultHandler(event:FaultEvent):void {
    Alert.show(event.fault.faultString);
}
