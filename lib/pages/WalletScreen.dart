import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/Wallet.dart';
import 'package:user_auth_crudd10/services/WalletService.dart';
import 'package:share_plus/share_plus.dart'; // Para compartir
 
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late WalletService _walletService;
  Wallet? wallet;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _walletService = WalletService();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    debugPrint('Iniciando carga del monedero...');
    try {
      debugPrint('Llamando a _walletService.getWallet()');
      final loadedWallet = await _walletService.getWallet();
      debugPrint('Monedero cargado exitosamente: balance=${loadedWallet.balance}, points=${loadedWallet.points}, referral_code=${loadedWallet.referralCode}');
      
      if (mounted) {
        debugPrint('Widget montado, actualizando estado');
        setState(() {
          wallet = loadedWallet;
          isLoading = false;
          debugPrint('Estado actualizado: wallet asignado, isLoading=$isLoading');
        });
      } else {
        debugPrint('Widget no montado, no se actualiza el estado');
      }
    } catch (e) {
      debugPrint('Error al cargar el monedero: $e');
      Fluttertoast.showToast(msg: 'Error al cargar monedero: $e');
      if (mounted) {
        debugPrint('Widget montado, estableciendo isLoading=false tras error');
        setState(() => isLoading = false);
      } else {
        debugPrint('Widget no montado, no se actualiza estado tras error');
      }
    }
  }

  // Función para compartir el referral_code
  void _shareReferralCode() {
    if (wallet?.referralCode != null) {
      Share.share(
        '¡Únete a la app con mi código de referido ${wallet!.referralCode} y ambos ganaremos 350 UYU cuando juegues tu primer partido!',
        subject: 'Invitación a la app',
      );
    } else {
      Fluttertoast.showToast(msg: 'No se encontró tu código de referido');
    }
  }

  // Función para copiar el referral_code al portapapeles
  void _copyReferralCode() {
    if (wallet?.referralCode != null) {
      FlutterClipboard.copy(wallet!.referralCode!).then((value) {
        Fluttertoast.showToast(
          msg: 'Código de referido copiado al portapapeles',
          backgroundColor: Colors.green,
        );
      });
    } else {
      Fluttertoast.showToast(msg: 'No se encontró tu código de referido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Monedero'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: wallet == null
                  ? const Center(child: Text('No se pudo cargar el monedero'))
                  : _buildWalletContent(),
            ),
    );
  }

  Widget _buildWalletContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Saldo Disponible',
                    style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${wallet!.balance.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 32, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.yellow),
                      const SizedBox(width: 8),
                      Text(
                        'Puntos: ${wallet!.points}',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Código de Referido',
                    style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Text(
                        wallet!.referralCode ?? 'No disponible',
                        style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.blue),
                            onPressed: _copyReferralCode,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.blue),
                            onPressed: _shareReferralCode,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comparte tu código con un amigo. Cuando se registre con él y juegue su primer partido, ambos ganarán 350 UYU.',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Transacciones',
                    style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  wallet!.transactions.isEmpty
                      ? const Center(child: Text('No hay transacciones aún'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: wallet!.transactions.length,
                          itemBuilder: (context, index) {
                            final tx = wallet!.transactions[index];
                            return ListTile(
                              leading: Icon(
                                tx.type == 'deposit' || tx.type == 'points_earned'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: tx.type == 'deposit' || tx.type == 'points_earned'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(tx.description, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.date), style: TextStyle(color: Colors.black)),
                              trailing: Text(
                                tx.amount != null
                                    ? '\$${tx.amount!.toStringAsFixed(2)}'
                                    : '${tx.points} pts',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: tx.type == 'deposit' || tx.type == 'points_earned'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}