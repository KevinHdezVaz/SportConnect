import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/booking.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  PageController _pageController = PageController();
  String activeTab = 'active';
  final BookingService bookingService = BookingService();
  List<Booking> activeReservations = [];
  List<Booking> reservationHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    try {
      setState(() => isLoading = true);
      final active = await bookingService.getActiveReservations();
      final history = await bookingService.getReservationHistory();

      print('Reservas activas recibidas: $active');
      print('Historial de reservas recibido: $history');

      setState(() {
        activeReservations = active;
        reservationHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar las reservas: $e');
    }
  }

  Future<void> _handleCancelReservation(int id) async {
    try {
      final result = await bookingService.cancelReservation(id.toString());
      if (result) {
        await _loadReservations();
        _showSuccessSnackBar('Reserva cancelada exitosamente');
      } else {
        _showErrorSnackBar('No se pudo cancelar la reserva');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cancelar la reserva');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Tabs replaced with a swipeable page view
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton('active', 'Reservas Activas'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTabButton('history', 'Historial'),
                ),
              ],
            ),
          ),

          // PageView to swipe between active and history reservations
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          activeTab = index == 0 ? 'active' : 'history';
                        });
                      },
                      children: [
                        _buildReservationList(activeReservations, true),
                        _buildReservationList(reservationHistory, false),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabType, String text) {
    return ElevatedButton(
      onPressed: () {
        setState(() => activeTab = tabType);
        _pageController.animateToPage(
          tabType == 'active' ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: activeTab == tabType ? Colors.blue : Colors.white,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: activeTab == tabType ? Colors.white : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildReservationList(List<Booking> reservations, bool isActive) {
    if (reservations.isEmpty) {
      return Center(
        child: Text(isActive
            ? 'No tienes reservas activas'
            : 'No tienes reservas en el historial'),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReservationHeader(reservation, isActive),
                const SizedBox(height: 8),
                _buildReservationDetails(reservation),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReservationHeader(Booking reservation, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Cancha ${reservation.fieldId}', // Ajusta según tus necesidades
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isActive)
          IconButton(
            icon: const Icon(Icons.cancel),
            color: Colors.red,
            onPressed: () => _handleCancelReservation(reservation.id),
          ),
      ],
    );
  }

  Widget _buildReservationDetails(Booking reservation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.calendar_today, Colors.blue,
            _formatDateTime(reservation.startTime)),
        const SizedBox(height: 4),
        _buildInfoRow(Icons.access_time, Colors.green,
            '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}'),
        const SizedBox(height: 4),
        _buildInfoRow(Icons.attach_money, Colors.purple,
            'Precio: ${reservation.totalPrice.toStringAsFixed(2)}'),
        const SizedBox(height: 4),
        _buildInfoRow(
            Icons.info, Colors.orange, 'Estado: ${reservation.status}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
}
