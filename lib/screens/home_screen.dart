import 'package:flutter/material.dart';
import 'package:type_racer/widgets/custom_button.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size= MediaQuery.of(context).size;
    return  Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Type Racer"),
      ),
      body: Center(
        child: ConstrainedBox(
          
          constraints: BoxConstraints(
            maxWidth: 600,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  const Text("Create/Join a room to play!",style: TextStyle(fontSize: 24),),
                  SizedBox(
                    height: size.height*0.1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomButton(text: "Create", onTap: ()=>Navigator.pushNamed(context, '/create-room'), ishome: true),
                      CustomButton(text: "Join", onTap: ()=>Navigator.pushNamed(context, '/join-room'),ishome:true),
                    ],
                  )
            ],
          ),
        ),
      ),
    );
  }
}
