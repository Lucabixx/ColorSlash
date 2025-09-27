import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informazioni")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "ColorSlash - Versione di Test BETA1",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Versione 0.1\n\n"
              "ColorSlash è un’app di note multimediali evolute. "
              "Aggiungi testo, immagini, audio, video e schizzi a mano libera "
              "in una sola interfaccia semplice e moderna.\n\n"
              "Progettato da Luca Bixx.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                "© 2025 Luca Bixx - Tutti i diritti riservati",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//import 'package:flutter/material.dart';
//class OnboardingPage extends StatefulWidget { const OnboardingPage({super.key}); @override State<OnboardingPage> createState() => _OnboardingPageState(); }
//class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  //final PageController _pc = PageController();
//  bool _dark = false;
  //late AnimationController _pulse
  //@override void initState(){ super.initState(); _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds:800)); }
  //@override void dispose(){ _pc.dispose(); _pulse.dispose(); super.dispose(); }
  //void _finish(){ _pulse.forward(from:0); showDialog(context: context, builder: (_)=> Center(child: ScaleTransition(scale: _pulse, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green, size:64), const SizedBox(height:12), const Text('Setup completato, sei pronto a usare ColorSlash!', textAlign: TextAlign.center)],))))); Future.delayed(const Duration(seconds:2), (){ Navigator.of(context).pop(); Navigator.of(context).pushReplacementNamed('/home'); }); }
  //Widget _page(IconData i, String t, String s) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(i,size:120,color:Colors.white), const SizedBox(height:20), Text(t, style: const TextStyle(fontSize:22,fontWeight: FontWeight.bold,color:Colors.white)), const SizedBox(height:12), Text(s, style: const TextStyle(color:Colors.white70), textAlign: TextAlign.center)]));
  //@override Widget build(BuildContext c) => Scaffold(body: Stack(children: [AnimatedContainer(duration: const Duration(seconds:3), decoration: const BoxDecoration(gradient: LinearGradient(colors:[Color(0xFF86A8E7), Color(0xFF91EAE4)])), child: const SizedBox.expand()), PageView(controller: _pc, children: [_page(Icons.edit,'Prendi appunti facilmente','Crea note colorate'), _page(Icons.palette,'Colora','Assegna colori'), _page(Icons.cloud,'Sync','Backup su cloud')]), Positioned(bottom:30,left:20,right:20,child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [TextButton(onPressed: ()=>Navigator.of(c).pushReplacementNamed('/home'), child: const Text('Salta')), Row(children: [Switch(value: _dark, onChanged: (v)=>setState(()=>_dark=v)), const SizedBox(width:8), ElevatedButton(onPressed: (){ if((_pc.page ?? 0) >= 2) {
    //_finish();
  //} else {
    //_pc.nextPage(duration: const Duration(milliseconds:300), curve: Curves.ease);
  //} }, child: const Text('Avanti'))])])));
//}
//Onboarding.dart
