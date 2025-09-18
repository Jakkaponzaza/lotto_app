// Flutter & Third-party imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Internal imports - Services
import '../../services/app_state.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  int _tabIndex = 0; // 0=ซื้อหวย, 1=ลอตเตอรี่ของฉัน, 2=ตรวจรางวัล

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลลอตเตอรี่ทันทีเมื่อเข้าหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTicketsData();
    });
  }

  Future<void> _loadTicketsData() async {
    final appState = context.read<LottoAppState>();
    try {
      debugPrint('🎫 Loading tickets data for member page...');
      
      // โหลดตั๋วทั้งหมด
      await appState.loadTickets();
      
      // โหลดตั๋วของผู้ใช้ (ถ้ามีการ login แล้ว)
      if (appState.currentUser != null) {
        await appState.loadUserTickets();
      }
      
      debugPrint('🎫 Tickets loaded: ${appState.allTickets.length} total, ${appState.availableTickets.length} available');
      debugPrint('🎫 User tickets loaded: ${appState.userTickets.length} user tickets');
      
      if (mounted) {
        setState(() {
          // รีเฟรช UI หลังโหลดข้อมูล
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading tickets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'ลองใหม่',
              textColor: Colors.white,
              onPressed: _loadTicketsData,
            ),
          ),
        );
      }
    }
  }

  // แก้ไข method logout ให้ทำงานถูกต้อง - กดแล้วออกเลย
  void _logout(BuildContext context) {
    debugPrint('DEBUG: Logout button pressed');

    final appState = context.read<LottoAppState>();
    debugPrint(
        'DEBUG: Current user before logout: ${appState.currentUser?.username}');

    // เรียก logout - HomeRouter จะ redirect ไปหน้า AuthView อัตโนมัติ
    appState.logout();

    debugPrint(
        'DEBUG: Current user after logout: ${appState.currentUser?.username}');
    debugPrint('DEBUG: Logout completed, should redirect to AuthView');

    // แสดงข้อความสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ออกจากระบบเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // ไม่ต้อง navigate เพราะ HomeRouter จะจัดการให้อัตโนมัติ
    // เมื่อ currentUser เป็น null, HomeRouter จะแสดง AuthView
  }

  // แก้ไข method _buyTickets - ลบการเด้งไปแท็บอื่น
  void _buyTickets(BuildContext context) async {
    final appState = context.read<LottoAppState>();
    final selectedCount = appState.selected.length;

    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาเลือกตั๋วที่ต้องการซื้อ"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('กำลังซื้อตั๋ว...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final success = await appState.purchaseSelected();

    // ปิด loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (success) {
      // อัพเดทหน้า UI
      setState(() {
        // เรียก setState เพื่อให้ UI อัพเดท
      });

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("ซื้อตั๋ว $selectedCount ใบ เรียบร้อย ✅"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'ดูตั๋วของฉัน',
            textColor: Colors.white,
            onPressed: () {
              // ให้ผู้ใช้เลือกเองว่าจะดูตั๋วหรือไม่
              setState(() {
                _tabIndex = 1;
              });
            },
          ),
        ),
      );

      // ลบการเด้งไปแท็บอื่นอัตโนมัติ - ให้อยู่ที่แท็บเดิม
      // Future.delayed(const Duration(seconds: 1), () {
      //   if (mounted) {
      //     setState(() {
      //       _tabIndex = 1; // ลบบรรทัดนี้
      //     });
      //   }
      // });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ยอดเงินไม่พอหรือมีปัญหา ⚠️"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _claimPrize(
      BuildContext context, String ticketNumber, double prizeAmount) async {
    final appState = context.read<LottoAppState>();

    // แสดง dialog ยืนยัน
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text(
          'ขึ้นเงินรางวัล',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'คุณต้องการขึ้นเงินรางวัล ${prizeAmount.toInt()} บาท\nสำหรับลอตเตอรี่หมายเลข $ticketNumber หรือไม่?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('ขึ้นเงิน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('กำลังขึ้นเงินรางวัล...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final success = await appState.claimPrize(
      ticketNumber: ticketNumber,
      prizeAmount: prizeAmount,
    );

    // ปิด loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (!mounted) return;

    if (success) {
      // รีเฟรชหน้าเพื่อแสดงผลที่อัพเดท
      setState(() {
        // Force rebuild เพื่อแสดงข้อมูลใหม่
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "ขึ้นเงินรางวัล ${prizeAmount.toInt()} บาท เรียบร้อย! 🎉\nตั๋วหมายเลข $ticketNumber ถูกลบออกจากระบบแล้ว",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ขึ้นเงินรางวัลไม่สำเร็จ ⚠️"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<LottoAppState>();
    final user = appState.currentUser;

    final availableTickets = appState.availableTickets;
    final userTickets = appState.userTickets;
    final draw = appState.latestDraw;

    Widget content = const SizedBox(); // Initialize with default widget

    if (_tabIndex == 0) {
      // ซื้อหวย
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "เลือกหมายเลขที่ต้องการ",
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: availableTickets.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่มีตั๋วให้ซื้อในขณะนี้",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: availableTickets.length,
                    itemBuilder: (context, index) {
                      final number = availableTickets[index];
                      final ticket = appState.allTickets.firstWhere(
                        (t) => t.number == number,
                        orElse: () => throw StateError('Ticket not found'),
                      );
                      final isSelected = appState.selected.contains(ticket.id);
                      final isBought =
                          userTickets.any((t) => t.number == number);

                      Color bgColor;
                      if (isBought) {
                        bgColor = Colors.grey.shade700;
                      } else if (isSelected) {
                        bgColor = Colors.green;
                      } else {
                        bgColor = const Color(0xFF334155);
                      }

                      return GestureDetector(
                        onTap: isBought
                            ? null
                            : () => appState.toggleSelect(number),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              number,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    } else if (_tabIndex == 1) {
      // ลอตเตอรี่ของฉัน
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "รายการลอตเตอรี่ของคุณ",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: userTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "คุณยังไม่มีลอตเตอรี่",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final appState = context.read<LottoAppState>();
                            if (appState.currentUser != null) {
                              debugPrint('🔄 Manual refresh user tickets...');
                              try {
                                await appState.loadUserTickets();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('รีเฟรชข้อมูลเรียบร้อยแล้ว'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('เกิดข้อผิดพลาด: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('รีเฟรชข้อมูล'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      final appState = context.read<LottoAppState>();
                      if (appState.currentUser != null) {
                        debugPrint('🔄 Pull-to-refresh user tickets...');
                        await appState.loadUserTickets();
                      }
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      itemCount: userTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = userTickets[index];
                        return Card(
                          color: const Color(0xFF334155),
                          child: ListTile(
                            title: Text(
                              "หมายเลข: ${ticket.number}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            subtitle: Text(
                              "สถานะ: ${ticket.status == 'sold' ? 'ซื้อแล้ว' : ticket.status}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: ticket.status == 'sold'
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      );
    } else if (_tabIndex == 2) {
      // ตรวจรางวัล
      if (draw == null) {
        content = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            Text(
              "ผลออกรางวัล",
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Text("ยังไม่มีการออกรางวัล",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      } else {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "ผลออกรางวัล",
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text("ผลการออกรางวัลล่าสุด:",
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  ...draw.winners.entries.map((entry) {
                    final prize = entry.key;
                    final numbers = entry.value;
                    return Card(
                      color: const Color(0xFF334155),
                      child: ListTile(
                        title: Text(
                          "รางวัล $prize",
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 16),
                        ),
                        subtitle: Text(
                          numbers.join(", "),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text("ลอตเตอรี่ของฉัน:",
                      style:
                          TextStyle(color: Colors.greenAccent, fontSize: 18)),
                  ...userTickets.map((ticket) {
                    bool won = draw.winners.values
                        .any((nums) => nums.contains(ticket.number));

                    // หาว่าถูกรางวัลอะไร และได้เงินเท่าไหร่
                    String? prizeType;
                    double prizeAmount = 0;

                    if (won) {
                      for (final entry in draw.winners.entries) {
                        if (entry.value.contains(ticket.number)) {
                          prizeType = entry.key;
                          // กำหนดเงินรางวัลตามประเภทรางวัล
                          switch (prizeType) {
                            case 'รางวัลที่ 1':
                              prizeAmount = 6000000;
                              break;
                            case 'รางวัลที่ 2':
                              prizeAmount = 200000;
                              break;
                            case 'รางวัลที่ 3':
                              prizeAmount = 80000;
                              break;
                            case 'รางวัลที่ 4':
                              prizeAmount = 40000;
                              break;
                            case 'รางวัลที่ 5':
                              prizeAmount = 20000;
                              break;
                            default:
                              prizeAmount = 2000;
                          }
                          break;
                        }
                      }
                    }

                    return Card(
                      color: won ? Colors.green : const Color(0xFF334155),
                      child: ListTile(
                        title: Text(
                          "หมายเลข: ${ticket.number}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        subtitle: won
                            ? Text(
                                '$prizeType - ${prizeAmount.toInt()} บาท',
                                style: const TextStyle(color: Colors.yellow),
                              )
                            : const Text(
                                "ไม่ถูกรางวัล",
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 14),
                              ), // ❌ เพิ่มข้อความ "ไม่ถูกรางวัล"
                        trailing: won
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.yellow),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _claimPrize(
                                        context, ticket.number, prizeAmount),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                    ),
                                    child: const Text(
                                      'ขึ้นเงิน',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: Column(
          children: [
            // Header with User Info
            if (user != null)
              Container(
                color: const Color(0xFF334155),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี ${user.username}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'ยอดเงิน: ${user.currentWallet.toInt()} บาท',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('ออกจากระบบ'),
                    ),
                  ],
                ),
              ),

            // Tabs
            Container(
              color: const Color(0xFF334155),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: _buildTab("ซื้อลอตเตอรี่", 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTab("ลอตเตอรี่ของฉัน", 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildTab("ตรวจรางวัล", 2)),
                ],
              ),
            ),

            // Content
            Expanded(child: content),

            // Footer (เฉพาะ tab 0)
            if (_tabIndex == 0 && availableTickets.isNotEmpty)
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      "รายการที่เลือก ${appState.selected.length} รายการ | ราคารวม : ${appState.selectedCost} บาท",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appState.selected.isNotEmpty
                              ? Colors.green
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: appState.selected.isNotEmpty
                            ? () => _buyTickets(context)
                            : null,
                        child: Text(
                          appState.selected.isEmpty
                              ? "เลือกตั๋วที่ต้องการซื้อ"
                              : "ยืนยันการซื้อ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildTab(String label, int index) {
    return GestureDetector(
      onTap: () async {
        setState(() => _tabIndex = index);
        
        // โหลดข้อมูลใหม่เมื่อสลับไปที่ลอตเตอรี่ของฉัน
        if (index == 1) {
          final appState = context.read<LottoAppState>();
          if (appState.currentUser != null) {
            debugPrint('🎫 Switching to "My Lottery" tab - refreshing user tickets...');
            try {
              await appState.loadUserTickets();
              debugPrint('🎫 User tickets refreshed: ${appState.userTickets.length} tickets');
            } catch (e) {
              debugPrint('❌ Error refreshing user tickets: $e');
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _tabIndex == index ? Colors.blue : const Color(0xFF475569),
          borderRadius: BorderRadius.circular(6),
          border: _tabIndex == index
              ? Border.all(color: Colors.white, width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight:
                _tabIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
