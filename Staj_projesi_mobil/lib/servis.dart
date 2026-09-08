import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Servis extends StatefulWidget {
  const Servis({super.key});

  @override
  State<Servis> createState() => _ServisState();
}

class _ServisState extends State<Servis> {
  Map<String, Map<String, Map<String, String>>> _servisVerileri = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServisler();
  }

  Future<void> _fetchServisler() async {
    try {
      final response = await http.get(Uri.parse('https://bilgilendirme20260908151059-gsbccpb0gbeng8gj.westus3-01.azurewebsites.net/servisler'));
      
      if (response.statusCode == 200) {
        Map<String, Map<String, Map<String, String>>> tempVeriler = {};
        for (var item in jsonDecode(response.body)) {
          tempVeriler.putIfAbsent(item['ilce'], () => {})[item['bolge']] = {
            'plaka': item['plaka'].toString(),
            'telefon': item['telefon'].toString(),
            'no': item['servisNo'].toString(),
          };
        }
        if (mounted) setState(() { _servisVerileri = tempVeriler; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Servis Takip'), backgroundColor: Colors.green, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ilceler = _servisVerileri.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Servis Takip', style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ilceler.length,
        itemBuilder: (context, index) {
          String ilce = ilceler[index];
          Map<String, Map<String, String>> bolgeler = _servisVerileri[ilce]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 1, // Hafif modern gölge
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                // Açılır menünün varsayılan çizgilerini kaldırıyoruz
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  // Sol taraftaki şık yeşil ikon kutusu
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_city, color: Colors.green, size: 28),
                  ),
                  title: Text(
                    ilce,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  children: bolgeler.keys.map((bolge) {
                    return InkWell(
                      onTap: () => _showServisDetay(context, ilce, bolge, bolgeler[bolge]!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.shade100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus, size: 18, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(bolge, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Tıklanınca Açılan Detay Penceresi
  void _showServisDetay(BuildContext context, String ilce, String bolge, Map<String, String> detaylar) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text('$bolge Servisi', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.pin, 'Servis No', detaylar['no'] ?? ''),
              const Divider(),
              _buildDetailRow(Icons.directions_car, 'Plaka', detaylar['plaka'] ?? ''),
              const Divider(),
              _buildDetailRow(Icons.phone, 'Şoför Tel', detaylar['telefon'] ?? ''),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KAPAT', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(deger, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}