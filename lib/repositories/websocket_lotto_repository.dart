// websocket_lotto_repository.dart
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models.dart';
import 'lotto_repository.dart';

class WebSocketLottoRepository implements LottoRepository {
  late final String baseUrl;
  late IO.Socket socket;
  bool _isConnected = false;

  final StreamController<List<Ticket>> _ticketsController =
      StreamController<List<Ticket>>.broadcast();
  final StreamController<List<Ticket>> _userTicketsController =
      StreamController<List<Ticket>>.broadcast();
  final StreamController<AppUser> _userController =
      StreamController<AppUser>.broadcast();
  final StreamController<String> _connectionController =
      StreamController<String>.broadcast();

  AppUser? _currentUser;
  List<String> _selectedTickets = [];
  List<Ticket> _allTickets = [];
  List<Ticket> _userTickets = [];

  // Streams
  Stream<List<Ticket>> get ticketsStream => _ticketsController.stream;
  Stream<List<Ticket>> get userTicketsStream => _userTicketsController.stream;
  Stream<AppUser> get userStream => _userController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  AppUser? get currentUser => _currentUser;
  List<String> get selectedTickets => List.from(_selectedTickets);
  List<Ticket> get allTickets => _allTickets;
  List<Ticket> get userTickets => _userTickets;
  bool get isConnected => _isConnected;

  WebSocketLottoRepository() {
    // ใช้ API_BASE_URL จาก .env หรือ Dart define, fallback default
    String baseEnvUrl = dotenv.env['API_BASE_URL'] ??
        const String.fromEnvironment(
            'API_BASE_URL', defaultValue: 'wss://flutter-lotto-backend.onrender.com');

    // Remove any trailing slash and clean up the URL
    baseUrl = baseEnvUrl.replaceAll(RegExp(r'/$'), '');
    
    // Special handling for Render URLs to prevent port issues
    if (baseUrl.contains('onrender.com')) {
      try {
        // Parse the URL using Dart's Uri class
        final uri = Uri.parse(baseUrl);
        
        // For Render URLs, we must be very careful about port handling
        // Reconstruct URL without any port specification to avoid :0 issue
        if (uri.scheme == 'wss') {
          baseUrl = 'wss://${uri.host}';
        } else if (uri.scheme == 'ws') {
          baseUrl = 'ws://${uri.host}';
        } else {
          // Fallback
          baseUrl = 'wss://${uri.host}';
        }
        
        print('DEBUG: Parsed URI - scheme: ${uri.scheme}, host: ${uri.host}, port: ${uri.port}');
      } catch (e) {
        print('DEBUG: Error parsing URI: $e');
        // Manual parsing as fallback
        if (baseUrl.startsWith('wss://')) {
          String hostPart = baseUrl.substring(6);
          // Remove everything after the first slash (path)
          if (hostPart.contains('/')) {
            hostPart = hostPart.split('/')[0];
          }
          // Remove everything after the first colon (port)
          if (hostPart.contains(':')) {
            hostPart = hostPart.split(':')[0];
          }
          baseUrl = 'wss://$hostPart';
        } else if (baseUrl.startsWith('ws://')) {
          String hostPart = baseUrl.substring(5);
          // Remove everything after the first slash (path)
          if (hostPart.contains('/')) {
            hostPart = hostPart.split('/')[0];
          }
          // Remove everything after the first colon (port)
          if (hostPart.contains(':')) {
            hostPart = hostPart.split(':')[0];
          }
          baseUrl = 'ws://$hostPart';
        }
      }
    }
    
    // Ensure it's using wss:// for secure WebSocket connection
    if (!baseUrl.startsWith('wss://') && !baseUrl.startsWith('ws://')) {
      baseUrl = 'wss://$baseUrl';
    }

    print('DEBUG: Final baseUrl for WebSocket connection: $baseUrl');

    _initializeSocket();
  }

  void _initializeSocket() {
    print('DEBUG: Initializing WebSocket connection to: $baseUrl');
    
    // Try a different approach with more explicit options
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Force WebSocket transport only
          .disableAutoConnect() // We'll connect manually
          .setTimeout(20000) // Increase timeout
          .setForceNew(true) // Force new connection
          .setReconnection(true) // Enable reconnection
          .setReconnectionAttempts(10) // Increase reconnection attempts
          .setReconnectionDelay(2000) // Set reconnection delay
          .setReconnectionDelayMax(5000) // Set max reconnection delay
          .setRandomizationFactor(0.5) // Set randomization factor
          .setPath('/socket.io') // Explicitly set path
          .setQuery({
            'EIO': '4', // Engine.IO version
            'transport': 'websocket' // Force WebSocket transport
          })
          .setExtraHeaders({
            // Add headers to help with connection
            'Connection': 'Upgrade',
            'Upgrade': 'websocket',
          })
          .build(),
    );
    
    // Add detailed connection state logging
    socket.onConnect((_) {
      print('✅ WebSocket CONNECTED');
      print('🆔 Socket ID: ${socket.id}');
      print('🔗 Connected: ${socket.connected}');
      print('🛣️ Transport: ${socket.io?.transport?.name ?? "unknown"}');
      _isConnected = true;
      _connectionController.add('connected');
      getAllTickets();
      if (_currentUser != null) getUserTickets(_currentUser!.id);
    });

    socket.onDisconnect((_) {
      print('❌ WebSocket DISCONNECTED');
      print('🆔 Socket ID: ${socket.id}');
      print('🔗 Connected: ${socket.connected}');
      _isConnected = false;
      _connectionController.add('disconnected');
    });

    socket.onConnectError((err) {
      print('⚠️ WebSocket CONNECTION ERROR');
      print('🆔 Socket ID: ${socket.id}');
      print('🔗 Connected: ${socket.connected}');
      print('📝 Error details: $err');
      _isConnected = false;
      _connectionController.add('error: $err');
    });
    
    // Add additional event listeners for debugging
    socket.on('connect_timeout', (_) {
      print('⏰ WebSocket CONNECT TIMEOUT');
    });
    
    socket.on('reconnect', (attempt) {
      print('🔁 WebSocket RECONNECT ATTEMPT: $attempt');
    });
    
    socket.on('reconnect_attempt', (attempt) {
      print('🔁 WebSocket RECONNECT ATTEMPT: $attempt');
    });
    
    socket.on('reconnect_failed', (_) {
      print('❌ WebSocket RECONNECT FAILED');
    });
    
    socket.on('reconnect_error', (err) {
      print('⚠️ WebSocket RECONNECT ERROR: $err');
    });
    
    socket.on('error', (err) {
      print('🚨 WebSocket GENERAL ERROR: $err');
    });
  }

  Future<void> connect() async {
    if (!_isConnected) {
      print('DEBUG: Attempting to connect to WebSocket');
      print('DEBUG: Current socket connected state: ${socket.connected}');
      print('DEBUG: Current socket ID: ${socket.id}');
      print('DEBUG: Base URL: $baseUrl');
      
      try {
        // Add a small delay before connecting
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Ensure socket is in a clean state
        if (socket.connected) {
          print('DEBUG: Socket already connected, disconnecting first');
          socket.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // Listen for connection events before connecting
        final connectionCompleter = Completer<String>();
        final subscription = connectionStream.listen((status) {
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.complete(status);
          }
        });
        
        print('DEBUG: Calling socket.connect()');
        socket.connect();
        
        print('DEBUG: Waiting for connection...');
        // Wait for connection with a longer timeout and better error handling
        String connectionStatus;
        try {
          connectionStatus = await connectionCompleter.future.timeout(const Duration(seconds: 25));
          print('DEBUG: Connection status received: $connectionStatus');
        } on TimeoutException {
          print('DEBUG: Connection timeout after 25 seconds');
          connectionStatus = 'timeout';
        } catch (e) {
          print('DEBUG: Connection error: $e');
          connectionStatus = 'error';
        } finally {
          await subscription.cancel();
        }
        
        print('DEBUG: Connection attempt completed with status: $connectionStatus');
        print('DEBUG: Final socket connected state: ${socket.connected}');
        print('DEBUG: Final socket ID: ${socket.id}');
      } catch (e, stackTrace) {
        print('DEBUG: Connection attempt failed with error: $e');
        print('DEBUG: Stack trace: $stackTrace');
        // Don't rethrow, just continue
      }
    } else {
      print('DEBUG: Already connected, skipping connection attempt');
    }
  }

  void disconnect() {
    print('DEBUG: Disconnecting WebSocket');
    socket.disconnect();
  }

  Future<AppUser> loginMember(
      {required String username, required String password}) async {
    await connect();
    final completer = Completer<AppUser>();

    late StreamSubscription userSub;
    userSub = userStream.listen((user) {
      if (!completer.isCompleted) completer.complete(user);
      userSub.cancel();
    });

    socket.emit('auth:login', {'username': username, 'password': password});

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      userSub.cancel();
      throw Exception('Login timeout');
    });
  }

  Future<void> getAllTickets() async {
    await connect();
    socket.emit('tickets:get-all');
  }

  Future<void> getUserTickets(String userId) async {
    await connect();
    socket.emit('tickets:get-user', {'userId': userId});
  }

  Future<void> selectTicket(String ticketId) async {
    await connect();
    if (!_selectedTickets.contains(ticketId)) {
      _selectedTickets.add(ticketId);
      socket.emit('tickets:select', {'ticketId': ticketId});
    }
  }

  Future<void> deselectTicket(String ticketId) async {
    await connect();
    if (_selectedTickets.contains(ticketId)) {
      _selectedTickets.remove(ticketId);
      socket.emit('tickets:deselect', {'ticketId': ticketId});
    }
  }

  Future<void> purchaseSelectedTickets() async {
    if (_currentUser == null || _selectedTickets.isEmpty) return;
    socket.emit('purchase:tickets', {
      'userId': _currentUser!.id,
      'ticketIds': _selectedTickets,
    });
  }

  Future<AppUser> registerMember({
    required String username,
    required String email,
    required String password,
    String? phone,
    int? wallet,
  }) async {
    await connect();
    final completer = Completer<AppUser>();

    late StreamSubscription userSub;
    userSub = userStream.listen((user) {
      if (!completer.isCompleted) completer.complete(user);
      userSub.cancel();
    });

    socket.emit('auth:register', {
      'username': username,
      'email': email,
      'password': password,
      'phone': phone ?? '',
      'wallet': wallet ?? 0,
    });

    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      userSub.cancel();
      throw Exception('Register timeout');
    });
  }

  @override
  Future<AppUser?> purchaseTickets(
      {required String userId, required List<String> ticketIds}) async {
    await connect();
    socket.emit('purchase:tickets', {'userId': userId, 'ticketIds': ticketIds});
    return _currentUser;
  }

  @override
  Future<List<Ticket>> listAllTickets() async {
    await getAllTickets();
    return ticketsStream.first;
  }

  @override
  Future<List<Ticket>> listUserTickets(String userId) async {
    await getUserTickets(userId);
    return userTicketsStream.first;
  }

  @override
  void dispose() {
    disconnect();
    _ticketsController.close();
    _userTicketsController.close();
    _userController.close();
    _connectionController.close();
  }

  // ฟังก์ชันอื่น ๆ ของ LottoRepository ที่ไม่จำเป็นตอนนี้
  @override
  Future<DrawResult?> getLatestDraw() async => null;

  @override
  Future<AppUser> getOwner() async {
    if (_currentUser != null) return _currentUser!;
    throw Exception('No authenticated user');
  }

  @override
  Future<SystemStats> getSystemStats() {
    throw UnimplementedError();
  }

  @override
  Future<void> resetAll() async {
    await connect();
    socket.emit('system:reset');
  }

  @override
  Future<AppUser> loginOrRegisterMember(
      {required String username, int? initialWallet}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> claimTicket({required String userId, required String ticketId}) async =>
      false;

  Future<void> createLotteryTickets() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}