import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/TermsAndConditionsScreen.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class MatchInfoTab extends StatefulWidget {
  final Future<Field> fieldFuture;
  final MathPartido match;

  const MatchInfoTab({
    Key? key,
    required this.fieldFuture,
    required this.match,
  }) : super(key: key);

  @override
  _MatchInfoTabState createState() => _MatchInfoTabState();
}

class _MatchInfoTabState extends State<MatchInfoTab> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<Field>(
            future: widget.fieldFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error cargando la cancha'));
              }

              if (!snapshot.hasData) {
                return Center(child: Text('No se encontró la cancha'));
              }

              final field = snapshot.data!;

              return Column(
                children: [
                  // Carrusel de imágenes mejorado
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CarouselSlider(
                            options: CarouselOptions(
                              height: 250,
                              viewportFraction: 1,
                              onPageChanged: (index, _) =>
                                  setState(() => _currentImage = index),
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 3),
                            ),
                            items: (field.images ?? []).map((url) {
                              final fullImageUrl = Uri.parse(baseUrl)
                                  .replace(path: url)
                                  .toString();

                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: CachedNetworkImage(
                                            imageUrl: fullImageUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                _buildShimmer(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: CachedNetworkImage(
                                  imageUrl: fullImageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      _buildShimmer(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              (field.images ?? []).asMap().entries.map((entry) {
                            return Container(
                              width: 10,
                              height: 10,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImage == entry.key
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de información básica de la cancha
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.name,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            text:
                                '${field.municipio ?? "Ubicación no disponible"}',
                          ),
                          SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.sports_soccer,
                            text: 'Partido de ${widget.match.gameTypeDisplay}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de amenidades
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amenidades:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (field.amenities ?? []).map((amenity) {
                              return Chip(
                                label: Text(amenity),
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                labelStyle: TextStyle(color: Colors.blue),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermsAndConditionsScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.description,
                                color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Términos y condiciones',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Tarjeta de reglas importantes
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reglas importantes:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildRuleItem(
                              '⏰ Llega 15 minutos antes de tu horario.'),
                          _buildRuleItem(
                              '👕 Usa vestimenta adecuada (zapatos y ropa deportiva).'),
                          _buildRuleItem(
                              '🚫 Respeta el tiempo de juego y no lo excedas.'),
                          _buildRuleItem(
                              '🧹 Mantén la cancha limpia y recoge tu basura.'),
                          _buildRuleItem(
                              '🤝 Sé respetuoso con los demás jugadores.'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Botón para ver la ubicación en Google Maps
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _openMaps(field.latitude!, field.longitude!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(Icons.map, color: Colors.white),
                      label: Text(
                        'Ver ubicación en Maps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    TextStyle? textStyle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        SizedBox(width: 10),
        Text(
          text,
          style: textStyle ??
              TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir Google Maps';
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }
}
