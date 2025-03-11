import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      if (mounted) setState(() => isLoading = true); // Verificar mounted
      final active = await bookingService.getActiveReservations();
      final history = await bookingService.getReservationHistory();
      if (mounted) {
        // Verificar mounted antes de actualizar el estado
        setState(() {
          activeReservations = active;
          reservationHistory = history;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Verificar mounted antes de mostrar error
        setState(() => isLoading = false);
        _showErrorSnackBar('Error al cargar las reservas: $e');
      }
    }
  }

  Future<void> _handleCancelReservation(Booking reservation) async {
    try {
      final now = DateTime.now();
      if (reservation.startTime.difference(now).inHours < 5) {
        _showErrorSnackBar(
            'No puedes cancelar con menos de 5 horas de antelación');
        return;
      }

      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar cancelación',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: const Text(
              'La reserva será cancelada y el monto se reembolsará a tu monedero. ¿Deseas continuar?',
              style: TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sí, cancelar reserva',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final result =
          await bookingService.cancelReservation(reservation.id.toString());

      if (result['success'] ||
          (result['message'] != null &&
              result['message'].contains('ya está cancelada'))) {
        await _loadReservations();
        if (result['success']) {
          _showSuccessSnackBar(
              result['message'] ?? 'Reserva cancelada exitosamente');
          if (result['refunded_amount'] != null) {
            Fluttertoast.showToast(
              msg: 'Monto reembolsado: \$${result['refunded_amount']}',
              backgroundColor: Colors.blue,
              toastLength: Toast.LENGTH_LONG,
            );
          }
        } else {
          _showInfoSnackBar(result['message']);
        }
      } else {
        _showErrorSnackBar(
            result['message'] ?? 'No se pudo cancelar la reserva');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cancelar la reserva: $e');
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[800],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Mis Reservas',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTabButton('active', 'Reservas Activas')),
                    Expanded(child: _buildTabButton('history', 'Historial')),
                  ],
                ),
              ),
            ),
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
                          if (mounted) {
                            setState(() {
                              activeTab = index == 0 ? 'active' : 'history';
                            });
                          }
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
    return GestureDetector(
      onTap: () {
        if (mounted) {
          setState(() => activeTab = tabType);
          _pageController.animateToPage(
            tabType == 'active' ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: activeTab == tabType
              ? LinearGradient(
                  colors: [Colors.blue[800]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: activeTab == tabType ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: activeTab == tabType ? Colors.white : Colors.blue[800],
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
              Icons.event_busy_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'Sin reservas activas' : 'Sin historial de reservas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
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
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailsScreen(
                    booking: reservation, isActive: isActive),
              ),
            ).then((_) => _loadReservations());
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            color: Colors.white,
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
        Flexible(
          child: Text(
            reservation.fieldName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isActive && reservation.status.toLowerCase() != 'cancelled')
          IconButton(
            icon: Icon(Icons.cancel_outlined, size: 26, color: Colors.red[800]),
            onPressed: () => _handleCancelReservation(reservation),
            tooltip: 'Cancelar reserva',
          ),
      ],
    );
  }

  Widget _buildReservationDetails(Booking reservation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.calendar_today_outlined, Colors.blue[800]!,
            _formatDateTime(reservation.startTime)),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.access_time_filled, Colors.green[800]!,
            '${_formatTime(reservation.startTime)} - ${_formatTime(reservation.endTime)}'),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.attach_money, Colors.purple[800]!,
            '\$${reservation.totalPrice.toStringAsFixed(2)}'),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.info_outline, _getStatusColor(reservation.status),
            'Estado: ${_getStatusText(reservation.status)}'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'completed':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      case 'confirmed':
        return Colors.blue[800]!;
      default:
        return Colors.blue[800]!;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'completed':
        return 'Completada';
      case 'cancelled':
        return 'Cancelada';
      case 'confirmed':
        return 'Confirmada';
      default:
        return status;
    }
  }
}
