import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  bool _loading=false;
  Future<void> _handleSignIn() async {
    setState(()=>_loading=true);
    try {
      final user = await FirebaseService.instance.signInWithGoogle();
      if (user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login annullato')));
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore login: $e'))); } finally { if (mounted) setState(()=>_loading=false); }
  }
  @override Widget build(BuildContext c)=>Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children:[Image.asset('assets/logo.png', width:96), const SizedBox(height:12), ElevatedButton.icon(onPressed: _loading?null:_handleSignIn, icon: const Icon(Icons.login), label: Text(_loading?'Accedo...':'Accedi con Google'))])));
}
