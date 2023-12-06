import 'package:flutter/material.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/custom_text_field.dart';

import '../utils/socket_client.dart';
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController= TextEditingController();
  final SocketClient _socketClient=SocketClient.instance;
  final SocketMethods _socketMethods=SocketMethods();
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _nameController.dispose();
  }
  @override
  void initState() {
    _socketMethods.updateGameListener(context);
    _socketMethods.notCorrectGameListener(context);
    super.initState();
  }
  // test(){
  //   _socketClient.socket!.emit('test',"This is working");
  // }
  @override
  Widget build(BuildContext context) {
    final size= MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MyBackButton(),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Create Room",style: TextStyle(fontSize: 30),),
                SizedBox(height: size.height*0.08,),
                CustomTextfield(controller: _nameController, hintText: "Enter your name here"),
                const SizedBox(height: 30,),
                CustomButton(text: "Create", onTap: ()=>_socketMethods.CreateGame(_nameController.text.toString())),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
