import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? selectedColor;
  String? selectedSize;
  int? selectedUnits;
  int? selectedNumber;
  final TextEditingController _unitsController = TextEditingController();

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  void openWhatsApp(BuildContext context) async {
    final String phoneNumber = "528186812341";
    String message =
        "👋 Hola, me interesa el producto: *${widget.product['name']}*";

    if (selectedColor != null) message += "\n\n🎨 Color: $selectedColor";
    if (selectedSize != null) message += "\n📏 Talla: $selectedSize";
    if (selectedUnits != null) {
      message +=
          "\n📦 Cantidad: $selectedUnits pieza${selectedUnits == 1 ? '' : 's'}";
    }
    if (selectedNumber != null) message += "\n🔢 Número: $selectedNumber";

    message += "\n\nGracias, espero su respuesta! 😊";

    final String url =
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product['images'] as List<dynamic>;
    final colors = widget.product['colors'] as List<dynamic>? ?? [];
    final sizes = widget.product['sizes'] as List<dynamic>? ?? [];
    final maxUnits = widget.product['units'] as int? ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name']),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (images.isNotEmpty)
              Card(
                elevation: 10,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 300.0,
                    enlargeCenterPage: true,
                    autoPlay: true,
                    viewportFraction: 1,
                  ),
                  items: images.map((image) {
                    final imageUrl =
                        "https://proyect.aftconta.mx/storage/$image";
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ZoomImageScreen(imageUrl: imageUrl),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${widget.product['price']}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Opciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (colors.isNotEmpty)
                    _buildCardSelector(
                      label: 'Color',
                      selectedValue: selectedColor,
                      options: colors,
                      onSelected: (value) {
                        setState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  if (sizes.isNotEmpty)
                    _buildCardSelector(
                      label: 'Talla',
                      selectedValue: selectedSize,
                      options: sizes,
                      onSelected: (value) {
                        setState(() {
                          selectedSize = value;
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _unitsController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad de piezas (máximo $maxUnits)',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      hintText: 'Ingrese un número',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      prefixIcon:
                          Icon(Icons.shopping_cart, color: Colors.blueAccent),
                      suffixIcon: selectedUnits != null &&
                              selectedUnits! >= 1 &&
                              selectedUnits! <= maxUnits
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      errorText: selectedUnits != null &&
                              (selectedUnits! < 1 || selectedUnits! > maxUnits)
                          ? 'Debe ser entre 1 y $maxUnits'
                          : null,
                      errorStyle: TextStyle(color: Colors.red),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        selectedUnits =
                            value.isNotEmpty ? int.tryParse(value) : null;
                      });
                    },
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Número Dorsal',
                      labelStyle: TextStyle(color: Colors.blueGrey),
                      hintText: 'Ingrese un número',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      prefixIcon: Icon(Icons.numbers, color: Colors.blueAccent),
                      suffixIcon: selectedNumber != null
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      errorText: selectedNumber != null && selectedNumber! < 1
                          ? 'Debe ser un número válido'
                          : null,
                      errorStyle: TextStyle(color: Colors.red),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: widget.product['numbers']?.toString(),
                    onChanged: (value) {
                      setState(() {
                        selectedNumber =
                            value.isNotEmpty ? int.tryParse(value) : null;
                      });
                    },
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => openWhatsApp(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/whatsapp.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Preguntar por Whatsapp',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSelector({
    required String label,
    required String? selectedValue,
    required List<dynamic> options,
    required Function(String) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: options.map((dynamic option) {
            final optionText = option.toString();
            final isSelected = selectedValue == optionText;
            return GestureDetector(
              onTap: () => onSelected(optionText),
              child: Card(
                elevation: isSelected ? 4.0 : 1.0,
                color: isSelected ? Colors.blue[700] : Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    optionText,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ZoomImageScreen extends StatelessWidget {
  final String imageUrl;

  const ZoomImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regresar'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text(
              'Error al cargar la imagen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
