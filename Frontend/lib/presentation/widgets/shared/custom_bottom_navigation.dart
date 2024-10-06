import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  const CustomBottomNavigation({super.key, required this.currentIndex});

  void onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home/0');
        break;
      case 1:
        context.go('/home/1');
        break;
      case 2:
        context.go('/home/2');
        break;
      case 3:
        context.go('/home/3');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (value) => onItemTapped(context, value),
      elevation: 8,
      selectedItemColor:
          AppColor.green, // Color de iconos y etiquetas seleccionados
      unselectedItemColor:
          Colors.grey, // Color de iconos y etiquetas no seleccionados
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.file_upload),
            activeIcon: CircleAvatar(
              radius: 20,
              backgroundColor: Color.fromARGB(255, 73, 190, 77),
              child: Icon(Icons.file_upload),
            ),
            label: 'Procesar'),
        BottomNavigationBarItem(
          icon: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.transparent,
            child: Image.asset(
              'lib/config/assets/images/snooker_icon.png',
            ),
          ),
          activeIcon: CircleAvatar(
            radius: 20,
            backgroundColor: const Color.fromARGB(255, 73, 190, 77),
            child: Image.asset(
              'lib/config/assets/images/snooker_icon.png',
            ),
          ),
          label: 'Partidos',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            activeIcon: CircleAvatar(
              radius: 20,
              backgroundColor: Color.fromARGB(255, 73, 190, 77),
              child: Icon(Icons.trending_up),
            ),
            label: 'Estadísticas'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: CircleAvatar(
              radius: 20,
              backgroundColor: Color.fromARGB(255, 73, 190, 77),
              child: Icon(Icons.person_outline),
            ),
            label: 'Perfil'),
      ],
    );
  }
}
