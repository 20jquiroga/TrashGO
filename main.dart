import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Prueba")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Super aplicacion de recorrido de camiones de basura"),
              Text("Enzo mamalo de lado"),
              ElevatedButton(onPressed: () {}, child: Text("Presioname")),
            ],
          ),
        ),

        ##barra inferior con tres botones que ocupen todo el ancho de la pantalla y sin bordes redondeados

        bottomNavigationBar: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text("Uno"),
              ),
            ),

            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text("Dos"),
              ),
            ),

            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20),
                ),
                child: Text("Tres"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
