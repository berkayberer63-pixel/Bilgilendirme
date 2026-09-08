import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'anasayfa.dart';

void main() => runApp(const FabrikaApp());

class FabrikaApp extends StatelessWidget {
  const FabrikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personel Takip',
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final kullanici = TextEditingController();
  final sifre = TextEditingController();

  bool loading = false;
  bool hatirla = true;
  bool sifreGoster = false;

  Future<void> girisYap() async {
    if (kullanici.text.isEmpty || sifre.text.isEmpty) {
      mesaj('Kullanıcı adı ve şifre gerekli');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse(
          'https://bilgilendirme20260908151059-gsbccpb0gbeng8gj.westus3-01.azurewebsites.net/login',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': kullanici.text.trim(),
          'password': sifre.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];

        if (hatirla) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(token: token),
          ),
        );
      } else {
        mesaj('Kullanıcı adı veya şifre yanlış');
      }
    } catch (e) {
      mesaj('Sunucuya bağlanılamadı');
    }

    if (mounted) setState(() => loading = false);
  }

  void mesaj(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: SizedBox(
            width: 380,
            child: Column(
              children: [
                Icon(
                  Icons.factory_rounded,
                  size: 70,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Personel Takip',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Personel hesabınızla giriş yapın',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: kullanici,
                  decoration: InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: sifre,
                  obscureText: !sifreGoster,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        sifreGoster
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => sifreGoster = !sifreGoster);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                Row(
                  children: [
                    Checkbox(
                      value: hatirla,
                      onChanged: (value) {
                        setState(() => hatirla = value ?? true);
                      },
                    ),
                    const Text('Beni hatırla'),
                  ],
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading ? null : girisYap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'GİRİŞ YAP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}