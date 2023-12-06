import 'package:flutter/material.dart';
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool ishome;
  const CustomButton({Key? key,required this.text,required this.onTap,this.ishome=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width =MediaQuery.of(context).size.width;
    return ElevatedButton(
        onPressed: onTap,
        child: Text(
          text,style: TextStyle(fontSize: 16,color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(!ishome? width:width/5, 50,),
          
        )
    );
  }
}
