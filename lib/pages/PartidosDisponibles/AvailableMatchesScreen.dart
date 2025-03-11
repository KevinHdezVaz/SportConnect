import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/MatchTeam.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchDetailsScreen.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:http/http.dart' as http;

class AvailableMatchesScreen extends StatefulWidget {
  const AvailableMatchesScreen({Key? key}) : super(key: key);

  @override
  _AvailableMatchesScreenState createState() => _AvailableMatchesScreenState();
}

class _AvailableMatchesScreenState extends State<AvailableMatchesScreen> {
  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];
  List<MathPartido> matches = [];
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
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    next7Days = List.generate(7, (i) => startOfDay.add(Duration(days: i)));
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
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> matchesData = data['matches'];
        matches = matchesData
            .map((json) => MathPartido.fromJson(json))
            .whereType<MathPartido>()
            .toList();
        print(
            'Matches cargados: ${matches.map((m) => "${m.name} - ${m.status} - Jugadores: ${m.playerCount}").toList()}');
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
    final now = DateTime.now();
    return matches.where((match) {
      final isSameDay = DateUtils.isSameDay(match.scheduleDate, date);
      if (!isSameDay) return false;
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
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.status == 'open' &&
            a.playerCount == 0 &&
            (b.status != 'open' || b.playerCount > 0)) return -1;
        if ((a.status != 'open' || a.playerCount > 0) &&
            b.status == 'open' &&
            b.playerCount == 0) return 1;
        return a.startTime.compareTo(b.startTime);
      });
  }

  @override
  Widget build(BuildContext context) {
    final matchesForSelectedDate = _getMatchesForDate(selectedDate);

    return Column(
      children: [
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: next7Days.length,
            itemBuilder: (context, index) {
              final date = next7Days[index];
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final matchesCount = _getMatchesForDate(date).length;

              return GestureDetector(
                onTap: () => setState(() => selectedDate = date),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
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
                      const SizedBox(height: 4),
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
                          padding: const EdgeInsets.all(4),
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
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (matchesForSelectedDate.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text(
                'No hay partidos disponibles para esta fecha',
                style: TextStyle(color: Colors.black),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: matchesForSelectedDate.length,
            itemBuilder: (context, index) {
              final match = matchesForSelectedDate[index];
              // Deshabilitar si no está disponible o tiene jugadores
              final isDisabled =
                  match.status != 'open' || match.playerCount > 0;
              final team1 =
                  match.teams?.isNotEmpty == true ? match.teams![0] : null;
              final team2 = match.teams?.length == 2 ? match.teams![1] : null;

              return InkWell(
                onTap: isDisabled
                    ? null
                    : () async {
                        final shouldReload = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MatchDetailsScreen(match: match),
                          ),
                        );
                        if (shouldReload == true) {
                          _loadMatches();
                        }
                      },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  color: isDisabled ? Colors.grey[300] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              match.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDisabled
                                    ? Colors.grey[700]
                                    : Colors.black,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: match.status == 'open' &&
                                        match.playerCount == 0
                                    ? Colors.green
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                match.status == 'cancelled'
                                    ? 'Cancelado'
                                    : (match.status == 'reserved'
                                        ? 'Reservado'
                                        : (match.status == 'full'
                                            ? 'Completo'
                                            : (match.playerCount > 0
                                                ? 'Con Jugadores'
                                                : 'Disponible'))),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14,
                                color: isDisabled ? Colors.grey : Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              '${match.formattedStartTime} - ${match.formattedEndTime}',
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.green,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people,
                                size: 14,
                                color: isDisabled ? Colors.grey : Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              match.gameTypeDisplay,
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.gps_fixed,
                                size: 14,
                                color: isDisabled ? Colors.grey : Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              match.field?.name ?? 'Cancha no especificada',
                              style: TextStyle(
                                color: isDisabled ? Colors.grey : Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (team1 != null && team2 != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTeamWidget(team1, isDisabled),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              _buildTeamWidget(team2, isDisabled),
                            ],
                          )
                        else
                          const Text(
                            'Aún no hay equipos asignados',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Precio: " '\$${match.price}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDisabled
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              fontSize: 18,
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

  Widget _buildTeamWidget(MatchTeam team, bool isDisabled) {
    final players = team.players ?? [];
    final extraPlayers =
        team.playerCount - (players.length > 3 ? 3 : players.length);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            team.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDisabled ? Colors.grey : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              ...players.take(3).map((player) => CachedNetworkImage(
                    imageUrl: player.user?.profileImage != null
                        ? 'https://proyect.aftconta.mx/storage/${player.user!.profileImage}'
                        : '',
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 16,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                  )),
              if (extraPlayers > 0)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    '+$extraPlayers',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${team.playerCount}/${team.maxPlayers}',
            style: TextStyle(
              color: isDisabled ? Colors.grey : Colors.black,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
