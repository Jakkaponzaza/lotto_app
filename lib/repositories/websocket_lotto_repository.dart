// Dart imports
import 'dart:convert';
import 'dart:async';
import 'dart:io';

// Flutter & Third-party imports
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Internal imports - Models
import '../models.dart';

// Internal imports - Repositories
import 'lotto_repository.dart';

class WebSocketLottoRepository implements LottoRepository {
  late final String baseUrl;
  late IO.Socket socket;
  bool _isConnected = false;
  
  // Stream controllers for real-time updates
  final StreamController<List<Ticket>> _ticketsController = StreamController<List<Ticket>>.broadcast();
  final StreamController<List<Ticket>> _userTicketsController = StreamController<List<Ticket>>.broadcast();
  final StreamController<AppUser> _userController = StreamController<AppUser>.broadcast();
  final StreamController<SystemStats> _statsController = StreamController<SystemStats>.broadcast();
  final StreamController<DrawResult?> _drawController = StreamController<DrawResult?>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  // Current user session state
  AppUser? _currentUser;
  DrawResult? _latestDraw;
  List<String> _selectedTickets = [];
  List<Ticket> _allTickets = [];
  List<Ticket> _userTickets = [];

  // Getters for streams
  Stream<List<Ticket>> get ticketsStream => _ticketsController.stream;
  Stream<List<Ticket>> get userTicketsStream => _userTicketsController.stream;
  Stream<AppUser> get userStream => _userController.stream;
  Stream<SystemStats> get statsStream => _statsController.stream;
  Stream<DrawResult?> get drawStream => _drawController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  // Getters for current state
  AppUser? get currentUser => _currentUser;
  List<String> get selectedTickets => List.from(_selectedTickets); // Return copy to prevent external modification
  List<Ticket> get allTickets => _allTickets;
  List<Ticket> get userTickets => _userTickets;
  bool get isConnected => _isConnected;

  WebSocketLottoRepository() {
    baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    debugPrint('DEBUG: WebSocketLottoRepository initialized with baseUrl: $baseUrl');
    _initializeSocket();
  }

  void _initializeSocket() {
    debugPrint('DEBUG: Initializing WebSocket connection to $baseUrl');
    
    socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setTimeout(5000)
        .build());

    // Connection events
    socket.onConnect((_) {
      debugPrint('🔌 WebSocket connected');
      _isConnected = true;
      _connectionController.add('connected');
      
      // โหลด latest draw เมื่อเชื่อมต่อครั้งแรก
      getLatestDraw();
    });

    socket.onDisconnect((_) {
      debugPrint('🔌 WebSocket disconnected');
      _isConnected = false;
      _connectionController.add('disconnected');
    });

    socket.onConnectError((error) {
      debugPrint('❌ WebSocket connection error: $error');
      _connectionController.add('error: $error');
    });

    // Authentication events
    socket.on('auth:success', (data) {
      debugPrint('✅ Authentication successful');
      debugPrint('📝 Raw data received: $data');
      _currentUser = AppUser.fromJson(data['user']);
      debugPrint('📝 User parsed: ${_currentUser?.username}');
      _userController.add(_currentUser!);
      debugPrint('📢 User added to userStream');
    });

    socket.on('auth:error', (data) {
      debugPrint('❌ Authentication error: ${data['error']}');
      _connectionController.add('auth_error: ${data['error']}');
    });

    socket.on('auth:required', (data) {
      debugPrint('🔐 Authentication required');
      _connectionController.add('auth_required');
    });

    // Draw result events
    socket.on('draw:new-result', (data) {
      debugPrint('🏆 New draw result received');
      try {
        final drawData = data['drawResult'];
        if (drawData != null) {
          final drawResult = DrawResult.fromJson(drawData);
          _latestDraw = drawResult;
          _drawController.add(drawResult);
          debugPrint('🏆 Draw result updated: ${drawResult.id}');
        }
      } catch (e) {
        debugPrint('❌ Error processing draw result: $e');
      }
    });

    socket.on('draw:latest-result', (data) {
      debugPrint('📊 Latest draw result received');
      try {
        final drawData = data['drawResult'];
        if (drawData != null) {
          final drawResult = DrawResult.fromJson(drawData);
          _latestDraw = drawResult;
          _drawController.add(drawResult);
        } else {
          debugPrint('📊 No latest draw result available');
          _drawController.add(null);
        }
      } catch (e) {
        debugPrint('❌ Error processing latest draw result: $e');
      }
    });

    // Admin draw events
    socket.on('admin:draw-success', (data) {
      debugPrint('🎯 Draw success received');
      try {
        final drawData = data['drawResult'];
        if (drawData != null) {
          final drawResult = DrawResult.fromJson(drawData);
          _latestDraw = drawResult;
          _drawController.add(drawResult);
        }
      } catch (e) {
        debugPrint('❌ Error processing draw success: $e');
      }
    });

    socket.on('admin:draw-error', (data) {
      debugPrint('❌ Draw error received: ${data['error']}');
      // Error handling is managed by individual function calls
    });

    // Ticket events
    socket.on('tickets:list', (data) {
      debugPrint('🎫 Received tickets:list event');
      debugPrint('🎫 Raw data type: ${data.runtimeType}');
      debugPrint('🎫 Raw data length: ${data is List ? data.length : 'not a list'}');
      
      try {
        if (data is List) {
          debugPrint('🎫 Processing ${data.length} tickets...');
          final ticketsList = <Ticket>[];
          
          for (int i = 0; i < data.length; i++) {
            try {
              final ticketData = data[i];
              
              // Debug: แสดงข้อมูลตั๋วแรก
              if (i < 3) {
                debugPrint('🎫 Debug ticket $i: $ticketData');
                debugPrint('🎫 Types - id: ${ticketData['id'].runtimeType}, number: ${ticketData['number'].runtimeType}');
              }
              
              final ticket = Ticket.fromJson(ticketData);
              ticketsList.add(ticket);
              
              // Debug: แสดงตั๋วที่ parse สำเร็จ
              if (i < 3) {
                debugPrint('🎫 Parsed ticket $i: id=${ticket.id}, number=${ticket.number}, status=${ticket.status}');
              }
            } catch (e) {
              debugPrint('❌ Error parsing ticket $i: $e');
              // แสดงข้อมูลที่ทำให้ error
              if (i < 3) {
                debugPrint('🎫 Failed ticket data $i: ${data[i]}');
              }
            }
          }
          
          _allTickets = ticketsList;
          debugPrint('🎫 Successfully processed ${_allTickets.length} tickets');
          debugPrint('🎫 Sample tickets: ${_allTickets.take(3).map((t) => '${t.number}(${t.id})').toList()}');
          
          // ส่งข้อมูลไปยัง stream
          _ticketsController.add(_allTickets);
          debugPrint('🎫 Tickets added to stream controller successfully');
        } else {
          debugPrint('❌ Error: tickets:list data is not a List: $data');
          _ticketsController.add(<Ticket>[]);
        }
      } catch (e) {
        debugPrint('❌ Error processing tickets:list: $e');
        _ticketsController.add(<Ticket>[]);
      }
    });

    socket.on('tickets:user-list', (data) {
      debugPrint('🎫 Received user tickets: ${data.length} tickets');
      try {
        if (data is List) {
          final userTicketsList = (data as List).map((item) => Ticket.fromJson(item)).toList();
          _userTickets = userTicketsList;
          debugPrint('🎫 Successfully processed ${_userTickets.length} user tickets');
          
          // ส่งข้อมูลไปยัง user tickets stream
          _userTicketsController.add(_userTickets);
          debugPrint('🎫 User tickets added to stream controller successfully');
        } else {
          debugPrint('❌ Error: tickets:user-list data is not a List: $data');
          _userTicketsController.add(<Ticket>[]);
        }
      } catch (e) {
        debugPrint('❌ Error processing tickets:user-list: $e');
        _userTicketsController.add(<Ticket>[]);
      }
    });

    socket.on('tickets:selected', (data) {
      debugPrint('🎯 Ticket selected: ${data['ticketId']}');
      _selectedTickets = List<String>.from(data['selectedTickets']);
    });

    socket.on('tickets:deselected', (data) {
      debugPrint('❌ Ticket deselected: ${data['ticketId']}');
      _selectedTickets = List<String>.from(data['selectedTickets']);
    });

    socket.on('tickets:updated', (data) {
      debugPrint('🔄 Tickets updated: ${data['ticketIds']}');
      // ลบ cache และโหลดข้อมูลใหม่ทันที
      _allTickets.clear();
      getAllTickets();
    });

    // Purchase events
    socket.on('purchase:success', (data) {
      debugPrint('💰 Purchase successful: ${data['message']}');
      debugPrint('💰 Purchased tickets: ${data['purchasedTickets']}');
      debugPrint('💰 Remaining wallet: ${data['remainingWallet']}');
      
      // ลบ selected tickets
      _selectedTickets.clear();
      
      // อัพเดต wallet ของ user ทันที
      if (_currentUser != null) {
        final newWallet = (data['remainingWallet'] as num).toDouble();
        debugPrint('💰 Updating user wallet from ${_currentUser!.currentWallet} to $newWallet');
        _currentUser = _currentUser!.copyWith(wallet: newWallet);
        _userController.add(_currentUser!);
        debugPrint('💰 User wallet updated and broadcasted via userStream');
      }
      
      // ลบ cache และโหลดข้อมูลใหม่ทันที
      debugPrint('🔄 Clearing tickets cache and requesting fresh data...');
      _allTickets.clear();
      _userTickets.clear();
      
      // โหลดข้อมูลใหม่ทันทีเพื่อให้ UI ได้รับข้อมูลอัพเดต
      socket.emit('tickets:get-all');
      
      // โหลดตั๋วของผู้ใช้ใหม่ด้วย
      if (_currentUser != null) {
        socket.emit('tickets:get-user', {'userId': _currentUser!.userId});
        debugPrint('🔄 Requesting fresh user tickets for user: ${_currentUser!.userId}');
      }
      
      // ส่งสัญญาณสำเร็จไปยัง connection stream
      _connectionController.add('purchase_success: ซื้อสำเร็จ!');
    });

    socket.on('purchase:error', (data) {
      debugPrint('❌ Purchase error: ${data['error']}');
      _connectionController.add('purchase_error: ${data['error']}');
    });

    // Admin events
    socket.on('admin:stats', (data) {
      debugPrint('📊 Received admin stats');
      final stats = SystemStats(
        totalMembers: (data['totalMembers'] as num).toInt(),
        ticketsSold: (data['ticketsSold'] as num).toInt(),
        ticketsLeft: (data['ticketsLeft'] as num).toInt(),
        totalValue: _parseDouble(data['totalValue']),
      );
      _statsController.add(stats);
    });

    socket.on('admin:tickets-created', (data) {
      debugPrint('🎫 Tickets created: ${data['ticketsCreated']}');
      _allTickets.clear();
      _ticketsController.add(_allTickets);
      // Refresh tickets after creation
      getAllTickets();
    });

    socket.on('admin:reset-success', (data) {
      debugPrint('🔄 System reset successful');
      _allTickets.clear();
      _userTickets.clear();
      _selectedTickets.clear();
      _ticketsController.add(_allTickets);
      // Refresh tickets after reset
      getAllTickets();
    });

    // Session events
    socket.on('session:info', (data) {
      debugPrint('📋 Session info received');
    });

    // User events
    socket.on('user:joined', (data) {
      debugPrint('👤 User joined: ${data['username']}');
    });

    socket.on('user:left', (data) {
      debugPrint('👤 User left: ${data['username']}');
    });

    // Error events
    socket.on('error', (data) {
      debugPrint('❌ Server error: ${data['error']}');
      _connectionController.add('server_error: ${data['error']}');
    });
  }

  // Helper method to safely parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  // Connection management
  Future<void> connect() async {
    if (!_isConnected) {
      debugPrint('🔌 Connecting to WebSocket server...');
      
      try {
        socket.connect();
        
        // รอการเชื่อมต่อด้วย timeout
        await Future.any([
          connectionStream.firstWhere((status) => status == 'connected'),
          Future.delayed(const Duration(seconds: 8))
        ]);
        
        if (_isConnected) {
          debugPrint('✅ WebSocket connected successfully');
        } else {
          debugPrint('⚠️ WebSocket connection timeout');
        }
      } catch (e) {
        debugPrint('❌ WebSocket connection error: $e');
        _isConnected = false;
      }
    } else {
      debugPrint('🔌 WebSocket already connected');
    }
  }

  void disconnect() {
    if (_isConnected) {
      debugPrint('🔌 Disconnecting from WebSocket server...');
      socket.disconnect();
    }
  }

  // Authentication methods
  Future<AppUser> loginMember({
    required String username,
    required String password,
  }) async {
    debugPrint('🔐 Attempting WebSocket login for: $username');
    
    await connect();
    
    final completer = Completer<AppUser>();
    
    // Listen for auth success/error with proper event handling
    late StreamSubscription authSuccessSubscription;
    late StreamSubscription authErrorSubscription;
    
    // Listen for auth success
    authSuccessSubscription = userStream.listen((user) {
      debugPrint('✅ Auth success received for user: ${user.username}');
      debugPrint('🔍 Completing login with user: ${user.toString()}');
      authSuccessSubscription.cancel();
      authErrorSubscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(user);
        debugPrint('🎉 Login completer completed successfully');
      } else {
        debugPrint('⚠️ Login completer already completed');
      }
    });
    
    // Listen for auth errors
    authErrorSubscription = connectionStream.listen((status) {
      if (status.startsWith('auth_error:')) {
        debugPrint('❌ Auth error received: $status');
        authSuccessSubscription.cancel();
        authErrorSubscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception(status.replaceFirst('auth_error: ', '')));
        }
      }
    });

    // Send login request
    debugPrint('📤 Sending login request for: $username');
    socket.emit('auth:login', {
      'username': username,
      'password': password,
    });
    debugPrint('📤 Login request sent, waiting for response...');

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        authSuccessSubscription.cancel();
        authErrorSubscription.cancel();
        throw Exception('Login timeout - ไม่ได้รับการตอบกลับจากเซิร์ฟเวอร์');
      },
    );
  }

  Future<AppUser> registerMember({
    required String username,
    required String email,
    required String password,
    String? phone,
    int? wallet,
  }) async {
    debugPrint('📝 Attempting WebSocket registration for: $username');
    
    await connect();
    
    final completer = Completer<AppUser>();
    
    // Listen for auth success/error with proper event handling
    late StreamSubscription authSuccessSubscription;
    late StreamSubscription authErrorSubscription;
    
    // Listen for auth success
    authSuccessSubscription = userStream.listen((user) {
      debugPrint('✅ Registration success received for user: ${user.username}');
      authSuccessSubscription.cancel();
      authErrorSubscription.cancel();
      if (!completer.isCompleted) {
        completer.complete(user);
      }
    });
    
    // Listen for auth errors
    authErrorSubscription = connectionStream.listen((status) {
      if (status.startsWith('auth_error:')) {
        debugPrint('❌ Registration error received: $status');
        authSuccessSubscription.cancel();
        authErrorSubscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(Exception(status.replaceFirst('auth_error: ', '')));
        }
      }
    });

    // Send register request
    socket.emit('auth:register', {
      'username': username,
      'email': email,
      'phone': phone ?? '',
      'password': password,
      'wallet': wallet ?? 5000,
    });

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        authSuccessSubscription.cancel();
        authErrorSubscription.cancel();
        throw Exception('Registration timeout - ไม่ได้รับการตอบกลับจากเซิร์ฟเวอร์');
      },
    );
  }

  // Ticket management
  Future<void> getAllTickets() async {
    debugPrint('🎫 Requesting all tickets via WebSocket');
    await connect();
    debugPrint('🎫 WebSocket connected, sending tickets:get-all event');
    socket.emit('tickets:get-all');
    debugPrint('🎫 tickets:get-all event sent successfully');
  }

  Future<void> getUserTickets(String userId) async {
    debugPrint('🎫 Requesting user tickets via WebSocket');
    await connect();
    socket.emit('tickets:get-user', {'userId': int.tryParse(userId) ?? userId});
  }

  Future<void> selectTicket(String ticketId) async {
    debugPrint('🎯 Selecting ticket: $ticketId');
    await connect();
    
    // เพิ่มใน local state
    if (!_selectedTickets.contains(ticketId)) {
      _selectedTickets.add(ticketId);
      debugPrint('🎯 Added to local selection: $ticketId');
      debugPrint('🎯 Current local selection: $_selectedTickets');
    }
    
    socket.emit('tickets:select', {'ticketId': ticketId});
  }

  Future<void> deselectTicket(String ticketId) async {
    debugPrint('❌ Deselecting ticket: $ticketId');
    await connect();
    
    // ลบจาก local state
    _selectedTickets.remove(ticketId);
    debugPrint('❌ Removed from local selection: $ticketId');
    debugPrint('❌ Current local selection: $_selectedTickets');
    
    socket.emit('tickets:deselect', {'ticketId': ticketId});
  }

  Future<void> purchaseSelectedTickets() async {
    debugPrint('💰 Purchasing selected tickets: $_selectedTickets');
    debugPrint('💰 Selected tickets count: ${_selectedTickets.length}');
    await connect();
    
    if (_selectedTickets.isEmpty) {
      debugPrint('❌ No tickets selected in repository!');
      debugPrint('❌ Repository state: selectedTickets=$_selectedTickets');
      throw Exception('ไม่มีลอตเตอรี่ที่เลือก');
    }
    
    // สร้าง Completer เพื่อรอผลลัพธ์การซื้อ
    final completer = Completer<void>();
    Timer? timeoutTimer;
    StreamSubscription? subscription;
    
    // ฟัง purchase events
    subscription = connectionStream.listen((status) {
      if (status.startsWith('purchase_success:')) {
        if (!completer.isCompleted) {
          debugPrint('✅ Purchase completed successfully');
          timeoutTimer?.cancel();
          subscription?.cancel();
          completer.complete();
        }
      } else if (status.startsWith('purchase_error:')) {
        if (!completer.isCompleted) {
          final error = status.replaceFirst('purchase_error: ', '');
          debugPrint('❌ Purchase failed: $error');
          timeoutTimer?.cancel();
          subscription?.cancel();
          completer.completeError(Exception(error));
        }
      }
    });
    
    // ตั้ง timeout (15 วินาที)
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        debugPrint('❌ Purchase timeout');
        subscription?.cancel();
        completer.completeError(Exception('การซื้อใช้เวลานานเกินไป - กรุณาลองใหม่'));
      }
    });
    
    // ส่งคำขอชื้อ
    socket.emit('tickets:purchase', {
      'ticketIds': _selectedTickets,
    });
    
    // รอผลลัพธ์
    await completer.future;
  }

  // Admin methods
  Future<void> getAdminStats() async {
    debugPrint('📊 Requesting admin stats via WebSocket');
    await connect();
    socket.emit('admin:get-stats');
  }

  Future<void> createLotteryTickets() async {
    debugPrint('🎫 Requesting lottery tickets creation via WebSocket');
    await connect();
    socket.emit('admin:create-tickets');
  }

  Future<void> resetSystem() async {
    debugPrint('🔄 Requesting system reset via WebSocket');
    await connect();
    socket.emit('admin:reset');
  }

  // Implementation of LottoRepository interface
  @override
  Future<AppUser> getOwner() async {
    // For WebSocket, we'll return current user or mock data
    if (_currentUser != null) {
      return _currentUser!;
    }
    throw Exception('No authenticated user');
  }

  @override
  Future<AppUser> loginOrRegisterMember({
    required String username,
    int? initialWallet,
  }) async {
    // Try login first, if fails, register
    try {
      return await loginMember(username: username, password: 'default');
    } catch (e) {
      return await registerMember(
        username: username,
        email: '$username@example.com',
        password: 'default',
        wallet: initialWallet ?? 5000,
      );
    }
  }

  @override
  Future<List<Ticket>> listAllTickets() async {
    debugPrint('🎫 WebSocket: listAllTickets called');
    
    try {
      await connect();
      
      // ส่งคำขอดึงตั๋วทั้งหมด (ไม่ใช้ cache)
      debugPrint('🎫 WebSocket: Requesting fresh tickets...');
      socket.emit('tickets:get-all');
      debugPrint('🎫 WebSocket: tickets:get-all event sent');
      
      // ใช้ Completer เพื่อจัดการ timeout และ error อย่างมั่นคง
      debugPrint('🎫 WebSocket: Waiting for tickets response...');
      
      final completer = Completer<List<Ticket>>();
      Timer? timeoutTimer;
      StreamSubscription? subscription;
      
      // ตั้ง timeout timer (10 วินาที - ลดลงเพื่อความเร็ว)
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('❌ WebSocket: Timeout waiting for tickets - returning current cache');
          subscription?.cancel();
          completer.complete(_allTickets); // คืน cache ถ้า timeout
        }
      });
      
      // ฟัง tickets stream
      subscription = ticketsStream.listen(
        (tickets) {
          if (!completer.isCompleted) {
            debugPrint('🎫 WebSocket: Received ${tickets.length} tickets from stream');
            timeoutTimer?.cancel();
            subscription?.cancel();
            completer.complete(tickets);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            debugPrint('❌ WebSocket: Stream error: $error');
            timeoutTimer?.cancel();
            subscription?.cancel();
            completer.complete(_allTickets);
          }
        },
      );
      
      final result = await completer.future;
      debugPrint('🎫 WebSocket: listAllTickets returning ${result.length} tickets');
      return result;
      
    } catch (e) {
      debugPrint('❌ WebSocket: Error in listAllTickets: $e');
      return _allTickets;
    }
  }

  @override
  Future<List<Ticket>> listUserTickets(String userId) async {
    debugPrint('🎫 WebSocket: listUserTickets called for userId: $userId');
    
    try {
      await connect();
      
      // ส่งคำขอดึงตั๋วของผู้ใช้ (ไม่ใช้ cache)
      debugPrint('🎫 WebSocket: Requesting fresh user tickets...');
      socket.emit('tickets:get-user', {'userId': int.tryParse(userId) ?? userId});
      debugPrint('🎫 WebSocket: tickets:get-user event sent');
      
      // ใช้ Completer เพื่อจัดการ timeout และ error อย่างมั่นคง
      debugPrint('🎫 WebSocket: Waiting for user tickets response...');
      
      final completer = Completer<List<Ticket>>();
      Timer? timeoutTimer;
      StreamSubscription? subscription;
      
      // ตั้ง timeout timer (8 วินาที)
      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          debugPrint('❌ WebSocket: Timeout waiting for user tickets - returning current cache');
          subscription?.cancel();
          completer.complete(_userTickets); // คืน cache ถ้า timeout
        }
      });
      
      // ฟัง user tickets stream
      subscription = userTicketsStream.listen(
        (tickets) {
          if (!completer.isCompleted) {
            debugPrint('🎫 WebSocket: Received ${tickets.length} user tickets from stream');
            timeoutTimer?.cancel();
            subscription?.cancel();
            completer.complete(tickets);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            debugPrint('❌ WebSocket: User tickets stream error: $error');
            timeoutTimer?.cancel();
            subscription?.cancel();
            completer.complete(_userTickets);
          }
        },
      );
      
      final result = await completer.future;
      debugPrint('🎫 WebSocket: listUserTickets returning ${result.length} user tickets');
      return result;
      
    } catch (e) {
      debugPrint('❌ WebSocket: Error in listUserTickets: $e');
      return _userTickets;
    }
  }

  @override
  Future<AppUser?> purchaseTickets({
    required String userId,
    required List<String> ticketIds,
  }) async {
    // Select all tickets first
    for (final ticketId in ticketIds) {
      await selectTicket(ticketId);
    }
    
    // Purchase selected tickets
    await purchaseSelectedTickets();
    
    return _currentUser;
  }

  @override
  Future<DrawResult> drawPrizes({
    required String poolType,
    required List<int> rewards,
  }) async {
    debugPrint('🎯 WebSocket: drawPrizes called with poolType: $poolType, rewards: $rewards');
    
    if (!socket.connected) {
      throw StateError('WebSocket not connected');
    }
    
    // สร้าง Completer เพื่อรอผลลัพธ์
    final completer = Completer<DrawResult>();
    Timer? timeoutTimer;
    
    try {
      // ฟังเหตุการณ์สำเร็จ
      late void Function(dynamic) successHandler;
      late void Function(dynamic) errorHandler;
      
      successHandler = (data) {
        if (!completer.isCompleted) {
          debugPrint('🎯 WebSocket: Received draw success');
          timeoutTimer?.cancel();
          socket.off('admin:draw-success', successHandler);
          socket.off('admin:draw-error', errorHandler);
          
          final drawData = data['drawResult'];
          final drawResult = DrawResult.fromJson(drawData);
          
          // อัปเดต _latestDraw
          _latestDraw = drawResult;
          
          completer.complete(drawResult);
        }
      };
      
      // ฟังเหตุการณ์ผิดพลาด
      errorHandler = (data) {
        if (!completer.isCompleted) {
          debugPrint('❌ WebSocket: Draw error: ${data['error']}');
          timeoutTimer?.cancel();
          socket.off('admin:draw-success', successHandler);
          socket.off('admin:draw-error', errorHandler);
          
          completer.completeError(StateError(data['error'] ?? 'เกิดข้อผิดพลาดในการออกรางวัล'));
        }
      };
      
      socket.on('admin:draw-success', successHandler);
      socket.on('admin:draw-error', errorHandler);
      
      // ตั้ง timeout
      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ WebSocket: Draw prizes timeout');
          socket.off('admin:draw-success', successHandler);
          socket.off('admin:draw-error', errorHandler);
          completer.completeError(TimeoutException('การออกรางวัลใช้เวลานานเกินไป', const Duration(seconds: 30)));
        }
      });
      
      // ส่งคำขอออกรางวัล
      socket.emit('admin:draw-prizes', {
        'poolType': poolType,
        'rewards': rewards,
      });
      
      debugPrint('🎯 WebSocket: Draw prizes request sent');
      
      return await completer.future;
      
    } catch (e) {
      debugPrint('❌ WebSocket: Error in drawPrizes: $e');
      timeoutTimer?.cancel();
      socket.off('admin:draw-success');
      socket.off('admin:draw-error');
      rethrow;
    }
  }

  @override
  Future<DrawResult?> getLatestDraw() async {
    debugPrint('📊 WebSocket: getLatestDraw called');
    
    if (!socket.connected) {
      debugPrint('❌ WebSocket: Not connected, returning cached draw');
      return _latestDraw;
    }
    
    // สร้าง Completer เพื่อรอผลลัพธ์
    final completer = Completer<DrawResult?>();
    Timer? timeoutTimer;
    
    try {
      // ฟังเหตุการณ์ผลลัพธ์
      late void Function(dynamic) resultHandler;
      
      resultHandler = (data) {
        if (!completer.isCompleted) {
          debugPrint('📊 WebSocket: Received latest draw result');
          timeoutTimer?.cancel();
          socket.off('draw:latest-result', resultHandler);
          
          final drawData = data['drawResult'];
          if (drawData != null) {
            final drawResult = DrawResult.fromJson(drawData);
            _latestDraw = drawResult;
            completer.complete(drawResult);
          } else {
            debugPrint('📊 WebSocket: No draw result found');
            _latestDraw = null;
            completer.complete(null);
          }
        }
      };
      
      socket.on('draw:latest-result', resultHandler);
      
      // ตั้ง timeout
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ WebSocket: Get latest draw timeout, returning cached');
          socket.off('draw:latest-result', resultHandler);
          completer.complete(_latestDraw);
        }
      });
      
      // ส่งคำขอดึงผลรางวัลล่าสุด
      socket.emit('draw:get-latest');
      
      debugPrint('📊 WebSocket: Get latest draw request sent');
      
      return await completer.future;
      
    } catch (e) {
      debugPrint('❌ WebSocket: Error in getLatestDraw: $e');
      timeoutTimer?.cancel();
      socket.off('draw:latest-result');
      return _latestDraw;
    }
  }

  @override
  Future<bool> claimTicket({
    required String userId,
    required String ticketId,
  }) async {
    throw UnimplementedError('Claim ticket not implemented for WebSocket');
  }

  @override
  Future<SystemStats> getSystemStats() async {
    await getAdminStats();
    return await statsStream.first;
  }

  @override
  Future<void> resetAll() async {
    await resetSystem();
    // Clear local state
    _allTickets.clear();
    _userTickets.clear();
    _selectedTickets.clear();
    _ticketsController.add(_allTickets);
  }

  // Cleanup
  void dispose() {
    debugPrint('🧹 Disposing WebSocket repository');
    disconnect();
    _ticketsController.close();
    _userTicketsController.close();
    _userController.close();
    _statsController.close();
    _drawController.close();
    _connectionController.close();
  }
}