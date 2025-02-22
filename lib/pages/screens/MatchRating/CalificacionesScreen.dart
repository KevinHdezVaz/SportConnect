import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/pages/screens/MatchRating/MatchRatingScreen.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';

class Calificacionesscreen extends StatefulWidget {
  final VoidCallback onReload; // Callback para recargar los partidos

  const Calificacionesscreen({Key? key, required this.onReload}) : super(key: key);

  @override
  _CalificacionesscreenState createState() => _CalificacionesscreenState();
}

class _CalificacionesscreenState extends State<Calificacionesscreen> {
  final MatchService _matchService = MatchService();
  late Future<List<MathPartido>> matchesToRateFuture;

  @override
  void initState() {
    super.initState();
    matchesToRateFuture = _matchService.getMatchesToRate();
  }

  void _reloadMatches() {
    setState(() {
      matchesToRateFuture = _matchService.getMatchesToRate();
    });
    widget.onReload(); // Llama al callback para notificar al padre
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MathPartido>>(
      future: matchesToRateFuture,
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
        }
        if (snapshot.hasError) {
          debugPrint('Error en FutureBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 8),
                Text('Error al cargar partidos: ${snapshot.error}', style: TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final matches = snapshot.data ?? [];
        debugPrint('Partidos encontrados: ${matches.length}');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Califica tus partidos terminados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            if (matches.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer_outlined, size: 50, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      '¡No tienes partidos pendientes por calificar!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cuando termines un partido, podrás calificarlo aquí.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: matches.length,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Container(
                      width: 280,
                      margin: EdgeInsets.only(right: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    child: Icon(Icons.sports_soccer, color: Colors.blue),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      match.name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Horario: ${match.formattedStartTime} - ${match.formattedEndTime}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                              if (match.field != null)
                                Text(
                                  'Cancha: ${match.field!.name}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => MatchRatingScreen(matchId: match.id)),
                                    );
                                    if (result == true) {
                                      _reloadMatches();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  child: Text(
                                    'Calificar',
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}