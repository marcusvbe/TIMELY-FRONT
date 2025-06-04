import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ipController = TextEditingController();
  bool _isTesting = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _ipController.text = AppConfig.wsUrl.replaceFirst('ws://', '');
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = '';
    });

    try {
      final url = 'ws://${_ipController.text}';
      final channel = WebSocketChannel.connect(Uri.parse(url));

      // Aguarda a conexão por 5 segundos
      await Future.delayed(const Duration(seconds: 2));

      // Tenta enviar uma mensagem
      channel.sink.add('{"action": "get_last_uid"}');

      // Aguarda resposta por 3 segundos
      await Future.delayed(const Duration(seconds: 3));

      // Fecha a conexão
      await channel.sink.close();

      setState(() {
        _testResult = 'Conexão bem-sucedida!';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Falha na conexão: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF006699);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Configuração do Dispositivo ESP32',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Endereço do ESP32 (IP:Porta)',
                hintText: 'Ex: 192.168.137.100:8765',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Testar Conexão'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final url = 'ws://${_ipController.text}';
                      await AppConfig.updateWsUrl(url);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configuração salva com sucesso!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            if (_testResult.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult.contains('sucedida')
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_testResult),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
