import 'package:flutter/material.dart';

class Yemekhane extends StatelessWidget {
  const Yemekhane({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Toplam 4 hafta
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yemekhane Menüsü'),
          // Üst kısma otomatik tıklanabilir butonlar ekliyor
          bottom: const TabBar(
            labelColor: Color.fromARGB(255, 252, 151, 0),
            unselectedLabelColor: Color.fromARGB(179, 70, 0, 0),
            indicatorColor: Color.fromARGB(255, 255, 153, 0),
            indicatorWeight: 4,
            tabs: [
              Tab(text: '1. Hafta'),
              Tab(text: '2. Hafta'),
              Tab(text: '3. Hafta'),
              Tab(text: '4. Hafta'),
            ],
          ),
        ),
        // Seçilen sekmeye göre ilgili haftanın listesini gösteriyor
        body: TabBarView(
          children: [
            _buildWeekMenu(1),
            _buildWeekMenu(2),
            _buildWeekMenu(3),
            _buildWeekMenu(4),
          ],
        ),
      ),
    );
  }

  // Her bir hafta sayfasını çizen tasarım 
  Widget _buildWeekMenu(int weekNumber) {
    final List<String> days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
    
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: days.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.restaurant_menu, color: Colors.white),
                  ),
                  title: Text(days[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_getMockMenu(weekNumber, index)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Geçici yemek verisi üreten metod
  String _getMockMenu(int week, int dayIndex) {
    List<String> mockMeals = [
      'Mercimek Çorbası, Orman Kebabı, Pirinç Pilavı, Cacık',
      'Ezogelin Çorbası, Tavuk Sote, Makarna, Meyve',
      'Yayla Çorbası, Kuru Fasulye, Bulgur Pilavı, Turşu',
      'Tarhana Çorbası, İzmir Köfte, Püre, Kemalpaşa Tatlısı',
      'Domates Çorbası, Fırın Tavuk, Patates Kızartması, Ayran',
      'Şehriye Çorbası, Etli Nohut, Pirinç Pilavı, Salata'
    ];
    
    int mealIndex = (week + dayIndex) % mockMeals.length;
    return mockMeals[mealIndex];
  }
}