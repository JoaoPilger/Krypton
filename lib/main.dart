import 'package:flutter/material.dart';

void main(){
  runApp(MaterialApp(home: Home(), debugShowCheckedModeBanner: false,));
}

class Home extends StatelessWidget{
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inicio"),
      ),
    );
  }
}