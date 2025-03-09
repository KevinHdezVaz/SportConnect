import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/main.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/model/WalletTransaction.dart';
import 'package:user_auth_crudd10/model/field.dart';
import 'package:user_auth_crudd10/model/Wallet.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/payment_service.dart';
import 'package:user_auth_crudd10/services/WalletService.dart';

class BookingDialog extends StatefulWidget {
  final Field field;
  final VoidCallback? onBookingComplete;
  final String? bookingId;

  const BookingDialog({
    super.key,
    required this.field,
    this.onBookingComplete,
    this.bookingId,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  List<String> availableHours = [];
  late BookingService _bookingService;
  late PaymentService _paymentService;
  late WalletService _walletService;
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  int? playersNeeded;
  bool isLoading = false;
  bool isLoadingHours = false;
  Wallet? wallet;
  bool useWallet = false;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService();
    _paymentService = PaymentService();
    _walletService = WalletService();
    initializeDateFormatting('es').then((_) {
      _refreshAvailableHours();
      _loadWallet();
    });
  }

  Future<void> _loadWallet() async {
    try {
      final loadedWallet = await _walletService.getWallet();
      if (mounted) setState(() => wallet = loadedWallet);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error al cargar monedero: $e');
    }
  }

  Future<void> _refreshAvailableHours() async {
    if (!mounted) return;
    setState(() => isLoadingHours = true);

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      debugPrint(
          'Fecha enviada: $formattedDate, Día: ${DateFormat('EEEE', 'en').format(selectedDate)}');
      final hours = await _bookingService.getAvailableHours(
        widget.field.id,
        formattedDate,
      );
      debugPrint('Horarios devueltos: $hours');
      if (mounted) {
        setState(() {
          availableHours = hours;
          if (!hours.contains(selectedTime)) selectedTime = null;
          isLoadingHours = false;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing hours: $e');
      if (mounted) {
        setState(() => isLoadingHours = false);
        Fluttertoast.showToast(
            msg: 'Error al cargar horarios: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
        selectedTime = null;
      });
      await _refreshAvailableHours();
    }
  }

  void _selectTime(String time) {
    setState(() => selectedTime = time);
  }

  Future<void> _createBooking() async {
    debugPrint("Método _createBooking ejecutado");

    DateTime today = DateTime.now();
    DateTime selectedOnlyDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime todayOnlyDate = DateTime(today.year, today.month, today.day);

    if (selectedOnlyDate.isBefore(todayOnlyDate)) {
      Fluttertoast.showToast(
          msg: 'Por favor selecciona una fecha válida',
          backgroundColor: Colors.red);
      return;
    }

    if (selectedTime == null || selectedTime!.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Por favor selecciona un horario', backgroundColor: Colors.red);
      return;
    }

    setState(() => isLoading = true);
    double total = widget.field.price_per_match.toDouble();
    double amountToPay = total;
    String? paymentId;
    String? orderId;

    if (useWallet && wallet != null && wallet!.balance > 0) {
      if (wallet!.balance >= total) {
        amountToPay = 0;
      } else {
        amountToPay -= wallet!.balance;
      }
    }

    if (amountToPay > 0) {
      try {
        final paymentResult = await _paymentService.procesarPago(
          context,
          [
            OrderItem(
                title: widget.field.name, quantity: 1, unitPrice: amountToPay)
          ],
          additionalData: {
            'reference_id': widget.field.id,
            'date': DateFormat('yyyy-MM-dd').format(selectedDate),
            'start_time': selectedTime,
            'players_needed': playersNeeded,
            'customer': {'name': 'Usuario', 'email': 'usuario@ejemplo.com'},
          },
          type: 'booking',
        );

        if (paymentResult['status'] == PaymentStatus.success) {
          paymentId = paymentResult['paymentId'];
          orderId = paymentResult['orderId'];
        } else {
          Fluttertoast.showToast(
              msg: 'Pago fallido: ${paymentResult['status']}',
              backgroundColor: Colors.orange);
          setState(() => isLoading = false);
          return;
        }
      } catch (e) {
        Fluttertoast.showToast(
            msg: 'Error al procesar pago: $e', backgroundColor: Colors.red);
        setState(() => isLoading = false);
        return;
      }
    }

    final bookingResult = await _bookingService.createBooking(
      fieldId: widget.field.id,
      date: DateFormat('yyyy-MM-dd').format(selectedDate),
      startTime: selectedTime!,
      playersNeeded: playersNeeded,
      useWallet: useWallet,
      paymentId: paymentId,
      orderId: orderId,
    );

    if (bookingResult['success']) {
      if (useWallet && wallet != null) {
        double usedFromWallet = total - amountToPay;
        if (usedFromWallet > 0) {
          wallet!.balance -= usedFromWallet;
          wallet!.transactions.add(WalletTransaction(
            type: 'withdrawal',
            amount: usedFromWallet,
            description: 'Pago de reserva',
            date: DateTime.now(),
          ));
        }
      }
      widget.onBookingComplete?.call();
      Navigator.pop(context, true);

      // Usar el mensaje personalizado que ahora devuelve el servicio
      String successMessage =
          bookingResult['message'] ?? 'Reserva procesada exitosamente';
      Fluttertoast.showToast(
          msg: successMessage, backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: bookingResult['message'], backgroundColor: Colors.red);
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _cancelBooking() async {
    if (widget.bookingId == null) return;

    setState(() => isLoading = true);
    try {
      final bookings = await _bookingService.getAllReservations();
      final booking =
          bookings.firstWhere((b) => b.id.toString() == widget.bookingId);
      final startTime = booking.startTime;
      final now = DateTime.now();

      if (startTime.difference(now).inHours < 5) {
        Fluttertoast.showToast(
          msg: 'No puedes cancelar con menos de 5 horas de antelación',
          backgroundColor: Colors.red,
        );
        setState(() => isLoading = false);
        return;
      }

      // Ahora manejamos el Map<String, dynamic> que devuelve
      final result = await _bookingService.cancelReservation(widget.bookingId!);

      if (result['success'] == true) {
        await _loadWallet();

        // Mostrar mensaje principal
        Fluttertoast.showToast(
          msg: result['message'] ??
              'Reserva cancelada. Dinero reembolsado al monedero.',
          backgroundColor: Colors.green,
        );

        // Si hay información sobre el monto reembolsado, mostrarla
        if (result['refunded_amount'] != null) {
          Fluttertoast.showToast(
            msg: 'Monto reembolsado: \$${result['refunded_amount']}',
            backgroundColor: Colors.blue,
            toastLength: Toast.LENGTH_LONG,
          );
        }

        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: result['message'] ?? 'Error al cancelar la reserva',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error al cancelar: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          disabledBackgroundColor: Colors.blue.withOpacity(0.6),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_soccer, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    widget.bookingId == null
                        ? 'Pagar y reservar'
                        : 'Actualizar reserva',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return widget.bookingId != null
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: ElevatedButton(
              onPressed: isLoading ? null : _cancelBooking,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text(
                'Cancelar Reserva',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          )
        : const SizedBox.shrink();
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
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE dd/MM/yyyy', 'es').format(selectedDate),
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(
              onPressed: _selectDate,
              child: const Text(
                'Elegir otra fecha',
                style: TextStyle(
                    color: Colors.black, decoration: TextDecoration.underline),
              ),
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
                const Text(
                  'Horarios Disponibles',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                if (isLoadingHours)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (availableHours.isEmpty && !isLoadingHours)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
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
                    onSelected: (_) => _selectTime(time),
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo en tu Monedero',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const Divider(),
            if (wallet == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo:', style: TextStyle(color: Colors.black)),
                  Text(
                    '\$${wallet!.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Puntos:', style: TextStyle(color: Colors.black)),
                  Text(
                    '${wallet!.points}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              if (wallet!.balance > 0 && widget.bookingId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: useWallet,
                        onChanged: (value) =>
                            setState(() => useWallet = value ?? false),
                      ),
                      Text(
                        'Usar monedero (\$${wallet!.balance.toStringAsFixed(2)})',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
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
            const Text(
              'Resumen de Reserva',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const Divider(),
            _buildSummaryRow('Cancha:', widget.field.name),
            _buildSummaryRow('Fecha:',
                DateFormat('EEEE dd/MM/yyyy', 'es').format(selectedDate)),
            if (selectedTime != null) _buildSummaryRow('Hora:', selectedTime!),
            _buildSummaryRow('Precio:', '\$${widget.field.price_per_match}'),
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
          Text(label, style: const TextStyle(color: Colors.black)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 30),
                  child: Text(
                    widget.bookingId == null
                        ? 'Reservar Cancha'
                        : 'Detalles de Reserva',
                    style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildTimeSlots(),
            const SizedBox(height: 16),
            _buildWalletSection(),
            const SizedBox(height: 16),
            _buildSummary(),
            const SizedBox(height: 24),
            _buildConfirmButton(),
            _buildCancelButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
