import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  double? _resultado;
  bool _isLoading = false;

  Future<void> _converter() async {
    String inputText = _controller.text.trim();

    if (inputText.isEmpty) {
      _mostrarMensagem("Por favor, insira um valor.");
      return;
    }

    double? metros = double.tryParse(inputText);
    if (metros == null || metros < 0) {
      _mostrarMensagem("Insira um número válido e positivo.");
      return;
    }

    double km = metros / 1000;

    setState(() {
      _resultado = km;
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('conversions').add({
        'metros': metros,
        'km': km,
        'timestamp': Timestamp.now(),
      });
      _mostrarMensagem("Conversão salva com sucesso!");
    } catch (e) {
      _mostrarMensagem("Erro ao salvar no Firestore: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem),
      duration: Duration(seconds: 2),
    ));
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
              onPressed: _isLoading ? null : _converter,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Converter'),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Nenhuma conversão registrada ainda."));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text('${data['metros']} m → ${data['km']} km'),
              subtitle: Text(_formatarData(data['timestamp'])),
            );
          },
        );
      },
    );
  }

  String _formatarData(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
  }
}
