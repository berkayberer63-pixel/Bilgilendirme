import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Bordro extends StatefulWidget {
  final String token;
  const Bordro({super.key, required this.token});

  @override
  State<Bordro> createState() => _BordroState();
}

class _BordroState extends State<Bordro> {
  Map<String, dynamic> _veri = {};
  bool _loading = true;
  String _hata = "";

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await http.get(
        Uri.parse('SENİNİN_API_URL/bordro'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (!mounted) return;
      setState(() {
        if (res.statusCode == 200) {
          _veri = jsonDecode(res.body);
        } else {
          _hata = "Bordro bulunamadı veya yetkisiz erişim.";
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = "Bağlantı Hatası: Sunucuya ulaşılamadı.";
        _loading = false;
      });
    }
  }

  String _deger(String a, String b) => (_veri[a] ?? _veri[b])?.toString() ?? "0";

  Widget _kart(Widget child) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: child,
      );

  Widget _ozetSatiri(IconData icon, String baslik, String deger, Color renk) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: renk, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(baslik, style: const TextStyle(color: Colors.black54, fontSize: 15))),
            Text(deger, style: TextStyle(color: renk, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hata.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Maaş Bilgileri')),
        body: Center(child: Text(_hata, style: const TextStyle(color: Colors.red, fontSize: 16))),
      );
    }

    final donem = (_veri['Donem'] ?? _veri['donem'])?.toString() ?? "Belirtilmedi";
    final net = _deger('NetMaas', 'netMaas');
    final izin = _deger('KalanIzin', 'kalanIzin');
    final brut = _deger('BrutMaas', 'brutMaas');
    final mesai = _deger('MesaiEkOdeme', 'mesaiEkOdeme');
    final yemekYol = _deger('YemekYolYardimi', 'yemekYolYardimi');
    final kesinti = _deger('Kesintiler', 'kesintiler');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text('Maaş Bilgileri', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Net Maaş
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x3D3F51B5), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.payments_outlined, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Text("$donem Net Maaş", style: const TextStyle(color: Colors.white70, fontSize: 15)),
                ]),
                const SizedBox(height: 12),
                Text("$net ₺",
                    style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Kalan İzin
          _kart(ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.beach_access, color: Colors.orange),
            ),
            title: const Text("Kalan Yıllık İzin", style: TextStyle(color: Colors.black45, fontSize: 13)),
            subtitle: Text("$izin Gün",
                style: const TextStyle(color: Color(0xFF1A237E), fontSize: 19, fontWeight: FontWeight.bold)),
          )),

          const SizedBox(height: 28),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text("Özet Döküm",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          ),

          _kart(Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(children: [
              _ozetSatiri(Icons.account_balance_wallet_outlined, "Brüt Maaş", "$brut ₺", const Color(0xFF3949AB)),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _ozetSatiri(Icons.access_time, "Mesai / Ek Ödeme", "$mesai ₺", Colors.teal),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _ozetSatiri(Icons.restaurant_outlined, "Yemek ve Yol Yardımı", "$yemekYol ₺", Colors.orange),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              _ozetSatiri(Icons.remove_circle_outline, "Kesintiler", "- $kesinti ₺", Colors.redAccent),
            ]),
          )),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}