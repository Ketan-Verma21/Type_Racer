import 'package:flutter/cupertino.dart';
import 'package:type_racer/models/client_state.dart';

class ClientStateProvider extends ChangeNotifier{
  ClientState _clientState =ClientState(
      timer: {'countDown':'','msg':''},);
  setClientState(timer){
    _clientState=ClientState(timer: timer);
    notifyListeners();
  }
  Map<String,dynamic> get clientState=>_clientState.toJson();
}