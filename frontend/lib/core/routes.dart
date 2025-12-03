// config/routes.dart
import 'package:flutter/material.dart';
import 'package:docuverse/features/auth/screens/login.dart';
import 'package:docuverse/features/auth/screens/register.dart';
import 'package:docuverse/features/auth/screens/forget_password.dart';
import 'package:docuverse/screens/onboarding.dart';
// import 'package:docuverse/features/home/screens/home.dart';
// import 'package:docuverse/features/documents/screens/documents.dart';
// import 'package:docuverse/features/home/screens/study_tools.dart';
// import 'package:docuverse/features/profile/screens/personal_space.dart';
import 'main_container.dart';
import 'package:docuverse/screens/ai_document_interaction.dart';
import 'package:docuverse/features/collaboration/screens/collaboration_sharing.dart';
import 'package:docuverse/features/collaboration/screens/friends_screen.dart';
import 'package:docuverse/features/collaboration/screens/notifications_screen.dart';
import 'package:docuverse/features/collaboration/screens/chat_screen.dart';
import 'package:docuverse/features/collaboration/screens/chat_list_screen.dart';
import 'package:docuverse/features/profile/screens/edit_profile.dart';
import 'package:docuverse/features/documents/screens/folder_view.dart';
import 'package:docuverse/features/documents/screens/starred_items.dart';
import 'package:docuverse/shared/constants/app_constants.dart';
import 'package:docuverse/shared/models/folder_model.dart';

class AppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: args['chatId'],
            friendName: args['friendName'],
            friendId: args['friendId'],
          ),
        );
      default:
        return null;
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    AppConstants.onboardingRoute: (context) => const OnboardingScreen(),
    AppConstants.loginRoute: (context) => const LoginScreen(),
    AppConstants.registerRoute: (context) => const RegisterScreen(),
    AppConstants.forgetPasswordRoute: (context) => const ForgetPasswordScreen(),
    AppConstants.homeRoute: (context) => const MainContainer(initialIndex: 0),
    AppConstants.documentsRoute: (context) => const MainContainer(initialIndex: 1),
    AppConstants.studyToolsRoute: (context) => const MainContainer(initialIndex: 2),
    AppConstants.personalSpaceRoute: (context) => const MainContainer(initialIndex: 3),
    AppConstants.aiDocumentRoute: (context) => const AIDocumentInteractionScreen(),
    AppConstants.collaborationRoute: (context) => const CollaborationSharingScreen(),
    '/edit-profile': (context) => const EditProfileScreen(),
    '/starred-items': (context) => const StarredItemsScreen(),
    '/friends': (context) => const FriendsScreen(),
    '/notifications': (context) => const NotificationsScreen(),
    '/chat-list': (context) => const ChatListScreen(),
    '/folder-view': (context) => FolderViewScreen(
        folder: FolderModel(
          id: 'default',
          name: 'Folder',
          createdAt: DateTime.now(),
        ),
      ),
  };
}