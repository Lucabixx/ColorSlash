import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoSync = true;

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(children: [
        SwitchListTile(
          title: const Text('Sincronizzazione automatica'),
          subtitle: const Text('Sincronizza all'avvio e alle modifiche delle note'),
          value: _autoSync,
          onChanged: (v) => setState(() => _autoSync = v),
        ),
        ListTile(
          title: const Text('Account'),
          subtitle: const Text('Gestisci il tuo account Google'),
        ),
      ]),
    );
  }
}
