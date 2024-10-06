import 'package:flutter/material.dart';
import 'package:snooker_flutter/config/theme/app_theme.dart';
import 'package:snooker_flutter/presentation/views/home_views/matches_view.dart';
import 'package:snooker_flutter/presentation/views/home_views/process_view.dart';
import 'package:snooker_flutter/presentation/views/home_views/profile_view.dart';
import 'package:snooker_flutter/presentation/views/home_views/statistics_view.dart';
import 'package:snooker_flutter/presentation/widgets/shared/custom_bottom_navigation.dart';

class HomeScreen extends StatelessWidget {
  static const name = 'home-screen';
  final int pageIndex;

  const HomeScreen({super.key, required this.pageIndex});

  final viewRoutes = const <Widget>[ProcessView(), MatchesView(), StatisticsView(), ProfileView()];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: CustomBottomNavigation(currentIndex: pageIndex),
        backgroundColor: AppColor.grayBackground,
        //preserve scroll state
        body: IndexedStack(
          index: pageIndex,
          children: viewRoutes,
        ));
  }
}
