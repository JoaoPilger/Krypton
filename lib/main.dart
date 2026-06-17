import 'package:flutter/material.dart';
import 'views/login_view.dart';

void main() {
  runApp(const MaterialApp(
    home: LoginView(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Início"),
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        centerTitle: true,
      ),
      drawer: Drawer( // Novo widget
        backgroundColor: const Color.fromARGB(255, 216, 216, 224),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              color: const Color.fromARGB(255, 216, 216, 224),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.menu_open,
                    size: 40,
                    color: Color.fromARGB(255, 60, 52, 137),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 60, 52, 137),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Gerar Senha'),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Todos os itens'),
              iconColor: const Color.fromARGB(255, 102, 100, 117),
              textColor: const Color.fromARGB(255, 102, 100, 117),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favoritos'),
              iconColor: const Color.fromARGB(255, 102, 100, 117),
              textColor: const Color.fromARGB(255, 102, 100, 117),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Senhas'),
              iconColor: const Color.fromARGB(255, 102, 100, 117),
              textColor: const Color.fromARGB(255, 102, 100, 117),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          "Krypton",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}