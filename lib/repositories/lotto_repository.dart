// ======================================================
// File: lib/repositories/lotto_repository.dart
// Purpose: Interface for data layer - WebSocket implementation available
// ======================================================

import '../models.dart';

abstract class LottoRepository {
  Future<AppUser> getOwner();

  Future<AppUser> loginOrRegisterMember({
    required String username,
    int? initialWallet,
  });

  Future<List<Ticket>> listAllTickets();

  Future<List<Ticket>> listUserTickets(String userId);

  Future<AppUser?> purchaseTickets({
    required String userId,
    required List<String> ticketIds,
  });

  /// poolType: 'sold' | 'all'
  Future<DrawResult> drawPrizes({
    required String poolType,
    required List<int> rewards,
  });

  Future<DrawResult?> getLatestDraw();

  Future<bool> claimTicket({
    required String userId,
    required String ticketId,
  });

  Future<SystemStats> getSystemStats();

  Future<void> resetAll();
}