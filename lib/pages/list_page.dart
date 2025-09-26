@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista"), actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveList)]),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final it = _items[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                TextField(decoration: InputDecoration(hintText: "Elemento ${i+1}"), onChanged: (v) { it['text'] = v; _saveList(); }),
                Row(children: [
                  IconButton(icon: const Icon(Icons.mic), onPressed: () => _addAudioToItem(i)),
                  IconButton(icon: const Icon(Icons.image), onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text("Immagine"),
                    actions: [
                      TextButton(onPressed: () { Navigator.pop(context); _addImageToItem(i, ImageSource.camera); }, child: const Text("Scatta")),
                      TextButton(onPressed: () { Navigator.pop(context); _addImageToItem(i, ImageSource.gallery); }, child: const Text("Galleria")),
                    ],
                  ))),
                  IconButton(icon: const Icon(Icons.videocam), onPressed: () => showDialog(context: context, builder: (_) => AlertDialog(
                    title: const Text("Video"),
                    actions: [
                      TextButton(onPressed: () { Navigator.pop(context); _addVideoToItem(i, ImageSource.camera); }, child: const Text("Registra")),
                      TextButton(onPressed: () { Navigator.pop(context); _addVideoToItem(i, ImageSource.gallery); }, child: const Text("Galleria")),
                    ],
                  ))),
                  IconButton(icon: const Icon(Icons.brush), onPressed: () => _openDrawingForItem(i)),
                  const Spacer(),
                  IconButton(icon: Icon(it['done'] ? Icons.check_circle : Icons.cancel, color: it['done'] ? Colors.green : Colors.red), onPressed: () => _toggleDone(i)),
                ]),
                _buildAttachments(it['attachments']),
              ]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addItem, child: const Icon(Icons.add)),
    );
  }
}