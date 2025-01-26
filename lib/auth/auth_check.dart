import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_page_check.dart';
import 'package:user_auth_crudd10/pages/bottom_nav.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';

class AuthCheckMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return BottomNavBar();
        }
        return AuthPageCheck();
      },
    );
  }
}
