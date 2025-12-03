// core/main_container.dart
import 'package:flutter/material.dart';
import '../features/home/screens/home.dart';
import '../features/documents/screens/documents.dart';
import '../features/home/screens/study_tools.dart';
import '../features/profile/screens/personal_space.dart';

class MainContainer extends StatefulWidget {
  final int initialIndex;
  
  const MainContainer({super.key, this.initialIndex = 0});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const HomeScreenContent(),
          const DocumentsScreenContent(),
          const StudyToolsScreenContent(),
          const PersonalSpaceScreenContent(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Study Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Personal Space',
          ),
        ],
      ),
    );
  }
}