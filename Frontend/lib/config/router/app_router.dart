import 'package:go_router/go_router.dart';
import 'package:snooker_flutter/presentation/screens/auth/put_register_code.dart';
import 'package:snooker_flutter/presentation/screens/auth/put_reset_pass_code.dart';
import 'package:snooker_flutter/presentation/screens/auth/register.dart';
import 'package:snooker_flutter/presentation/screens/auth/reset_pass.dart';
import 'package:snooker_flutter/presentation/screens/auth/send_email_pass_recovery.dart';
import 'package:snooker_flutter/presentation/screens/home_screen.dart';
import 'package:snooker_flutter/presentation/screens/auth/login.dart';
import 'package:snooker_flutter/presentation/screens/matches/create_match.dart';
import 'package:snooker_flutter/presentation/screens/matches/list_matches.dart';
import 'package:snooker_flutter/presentation/screens/matches/my_matches.dart';
import 'package:snooker_flutter/presentation/screens/matches/my_requests.dart';
import 'package:snooker_flutter/presentation/screens/matches/match_details.dart';
import 'package:snooker_flutter/presentation/screens/plays/play_details.dart';
import 'package:snooker_flutter/presentation/screens/projects/my_projects.dart';
import 'package:snooker_flutter/presentation/screens/projects/project_details.dart';
import 'package:snooker_flutter/presentation/screens/projects/project_statistics.dart';
import 'package:snooker_flutter/presentation/screens/plays/my_plays.dart';
import 'package:snooker_flutter/presentation/screens/statistics/general_statistics.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: LoginScreen.name,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/confirm_email/:email',
      name: RegisterCodeScreen.name,
      builder: (context, state) {
        final email = state.pathParameters['email'];
        if (email == null) {
          throw Exception('Email is missing');
        }
        return RegisterCodeScreen(email: email);
      },
    ),
    GoRoute(
      path: '/password_recovery',
      name: SendEmailResetPassScreen.name,
      builder: (context, state) => const SendEmailResetPassScreen(),
    ),
    GoRoute(
      path: '/confirm_pass_code/:email',
      name: ResetPassCodeScreen.name,
      builder: (context, state) {
        final email = state.pathParameters['email'];
        if (email == null) {
          throw Exception('Email is missing');
        }
        return ResetPassCodeScreen(email: email);
      },
    ),
    GoRoute(
      path: '/reset_pass/:email/:code',
      name: ResetPassScreen.name,
      builder: (context, state) {
        final email = state.pathParameters['email'];
        final code = state.pathParameters['code'];
        if (email == null || code == null) {
          throw Exception('Email is missing');
        }
        return ResetPassScreen(email: email, code: code);
      },
    ),
    GoRoute(
      path: '/home/:page',
      name: HomeScreen.name,
      builder: (context, state) {
        final pageIndex = int.parse(state.pathParameters['page'] ?? '0');
        return HomeScreen(pageIndex: pageIndex);
      },
    ),
    GoRoute(
      path: '/my_plays',
      name: MyPlaysScreen.name,
      builder: (context, state) => const MyPlaysScreen(),
    ),
    GoRoute(
      path: '/my_projects/:to',
      name: MyProjectsScreen.name,
      builder: (context, state) {
        final to = state.pathParameters['to'];
        if (to == null) {
          throw Exception('to is missing');
        }
        return MyProjectsScreen(to: to);
      },
    ),
    GoRoute(
      path: '/my_general_statistics',
      name: GeneralStatisticsScreen.name,
      builder: (context, state) => const GeneralStatisticsScreen(),
    ),
    GoRoute(
      path: '/plays/:playId/details',
      name: PlayDetailsScreen.name,
      builder: (context, state) {
        final id = state.pathParameters['playId'];
        if (id == null) {
          throw Exception('Play ID is missing');
        }
        return PlayDetailsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/projects/:projectId/details',
      name: ProjectDetailsScreen.name,
      builder: (context, state) {
        final id = state.pathParameters['projectId'];
        if (id == null) {
          throw Exception('Project ID is missing');
        }
        return ProjectDetailsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/projects/:projectId/statistics',
      name: ProjectStatisticsScreen.name,
      builder: (context, state) {
        final id = state.pathParameters['projectId'];
        if (id == null) {
          throw Exception('Project ID is missing');
        }
        return ProjectStatisticsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/matches/new',
      name: NewMatchScreen.name,
      builder: (context, state) => const NewMatchScreen(),
    ),
    GoRoute(
      path: '/matches/list',
      name: ListMatchesScreen.name,
      builder: (context, state) => const ListMatchesScreen(),
    ),
    GoRoute(
      path: '/matches/my_matches',
      name: MyMatchesScreen.name,
      builder: (context, state) => const MyMatchesScreen(),
    ),
    GoRoute(
      path: '/matches/:matchId',
      name: MatchDetailsScreen.name,
      builder: (context, state) {
        final id = state.pathParameters['matchId'];
        if (id == null) {
          throw Exception('Match ID is missing');
        }
        return MatchDetailsScreen(id: id);
      },
    ),
    GoRoute(
      path: '/my_requests',
      name: MyRequestScreen.name,
      builder: (context, state) => const MyRequestScreen(),
    ),
  ],
);
