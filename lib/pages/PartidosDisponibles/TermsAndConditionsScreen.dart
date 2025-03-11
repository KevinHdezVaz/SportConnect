import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Términos y Condiciones',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección Normas
            _buildSection('Normas', [
              _buildTermItem('1. Restricciones', [
                _buildSubTerm(
                    '1.1 Suspensión de partido: Si el partido se suspende, el dinero irá al monedero virtual de la app para que pueda anotarse a otro partido.'),
                _buildSubTerm(
                    '1.2 Faltar al evento: Al estar apuntado, no está permitido faltar y por lo tanto no se le devolverá el dinero.'),
                _buildSubTerm(
                    '1.3 Fumar: Está terminantemente prohibido fumar tabaco y sustancias ilícitas en las instalaciones deportivas.'),
                _buildSubTerm(
                    '1.4 Penalización: Las cuentas y bonos son intransferibles, son solo para uso único y exclusivo del usuario. Si un usuario tiene una deuda en una cuenta y se crea otra cuenta para no pagar, se cancelará una de las cuentas y se le sumará la deuda a la cuenta más antigua más 1€ de multa.'),
              ]),
            ]),
            SizedBox(height: 20),

            // Sección Deberes
            _buildSection('Deberes', [
              _buildTermItem('2. Deberes', [
                _buildSubTerm(
                    '2.1 Ver la pizarra del evento antes de salir: Antes de salir a cualquier juego se debe ver la pizarra o foro del partido, por cualquier cambio de última hora y confirmar que hay juego. En caso de suspenderse un partido será por falta de jugadores, 1 hora antes del partido necesitamos un mínimo de 10 personas confirmadas con check verde para dar de alta el partido, los que tienen símbolo ? son no confirmados.'),
                _buildSubTerm(
                    '2.2 Punto de encuentro: Se debe estar 15 minutos antes del partido para vestirse, hacer los equipos, calentar y pagar. Deben verificar su asistencia y pago en las listas con el organizador. Indumentaria para todos los partidos: camisetas rojas y azules, botas de taco corto, pantalón corto, calcetines de fútbol y espinilleras. Llegar temprano tiene beneficios, ganas 1 punto por cada partido que llegues temprano, al llegar 15 minutos antes pide el QR al organizador, acumula 10 puntos y se cambian por 350 pesos para partidos.'),
                _buildSubTerm(
                    '2.3 Indumentaria: Traer para todos los partidos camisetas rojas y azules, botas de taco corto, pantalón corto, calcetines de fútbol y espinilleras.'),
                _buildSubTerm(
                    '2.4 Apuntarse con antelación: Para poder organizar un partido deben apuntarse con un mínimo de 48H a 24H de antelación; si se puede mucho antes, mejor. El mínimo de jugadores para realizar un partido es de 12 personas confirmadas con check ✓ verde.'),
                _buildSubTerm(
                    '2.5 Estado del tiempo: La lluvia, nieve, frío, calor no es motivo para suspender un partido, los campos están pagados, la lluvia no evita la realización del partido.'),
                _buildSubTerm(
                    '2.6 Lista de espera: Al llenarse la lista principal debe escribir en la pizarra del partido que desea jugar. La lista de espera no tiene prioridad, si decide ir al campo no podrá jugar a menos que falte uno de los convocados en la lista.'),
              ]),
            ]),
            SizedBox(height: 20),

            // Sección Organización
            _buildSection('Organización', [
              _buildTermItem('3. Organización', [
                _buildSubTerm(
                    '3.1 Fairplay (juego limpio): Gente de buenos modales, se reserva el derecho de admisión. Las faltas claras serán cantadas por los mismos jugadores, debe ser algo claro y aceptado por todos los compañeros. Está prohibido los insultos, burlas, faltas con mala intención, escupir y cualquier tipo de agresión, todo esto será motivo de expulsión.'),
                _buildSubTerm(
                    '3.2 Retos y Equipos: Si tienes un equipo completo podemos conseguirte rivales, si tienes 2 equipos te podemos conseguir campo; ponte en contacto con nosotros.'),
                _buildSubTerm(
                    '3.3 Material deportivo: Tenemos balones, petos, bebidas isotónicas, infladores, etc., que serán de uso exclusivo de nuestros usuarios. Todo balón que se tire fuera del campo debe ser ubicado por el jugador responsable; en caso de no ser encontrado, deberá pagar el importe del mismo. En caso de que necesiten un pantalón corto o calcetines, tenemos a la venta, pregunta al organizador. Ofrecemos equipación deportiva, balones y material deportivo relacionado con el fútbol a buen precio, estampado en vinilo, nombres, números, logos, etc.'),
                _buildSubTerm(
                    '3.4 Nivel: Puedes evaluar a tus compañeros después de cada partido pinchando su perfil, con la suma de las evaluaciones tendrás un promedio general de cada usuario en su nivel y aptitud en el terreno de juego. También podrás seguirles para jugar con ellos. Lo difícil era conseguir partidos donde jugar a cualquier hora por tus horarios de trabajo, familia, etc.; ahora buscas el siguiente escalón, partidos donde compitas y exista un nivel futbolístico aceptable, donde tengas compañeros que tengan un rendimiento técnico y físico determinante. En este punto te ofrecemos las ligas en los equipos de FUTPLAY. Ponte en contacto con nosotros para ubicarte en el equipo que mejor te va.'),
              ]),
            ]),
            SizedBox(height: 20),

            // Sección Bonos
            _buildSection('Bonos', [
              _buildTermItem('4. Bonos', [
                _buildSubTerm(
                    '4.1 Bono mañanas Ilimitados: Duración 30 días desde su compra, juega todo lo que quieras de 9am a 14pm de lunes a viernes, días no festivos, solo para las instalaciones de Canal Ocio y Deporte.'),
                _buildSubTerm(
                    '4.2 Bono mañanas 10 partidos: No tiene fecha de vencimiento, juega 10 partidos de 9am a 14pm de lunes a viernes, días no festivos, solo para las instalaciones de Canal Ocio y Deporte.'),
                _buildSubTerm(
                    '4.3 Bono total: Duración 30 días desde su compra, juega todo lo que quieras todo el día a cualquier hora en cualquier instalación.'),
                _buildSubTerm(
                    '4.4 Bono Día 10 partidos: No tiene fecha de vencimiento, juega 10 partidos donde quieras por la tarde o noche en cualquier instalación.'),
                _buildSubTerm(
                    '4.5 Bono Anual: Duración 365 días desde su compra, pagas 0,96€ al día y juegas cuando y donde quieras.'),
                _buildSubTerm(
                    '4.6 Bono Fútbol Talent: Entrena como los profesionales, mejora tus carencias en defensa, ataque, dribling, posicionamiento, tecnifícate con un entrenador personalizado.'),
                _buildSubTerm(
                    '4.7 Importante: Si te apuntas a un evento con bono ilimitado y no asistes, esto generará una deuda al monedero por el valor del importe del evento.'),
              ]),
            ]),
            SizedBox(height: 20),

            // Sección Promociones
            _buildSection('Promociones', [
              _buildTermItem('5. Promociones', [
                _buildSubTerm(
                    '5.1 Código QR: Gana puntos por llegar temprano.'),
                _buildSubTerm(
                    '5.2 Bonos: Ahorra con los bonos, juega más y paga menos.'),
                _buildSubTerm(
                    '5.3 Camisetas personalizadas: Entra en nuestra tienda y compra tu camiseta.'),
                _buildSubTerm(
                    '5.4 Código de Promoción: Trae un amigo y gana 200 pesos tú y tu amigo.'),
              ]),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, List<Widget> subTerms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        ...subTerms,
      ],
    );
  }

  Widget _buildSubTerm(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
