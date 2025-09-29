
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_manager.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AutoThemeMode _mode = AutoThemeMode.system;
  bool _manualDark = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('autoThemeMode') ?? 'system';
    setState((){
      _mode = AutoThemeMode.values.firstWhere((e)=>e.toString().split('.').last==s, orElse: ()=>AutoThemeMode.system);
      _manualDark = prefs.getBool('manualDark') ?? false;
    });
  }

  void _apply() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('autoThemeMode', _mode.toString().split('.').last);
    prefs.setBool('manualDark', _manualDark);
    // notify ThemeManager by popping and relying on rebuild; in a real app you'd use Provider or similar
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Impostazioni tema')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text('Seguire modalità di sistema'),
              leading: Radio<AutoThemeMode>(value: AutoThemeMode.system, groupValue: _mode, onChanged: (v){ setState(()=>_mode=v!); }),
            ),
            ListTile(
              title: Text('Automatico in base all'orario (sera/notte)'),
              leading: Radio<AutoThemeMode>(value: AutoThemeMode.time, groupValue: _mode, onChanged: (v){ setState(()=>_mode=v!); }),
            ),
            ListTile(
              title: Text('Manuale'),
              leading: Radio<AutoThemeMode>(value: AutoThemeMode.manual, groupValue: _mode, onChanged: (v){ setState(()=>_mode=v!); }),
            ),
            if (_mode==AutoThemeMode.manual)
              SwitchListTile(
                title: Text('Tema scuro'),
                value: _manualDark,
                onChanged: (v) => setState(()=>_manualDark=v),
              ),
            SizedBox(height:20),
            ElevatedButton(onPressed: _apply, child: Text('Salva'))
          ],
        ),
      ),
    );
  }
}
