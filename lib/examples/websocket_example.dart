import 'package:flutter/material.dart';
import '../repositories/websocket_lotto_repository.dart';
import '../models.dart';

class WebSocketExamplePage extends StatefulWidget {
  @override
  _WebSocketExamplePageState createState() => _WebSocketExamplePageState();
}

class _WebSocketExamplePageState extends State<WebSocketExamplePage> {
  late WebSocketLottoRepository repository;
  String connectionStatus = 'Disconnected';
  List<Ticket> tickets = [];
  AppUser? currentUser;

  @override
  void initState() {
    super.initState();
    repository = WebSocketLottoRepository();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to connection status
    repository.connectionStream.listen((status) {
      setState(() {
        connectionStatus = status;
      });
    });

    // Listen to tickets updates
    repository.ticketsStream.listen((ticketList) {
      setState(() {
        tickets = ticketList;
      });
    });

    // Listen to user updates
    repository.userStream.listen((user) {
      setState(() {
        currentUser = user;
      });
    });
  }

  Future<void> _connect() async {
    try {
      await repository.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to server')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  Future<void> _disconnect() async {
    repository.disconnect();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Disconnected')),
    );
  }

  Future<void> _login() async {
    if (connectionStatus != 'connected') return;
    try {
      await repository.loginMember(
        username: 'testuser',
        password: 'testpass',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  Future<void> _loadTickets() async {
    if (connectionStatus != 'connected') return;
    try {
      await repository.getAllTickets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tickets: $e')),
      );
    }
  }

  Future<void> _selectTicket(String ticketId) async {
    try {
      await repository.selectTicket(ticketId);
      await _loadTickets(); // update UI after selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket selected!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select ticket: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebSocket Lotto Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(connectionStatus,
                        style: TextStyle(
                          color: connectionStatus == 'connected' ? Colors.green : Colors.red,
                        )),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _connect,
                          child: Text('Connect'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _disconnect,
                          child: Text('Disconnect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // User Info
            if (currentUser != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current User:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Username: ${currentUser!.username}'),
                      Text('Wallet: ฿${currentUser!.currentWallet.toStringAsFixed(2)}'),
                      Text('Role: ${currentUser!.role.name}'),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Actions
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: connectionStatus == 'connected' ? _login : null,
                          child: Text('Login'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: connectionStatus == 'connected' ? _loadTickets : null,
                          child: Text('Load Tickets'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Tickets List
            Text('Tickets (${tickets.length}):', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  return Card(
                    child: ListTile(
                      title: Text('Ticket ${ticket.number}'),
                      subtitle: Text('Price: ฿${ticket.price} - Status: ${ticket.status}'),
                      trailing: ticket.status == 'available'
                          ? ElevatedButton(
                              onPressed: () => _selectTicket(ticket.id),
                              child: Text('Select'),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }
}
