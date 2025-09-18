import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/app_state.dart';
import '../../models.dart';
import '../widgets/common_widgets.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String pool = 'sold';
  String selectedAction = 'draw'; // 'draw' or 'create'
  final p1 = TextEditingController(text: '1000000');
  final p2 = TextEditingController(text: '500000');
  final p3 = TextEditingController(text: '100000');
  final p4 = TextEditingController(text: '50000');
  final p5 = TextEditingController(text: '10000');

  final formatter = NumberFormat.decimalPattern('th');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    p1.dispose();
    p2.dispose();
    p3.dispose();
    p4.dispose();
    p5.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LottoAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผู้ดูแลระบบ'),
        actions: [
          TextButton(
            onPressed: s.logout,
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'ออกรางวัล'),
            Tab(text: 'สถานะระบบ'),
            Tab(text: 'รีเซ็ตระบบ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildDrawTab(s),
          _buildStatusTab(s),
          _buildResetTab(s),
        ],
      ),
    );
  }

  Widget _buildDrawTab(LottoAppState s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตั้งค่าและออกรางวัล',
            style: TextStyle(fontSize: 18, color: Colors.amberAccent),
          ),
          const SizedBox(height: 12),
          // Always show draw interface
          ..._buildDrawInterface(),
          const SizedBox(height: 16),
          // Single action button for drawing prizes
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    pool == 'create' ? Colors.green : const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (pool == 'create') {
                  _handleCreateAction(s);
                } else {
                  _handleDrawAction(s);
                }
              },
              child: Text(
                pool == 'create'
                    ? '🎫 สร้างตั๋วลอตโต่ 120 ใบใหม่ (ลบข้อมูลเก่า) 🎫'
                    : '✨ สุ่มและประกาศรางวัล ✨',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: pool == 'create' ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Widget> _buildDrawInterface() {
    return [
      DropdownButtonFormField<String>(
        value: pool,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Color(0xFF1F2937),
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(
            value: 'sold',
            child: Text('สุ่มจากลอตเตอรี่ที่ขายไปแล้วเท่านั้น'),
          ),
          DropdownMenuItem(
            value: 'all',
            child: Text('สุ่มจากลอตเตอรี่ทั้งหมดในระบบ'),
          ),
          DropdownMenuItem(
            value: 'create',
            child: Text('สร้างตั๋วลอตเตอรี่ใหม่ 120 ใบ'),
          ),
        ],
        onChanged: (v) => setState(() {
          pool = v ?? 'sold';
          if (v == 'create') {
            selectedAction = 'create';
          } else {
            selectedAction = 'draw';
          }
        }),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          PrizeInputField(label: 'รางวัลที่ 1 (บาท)', controller: p1),
          PrizeInputField(label: 'รางวัลที่ 2 (บาท)', controller: p2),
          PrizeInputField(label: 'รางวัลที่ 3 (บาท)', controller: p3),
          PrizeInputField(label: 'รางวัลที่ 4 (บาท)', controller: p4),
          PrizeInputField(label: 'รางวัลที่ 5 (บาท)', controller: p5),
        ],
      ),
    ];
  }

  List<Widget> _buildCreateInterface() {
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สร้างลอตเตอรี่ใหม่',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text('• จะสร้างลอตเตอรี่ใหม่ 120 ใบ'),
            Text('• หมายเลข 6 หลัก (000000-999999)'),
            Text('• ราคา 80 บาท/ใบ'),
            SizedBox(height: 8),
            Text(
              '⚠️ ลอตเตอรี่เก่าจะถูกลบทั้งหมด',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _handleAction(LottoAppState s) async {
    if (selectedAction == 'draw') {
      await _handleDrawAction(s);
    } else {
      await _handleCreateAction(s);
    }
  }

  Future<void> _handleCreateAction(LottoAppState s) async {
    if (!s.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เฉพาะผู้ดูแลระบบเท่านั้นที่สามารถสร้างลอตเตอรี่ได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('สร้างลอตเตอรี่ใหม่'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('จะสร้างลอตเตอรี่ใหม่ 120 ใบ'),
            Text('หมายเลข 6 หลัก (000000-999999)'),
            Text('ราคา 80 บาท/ใบ'),
            SizedBox(height: 8),
            Text(
              'ลอตเตอรี่เก่าจะถูกลบทั้งหมด',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('สร้าง', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
              Text('กำลังสร้างลอตเตอรี่...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      try {
        await s.createLotteryTickets();
        if (mounted) {
          Navigator.of(context).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('สร้างลอตเตอรี่ 120 ใบเรียบร้อย ✅'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
        }
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
  }

  Future<void> _handleDrawAction(LottoAppState s) async {
    if (!s.isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เฉพาะผู้ดูแลระบบเท่านั้นที่สามารถออกรางวัลได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final rewards = [p1, p2, p3, p4, p5]
        .map((c) => int.tryParse(c.text.trim()) ?? 0)
        .toList();

    if (rewards.any((r) => r <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาระบุจำนวนเงินรางวัลให้ถูกต้อง'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('ยืนยันการออกรางวัล'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'ประเภท: ${pool == 'sold' ? 'สุ่มจากลอตเตอรี่ที่ขายไปแล้วเท่านั้น' : 'สุ่มจากลอตเตอรี่ทั้งหมดในระบบ'}'),
            const SizedBox(height: 8),
            const Text('รางวัล:'),
            ...rewards.asMap().entries.map((entry) {
              final tier = entry.key + 1;
              final amount = entry.value;
              return Text('รางวัลที่ $tier: ${formatter.format(amount)} บาท');
            }),
            const SizedBox(height: 16),
            const Text(
              'ต้องการออกรางวัลหรือไม่?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ยืนยัน',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await s.drawPrizes(
        poolType: pool,
        rewards: rewards,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text(
              '🏆 ประกาศผลรางวัล LOTTO!',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ออกรางวัลเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(result.createdAt)}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🏅 ผู้ชนะรางวัล',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.prizes.map((p) {
                      final ticket = s.allTickets.firstWhere(
                        (t) => t.id == p.ticketId || t.number == p.ticketId,
                        orElse: () =>
                            Ticket(id: '', number: p.ticketId, price: 80.0),
                      );
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getTierColor(p.tier).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${p.tier}',
                                  style: TextStyle(
                                    color: _getTierColor(p.tier),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
                                    'รางวัลที่ ${p.tier}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'หมายเลข: ${ticket.number}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${formatter.format(p.amount)} บาท',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'เรียบร้อย',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('DEBUG: Draw error occurred: $e');

      // จัดการ error ตามประเภท
      String errorString = e.toString();

      if (errorString.contains('NO_SOLD_TICKETS') ||
          errorString.contains('ไม่มีตั๋วที่ขายแล้วในระบบ')) {
        // แสดง dialog สำหรับกรณีไม่มีตั๋วที่ขายแล้ว
        if (mounted) {
          final shouldChangeToAll = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF111827),
              title: const Text('ไม่มีตั๋วที่ขายแล้ว'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ไม่มีตั๋วที่ขายแล้วในระบบ'),
                  Text('ไม่สามารถสุ่มออกรางวัลจากตั๋วที่ขายแล้วได้'),
                  SizedBox(height: 16),
                  Text('ต้องการเปลี่ยนเป็นสุ่มจากตั๋วทั้งหมดในระบบหรือไม่?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('เปลี่ยนเป็นทั้งหมด',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );

          if (shouldChangeToAll == true) {
            setState(() {
              pool = 'all';
            });
            // ลองออกรางวัลอีกครั้งด้วย 'all' mode
            _handleDrawAction(s);
            return;
          }
        }
      } else if (errorString.contains('INSUFFICIENT_SOLD_TICKETS') ||
          errorString.contains('มีตั๋วที่ขายแล้วเพียง')) {
        // กรณีตั๋วที่ขายแล้วไม่เพียงพอ
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF111827),
              title: const Text('ตั๋วที่ขายแล้วไม่เพียงพอ'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตั๋วที่ขายแล้วในระบบมีไม่เพียงพอ'),
                  Text('ต้องการ 5 ใบขั้นต่ำสำหรับการออกรางวัล'),
                  SizedBox(height: 16),
                  Text('ข้อแนะนำ:'),
                  Text('1. เปลี่ยนเป็น"สุ่มจากลอตเตอรี่ทั้งหมด"'),
                  Text('2. หรือขายตั๋วเพิ่มเติมก่อน'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('รับทราบ'),
                ),
              ],
            ),
          );
        }
      } else if (errorString.contains('INSUFFICIENT_TICKETS') ||
          errorString.contains('มีตั๋วในระบบเพียง')) {
        // กรณีตั๋วในระบบไม่เพียงพอ (สำหรับ 'all' mode)
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF111827),
              title: const Text('ตั๋วในระบบไม่เพียงพอ'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ตั๋วในระบบมีไม่เพียงพอ'),
                  Text('ต้องการ 5 ใบขั้นต่ำสำหรับการออกรางวัล'),
                  SizedBox(height: 16),
                  Text('กรุณาสร้างตั๋วใหม่ก่อนออกรางวัล'),
                  Text('หรือเลือก "สร้างตั๋วลอตเตอรี่ใหม่" จากเมนู'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('รับทราบ'),
                ),
              ],
            ),
          );
        }
      } else {
        // กรณี error อื่นๆ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $errorString'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusTab(LottoAppState s) {
    return FutureBuilder(
      future: s.getStats(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final st = snap.data as SystemStats;
        final stats = [
          {'title': 'จำนวนสมาชิก', 'value': '${st.totalMembers}'},
          {'title': 'ลอตเตอรี่ที่ขายแล้ว', 'value': '${st.ticketsSold}'},
          {'title': 'ลอตเตอรี่คงเหลือ', 'value': '${st.ticketsLeft}'},
          {
            'title': 'มูลค่าที่ขาย (บาท)',
            'value': formatter.format(st.totalValue.toInt())
          },
        ];

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ภาพรวมระบบ',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                // เปลี่ยนเป็น 2 columns และปรับ aspect ratio
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: stats.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // กลับเป็น 3 columns
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                      childAspectRatio:
                          0.85, // ปรับให้สูงขึ้นเพื่อรองรับข้อความที่ยาว
                    ),
                    itemBuilder: (context, index) {
                      final stat = stats[index];
                      return _buildModernStatCard(
                        title: stat['title']!,
                        value: stat['value']!,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4B5563),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ปรับ font size ให้เหมาะสมกับ 3 columns
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // ลดเป็น 24 เพื่อให้พอดีกับ 3 columns
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ปรับข้อความให้อ่านง่ายขึ้นและรองรับ 3 บรรทัด
            Flexible(
              flex: 2,
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontSize: 11, // ลดเป็น 11 เพื่อให้พอดี
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 3, // เพิ่มเป็น 3 บรรทัดเพื่อรองรับข้อความยาว
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetTab(LottoAppState s) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: const Color(0xFF7F1D1D),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'รีเซ็ตระบบทั้งหมด',
                style: TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              const Text(
                'คำเตือน: จะลบข้อมูลสมาชิก, ลอตเตอรี่ที่ขายแล้ว และผลรางวัลทั้งหมด เหลือเฉพาะเจ้าของระบบ',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF111827),
                          title: const Text('ยืนยันการรีเซ็ตระบบ'),
                          content:
                              const Text('ต้องการรีเซ็ตระบบทั้งหมดหรือไม่?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ยกเลิก'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('ยืนยัน'),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (ok) {
                    await s.resetAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('รีเซ็ตระบบเรียบร้อย')),
                      );
                    }
                  }
                },
                child: const Text(
                  'ยืนยันการรีเซ็ตระบบ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
