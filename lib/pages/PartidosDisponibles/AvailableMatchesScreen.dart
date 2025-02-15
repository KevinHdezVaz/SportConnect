import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AvailableMatchesScreen extends StatefulWidget {
  @override
  _AvailableMatchesScreenState createState() => _AvailableMatchesScreenState();
}

class _AvailableMatchesScreenState extends State<AvailableMatchesScreen> {
  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];

  @override
  void initState() {
    super.initState();
    // Generar los próximos 7 días
    for (int i = 0; i < 7; i++) {
      next7Days.add(DateTime.now().add(Duration(days: i)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partidos Disponibles'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Calendario horizontal
          Container(
            height: 100,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: next7Days.length,
              itemBuilder: (context, index) {
                final date = next7Days[index];
                final isSelected = DateUtils.isSameDay(date, selectedDate);
                
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
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Lista de partidos
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 5, // Esto vendrá de tu API
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Icon(Icons.sports_soccer, color: Colors.white),
                    ),
                    title: Text(
                      'Cancha Principal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('8:00 PM - 9:00 PM'),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people, size: 16, color: Colors.grey),
                            SizedBox(width: 4),
                            Text('5/7 jugadores'),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$50',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Disponible',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navegar a los detalles del partido
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}