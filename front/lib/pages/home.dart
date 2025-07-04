import '../services/rfid_data_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/date_format.dart';
import '../config/app_config.dart';
import '../modelos/cartao.dart';
import '../services/data_service_interface.dart';
import '../services/data_service_provider.dart';
import '../components/drawer.dart';
import '../services/rfid_service.dart';

// Enum para os tipos de filtro de tempo
enum FiltroTempo { hoje, seteDias, quinzeDias, trintaDias, todos }

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final DataServiceInterface _dataService;
  late final RfidService _rfidService;
  List<CartaoModel> _registros = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _isWebSocketConnected = false;
  String _errorMessage = '';
  Timer? _timer;
  StreamSubscription<CartaoModel>? _novoCartaoSubscription;

  // Filtro de tempo selecionado (padrão: todos)
  FiltroTempo _filtroSelecionado = FiltroTempo.todos;

  final Color _primaryBlue = const Color(0xFF006699);
  final Color _lightBlue = const Color(0xFFE6F2F8);

  @override
  void initState() {
    super.initState();

    _dataService = DataServiceProvider.getService(
        useMockData: AppConfig.useMockData, apiBaseUrl: AppConfig.apiBaseUrl);

    _rfidService = RfidService();
    _rfidService.connect();
    _rfidService.onConnectionChange = (isConnected) {
      setState(() {
        _isWebSocketConnected = isConnected;
      });
    };

    // Se estivermos usando RfidDataService, escutar o stream de novos cartões
    if (_dataService is RfidDataService) {
      final rfidDataService = _dataService as RfidDataService;
      _novoCartaoSubscription = rfidDataService.onNovoCartao.listen(
        (novoCartao) {
          if (!mounted) return; // Verificar se widget ainda está montado

          // Feedback visual
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cartão detectado: ${novoCartao.codigo}'),
              backgroundColor: (novoCartao.autorizado == true)
                  ? Colors.green
                  : Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );

          // Atualizar dados na UI
          _carregarDados();
        },
        onError: (error) {
          if (AppConfig.enableLogging) {
            print('Erro no stream de novos cartões: $error');
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro na comunicação RFID: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } else {
      // Para outros serviços, manter o callback original
      _rfidService.onMessage = (message) {
        if (message.containsKey('event') && message['event'] == 'card_read') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cartão detectado: ${message['uid']}'),
              backgroundColor: message['status'] == 'authorized'
                  ? Colors.green
                  : Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          _carregarDados();
        }
      };
    }

    _timer = Timer.periodic(Duration(seconds: AppConfig.dataRefreshInterval),
        (timer) => _carregarDados());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _novoCartaoSubscription?.cancel();
    _rfidService.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    if (_isLoading) return;

    if (AppConfig.enableLogging) {
      print('Carregando dados...');
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Adicionar timeout
      final registros = await _dataService.getUltimosRegistros().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
              'Timeout ao carregar dados', Duration(seconds: 10));
        },
      );

      if (mounted) {
        setState(() {
          _registros = registros;
          _isLoading = false;
        });
      }

      if (AppConfig.enableLogging) {
        print('Dados carregados: ${registros.length} registros');
      }
    } on TimeoutException catch (e) {
      if (AppConfig.enableLogging) {
        print('Timeout ao carregar dados: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Timeout: Verifique a conexão com o dispositivo';
        });
      }
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('Erro ao carregar dados: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Erro: ${e.toString()}';
        });
      }
    }
  }

  String _formatarTimestamp(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormatter.format(dateTime, 'HH:mm:ss');
  }

  String _formatarData(int timestamp) {
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormatter.format(dateTime, 'dd/MM/yyyy');
  }

  // Método para filtrar registros com base no período selecionado
  List<CartaoModel> _getRegistrosFiltrados() {
    final agora = DateTime.now();
    late final DateTime dataLimite;

    switch (_filtroSelecionado) {
      case FiltroTempo.hoje:
        dataLimite = DateTime(agora.year, agora.month, agora.day);
        break;
      case FiltroTempo.seteDias:
        dataLimite = agora.subtract(const Duration(days: 7));
        break;
      case FiltroTempo.quinzeDias:
        dataLimite = agora.subtract(const Duration(days: 15));
        break;
      case FiltroTempo.trintaDias:
        dataLimite = agora.subtract(const Duration(days: 30));
        break;
      case FiltroTempo.todos:
        return _registros; // Retorna todos os registros
    }

    final timestampLimite = dataLimite.millisecondsSinceEpoch;

    return _registros
        .where((registro) => registro.timestamp >= timestampLimite)
        .toList();
  }

  // String do título do filtro
  String _getTituloFiltro() {
    switch (_filtroSelecionado) {
      case FiltroTempo.hoje:
        return 'Registros de hoje';
      case FiltroTempo.seteDias:
        return 'Últimos 7 dias';
      case FiltroTempo.quinzeDias:
        return 'Últimos 15 dias';
      case FiltroTempo.trintaDias:
        return 'Últimos 30 dias';
      case FiltroTempo.todos:
        return 'Todos os registros';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Acesso'),
        backgroundColor: _primaryBlue,
        actions: [
          // Indicador de status WebSocket
          _isWebSocketConnected
              ? Icon(Icons.wifi, color: Colors.green)
              : Icon(Icons.wifi_off, color: Colors.red),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      drawer: MeuDrawer(),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Controle de Acesso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _primaryBlue)),
                const SizedBox(height: 12),
                _buildFiltroSelect(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: _lightBlue,
            width: double.infinity,
            child: Text(
              _getTituloFiltro(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ),
          Expanded(
            child: _buildRegisterTable(_getRegistrosFiltrados()),
          ),
          Container(
            width: double.infinity,
            color: _primaryBlue,
            padding: EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              'Copyright © 2025',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarDialogAutorizarCartao(context);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget para o seletor de filtro (dropdown)
  Widget _buildFiltroSelect() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _primaryBlue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FiltroTempo>(
          value: _filtroSelecionado,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _primaryBlue),
          style: TextStyle(color: _primaryBlue, fontSize: 16),
          onChanged: (FiltroTempo? newValue) {
            if (newValue != null) {
              setState(() {
                _filtroSelecionado = newValue;
              });
            }
          },
          items: [
            DropdownMenuItem(
              value: FiltroTempo.hoje,
              child: Text('Hoje'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.seteDias,
              child: Text('Últimos 7 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.quinzeDias,
              child: Text('Últimos 15 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.trintaDias,
              child: Text('Últimos 30 dias'),
            ),
            DropdownMenuItem(
              value: FiltroTempo.todos,
              child: Text('Todos os registros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTable(List<CartaoModel> registros) {
    if (_isLoading && registros.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhum registro encontrado para este período'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          color: _primaryBlue,
          child: Row(
            children: [
              _buildHeaderCell('Nome', flex: 1),
              _buildHeaderCell('Início', flex: 1),
              _buildHeaderCell('Fim', flex: 1),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregarDados,
            child: ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final registro = registros[index];
                final bool isEven = index.isEven;

                return Container(
                  color: isEven ? Colors.white : _lightBlue,
                  child: Row(
                    children: [
                      _buildDataCell(registro.nome ?? 'Nome', flex: 1),
                      _buildDataCell(_formatarTimestamp(registro.timestamp),
                          flex: 1),
                      _buildDataCell('Fim', flex: 1),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Método para mostrar o diálogo de autorização de cartão
  void _mostrarDialogAutorizarCartao(BuildContext context) {
    final TextEditingController _uidController = TextEditingController();
    final TextEditingController _nomeController = TextEditingController();
    bool _isProcessing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Autorizar Novo Cartão',
                style: TextStyle(color: _primaryBlue),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _uidController,
                      decoration: InputDecoration(
                        labelText: 'UID do Cartão',
                        hintText: 'Ex: A1B2C3D4',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome do Usuário',
                        hintText: 'Ex: João Silva',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.contactless),
                      label: Text('Capturar último cartão lido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      onPressed: () async {
                        try {
                          if (!_rfidService.isConnected) {
                            throw Exception('Dispositivo RFID não conectado');
                          }

                          // Para RfidDataService, pegar o último registro da lista
                          if (_dataService is RfidDataService) {
                            if (_registros.isNotEmpty) {
                              final ultimoRegistro = _registros
                                  .first; // Já está ordenado por timestamp
                              _uidController.text = ultimoRegistro.codigo;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Último cartão capturado: ${ultimoRegistro.codigo}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              throw Exception('Nenhum cartão foi lido ainda');
                            }
                          } else {
                            // Para outros serviços, usar a abordagem original com listener temporário
                            String? capturedUid;
                            bool responseReceived = false;

                            // Criar listener temporário
                            void tempListener(Map<String, dynamic> message) {
                              if (message.containsKey('last_uid') &&
                                  message['last_uid'] != null) {
                                capturedUid = message['last_uid'];
                                responseReceived = true;
                              }
                            }

                            // Guardar callback original e definir temporário
                            final originalCallback = _rfidService.onMessage;
                            _rfidService.onMessage = tempListener;

                            try {
                              // Enviar comando
                              _rfidService.getLastUid();

                              // Aguardar resposta por 3 segundos
                              int attempts = 0;
                              const maxAttempts = 15; // 3 segundos total

                              while (
                                  !responseReceived && attempts < maxAttempts) {
                                await Future.delayed(
                                    Duration(milliseconds: 200));
                                attempts++;
                              }

                              if (capturedUid != null) {
                                _uidController.text = capturedUid!;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Cartão capturado: $capturedUid'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                throw Exception(
                                    'Timeout: Nenhum cartão encontrado');
                              }
                            } finally {
                              // Sempre restaurar callback original
                              _rfidService.onMessage = originalCallback;
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao capturar cartão: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                _isProcessing
                    ? CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                        ),
                        onPressed: () async {
                          final uid = _uidController.text.trim();
                          final nome = _nomeController.text.trim();

                          if (uid.isEmpty || nome.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Por favor, preencha o UID e o nome do usuário'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _isProcessing = true;
                          });

                          try {
                            // Verificar se WebSocket está conectado
                            if (!_rfidService.isConnected) {
                              throw Exception('Dispositivo RFID não conectado');
                            }

                            // Autoriza o cartão no ESP32
                            _rfidService.authorizeCard(uid, nome);

                            // Aguardar um tempo para confirmação
                            await Future.delayed(Duration(milliseconds: 800));

                            setState(() {
                              _isProcessing = false;
                            });

                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Cartão $uid autorizado para $nome com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );

                            // Atualiza a lista de registros
                            _carregarDados();
                          } catch (e) {
                            setState(() {
                              _isProcessing = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao autorizar cartão: $e'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 4),
                              ),
                            );

                            if (AppConfig.enableLogging) {
                              print('Erro na autorização do cartão: $e');
                            }
                          }
                        },
                        child: Text('Autorizar'),
                      ),
              ],
            );
          },
        );
      },
    );
  }
}
