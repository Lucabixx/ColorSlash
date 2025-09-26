onPressed: () => showAboutDialog(
            context: context,
            applicationName: "ColorSlash",
            applicationVersion: "1.0",
            children: const [Text("Progettato da Luca Bixx")],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: _handleGoogleSignIn,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text("Progettato da Luca Bixx", style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text("Sincronizza adesso"),
              onTap: () async {
                await StorageService.syncAllNotes();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizzazione inviata")));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout Google"),
              onTap: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                setState(() => user = null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: notes.isEmpty
          ? const Center(child: Text("Nessuna nota ancora"))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (ctx, i) {
                final n = notes[i];
                final title = (n['type'] == 'nota') ? (n['text'] ?? '(nota vuota)') : 'Lista - ${n['id']}';
                return ListTile(
                  title: Text(
                    title.toString().split('\n').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(n['timestamp'] ?? ''),
                );
              }),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.blue.shade700,
        onPressed: _onAddPressed,
        child: const Icon(Icons.add, size: 48),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}