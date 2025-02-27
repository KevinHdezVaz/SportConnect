// lib/pages/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/model/Wallet.dart';
import 'package:user_auth_crudd10/services/WalletService.dart'; 

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late WalletService _walletService;
  Wallet? wallet;
  bool isLoading = true;
  final TextEditingController _referralController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar el servicio sin pasar token
    _walletService = WalletService();
    _loadWallet();
  }


Future<void> _loadWallet() async {
  debugPrint('Iniciando carga del monedero...');
  try {
    debugPrint('Llamando a _walletService.getWallet()');
    final loadedWallet = await _walletService.getWallet();
    debugPrint('Monedero cargado exitosamente: balance=${loadedWallet.balance}, points=${loadedWallet.points}');
    
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

  Future<void> _handleReferral(String referralCode) async {
    setState(() => isLoading = true);
    try {
      await _walletService.addReferralPoints(referralCode);
      await _loadWallet(); // Recargar el monedero tras agregar puntos
      Fluttertoast.showToast(msg: 'Puntos por referido agregados', backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error al procesar referido: $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _referralController.dispose();
    super.dispose();
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
          // Saldo y puntos
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

          // Sección de referidos
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invita y Gana',
                    style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _referralController,
                    decoration: InputDecoration(
                      labelText: 'Ingresa código de referido',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => _handleReferral(_referralController.text),
                      ),
                    ),
                    onSubmitted: _handleReferral,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invita a un amigo y ambos ganan 50 puntos.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Historial de transacciones
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
                              title: Text(tx.description, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.date), style: TextStyle(color: Colors.black),),
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