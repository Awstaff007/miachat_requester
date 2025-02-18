// #### **lib/help_screen.dart**

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  final List<Map<String, String>> helpItems = [
    {
      'title': 'Come ottenere la API Key',
      'content':
          'Puoi ottenere la tua API Key accedendo al tuo account sul sito di DeepSeek e navigando nella sezione "API Keys".'
    },
    {
      'title': 'Configurare il Backoff Esponenziale',
      'content':
          'Il Backoff Esponenziale aumenta progressivamente l\'intervallo tra i tentativi dopo ogni errore, al fine di ridurre il carico sul server.'
    },
    {
      'title': 'Continuare una Conversazione',
      'content':
          'Se desideri continuare una conversazione esistente, inserisci l\'ID della conversazione e attiva l\'opzione "Continuare Conversazione".'
    },
    {
      'title': 'Gestire i Messaggi di Errore',
      'content':
          'Puoi aggiungere messaggi di errore personalizzati che l\'app riconoscerà per applicare il backoff esponenziale.'
    },
    {
      'title': 'Visualizzare e Gestire i Log',
      'content':
          'La schermata Logs ti permette di consultare le attività registrate dall\'app e cancellare i log se necessario.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aiuto'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: helpItems.length,
        itemBuilder: (context, index) {
          final item = helpItems[index];
          return ExpansionTile(
            title: Text(item['title']!),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(item['content']!),
              ),
            ],
          );
        },
      ),
    );
  }
}