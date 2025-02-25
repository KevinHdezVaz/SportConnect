import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/booking_service.dart';
import 'package:user_auth_crudd10/model/booking.dart';
import 'package:user_auth_crudd10/pages/screens/bookin/BookingDetailsScreen.dart';

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
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Mis Reservas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
           foregroundColor: Colors.blue[800],
        ),
        body: Column(
          children: [
            // Tabs modernos con indicador animado
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('active', 'Reservas Activas'),
                    ),
                    Expanded(
                      child: _buildTabButton('history', 'Historial'),
                    ),
                  ],
                ),
              ),
            ),

            // Contenido de las reservas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabType, String text) {
    return InkWell(
      onTap: () {
        setState(() => activeTab = tabType);
        _pageController.animateToPage(
          tabType == 'active' ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activeTab == tabType ? Colors.blue[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: activeTab == tabType ? Colors.white : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReservationList(List<Booking> reservations, bool isActive) {
    if (reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'No tienes reservas activas'
                  : 'No hay historial de reservas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return InkWell(
          // Agregar este widget
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(
                  booking: reservation,
                  isActive: isActive,
                ),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReservationHeader(reservation, isActive),
                  const SizedBox(height: 12),
                  _buildReservationDetails(reservation),
                ],
              ),
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
          '${reservation.fieldName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        if (isActive)
          IconButton(
            icon: const Icon(Icons.cancel, size: 24),
            color: Colors.red[800],
            onPressed: () => _handleCancelReservation(reservation.id),
          ),
      ],
    );
  }

  Widget _buildReservationDetails(Booking reservation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.calendar_today, Colors.blue[800]!,
            _formatDateTime(reservation.startTime)),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.access_time, Colors.green[800]!,
            '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.attach_money, Colors.purple[800]!,
            'Precio: ${reservation.totalPrice.toStringAsFixed(2)}'),
        const SizedBox(height: 8),
        _buildInfoRow(
            Icons.info, Colors.orange[800]!, 'Estado: ${reservation.status}'),
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
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blueGrey,
          ),
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
