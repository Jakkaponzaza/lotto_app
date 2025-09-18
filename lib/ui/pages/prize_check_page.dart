// ======================================================
// File: lib/ui/pages/prize_check_page.dart
// Purpose: หน้าตรวจสอบรางวัลลอตเตอรี่
// ======================================================

// Flutter & Third-party imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Internal imports - Models
import '../../models.dart';

// Internal imports - Services
import '../../services/app_state.dart';

class PrizeCheckPage extends StatefulWidget {
  const PrizeCheckPage({super.key});

  @override
  State<PrizeCheckPage> createState() => _PrizeCheckPageState();
}

class _PrizeCheckPageState extends State<PrizeCheckPage> {
  // ======================================================
  // Properties
  // ======================================================
  final NumberFormat _formatter = NumberFormat.decimalPattern('th');
  bool _isLoading = false;

  // ======================================================
  // Lifecycle Methods
  // ======================================================
  @override
  void initState() {
    super.initState();
    print('DEBUG: PrizeCheckPage - initState called');
    // โหลดข้อมูลการออกรางวัลล่าสุดทันทีเมื่อเข้าหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG: PrizeCheckPage - Post frame callback executing');
      _loadLatestDraw();
    });
  }

  // ======================================================
  // Private Methods
  // ======================================================
  Future<void> _loadLatestDraw() async {
    print('=====================================');
    print('DEBUG: _loadLatestDraw START');
    print('=====================================');
    
    setState(() => _isLoading = true);
    
    try {
      final appState = context.read<LottoAppState>();
      
      print('DEBUG: Current user: ${appState.currentUser?.username}');
      print('DEBUG: Current user ID: ${appState.currentUser?.id}');
      
      // โหลดข้อมูลการออกรางวัลล่าสุด
      print('DEBUG: Calling loadLatestDraw...');
      await appState.loadLatestDraw();
      print('DEBUG: loadLatestDraw completed');
      
      // โหลดตั๋วของผู้ใช้ถ้ามี
      if (appState.currentUser != null) {
        print('DEBUG: Loading user tickets...');
        await appState.loadTickets();
        print('DEBUG: loadTickets completed');
      } else {
        print('DEBUG: No current user - skipping loadTickets');
      }
      
      print('DEBUG: Latest draw result: ${appState.latestDraw?.id}');
      print('DEBUG: User tickets count: ${appState.userTickets.length}');
      
      // แสดงข้อมูลรางวัลทั้งหมด
      if (appState.latestDraw != null) {
        print('DEBUG: Draw prizes:');
        for (final prize in appState.latestDraw!.prizes) {
          print('  - Tier ${prize.tier}: ${prize.ticketId} = ${prize.amount} baht');
        }
      } else {
        print('DEBUG: No draw data available');
      }
      
      // แสดงข้อมูลตั๋วผู้ใช้
      if (appState.userTickets.isNotEmpty) {
        print('DEBUG: User tickets:');
        for (final ticket in appState.userTickets) {
          print('  - Ticket: ${ticket.number}');
        }
      } else {
        print('DEBUG: User has no tickets');
      }
      
      // ตรวจสอบรางวัล
      if (appState.latestDraw != null && appState.userTickets.isNotEmpty) {
        print('DEBUG: Checking for winning tickets...');
        for (final userTicket in appState.userTickets) {
          final prize = appState.checkTicketPrize(userTicket.number);
          if (prize != null) {
            print('🎉 WINNER: ${userTicket.number} won tier ${prize.tier} = ${prize.amount} baht');
          } else {
            print('❌ NOT WIN: ${userTicket.number}');
          }
        }
      }
      
    } catch (e, stackTrace) {
      print('ERROR: _loadLatestDraw failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
      print('DEBUG: _loadLatestDraw END');
      print('=====================================');
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ======================================================
  // UI Build Methods
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LottoAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบรางวัล'),
        backgroundColor: const Color(0xFF1F2937),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLatestDraw,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF111827),
      body: RefreshIndicator(
        onRefresh: _loadLatestDraw,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดข้อมูล...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLatestDrawSection(appState),
                    const SizedBox(height: 24),
                    if (appState.latestDraw != null) ...[
                      _buildAllWinningNumbersSection(appState),
                      const SizedBox(height: 24),
                    ],
                    _buildMyTicketsWithResultsSection(appState),
                    const SizedBox(height: 24),
                    if (appState.latestDraw != null) ...[
                      _buildWinningTicketsSection(appState),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLatestDrawSection(LottoAppState appState) {
    if (appState.latestDraw == null) {
      return _buildNoDrawCard();
    }

    final draw = appState.latestDraw!;
    return Card(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'ผลรางวัลล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'ออกรางวัลเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(draw.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'ประเภท: ${draw.poolType == 'sold' ? 'จากลอตเตอรี่ที่ขายแล้ว' : 'จากลอตเตอรี่ทั้งหมด'}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...draw.prizes.map((prize) => _buildPrizeItem(prize, appState)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDrawCard() {
    print('DEBUG: Building NoDrawCard');
    return Card(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              'ยังไม่มีการออกรางวัล',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'รอการออกรางวัลจากผู้ดูแลระบบ',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                print('DEBUG: Manual refresh button pressed');
                _loadLatestDraw();
              },
              child: const Text('รีเฟรชข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeItem(PrizeItem prize, LottoAppState appState) {
    final ticket = appState.allTickets.firstWhere(
      (t) => t.id == prize.ticketId || t.number == prize.ticketId,
      orElse: () => Ticket(id: '', number: prize.ticketId, price: 80.0),
    );

    final isMyTicket = appState.userTickets.any((t) => t.number == ticket.number);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyTicket ? const Color(0xFF065F46) : const Color(0xFF374151),
        borderRadius: BorderRadius.circular(8),
        border: isMyTicket ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getTierColor(prize.tier),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${prize.tier}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รางวัลที่ ${prize.tier}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'หมายเลข: ${ticket.number}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatter.format(prize.amount)} บาท',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 16,
                ),
              ),
              if (isMyTicket)
                const Text(
                  '🎉 ของคุณ!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyTicketsWithResultsSection(LottoAppState appState) {
    if (appState.currentUser == null) {
      return Card(
        color: const Color(0xFF1F2937),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              Icon(Icons.account_circle, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'กรุณาเข้าสู่ระบบก่อน',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'ลอตเตอรี่ของฉัน & ผลรางวัล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appState.userTickets.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'คุณยังไม่มีลอตเตอรี่',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ไปซื้อลอตเตอรี่ก่อนเพื่อตรวจสอบรางวัล',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else if (appState.latestDraw == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ยังไม่มีการออกรางวัล',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ตั๋วของคุณ (รอผลรางวัล):',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: appState.userTickets.map((ticket) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B7280),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[500]!, width: 1),
                          ),
                          child: Column(
                            children: [
                              Text(
                                ticket.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'รอผล',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            else ...[
              // มีการออกรางวัลแล้ว - แสดงผลตั๋วทั้งหมดของผู้ใช้พร้อมสถานะ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📋 ผลตรวจสอบตั๋วของคุณ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              
              // แสดงตั๋วทั้งหมดของผู้ใช้ พร้อมสถานะ
              ...appState.userTickets.map((ticket) {
                final prize = appState.checkTicketPrize(ticket.number);
                final isWinner = prize != null;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWinner 
                        ? const Color(0xFF16A34A) // สีเขียวสำหรับถูกรางวัล
                        : const Color(0xFF6B7280), // สีเทาสำหรับไม่ถูกรางวัล
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWinner 
                          ? Colors.green[300]! 
                          : Colors.grey[600]!,
                      width: isWinner ? 2 : 1,
                    ),
                    boxShadow: isWinner 
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      // ไอคอนสถานะ
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isWinner 
                              ? _getTierColor(prize!.tier)
                              : Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: isWinner
                              ? Text(
                                  '${prize!.tier}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // ข้อมูลตั๋ว
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'หมายเลข: ${ticket.number}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isWinner 
                                  ? 'รางวัลที่ ${prize!.tier}'
                                  : 'ไม่ถูกรางวัล',
                              style: TextStyle(
                                color: isWinner 
                                    ? Colors.white70
                                    : Colors.white60,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // สถานะและเงินรางวัล
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isWinner) ...[
                            Text(
                              '${_formatter.format(prize!.amount)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const Text(
                              'บาท',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🎉 ถูกรางวัล',
                                style: TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '❌ ไม่ถูกรางวัล',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 16),
              
              // สรุปผลรางวัล
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF374151),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[600]!, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${_getWinningTickets(appState).length}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ตั๋วถูกรางวัล',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[600],
                    ),
                    Column(
                      children: [
                        Text(
                          '${_getNonWinningTickets(appState).length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ตั๋วไม่ถูกรางวัล',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[600],
                    ),
                    Column(
                      children: [
                        Text(
                          '${appState.userTickets.length}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ตั๋วทั้งหมด',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Ticket> _getWinningTickets(LottoAppState appState) {
    if (appState.latestDraw == null) return [];
    return appState.userTickets
        .where((ticket) => appState.checkTicketPrize(ticket.number) != null)
        .toList();
  }

  List<Ticket> _getNonWinningTickets(LottoAppState appState) {
    if (appState.latestDraw == null) return appState.userTickets;
    return appState.userTickets
        .where((ticket) => appState.checkTicketPrize(ticket.number) == null)
        .toList();
  }

  Widget _buildWinningTicketsSection(LottoAppState appState) {
    if (appState.currentUser == null) {
      return const SizedBox.shrink();
    }

    final winningTickets = appState.getUserWinningTickets();

    if (winningTickets.isEmpty) {
      return _buildNoWinningTicketsCard();
    }

    // ตรวจสอบว่ารางวัลถูกขึ้นไปแล้วหรือยัง
    final hasClaimedPrizes = winningTickets.any((prize) => prize.claimed);
    
    if (hasClaimedPrizes) {
      return _buildAlreadyClaimedCard(winningTickets, appState);
    }

    return _buildWinningTicketsCard(winningTickets, appState);
  }

  Widget _buildAllWinningNumbersSection(LottoAppState appState) {
    if (appState.latestDraw == null) {
      return const SizedBox.shrink();
    }

    final draw = appState.latestDraw!;
    return Card(
      color: const Color(0xFF1F2937),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '🏆 หมายเลขที่ถูกรางวัลทั้งหมด 🏆',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ออกรางวัลเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(draw.createdAt)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // แสดงรางวัลแต่ละรางวัลพร้อมเงินรางวัล
            ...draw.prizes.asMap().entries.map((entry) {
              final index = entry.key;
              final prize = entry.value;
              final isMyTicket = appState.currentUser != null &&
                  appState.userTickets.any((t) => t.number == prize.ticketId);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMyTicket 
                      ? const Color(0xFF16A34A) // สีเขียวสำหรับตั๋วของผู้ใช้
                      : const Color(0xFF374151), // สีเทาสำหรับตั๋วอื่น
                  borderRadius: BorderRadius.circular(12),
                  border: isMyTicket 
                      ? Border.all(color: Colors.green[300]!, width: 3)
                      : Border.all(color: Colors.grey[600]!, width: 1),
                  boxShadow: isMyTicket 
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // ไอคอนรางวัล
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTierColor(prize.tier),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _getTierColor(prize.tier).withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${prize.tier}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // ข้อมูลรางวัล
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รางวัลที่ ${prize.tier}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isMyTicket 
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'หมายเลข: ${prize.ticketId}',
                              style: TextStyle(
                                color: isMyTicket ? Colors.white : Colors.grey[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // เงินรางวัลและสถานะ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_formatter.format(prize.amount)}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'บาท',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                        if (isMyTicket) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🎉 ของคุณ!',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWinningTicketsCard() {
    return Card(
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Icon(
              Icons.sentiment_neutral,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'คุณไม่ถูกรางวัลในครั้งนี้',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'โชคดีครั้งหน้า! 🍀',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyClaimedCard(List<PrizeItem> winningTickets, LottoAppState appState) {
    final totalPrize = winningTickets.fold<double>(
      0,
      (sum, prize) => sum + prize.amount,
    );

    return Card(
      color: const Color(0xFF6B7280),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'ขึ้นเงินรางวัลเรียบร้อยแล้ว ✓',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...winningTickets.map((prize) {
              final ticket = appState.userTickets.firstWhere(
                (t) => t.number == prize.ticketId,
                orElse: () => Ticket(id: '', number: prize.ticketId, price: 80.0),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B5563),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รางวัลที่ ${prize.tier} (ขึ้นแล้ว)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'หมายเลข: ${ticket.number}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatter.format(prize.amount)} บาท',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'ยอดรวมที่ได้รับ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatter.format(totalPrize)} บาท',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinningTicketsCard(List<PrizeItem> winningTickets, LottoAppState appState) {
    final totalPrize = winningTickets.fold<double>(
      0,
      (sum, prize) => sum + prize.amount,
    );

    return Card(
      color: const Color(0xFF065F46),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.celebration,
                  color: Colors.amber,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'ยินดีด้วย! คุณถูกรางวัล! 🎉',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...winningTickets.map((prize) {
              final ticket = appState.userTickets.firstWhere(
                (t) => t.number == prize.ticketId,
                orElse: () => Ticket(id: '', number: prize.ticketId, price: 80.0),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getTierColor(prize.tier),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${prize.tier}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รางวัลที่ ${prize.tier}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'หมายเลข: ${ticket.number}',
                            style: TextStyle(color: Colors.green[200]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatter.format(prize.amount)} บาท',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            _buildTotalPrizeSection(totalPrize),
            const SizedBox(height: 16),
            _buildClaimButton(appState, totalPrize),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPrizeSection(double totalPrize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF047857),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            'เงินรางวัลรวม',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatter.format(totalPrize)} บาท',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimButton(LottoAppState appState, double totalPrize) {
    // ตรวจสอบว่ารางวัลถูกขึ้นไปแล้วหรือยัง
    final winningTickets = appState.getUserWinningTickets();
    final alreadyClaimed = winningTickets.any((prize) => prize.claimed);
    
    if (alreadyClaimed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'ขึ้นเงินรางวัลเรียบร้อยแล้ว',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);

                final success = await appState.claimAllPrizes();

                setState(() => _isLoading = false);

                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ขึ้นเงินรางวัล ${_formatter.format(totalPrize)} บาท เรียบร้อย!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // รีโหลดข้อมูลหลังจากขึ้นเงินรางวัล
                    await appState.loadLatestDraw();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เกิดข้อผิดพลาดในการขึ้นเงินรางวัล'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : const Text(
                '💰 ขึ้นเงินรางวัล',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}