// #### **lib/log_screen.dart**

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key}); // Aggiunto super.key

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final ScrollController _scrollController = ScrollController();
  String _logContent = '';
  bool _isLoadingLog = false; // Stato di caricamento del log
  bool _isClearingLog = false; // Stato di cancellazione del log
  bool _isLoadingMore = false; // Stato di caricamento aggiuntivo

  int _currentPage = 0;
  final int _pageSize = 1000;
  List<String> _paginatedLogs = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadLog();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreLogs();
    }
  }

  Future<void> _loadLog() async {
    setState(() {
      _isLoadingLog = true; // Inizia caricamento
      _logContent = 'Caricamento log...'; // Messaggio temporaneo
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/app_log.txt';
      final file = File(path);

      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _logContent = content;
        });
        _loadPaginatedLogs(); // Carica i log paginati
      } else {
        setState(() {
          _logContent = 'Nessun log disponibile.';
        });
      }
    } catch (e) {
      setState(() {
        _logContent = 'Errore nel caricamento del log: $e';
      });
      print('Errore nel caricamento del log: $e'); // Log per debug
    } finally {
      setState(() {
        _isLoadingLog = false; // Fine caricamento
      });
    }
  }

  Future<void> _clearLog() async {
    setState(() {
      _isClearingLog = true; // Inizia cancellazione
    });
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.writeAsString('');
      }

      setState(() {
        _logContent = 'Log cancellato.';
        _paginatedLogs = []; // Resetta i log paginati
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Log cancellato con successo.')),
      );
    } catch (e) {
      setState(() {
        _logContent = 'Errore nella cancellazione del log: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nella cancellazione del log.')),
      );
      print('Errore nella cancellazione del log: $e'); // Log per debug
    } finally {
      setState(() {
        _isClearingLog = false; // Fine cancellazione
      });
    }
  }

  void _confirmClearLog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Conferma cancellazione'),
        content: Text('Vuoi davvero cancellare tutti i log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearLog();
            },
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPaginatedLogs() async {
    final allLogs = _logContent.split('\n');
    final startIndex = _currentPage * _pageSize;
    final endIndex = startIndex + _pageSize;
    
    setState(() {
      _paginatedLogs = allLogs.sublist(
        startIndex.clamp(0, allLogs.length),
        endIndex.clamp(0, allLogs.length),
      );
    });
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore) return;
    
    setState(() => _isLoadingMore = true);
    await Future.delayed(Duration(seconds: 1)); // Simula caricamento
    
    setState(() {
      _currentPage++;
      _isLoadingMore = false;
    });
    _loadPaginatedLogs();
  }

  Future<File> get _logFile async { // Aggiunto
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_log.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
        actions: [
          IconButton(
            icon: _isClearingLog ? CircularProgressIndicator() : Icon(Icons.delete_forever), // Mostra indicator durante cancellazione
            onPressed: _isClearingLog ? null : _confirmClearLog, // Disabilita button durante cancellazione
            disabledColor: Colors.grey, // Imposta colore se disabilitato
          ),
        ],
      ),
      body: Stack( // Stack per mostrare il loading in overlay
        children: [
          Column(
            children: [
              Expanded(
                child: FutureBuilder<File>( // Integrato FutureBuilder
                  future: _logFile, // Utilizzo _logFile per ottenere il file
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return StreamBuilder<String>(
                        stream: snapshot.data!.openRead().transform(utf8.decoder),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            _logContent = snapshot.data!; // Aggiorna _logContent
                            _loadPaginatedLogs(); // Carica i log paginati
                            return _buildLogList(_logContent);
                          }
                          return const CircularProgressIndicator();
                        },
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0 ? () {
                      setState(() => _currentPage--);
                      _loadPaginatedLogs();
                    } : null,
                  ),
                  Text('Pagina ${_currentPage + 1}'),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() => _currentPage++);
                      _loadPaginatedLogs();
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_isLoadingLog) // Overlay di caricamento
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5), // Sfondo semi-trasparente
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogList(String logs) { // Aggiornato
    return ListView.builder(
      controller: _scrollController,
      itemCount: _paginatedLogs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _paginatedLogs.length) {
          return Center(child: CircularProgressIndicator());
        }
        final logEntry = _paginatedLogs[index];
        return ListTile(
          title: Text(logEntry),
        );
      },
    );
  }
}
