import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:lottie/lottie.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_auth_crudd10/auth/auth_check.dart';
import 'package:user_auth_crudd10/onscreen/screen_two.dart';
import 'package:user_auth_crudd10/onscreen/slanding_clipper.dart';

import 'constants2.dart';

class OnboardingScreenOne extends StatelessWidget {
  final PageController pageController;

  OnboardingScreenOne({required this.pageController});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode(BuildContext context) {
      return Theme.of(context).brightness == Brightness.dark;
    }

    Color fondo = isDarkMode(context) ? Colors.white : Colors.black;

    final sizeReference = 700.0;

    double getResponsiveText(double size) =>
        size * sizeReference / MediaQuery.of(context).size.longestSide;

    // Obtén el tamaño de la pantalla
    Size size = MediaQuery.of(context).size;
    double screenHeight = size.height;
    double screenWidth = size.width;

    final double itemHeight = (size.height - kToolbarHeight - 24) / 2;
    final double itemWidth = size.width / 1.6;

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
                    padding: const EdgeInsets.only(top: 50),
                    child: Container(
                      height: 300,
                      width: 300,
                      child: Lottie.asset('assets/images/jugadordomi.json'),
                    ),
                  ),
                  ClipPath(
                    clipper: SlandingClipper(),
                    child: Container(
                      height: size.height * 0.5,
                      color: Colors.lightBlue[100],
                    ),
                  )
                ],
              ),
              Positioned(
                top: size.height * 0.55, // Ajusté posición vertical
                child: Container(
                  width: size.width,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03, // Reduje padding lateral
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Centrado vertical
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                         "Unite a la comunidad\nfutbolística mas grande del Uruguay", // Salto de línea
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                          fontSize: getResponsiveText(
                              32), // Tamaño responsivo aumentado
                          height: 1.2, // Espaciado entre líneas
                        ),
                      ),
                      SizedBox(
                          height:
                              size.height * 0.03), // Aumenté espacio vertical
                      Container(
  padding: EdgeInsets.symmetric(
                    horizontal: 20, // Reduje padding lateral
                  ),
                        child: RichText(
                          textAlign: TextAlign.start,
                          text: TextSpan(
                            style: TextStyle(color: Colors.black, fontSize: 16),
                            children: <TextSpan>[
                              TextSpan(
                                  style: TextStyle(
                                      fontSize: getResponsiveText(24),
                                      fontFamily: 'Viga-Regular',
                                      color: Colors.black),
                                  text:
                                       "Empeza a jugar partidos "),
                              TextSpan(
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontSize: getResponsiveText(24),
                                  ),
                                  text: "cuando quieras y disfruta "),
                              TextSpan(
                                  style: TextStyle(
                                      fontSize: getResponsiveText(24),
                                      color: Colors.black),
                                  text: "La EXPERIENCIA. "),
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
                          color: Colors.blue),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.white),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: appPadding / 4),
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          border: Border.all(color: black, width: 2),
                          shape: BoxShape.circle,
                          color: Colors.white),
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
                          pageController.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        backgroundColor: white,
                        child: Icon(
                          Icons.navigate_next_rounded,
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
