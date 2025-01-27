import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/field.dart';

class BookingDialog extends StatefulWidget {
  final Field field;

  const BookingDialog({super.key, required this.field});

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _bookingService = BookingService();
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  int? playersNeeded;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null; // Reset time when date changes
      });
    }
  }

  void _selectTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  Future<void> _createBooking() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona un horario')),
      );
      return;
    }

    try {
      final success = await _bookingService.createBooking(
        fieldId: widget.field.id,
        date: DateFormat('yyyy-MM-dd').format(selectedDate),
        startTime: selectedTime!,
        playersNeeded: playersNeeded,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva creada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la reserva')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reservar ${widget.field.name}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Fecha'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
            onTap: _selectDate,
          ),
          SizedBox(height: 10),
          Text('Horarios Disponibles'),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: (widget.field.available_hours ?? []).map((time) {
              bool isSelected = time == selectedTime;
              return FilterChip(
                label: Text(time),
                selected: isSelected,
                onSelected: (_) => _selectTime(time),
                backgroundColor: isSelected ? Colors.blue : null,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jugadores necesarios (opcional)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                playersNeeded = int.tryParse(value);
              });
            },
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.attach_money),
              SizedBox(width: 8),
              Text(
                'Precio: \$${widget.field.price_per_match}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _createBooking,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.blue,
            ),
            child: Text(
              'Confirmar Reserva',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
