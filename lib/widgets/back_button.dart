import 'package:flutter/material.dart';
class MyBackButton extends StatelessWidget {
  const MyBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios),
      color: Colors.black,
      onPressed: ()=> Navigator.of(context).pop(),
    );
  }
}
