// ======================================================
// 🔧 APPLICATION STATE MANAGEMENT
// ======================================================
// File: lib/services/app_state.dart
// Purpose: จัดการสถานะของแอปพลิเคชันทั้งหมด
// Features:
//   - User authentication state
//   - Ticket management
//   - Purchase operations
//   - Prize claiming
//   - System statistics
// ======================================================

// 📦 FLUTTER & THIRD-PARTY IMPORTS
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

// 🏗️ INTERNAL IMPORTS - DATA MODELS
import '../models.dart';

// 💾 INTERNAL IMPORTS - DATA REPOSITORIES
import '../repositories/websocket_lotto_repository.dart';
import '../repositories/lotto_repository.dart';

// 🔄 DART CORE IMPORTS
import 'dart:async';

// ======================================================
//  MAIN APPLICATION STATE CLASS
// ======================================================
class LottoAppState extends ChangeNotifier {
  // REPOSITORY DEPENDENCY
  final LottoRepository repo;

  // LOADING & ERROR STATES
  bool isLoading = false;
  String? errorMessage;
  
  // STREAM SUBSCRIPTIONS FOR REAL-TIME UPDATES
  StreamSubscription? _userStreamSubscription;
  StreamSubscription? _ticketsStreamSubscription;
  StreamSubscription? _userTicketsStreamSubscription;

  LottoAppState(this.repo) {
    _setupRealtimeListeners();
    initializeApp();
  }
  
  // ตั้งค่า real-time listeners สำหรับ WebSocket
  void _setupRealtimeListeners() {
    if (repo is WebSocketLottoRepository) {
      final wsRepo = repo as WebSocketLottoRepository;
      
      // ฟัง user updates สำหรับการอัพเดท wallet แบบ real-time
      _userStreamSubscription = wsRepo.userStream.listen((user) {
        debugPrint('🔄 Real-time user update received: wallet=${user.currentWallet}');
        if (currentUser != null && user.userId == currentUser!.userId) {
          debugPrint('🔄 Updating current user wallet from ${currentUser!.currentWallet} to ${user.currentWallet}');
          currentUser = user;
          notifyListeners();
          debugPrint('🔄 UI notified of wallet change');
        }
      });
      
      // ฟัง tickets updates สำหรับการอัพเดตรายการตั๋ว real-time
      _ticketsStreamSubscription = wsRepo.ticketsStream.listen((tickets) {
        debugPrint('🎫 Real-time tickets update received: ${tickets.length} tickets');
        allTickets = tickets;
        notifyListeners();
        debugPrint('🎫 UI notified of tickets change');
      });
      
      // ฟัง user tickets updates สำหรับการอัพเดตลอตเตอรี่ของฉัน real-time
      _userTicketsStreamSubscription = wsRepo.userTicketsStream.listen((tickets) {
        debugPrint('🎫 Real-time user tickets update received: ${tickets.length} user tickets');
        userTickets = tickets;
        notifyListeners();
        debugPrint('🎫 UI notified of user tickets change');
      });
    }
  }

  // ======================================================
  // APPLICATION INITIALIZATION
  // ======================================================

  Future<void> initializeApp() async {
    if (isLoading) {
      debugPrint('DEBUG: App already initializing, skipping...');
      return;
    }
    
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      debugPrint('DEBUG: Starting app initialization...');
      
      // โหลดข้อมูลตั๋วก่อน - สำคัญที่สุด
      await loadTickets();
      debugPrint('DEBUG: Tickets loaded successfully');
      
      // ไม่โหลดผลรางวัลตอน init เพื่อความเร็ว
      // จะโหลดทีหลังเมื่อมีการ login
      
      debugPrint('DEBUG: App initialization completed successfully');
      isLoading = false;
      
    } catch (e) {
      debugPrint('DEBUG: App initialization error: $e');
      isLoading = false;
      errorMessage = 'ไม่สามารถเริ่มต้นแอปได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }
    
    notifyListeners();
  }

  // ======================================================
  // APPLICATION DATA STATE
  // ======================================================

  final formatter = NumberFormat.decimalPattern('th');

  // USER STATE
  AppUser? currentUser;

  // TICKET DATA
  List<Ticket> allTickets = [];
  List<Ticket> userTickets = [];
  final Set<String> selected = {}; // Selected tickets for purchase

  // DRAW & PRIZE DATA
  DrawResult? latestDraw;

  // ======================================================
  // USER MANAGEMENT METHODS
  // ======================================================

  void setCurrentUserFromJson(Map<String, dynamic> userData) {
    currentUser = AppUser.fromJson(userData);
    notifyListeners();
  }

  // ======================================================
  // UI HELPER GETTERS
  // ======================================================

  int get lottoPrice => LottoConstants.lottoPrice;

  String get walletText {
    final wallet = currentUser?.wallet ?? 0;
    debugPrint('DEBUG: walletText getter called - wallet: $wallet');
    return currentUser == null
        ? 'ยอดเงิน: 0 บาท'
        : 'ยอดเงิน: ${formatter.format(wallet)} บาท';
  }

  List<String> get availableTickets => allTickets
      .where((t) => t.status == 'available')
      .map((t) => t.number)
      .toList();

  // ======================================================
  // TICKET MANAGEMENT METHODS
  // ======================================================

  Future<void> loadTickets() async {
    try {
      debugPrint('DEBUG: Loading tickets...');
      
      if (repo is WebSocketLottoRepository) {
        final wsRepo = repo as WebSocketLottoRepository;
        
        // รอให้ WebSocket เชื่อมต่อก่อน
        if (!wsRepo.isConnected) {
          debugPrint('DEBUG: WebSocket not connected, attempting to connect...');
          await wsRepo.connect();
        }
        
        // โหลดตั๋วทั้งหมด (บังคับให้โหลดข้อมูลใหม่ทุกครั้ง)
        debugPrint('DEBUG: Requesting all tickets from WebSocket...');
        final freshTickets = await wsRepo.listAllTickets();
        
        // อัพเดต allTickets ทันที
        allTickets = freshTickets;
        
        debugPrint('DEBUG: Received ${allTickets.length} tickets from WebSocket');
      } else {
        // สำหรับ repository อื่นๆ
        allTickets = await repo.listAllTickets();
      }
      
      debugPrint('DEBUG: Total tickets loaded: ${allTickets.length}');
      if (allTickets.isNotEmpty) {
        debugPrint('DEBUG: Sample tickets: ${allTickets.take(3).map((t) => '${t.number}(${t.status})').toList()}');
      }

      // ไม่โหลด user tickets ตอน init เพื่อความเร็ว
      // จะโหลดหลัง login แทน
      
      // อัพเดต UI
      notifyListeners();
      
    } catch (e) {
      debugPrint('DEBUG: Error loading tickets: $e');
      // ตั้งค่า default เพื่อป้องกันแอป crash
      allTickets = [];
      userTickets = [];
      errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูลตั๋ว: $e';
      notifyListeners();
    }
  }

  // โหลดตั๋วของผู้ใช้แยกต่างหาก
  Future<void> loadUserTickets() async {
    if (currentUser == null) {
      debugPrint('DEBUG: No current user - cannot load user tickets');
      return;
    }
    
    try {
      debugPrint('DEBUG: Loading user tickets for: ${currentUser!.username}');
      userTickets = await repo.listUserTickets(currentUser!.id);
      debugPrint('DEBUG: Loaded ${userTickets.length} user tickets');
      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG: Error loading user tickets: $e');
      userTickets = [];
      notifyListeners();
    }
  }

  Future<void> loginOwner() async {
    currentUser = await repo.getOwner();
    await loadTickets();
    await loadLatestDraw(); // เพิ่มเพื่อโหลดผลรางวัล
    notifyListeners();
  }

  bool get isAdmin =>
      currentUser?.role == UserRole.admin ||
      currentUser?.role == UserRole.owner;

  Future<void> loginOrRegisterMember(String username,
      {int? initialWallet}) async {
    currentUser = await repo.loginOrRegisterMember(
      username: username,
      initialWallet: initialWallet,
    );
    await loadTickets();
    await loadLatestDraw(); // เพิ่มเพื่อโหลดผลรางวัล
    notifyListeners();
  }

  Future<void> registerMember({
    required String username,
    required String email,
    required String password,
    String? phone,
    int? initialWallet,
  }) async {
    if (repo is WebSocketLottoRepository) {
      final wsRepo = repo as WebSocketLottoRepository;
      currentUser = await wsRepo.registerMember(
        username: username,
        email: email,
        password: password,
        phone: phone,
        wallet: initialWallet,
      );
    } else {
      currentUser = await repo.loginOrRegisterMember(
        username: username,
        initialWallet: initialWallet,
      );
    }
    await loadTickets();
    await loadLatestDraw(); // เพิ่มเพื่อโหลดผลรางวัล
    notifyListeners();
  }

  Future<void> loginMember({
    required String username,
    required String password,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      debugPrint('DEBUG: Attempting login for user: $username');

      if (repo is WebSocketLottoRepository) {
        final wsRepo = repo as WebSocketLottoRepository;
        
        // ตรวจสอบการเชื่อมต่อก่อน
        if (!wsRepo.isConnected) {
          debugPrint('DEBUG: WebSocket not connected, connecting...');
          await wsRepo.connect();
        }
        
        final response = await wsRepo.loginMember(
          username: username,
          password: password,
        );

        debugPrint('DEBUG: Login response received: ${response.toString()}');

        currentUser = response;
        
        // โหลดข้อมูลหลัง login สำเร็จ
        try {
          debugPrint('DEBUG: Loading user-specific data after login...');
          await loadUserTickets(); // โหลดตั๋วของผู้ใช้
          
          // เริ่มฟัง user tickets real-time updates หลัง login
          if (repo is WebSocketLottoRepository) {
            final wsRepo = repo as WebSocketLottoRepository;
            wsRepo.getUserTickets(currentUser!.id);
            debugPrint('DEBUG: Started listening for user tickets updates');
          }
        } catch (e) {
          debugPrint('DEBUG: Error loading user data after login: $e');
          // ไม่ให้ error นี้บล็อกการ login
        }
        
        isLoading = false;
        notifyListeners();

        debugPrint('DEBUG: Login successful for ${currentUser?.username}, wallet: ${currentUser?.wallet}');
      } else {
        throw Exception('ระบบนี้รองรับเฉพาะ WebSocket เท่านั้น');
      }
    } catch (e) {
      debugPrint('DEBUG: Login failed: $e');
      isLoading = false;
      currentUser = null;
      errorMessage = 'การเข้าสู่ระบบล้มเหลว: $e';
      notifyListeners();
      rethrow; // ส่ง error ต่อเพื่อให้ UI จัดการ
    }
  }

  // ======================================================
  // PURCHASE MANAGEMENT METHODS
  // ======================================================

  void toggleSelect(String ticketNumber) {
    final ticket = allTickets.firstWhere(
      (t) => t.number == ticketNumber,
      orElse: () => Ticket(id: '', number: '', price: 80.0),
    );

    if (ticket.id.isEmpty || ticket.status != 'available') {
      debugPrint('DEBUG: Cannot select ticket $ticketNumber - not available or not found');
      return;
    }

    debugPrint('DEBUG: Toggling ticket selection - ticketId: ${ticket.id}, number: $ticketNumber');
    
    if (selected.contains(ticket.id)) {
      // ยกเลิกการเลือก
      selected.remove(ticket.id);
      debugPrint('DEBUG: Removed from selection: ${ticket.id}');
      
      // Sync กับ Repository
      if (repo is WebSocketLottoRepository) {
        final wsRepo = repo as WebSocketLottoRepository;
        wsRepo.deselectTicket(ticket.id);
      }
    } else {
      // เลือกตั๋ว
      selected.add(ticket.id);
      debugPrint('DEBUG: Added to selection: ${ticket.id}');
      
      // Sync กับ Repository
      if (repo is WebSocketLottoRepository) {
        final wsRepo = repo as WebSocketLottoRepository;
        wsRepo.selectTicket(ticket.id);
      }
    }
    
    debugPrint('DEBUG: Current App State selection: $selected');
    notifyListeners();
  }

  int get selectedCost {
    if (selected.isEmpty) return 0;

    double totalCost = 0;
    for (final ticketId in selected) {
      final ticket = allTickets.firstWhere(
        (t) => t.id == ticketId,
        orElse: () => Ticket(id: '', number: '', price: 80.0),
      );
      if (ticket.id.isNotEmpty) totalCost += ticket.price;
    }
    return totalCost.round();
  }

  Future<bool> purchaseSelected() async {
    if (currentUser == null || selected.isEmpty) {
      debugPrint('DEBUG: Cannot purchase - no user or no selected tickets');
      return false;
    }

    try {
      debugPrint('DEBUG: Starting purchase for ${selected.length} tickets: $selected');
      
      // ตรวจสอบว่าตั๋วที่เลือกยัง available อยู่หรือไม่
      final availableSelected = selected.where((ticketId) {
        final ticket = allTickets.firstWhere(
          (t) => t.id == ticketId,
          orElse: () => Ticket(id: '', number: '', price: 80.0),
        );
        return ticket.id.isNotEmpty && ticket.status == 'available';
      }).toList();
      
      if (availableSelected.isEmpty) {
        errorMessage = 'ตั๋วที่เลือกไม่พร้อมใช้งานแล้ว';
        notifyListeners();
        return false;
      }
      
      if (availableSelected.length != selected.length) {
        debugPrint('DEBUG: Some selected tickets are no longer available');
        errorMessage = 'บางตั๋วถูกขายไปแล้ว กรุณาเลือกใหม่';
        
        // ลบตั๋วที่ไม่ available ออกจาก selection
        selected.clear();
        selected.addAll(availableSelected);
        
        notifyListeners();
        return false;
      }

      if (repo is WebSocketLottoRepository) {
        final wsRepo = repo as WebSocketLottoRepository;
        
        debugPrint('DEBUG: App State selected: $selected');
        debugPrint('DEBUG: Repository selected: ${wsRepo.selectedTickets}');
        
        // ตรวจสอบว่า Repository มีข้อมูลตั๋วที่เลือกหรือไม่
        if (wsRepo.selectedTickets.isEmpty && selected.isNotEmpty) {
          debugPrint('DEBUG: Repository selection is empty, syncing from App State...');
          
          // Sync ข้อมูลจาก App State ไป Repository
          for (final ticketId in selected) {
            await wsRepo.selectTicket(ticketId);
          }
        }
        
        // ใช้วิธีที่ปรับปรุงใหม่ที่รอผลลัพธ์
        await wsRepo.purchaseSelectedTickets();
        
        debugPrint('DEBUG: Purchase completed successfully');
        
        // ลบ selected tickets ทันที
        selected.clear();
        
        // อัพเดต current user จาก repository (ถ้ามีการอัพเดต)
        if (wsRepo.currentUser != null) {
          currentUser = wsRepo.currentUser;
          debugPrint('DEBUG: Updated current user from repository - wallet: ${currentUser?.currentWallet}');
        }
        
        // real-time update จะมาจาก purchase:success event ที่ตั้งไว้แล้ว
        
      } else {
        final updatedUser = await repo.purchaseTickets(
          userId: currentUser!.id,
          ticketIds: selected.toList(),
        );
        if (updatedUser != null) currentUser = updatedUser;
        
        await loadTickets();
        selected.clear();
      }

      notifyListeners();
      debugPrint('DEBUG: Purchase process completed successfully');
      return true;
    } catch (e) {
      debugPrint('DEBUG: Purchase error: $e');
      errorMessage = 'การซื้อตั๋วล้มเหลว: $e';
      notifyListeners();
      return false;
    }
  }

  // ======================================================
  // DRAW & PRIZE MANAGEMENT METHODS
  // ======================================================

  Future<DrawResult> drawPrizes({
    required String poolType,
    required List<int> rewards,
  }) async {
    debugPrint('DEBUG: drawPrizes called with poolType: $poolType, rewards: $rewards');
    
    try {
      // แสดง loading state
      isLoading = true;
      notifyListeners();
      
      DrawResult result;
      if (repo is WebSocketLottoRepository) {
        debugPrint('DEBUG: Using WebSocket repository for draw prizes');
        result = await repo.drawPrizes(poolType: poolType, rewards: rewards);
      } else {
        debugPrint('DEBUG: Using in-memory repository for draw prizes');
        result = await repo.drawPrizes(poolType: poolType, rewards: rewards);
      }
      
      // อัปเดต latestDraw
      latestDraw = result;
      debugPrint('DEBUG: Draw completed successfully, result ID: ${result.id}');
      
      // โหลดตั๋วใหม่หลังจากการออกรางวัล
      if (repo is WebSocketLottoRepository) {
        await loadTickets();
        await loadLatestDraw();
      }
      
      isLoading = false;
      notifyListeners();
      return result;
      
    } catch (e) {
      debugPrint('DEBUG: Draw prizes error: $e');
      errorMessage = 'เกิดข้อผิดพลาดในการออกรางวัล: $e';
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadLatestDraw() async {
    debugPrint('*************************************');
    debugPrint('DEBUG: AppState.loadLatestDraw START');
    try {
      debugPrint('DEBUG: Calling repo.getLatestDraw()...');
      
      // Check if WebSocket repository - skip if not implemented
      if (repo is WebSocketLottoRepository) {
        debugPrint('DEBUG: WebSocket repository - getLatestDraw not yet implemented');
        latestDraw = null;
        errorMessage = null;
        notifyListeners();
        return;
      }
      
      latestDraw = await repo.getLatestDraw();
      debugPrint('DEBUG: Repo call completed');
      debugPrint('DEBUG: latestDraw result: ${latestDraw?.id}');
      
      if (latestDraw != null) {
        debugPrint('DEBUG: Draw has ${latestDraw!.prizes.length} prizes:');
        for (int i = 0; i < latestDraw!.prizes.length; i++) {
          final prize = latestDraw!.prizes[i];
          debugPrint('  [${i + 1}] Tier ${prize.tier}: ticketId="${prize.ticketId}", amount=${prize.amount}');
        }
      } else {
        debugPrint('DEBUG: No draw found (latestDraw is null)');
      }
      
      errorMessage = null;
      notifyListeners();
      debugPrint('DEBUG: AppState.loadLatestDraw COMPLETED');
    } catch (e, stackTrace) {
      debugPrint('ERROR: AppState.loadLatestDraw failed: $e');
      debugPrint('Stack trace: $stackTrace');
      latestDraw = null;
      // Don't show error for unimplemented methods
      if (!e.toString().contains('not implemented')) {
        errorMessage = 'ไม่สามารถโหลดผลรางวัลได้: $e';
      }
      notifyListeners();
    }
    debugPrint('*************************************');
  }

  Future<bool> claimTicket(String ticketId) async {
    if (currentUser == null) return false;

    if (repo is WebSocketLottoRepository) {
      debugPrint('Claim ticket not yet implemented for WebSocket repository');
      return false;
    }

    final ok = await repo.claimTicket(userId: currentUser!.id, ticketId: ticketId);
    if (ok) {
      await loadTickets();
      notifyListeners();
    }
    return ok;
  }

  // ======================================================
  // SYSTEM STATISTICS METHODS
  // ======================================================

  Future<SystemStats> getStats() => repo.getSystemStats();

  // ======================================================
  // PRIZE CLAIMING METHODS
  // ======================================================

  Future<bool> claimPrize({
    required String ticketNumber,
    required double prizeAmount,
  }) async {
    if (currentUser == null) return false;

    try {
      // Note: WebSocket repository doesn't have claimPrize method yet
      // This will need to be implemented or use alternative approach
      debugPrint('Prize claiming not yet implemented for WebSocket repository');
      return false;
    } catch (e) {
      debugPrint('Claim prize error: $e');
      errorMessage = 'การขึ้นเงินรางวัลล้มเหลว: $e';
      notifyListeners();
      return false;
    }
  }

  // ======================================================
  // SYSTEM RESET METHODS
  // ======================================================

  Future<void> createLotteryTickets() async {
    if (repo is WebSocketLottoRepository) {
      final wsRepo = repo as WebSocketLottoRepository;
      await wsRepo.createLotteryTickets();
      // Refresh tickets after creation
      await loadTickets();
    }
    notifyListeners();
  }

  Future<void> resetAll() async {
    if (repo is WebSocketLottoRepository) {
      final wsRepo = repo as WebSocketLottoRepository;
      await wsRepo.resetAll();
      // Refresh tickets after reset
      await loadTickets();
    } else {
      await repo.resetAll();
      await loadTickets();
      await loadLatestDraw();
    }
    
    // Clear local state
    selected.clear();
    latestDraw = null;
    notifyListeners();
  }

  // ======================================================
  // PRIZE CHECKING & VALIDATION METHODS
  // ======================================================

  PrizeItem? checkTicketPrize(String ticketNumber) {
    debugPrint('-----------------------------------');
    debugPrint('DEBUG: checkTicketPrize START');
    debugPrint('DEBUG: Checking ticket: "$ticketNumber"');
    
    if (latestDraw == null) {
      debugPrint('DEBUG: checkTicketPrize - latestDraw is null');
      debugPrint('-----------------------------------');
      return null;
    }

    debugPrint('DEBUG: checkTicketPrize - Draw has ${latestDraw!.prizes.length} prizes');
    
    // Normalize ticketNumber และ prize.ticketId
    final normalizedTicketNumber = ticketNumber.trim().toLowerCase();
    for (int i = 0; i < latestDraw!.prizes.length; i++) {
      final prize = latestDraw!.prizes[i];
      final normalizedPrizeTicketId = prize.ticketId.trim().toLowerCase();
      debugPrint('DEBUG: Comparing "$normalizedTicketNumber" with prize[${i + 1}].ticketId: "$normalizedPrizeTicketId"');
      
      if (normalizedPrizeTicketId == normalizedTicketNumber) {
        debugPrint('✅ MATCH FOUND! Ticket "$ticketNumber" won tier ${prize.tier} = ${prize.amount} baht');
        debugPrint('-----------------------------------');
        return prize;
      }
    }
    
    debugPrint('❌ No match found for ticket: "$ticketNumber"');
    debugPrint('-----------------------------------');
    return null;
  }

  List<PrizeItem> getUserWinningTickets() {
    if (currentUser == null || latestDraw == null) return [];

    final winningTickets = <PrizeItem>[];
    for (final userTicket in userTickets) {
      final prize = checkTicketPrize(userTicket.number);
      if (prize != null) winningTickets.add(prize);
    }
    return winningTickets;
  }

  Future<bool> claimAllPrizes() async {
    if (currentUser == null) return false;

    final winningTickets = getUserWinningTickets();
    if (winningTickets.isEmpty) return false;

    try {
      double totalPrize = 0;
      for (final prize in winningTickets) totalPrize += prize.amount;

      // Note: Prize claiming functionality needs to be implemented for WebSocket
      // For now, return false until WebSocket claim prize is implemented
      debugPrint('Prize claiming not yet fully implemented for WebSocket repository');
      return false;
    } catch (e) {
      debugPrint('Claim all prizes error: $e');
      errorMessage = 'การขึ้นเงินรางวัลทั้งหมดล้มเหลว: $e';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    debugPrint('DEBUG: logout() called');
    debugPrint('DEBUG: Current user before clear: ${currentUser?.username}');

    currentUser = null;
    userTickets.clear();
    allTickets.clear();
    selected.clear();
    latestDraw = null;
    errorMessage = null;
    isLoading = false;

    debugPrint('DEBUG: Current user after clear: ${currentUser?.username}');
    debugPrint('DEBUG: About to call notifyListeners()');
    notifyListeners();
    debugPrint('DEBUG: notifyListeners() called successfully');
  }
  
  // ======================================================
  // CLEANUP METHODS
  // ======================================================
  
  @override
  void dispose() {
    debugPrint('DEBUG: Disposing LottoAppState...');
    _userStreamSubscription?.cancel();
    _ticketsStreamSubscription?.cancel();
    _userTicketsStreamSubscription?.cancel();
    super.dispose();
  }
}