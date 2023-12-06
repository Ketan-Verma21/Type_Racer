import 'package:flutter/material.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/back_button.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({Key? key}) : super(key: key);

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _nameController= TextEditingController();
  final _gameIdController= TextEditingController();
  final SocketMethods _socketMethods= SocketMethods();
  @override
  void initState() {
    _socketMethods.updateGameListener(context);
    _socketMethods.notCorrectGameListener(context);
    super.initState();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _nameController.dispose();
    _gameIdController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final size= MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MyBackButton(),
      ),
      body:Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Join Room",style: TextStyle(fontSize: 30),),
                SizedBox(height: size.height*0.08,),
                CustomTextfield(controller: _nameController, hintText: "Enter your name here"),
                const SizedBox(height: 15,),
                CustomTextfield(controller: _gameIdController, hintText: "Enter game id here"),
                const SizedBox(height: 30,),
                CustomButton(text: "Join", onTap: ()=>_socketMethods.JoinGame(_gameIdController.text.toString(), _nameController.text.toString())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
