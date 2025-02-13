import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';


class BookingDialog extends StatefulWidget {
  final Field field;
  final VoidCallback? onBookingComplete;  // Añade esta línea

  const BookingDialog({
    super.key, 
    required this.field,
    this.onBookingComplete,  // Añade esta línea
  });
  
  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  List<String> availableHours = [];
    final _bookingService = BookingService();
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  int? playersNeeded;
  bool isLoading = false;
  bool isLoadingHours = false;
    final _paymentService = PaymentService();

   

  @override
  void initState() {
    super.initState();
initializeDateFormatting('en').then((_) {
    _refreshAvailableHours();
  });
  }

 Future<void> _refreshAvailableHours() async {
  setState(() {
    isLoadingHours = true;
  });

  try {
    final availableHours = await _bookingService.getAvailableHours(
      widget.field.id,
      DateFormat('yyyy-MM-dd').format(selectedDate),
    );

    setState(() {
      this.availableHours = availableHours;
      if (!availableHours.contains(selectedTime)) {
        selectedTime = null;
      }
    });
 
  } catch (e) {
    debugPrint('Error refreshing hours: $e');
  } finally {
    setState(() {
      isLoadingHours = false;
    });
  }
}
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
                foregroundColor: Colors.blue,
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
        selectedTime = null;
      });
      await _refreshAvailableHours();
    }
  }

  void _selectTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

Future<void> _createBooking() async {
  debugPrint("Método _createBooking ejecutado");
  
  // Validaciones de fecha y hora
  DateTime today = DateTime.now();
  DateTime selectedOnlyDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  DateTime todayOnlyDate = DateTime(today.year, today.month, today.day);

  if (selectedOnlyDate.isBefore(todayOnlyDate)) {
    Fluttertoast.showToast(
      msg: 'Por favor selecciona una fecha válida',
      backgroundColor: Colors.red,
    );
    return;
  }

  if (selectedTime == null || selectedTime!.isEmpty) {
    Fluttertoast.showToast(
      msg: 'Por favor selecciona un horario',
      backgroundColor: Colors.red,
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    // 1. Crear items para MercadoPago
final items = [
  OrderItem(
    title: "Reserva - ${widget.field.name}",
    quantity: 1,
    unitPrice: double.parse(widget.field.price_per_match.toString()), // Convertir a double
  ),
];

    // 2. Procesar el pago con MercadoPago
    await _paymentService.procesarPago(
      context, 
      items,
      additionalData: {
        'field_id': widget.field.id,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'start_time': selectedTime!,
        'players_needed': playersNeeded,
      }
    );

    // 3. La reserva se creará en el webhook cuando el pago sea confirmado
    Fluttertoast.showToast(
      msg: 'Reserva en proceso. Recibirás una confirmación cuando se complete el pago.',
      toastLength: Toast.LENGTH_LONG,
      backgroundColor: Colors.green,
    );

    widget.onBookingComplete?.call();
    Navigator.pop(context);

  } catch (e, stackTrace) {
    debugPrint("Error: ${e.toString()}");
    debugPrint("Stack trace: $stackTrace");
    
    Fluttertoast.showToast(
      msg: 'Error al procesar el pago: ${e.toString()}',
      backgroundColor: Colors.red,
    );
    
    await _refreshAvailableHours();
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  Widget _buildDatePicker() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  DateFormat('EEEE dd/MM/yyyy', 'es').format(selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _selectDate,
              child: Text('Cambiar fecha'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Horarios Disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              if (isLoadingHours)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (availableHours.isEmpty && !isLoadingHours)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No hay horarios disponibles para este día',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableHours.map((time) {
                bool isSelected = time == selectedTime;
                return FilterChip(
                  label: Text(time),
                  selected: isSelected,
                  onSelected: (_) => setState(() => selectedTime = time),
                  backgroundColor: isSelected ? Colors.blue : Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ),
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
          color: Colors.blue,
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

  Widget _buildSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Reserva',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Divider(),
            _buildSummaryRow('Cancha:', widget.field.name),
            _buildSummaryRow('Fecha:', 
              DateFormat('EEEE dd/MM/yyyy', 'es').format(selectedDate)),
            if (selectedTime != null)
              _buildSummaryRow('Hora:', selectedTime!),
            _buildSummaryRow('Precio:', 
              '\$${widget.field.price_per_match}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.black)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }

Widget _buildConfirmButton() {
  final bool isDisabled = isLoading || selectedTime == null;
  
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 30),
    child: ElevatedButton(
      onPressed: isDisabled ? null : _createBooking,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        // Añadir el color de fondo cuando está deshabilitado
        disabledBackgroundColor: Colors.blue.withOpacity(0.6),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer,
                  // Color condicional para el icono
                  color: isDisabled ? Colors.white : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pagar y resevar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    // Color condicional para el texto
                    color: isDisabled ? Colors.white : Colors.white,
                  ),
                ),
              ],
            ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 30),
                  child: Text(
                    'Reservar Cancha',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDatePicker(),
            SizedBox(height: 16),
            _buildTimeSlots(),
            SizedBox(height: 16),
            _buildSummary(),
            SizedBox(height: 24),
            _buildConfirmButton(),
                        SizedBox(height: 24),

          ],
        ),
      ),
    );
  }
}