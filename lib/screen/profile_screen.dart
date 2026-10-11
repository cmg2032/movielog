import 'package:flutter/material.dart';

import '../widget/common_app_bar.dart';
import '../widget/profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: const CommonAppBar(title: '내 프로필', centerTitle: false),
      body: const ProfileBody(),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const ProfileHeader(),
          const SizedBox(height: 24),
          const EditProfileButton(),
          const SizedBox(height: 32),
          const ProfileStats(),
          const SizedBox(height: 36),
          const Align(alignment: Alignment.centerLeft, child: FavoriteGenres()),
        ],
      ),
    );
  }
}
