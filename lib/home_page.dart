import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  double? _resultado;

  Future<void> _converter() async {
    if (_controller.text.isEmpty) return;

    double metros = double.tryParse(_controller.text) ?? 0;
    double km = metros / 1000;

    setState(() {
      _resultado = km;
    });

    // salva no Firestore
    await FirebaseFirestore.instance.collection('conversions').add({
      'metros': metros,
      'km': km,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversor de Metros para Km')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Digite metros'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _converter,
              child: Text('Converter'),
            ),
            if (_resultado != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Resultado: $_resultado km',
                    style: TextStyle(fontSize: 18)),
              ),
            SizedBox(height: 20),
            Expanded(child: _buildHistorico()),
          ],
        ),
      ),
    );
  }

  // mostra o histórico de conversões
  Widget _buildHistorico() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('${data['metros']} m → ${data['km']} km'),
              subtitle: Text(data['timestamp'].toDate().toString()),
            );
          },
        );
      },
    );
  }
}
