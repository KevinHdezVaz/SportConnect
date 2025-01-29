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
    bool isLoading = false;

Future<void> _selectDate() async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 30)),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,  
            onPrimary: Colors.white,  
            onSurface: Colors.black,  
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue, // Color de los botones (Cancelar, Aceptar)
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null && picked != selectedDate) {
    setState(() {
      selectedDate = picked;
      selectedTime = null; // Reinicia la hora si cambia la fecha
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
      const SnackBar(content: Text('Por favor selecciona un horario')),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final success = await _bookingService.createBooking(
      fieldId: widget.field.id,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      startTime: selectedTime!,
      playersNeeded: playersNeeded,
    );

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reserva creada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la reserva')),
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

Widget _buildDatePicker() {
  return ListTile(
    leading: const Icon(Icons.calendar_today),
    title: const Text(
      'Fecha',
      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(selectedDate),
          style: const TextStyle(color: Colors.black),
        ),
        const Text(
          'Toca para cambiar fecha',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    ),
    onTap: _selectDate,
  );
}


  Widget _buildTimeSlots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Horarios Disponibles', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),),
        const SizedBox(height: 10),
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
      ],
    );
  }

 Widget _buildPlayersNeededInput() {
  return TextField(
    style: const TextStyle(
      color: Colors.black,
    ),
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      fillColor: Colors.green,
      labelText: 'Jugadores necesarios (opcional)',
      labelStyle: TextStyle(
        color: Colors.blue, // Cambia aquí el color del label
      ),
      border: OutlineInputBorder(),
    ),
    onChanged: (value) {
      setState(() {
        playersNeeded = int.tryParse(value);
      });
    },
  );
}


  Widget _buildPriceInfo() {
    return Row(
      children: [
        const Icon(Icons.attach_money),
        const SizedBox(width: 8),
        Text(
          'Precio: \$${widget.field.price_per_match}',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

Widget _buildConfirmButton() {
  return ElevatedButton(
    onPressed: isLoading ? null : _createBooking,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      backgroundColor: isLoading ? Colors.grey : Colors.blue,
    ),
    child: isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text(
            'Confirmar Reserva',
            style: TextStyle(fontSize: 16),
          ),
  );
}
  @override
  Widget build(BuildContext context) {
 
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reservar - ${widget.field.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildDatePicker(),
          const SizedBox(height: 20),
          _buildTimeSlots(),
          const SizedBox(height: 30),
          _buildPlayersNeededInput(),
          const SizedBox(height: 30),
          _buildPriceInfo(),
          const SizedBox(height: 40),
          _buildConfirmButton(),
        ],
      ),
    );
  }
}