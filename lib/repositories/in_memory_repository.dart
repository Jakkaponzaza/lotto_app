// ======================================================
// File: lib/repositories/in_memory_repository.dart
// Purpose: Implementation ชั่วคราวแบบ In-Memory (ใช้แทน DB ชั่วคราว)
// Note[DB]: ใช้ทดสอบ UI/ฟังก์ชันได้ทันที แล้วค่อยสลับไป DatabaseLottoRepository ภายหลัง
// ======================================================

import 'dart:math';
import '../models.dart';
import 'lotto_repository.dart';

class InMemoryLottoRepository implements LottoRepository {
  final _users = <String, AppUser>{};
  final _tickets = <String, Ticket>{};
  DrawResult? _latestDraw;

  InMemoryLottoRepository() {
    // owner
    final owner = AppUser(
      userId: 1,
      username: 'owner',
      role: UserRole.owner,
      initialWallet: 0.0,
      currentWallet: 0.0,
      email: 'admin@lotto.com',
      phone: '0000000000',
      passwordHash: 'hashed_admin_password',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users[owner.id] = owner;

    // สร้างตั๋วตัวอย่าง 100 ใบ
    for (int i = 1; i <= 100; i++) {
      final ticket = Ticket(
        id: 'ticket_$i',
        number: i.toString().padLeft(6, '0'),
        price: LottoConstants.lottoPrice.toDouble(),
        status: 'available',
      );
      _tickets[ticket.id] = ticket;
    }
  }

  @override
  Future<AppUser> getOwner() async => _users['owner']!;

  @override
  Future<AppUser> loginOrRegisterMember({
    required String username,
    int? initialWallet,
  }) async {
    final found = _users.values
        .where((u) => u.role == UserRole.member && u.username == username)
        .toList();

    if (found.isNotEmpty) return found.first;

    final walletAmount = (initialWallet ?? 5000).toDouble();
    final u = AppUser(
      userId: DateTime.now().millisecondsSinceEpoch,
      username: username,
      role: UserRole.member,
      initialWallet: walletAmount,
      currentWallet: walletAmount,
      email: '$username@example.com',
      phone: '0123456789',
      passwordHash: 'hashed_password',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _users[u.id] = u;
    return u;
  }

  @override
  Future<List<Ticket>> listAllTickets() async =>
      _tickets.values.toList()..sort((a, b) => a.number.compareTo(b.number));

  @override
  Future<List<Ticket>> listUserTickets(String userId) async =>
      _tickets.values.where((t) => t.ownerId == userId).toList();

  @override
  Future<AppUser?> purchaseTickets({
    required String userId,
    required List<String> ticketIds,
  }) async {
    final user = _users[userId]!;
    
    // คำนวณราคารวมจากราคาจริงของตั๋วแต่ละใบ
    double totalCost = 0;
    for (final id in ticketIds) {
      final ticket = _tickets[id];
      if (ticket != null) {
        totalCost += ticket.price;
      }
    }

    if (user.currentWallet < totalCost) throw StateError('WALLET_NOT_ENOUGH');

    // สร้าง user ใหม่ด้วย wallet ที่อัปเดต
    final updatedUser = user.copyWith(
      wallet: user.currentWallet - totalCost,
      updatedAt: DateTime.now(),
    );
    _users[userId] = updatedUser;

    for (final id in ticketIds) {
      final t = _tickets[id]!;
      if (t.status != 'available') throw StateError('TICKET_NOT_AVAILABLE');
      t.status = 'sold';
      t.ownerId = userId;
    }
    
    return updatedUser;
  }

  @override
  Future<DrawResult> drawPrizes({
    required String poolType,
    required List<int> rewards,
  }) async {
    final pool = _tickets.values
        .where((t) => poolType == 'all' ? true : t.status == 'sold')
        .toList();

    if (pool.length < 5) throw StateError('POOL_NOT_ENOUGH');

    pool.shuffle(Random());
    final winners = pool.take(5).toList();
    final prizes = List<PrizeItem>.generate(
      5,
      (i) => PrizeItem(
        tier: i + 1,
        ticketId: winners[i].number, // ใช้ ticket number แทน ticket ID
        amount: rewards[i],
        claimed: false,
      ),
    );

    _latestDraw = DrawResult(
      id: 'd_${DateTime.now().millisecondsSinceEpoch}',
      poolType: poolType,
      createdAt: DateTime.now(),
      prizes: prizes,
    );

    return _latestDraw!;
  }

  @override
  Future<DrawResult?> getLatestDraw() async => _latestDraw;

  @override
  Future<bool> claimTicket({
    required String userId,
    required String ticketId,
  }) async {
    final t = _tickets[ticketId];
    if (t == null || t.ownerId != userId || t.status != 'sold') return false;

    // หา prize ที่ตรงกับ ticket number
    final prize = _latestDraw?.prizes.firstWhere(
      (p) => p.ticketId == t.number,
      orElse: () => PrizeItem(tier: -1, ticketId: '', amount: 0, claimed: false),
    );

    if (prize == null || prize.tier == -1) return false;

    // ปรับ wallet และลบ/เปลี่ยนสถานะตั๋ว
    final user = _users[userId]!;
    final updatedUser = user.copyWith(
      wallet: user.currentWallet + prize.amount.toDouble(),
      updatedAt: DateTime.now(),
    );
    _users[userId] = updatedUser;
    t.status = 'claimed';

    // ตามสเปค: ขึ้นเงินแล้ว "ตั๋วหายไป" → ลบออกจากคลัง
    _tickets.remove(ticketId);
    return true;
  }

  @override
  Future<SystemStats> getSystemStats() async {
    final sold = _tickets.values.where((t) => t.status == 'sold').length;
    final left = _tickets.length - sold;
    final members =
        _users.values.where((u) => u.role == UserRole.member).length;

    return SystemStats(
      totalMembers: members,
      ticketsSold: sold,
      ticketsLeft: left,
      totalValue: (sold * LottoConstants.lottoPrice).toDouble(),
    );
  }

  @override
  Future<void> resetAll() async {
    // เหลือ owner
    _users.removeWhere((k, v) => v.role == UserRole.member);

    // รีโหลดตั๋วใหม่
    _tickets.clear();
    for (int i = 1; i <= 100; i++) {
      final ticket = Ticket(
        id: 'ticket_$i',
        number: i.toString().padLeft(6, '0'),
        price: LottoConstants.lottoPrice.toDouble(),
        status: 'available',
      );
      _tickets[ticket.id] = ticket;
    }

    _latestDraw = null;
  }
}
