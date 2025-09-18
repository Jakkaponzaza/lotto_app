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
    baseUrl = dotenv.env['API_BASE_URL'] ??
        const String.fromEnvironment(
            'API_BASE_URL', defaultValue: 'wss://flutter-lotto-backend.onrender.com');

    _initializeSocket();
  }

  void _initializeSocket() {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(5000)
          .build(),
    );

    // Event handlers
    socket.onConnect((_) {
      _isConnected = true;
      _connectionController.add('connected');
      getAllTickets();
      if (_currentUser != null) getUserTickets(_currentUser!.id);
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add('disconnected');
    });

    socket.onConnectError((err) {
      _isConnected = false;
      _connectionController.add('error: $err');
    });

    socket.on('auth:success', (data) {
      _currentUser = AppUser.fromJson(data['user']);
      _userController.add(_currentUser!);
    });

    socket.on('tickets:list', (data) {
      _allTickets = (data as List).map((t) => Ticket.fromJson(t)).toList();
      _ticketsController.add(_allTickets);
    });

    socket.on('tickets:user-list', (data) {
      _userTickets = (data as List).map((t) => Ticket.fromJson(t)).toList();
      _userTicketsController.add(_userTickets);
    });

    socket.on('tickets:selected', (data) {
      _selectedTickets = List<String>.from(data['selectedTickets']);
    });

    socket.on('tickets:deselected', (data) {
      _selectedTickets = List<String>.from(data['selectedTickets']);
    });

    socket.on('purchase:success', (data) {
      _selectedTickets.clear();
      if (_currentUser != null) {
        _currentUser = _currentUser!
            .copyWith(wallet: (data['remainingWallet'] as num).toDouble());
        _userController.add(_currentUser!);
      }
      getAllTickets();
      if (_currentUser != null) getUserTickets(_currentUser!.id);
    });
  }

  Future<void> connect() async {
    if (!_isConnected) {
      socket.connect();
      await Future.any([
        connectionStream.firstWhere((status) => status == 'connected'),
        Future.delayed(const Duration(seconds: 8))
      ]);
    }
  }

  void disconnect() => socket.disconnect();

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
