import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchDetailsScreen.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class AvailableMatchesScreen extends StatefulWidget {
  @override
  _AvailableMatchesScreenState createState() => _AvailableMatchesScreenState();
}

class _AvailableMatchesScreenState extends State<AvailableMatchesScreen> {
  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];
  List<MathPartido> matches = []; // Lista de partidos
  bool isLoading = true;
  final storage = StorageService();

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadMatches();
  }

  void _initializeDates() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    next7Days.clear();
    for (int i = 0; i < 7; i++) {
      next7Days.add(startOfDay.add(Duration(days: i)));
      print('Generated date: ${next7Days[i]}'); // Depuración
    }
  }

  Future<void> _loadMatches() async {
    setState(() => isLoading = true);
    try {
      final token = await storage.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/daily-matches'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      print('Response status loadmatch: ${response.statusCode}');
      print('Response body loadmatches: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> matchesData = data['matches'];
        print('Received matches: $matchesData');
        matches =
            matchesData.map((json) => MathPartido.fromJson(json)).toList();
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading matches: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<MathPartido> _getMatchesForDate(DateTime date) {
    print(
        'Filtering matches for date: $date'); // Depuración: Imprime la fecha seleccionada
    print(
        'Total matches available: ${matches.length}'); // Depuración: Imprime el total de partidos

    return matches.where((match) {
      // Comparar solo el año, mes y día
      bool isSameDay = match.scheduleDate.year == date.year &&
          match.scheduleDate.month == date.month &&
          match.scheduleDate.day == date.day;

      // Depuración: Imprimir las fechas que se están comparando
      print(
          'Match date: ${match.scheduleDate}, Selected date: $date, Is same day: $isSameDay');

      return isSameDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final matchesForSelectedDate = _getMatchesForDate(selectedDate);

    print('Selected date: $selectedDate');
    print('Matches found: ${matchesForSelectedDate.length}');

    return Column(
      children: [
        // Calendario horizontal
        Container(
          height: 100, // Altura fija para el calendario
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: next7Days.length,
            itemBuilder: (context, index) {
              final date = next7Days[index];
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final matchesCount = _getMatchesForDate(date).length;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date; // Actualizar la fecha seleccionada
                  });
                },
                child: Container(
                  width: 70,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (matchesCount > 0)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$matchesCount',
                            style: TextStyle(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Lista de partidos
        isLoading
            ? Center(child: CircularProgressIndicator())
            : matchesForSelectedDate.isEmpty
                ? Center(
                    child: Container(
                        margin: EdgeInsets.only(top: 40),
                        child: Text(
                          'No hay partidos disponibles para esta fecha',
                          style: TextStyle(color: Colors.black),
                        )),
                  )
                : ListView.builder(
                    shrinkWrap: true, // Evita conflictos con CustomScrollView
                    physics:
                        NeverScrollableScrollPhysics(), // Desactiva el desplazamiento interno

                    padding: EdgeInsets.all(16),
                    itemCount: matchesForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final match = matchesForSelectedDate[index];
                      return InkWell(
                        onTap: () {
                          // Navegar a MatchDetailsScreen cuando se hace clic en el partido
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MatchDetailsScreen(match: match),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Icon(Icons.sports_soccer,
                                  color: Colors.white),
                            ),
                            title: Text(
                              match.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.black),
                                    SizedBox(width: 4),
                                    Text(
                                        style: TextStyle(color: Colors.green),
                                        '${match.formattedStartTime} - ${match.formattedEndTime}'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people,
                                        size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      '${match.playerCount}/${match.maxPlayers} jugadores',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${match.price}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: match.status == 'open'
                                        ? Colors.green
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    match.status == 'open'
                                        ? 'Disponible'
                                        : 'Completo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
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
      ],
    );
  }
}
