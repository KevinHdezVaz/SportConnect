import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:card_swiper/card_swiper.dart';

class IntroScreen extends StatelessWidget {
  IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Swiper(
                itemBuilder: (context, index) => Image.asset(
                  'assets/images/intro_img1.png',
                  fit: BoxFit.contain,
                ),
                itemCount: 1,
                pagination: const SwiperPagination(),
                autoplay: true,
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Welcome !",
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthCheckMain()),
                    ),
                    child: Container(
                      height: 60,
                      width: size.width * 0.8,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage("assets/icons/ic_button.png"),
                          fit: BoxFit.fill,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Comenzar ",
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          Image.asset(
                            "assets/icons/ic_intro_hand.png",
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}