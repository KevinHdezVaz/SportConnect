import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
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
        initializeDateFormatting('es_ES', null);

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
    print('Token: $token');
    final response = await http.get(
      Uri.parse('$baseUrl/daily-matches'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
    );
    print('Response status: ${response.statusCode}');
    print('Full response body: ${response.body}'); // Imprimir JSON completo
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> matchesData = data['matches'];
      print('Matches data length: ${matchesData.length}');
      matches = matchesData.map((json) {
        try {
          return MathPartido.fromJson(json);
        } catch (e) {
          print('Error parsing match: $e');
          print('Problematic JSON: $json');
          return null;
        }
      }).whereType<MathPartido>().toList();
      print('Parsed matches: ${matches.length}');
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
  print('Filtrando partidos para fecha: ${date.toString()}');
  print('Total de partidos antes del filtro: ${matches.length}');

  final now = DateTime.now();
  final filteredMatches = matches.where((match) {
    // Verificar si es el mismo día
    bool isSameDay = match.scheduleDate.year == date.year &&
        match.scheduleDate.month == date.month &&
        match.scheduleDate.day == date.day;

    print('Partido ${match.name} - Fecha: ${match.scheduleDate} - Es mismo día: $isSameDay');

    if (!isSameDay) return false;

    // Si es el día actual, verificar la hora
    if (DateUtils.isSameDay(date, now)) {
      final matchTime = match.startTime.split(':');
      final matchDateTime = DateTime(
        match.scheduleDate.year,
        match.scheduleDate.month,
        match.scheduleDate.day,
        int.parse(matchTime[0]),
        int.parse(matchTime[1]),
      );

      return matchDateTime.isAfter(now);
    }

    // Si es un día futuro, mostrar todos los partidos
    return true;
  }).toList();

  // Ordenar los partidos: primero los disponibles, luego los completos
  filteredMatches.sort((a, b) {
    if (a.status == 'open' && b.status != 'open') return -1;
    if (a.status != 'open' && b.status == 'open') return 1;
    
    // Si ambos tienen el mismo status, ordenar por hora
    final aTime = a.startTime.split(':');
    final bTime = b.startTime.split(':');
    final aHour = int.parse(aTime[0]);
    final bHour = int.parse(bTime[0]);
    return aHour.compareTo(bHour);
  });

  print('Partidos filtrados para mostrar: ${filteredMatches.length}');
  return filteredMatches;
}


  @override
  Widget build(BuildContext context) {
    final matchesForSelectedDate = _getMatchesForDate(selectedDate);

    print('Selected date: $selectedDate');
    print('Matches found: ${matchesForSelectedDate.length}');

    return Column(
      children: [
         Container(
          height: 100, 
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
                    selectedDate = date;  
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
    DateFormat('EEE', 'es_ES').format(date).toUpperCase(),
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
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  padding: EdgeInsets.all(16),
  itemCount: matchesForSelectedDate.length,
  itemBuilder: (context, index) {
    final match = matchesForSelectedDate[index];
    final isFull = match.status == 'full'; 

    return InkWell(
      onTap: () {
        if (!isFull) {  
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchDetailsScreen(match: match),
            ),
          );
        }
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 16),
        elevation: 4,
        color: isFull ? Colors.grey[300] : Colors.white,  
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isFull
                ? Colors.grey
                : Theme.of(context).primaryColor,  
            child: Icon(Icons.sports_soccer, color: Colors.white),
          ),
          title: Text(
            match.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFull ? Colors.grey[700] : Colors.black,  
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: isFull ? Colors.grey : Colors.black),
                  SizedBox(width: 4),
                  Text(
                    '${match.formattedStartTime} - ${match.formattedEndTime}',
                    style: TextStyle(
                      color: isFull ? Colors.grey : Colors.green,  
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: isFull ? Colors.grey : Colors.black),
                  SizedBox(width: 4),
                  Text(
                    '${match.gameTypeDisplay}',
                    style: TextStyle(
                      color: isFull ? Colors.grey : Colors.black, 
                    ),
                  ),
                ],
              ),
              if (isFull)  
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Partido completo',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                  color: isFull ? Colors.grey : Theme.of(context).primaryColor, // Cambiar el color del precio si está completo
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.grey
                      : (match.status == 'open' ? Colors.green : Colors.grey), // Cambiar el color del estado si está completo
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isFull ? 'Completo' : (match.status == 'open' ? 'Disponible' : 'Completo'), // Cambiar el texto del estado si está completo
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
