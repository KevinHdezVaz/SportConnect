import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/screen_two.dart';
import 'package:user_auth_crudd10/onscreen/slanding_clipper.dart';

import 'constants2.dart';

class OnBoardingCuatro extends StatelessWidget {
  final PageController pageController;

  OnBoardingCuatro({required this.pageController});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

    Color fondo = isDarkMode(context) ? Colors.white : Colors.black;

    Size size = MediaQuery.of(context).size;
    final sizeReference = 700.0;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 1.6;

    double getResponsiveText(double size) =>
        size * sizeReference / MediaQuery.of(context).size.longestSide;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Container(
          child: Stack(
            children: [
              Particles(
                awayRadius: 150,
                particles: [], // List of particles
                height: screenHeight,
                width: screenWidth,
                onTapAnimation: true,
                awayAnimationDuration: const Duration(milliseconds: 100),
                awayAnimationCurve: Curves.linear,
                enableHover: true,
                hoverRadius: 90,
                connectDots: false,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Container(
                      width: 300,
                      height: 300,
                      child: Lottie.asset('assets/images/balon.json'),
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: 2,
                    child: ClipPath(
                      clipper: SlandingClipper(),
                      child: Container(
                        height: size.height * 0.4,
                        color: const Color.fromARGB(255, 159, 212, 158),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: size.height * 0.60,
                child: Container(
                  width: size.width,
                  padding: EdgeInsets.all(appPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jugá en proximos torneos",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                           fontSize: 27,
                        ),
                      ),
                      SizedBox(
                        height: size.height * 0.02,
                      ),
                        Container(
  padding: EdgeInsets.symmetric(
                    horizontal: 10, // Reduje padding lateral
                  ),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: <TextSpan>[
                              TextSpan(
                                  style: TextStyle(
                         fontWeight: FontWeight.w900,

                                      fontSize: getResponsiveText(24),
                                       color: Colors.black),
                                                                      text:
                                      "Disfruta de torneos amistosos"),
                              TextSpan(
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontSize: getResponsiveText(24),
                                  ),
                                  text: " o competitivos organizados "),
                              TextSpan(
                                  style: TextStyle(
                                      fontSize: getResponsiveText(24),
                                      color: Colors.black),
                                  text: "por FUTPLAY "),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: appPadding * 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _storeOnboardInfo();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AuthCheckMain(),
                            ),
                          );
                        },
                        child: Text(
                          "OMITIR",
                          style: TextStyle(
                            color: fondo,
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: appPadding),
                      child: FloatingActionButton(
                        onPressed: () {
                           _storeOnboardInfo();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AuthCheckMain(),
                              ),
                            );
                        },
                        backgroundColor: white,
                        child: const Icon(
                          Icons.check,
                          color: black,
                          size: 30,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _storeOnboardInfo() async {
    print("Shared pref called");
    int isViewed = 0;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('onBoard', isViewed);
    print(prefs.getInt('onBoard'));
  }
}
