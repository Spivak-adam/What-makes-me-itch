import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
//import 'add_entry_page.dart';
//import 'analytics_page.dart'; // can be stub
import '../theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Home default

  final List<Widget> _pages = [
    ProfilePage(),
    HomePage(),
    //AnalyticsPage(), // simple placeholder
    //AddEntryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      /// ✅ MOCKUP-STYLE BOTTOM NAV
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "Analytics",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add),
              label: "Add Entry",
            ),
          ],
        ),
      ),
    );
  }
}
