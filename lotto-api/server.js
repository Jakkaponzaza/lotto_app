const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const mysql = require('mysql2/promise');
const cors = require('cors');
require('dotenv').config();

// Create Express app and HTTP server
const app = express();
const server = http.createServer(app);

// Get port from environment variable (Render) or default to 3000
const PORT = process.env.PORT || 3000;

const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Database connection config
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  charset: 'utf8mb4',
  timezone: '+00:00'
};

console.log('=== LOTTO WEBSOCKET SERVER ===');
console.log('Host:', dbConfig.host);
console.log('User:', dbConfig.user);
console.log('Database:', dbConfig.database);
console.log('Port:', dbConfig.port);

// Helper function to get database connection
async function getConnection() {
  try {
    const connection = await mysql.createConnection(dbConfig);
    console.log('Database connection established');
    return connection;
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }
}

// Helper function to create required tables if they don't exist
async function initializeDatabase() {
  try {
    const connection = await getConnection();
    try {
      console.log('🗃️ Checking and creating required tables...');

      // Check if Prize table exists
      const [prizeTables] = await connection.execute(
        "SHOW TABLES LIKE 'Prize'"
      );

      if (prizeTables.length === 0) {
        console.log('📝 Creating Prize table with 3 columns only...');
        await connection.execute(`
          CREATE TABLE Prize (
            prize_id INT AUTO_INCREMENT PRIMARY KEY,
            amount DECIMAL(10,2) NOT NULL,
            \`rank\` INT NOT NULL,
            
            INDEX idx_prize_rank (\`rank\`)
          )
        `);
        console.log('✅ Prize table created successfully with 3 columns');
      } else {
        // Check if Prize table has the correct structure
        const [amountColumns] = await connection.execute(
          "SHOW COLUMNS FROM Prize LIKE 'amount'"
        );

        if (amountColumns.length === 0) {
          console.log('🔄 Prize table exists but using old structure, recreating with 3 columns...');

          // ลบ foreign key constraints ก่อน
          try {
            await connection.execute('ALTER TABLE Ticket DROP FOREIGN KEY Ticket_ibfk_3');
            console.log('✅ Dropped foreign key constraint Ticket_ibfk_3');
          } catch (error) {
            console.log('⚠️ Foreign key Ticket_ibfk_3 may not exist:', error.message);
          }

          try {
            await connection.execute('ALTER TABLE Ticket DROP COLUMN prize_id');
            console.log('✅ Dropped prize_id column from Ticket');
          } catch (error) {
            console.log('⚠️ prize_id column may not exist:', error.message);
          }

          // ลบตาราง Prize
          await connection.execute('DROP TABLE IF EXISTS Prize');
          console.log('✅ Dropped Prize table');

          // สร้างตาราง Prize ใหม่ด้วย 3 columns เท่านั้น
          await connection.execute(`
            CREATE TABLE Prize (
              prize_id INT AUTO_INCREMENT PRIMARY KEY,
              amount DECIMAL(10,2) NOT NULL,
              \`rank\` INT NOT NULL,
              
              INDEX idx_prize_rank (\`rank\`)
            )
          `);
          console.log('✅ Prize table recreated successfully with 3 columns only');
        }
      }

      console.log('✅ Database initialization completed');

    } finally {
      await connection.end();
    }
  } catch (error) {
    console.error('❌ Error initializing database:', error);
  }
}

// Helper function to generate lottery tickets if none exist
async function initializeLotteryTickets() {
  try {
    const connection = await getConnection();
    try {
      // Check if tickets already exist
      const [existingTickets] = await connection.execute('SELECT COUNT(*) as count FROM Ticket');
      const ticketCount = existingTickets[0].count;

      if (ticketCount === 0) {
        console.log('🎫 No lottery tickets found, creating initial 120 tickets...');

        // หา admin/owner user_id สำหรับใส่เป็น created_by
        const [adminUser] = await connection.execute(
          "SELECT user_id FROM User WHERE role IN ('owner', 'admin') ORDER BY user_id LIMIT 1"
        );
        const adminUserId = adminUser.length > 0 ? adminUser[0].user_id : 1; // fallback เป็น 1

        const desiredCount = 120;
        const price = 80.00;
        const numbersSet = new Set();

        // สร้างหมายเลขสุ่ม 6 หลัก (000000-999999) จำนวน 120 ชุด
        while (numbersSet.size < desiredCount) {
          const n = Math.floor(Math.random() * 1000000); // 0-999999
          const s = n.toString().padStart(6, '0'); // เติม 0 ข้างหน้าให้ครบ 6 หลัก
          numbersSet.add(s);
        }
        const numbers = Array.from(numbersSet);

        const batchSize = 50;
        let inserted = 0;
        for (let i = 0; i < numbers.length; i += batchSize) {
          const batch = numbers.slice(i, i + batchSize);
          // ใส่ admin user_id เป็น created_by แทน NULL
          const placeholders = batch.map(() => '(?, ?, ?, ?, ?)').join(',');
          const values = [];
          const currentDate = new Date();
          for (const num of batch) {
            values.push(num, price, currentDate, currentDate, adminUserId); // number, price, start_date, end_date, created_by
          }
          await connection.execute(`INSERT INTO Ticket (number, price, start_date, end_date, created_by) VALUES ${placeholders}`, values);
          inserted += batch.length;
        }

        console.log(`✅ Created ${inserted} initial lottery tickets successfully!`);
      } else {
        console.log(`🎫 Found ${ticketCount} existing lottery tickets`);
      }
    } finally {
      await connection.end();
    }
  } catch (error) {
    console.error('❌ Error initializing lottery tickets:', error);
  }
}

// Store active connections and their states
const activeConnections = new Map();
const userSessions = new Map();

// User session class to maintain state
class UserSession {
  constructor(socketId, userId = null) {
    this.socketId = socketId;
    this.userId = userId;
    this.username = null;
    this.role = null;
    this.wallet = 0;
    this.isAuthenticated = false;
    this.selectedTickets = [];
    this.lastActivity = new Date();
    this.connectionTime = new Date();
  }

  authenticate(userData) {
    this.userId = userData.user_id;
    this.username = userData.username;
    this.role = userData.role;
    this.wallet = userData.wallet;
    this.isAuthenticated = true;
    this.lastActivity = new Date();
  }

  updateWallet(newAmount) {
    this.wallet = newAmount;
    this.lastActivity = new Date();
  }

  addSelectedTicket(ticketId) {
    if (!this.selectedTickets.includes(ticketId)) {
      this.selectedTickets.push(ticketId);
    }
    this.lastActivity = new Date();
  }

  removeSelectedTicket(ticketId) {
    this.selectedTickets = this.selectedTickets.filter(id => id !== ticketId);
    this.lastActivity = new Date();
  }

  clearSelectedTickets() {
    this.selectedTickets = [];
    this.lastActivity = new Date();
  }

  getSessionInfo() {
    return {
      socketId: this.socketId,
      userId: this.userId,
      username: this.username,
      role: this.role,
      wallet: this.wallet,
      isAuthenticated: this.isAuthenticated,
      selectedTickets: this.selectedTickets,
      lastActivity: this.lastActivity,
      connectionTime: this.connectionTime,
      connectionDuration: new Date() - this.connectionTime
    };
  }
}

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log(`\n🔌 NEW CONNECTION: ${socket.id}`);

  // Create new user session
  const session = new UserSession(socket.id);
  activeConnections.set(socket.id, session);

  // Send connection confirmation
  socket.emit('connected', {
    socketId: socket.id,
    timestamp: new Date().toISOString(),
    message: 'Connected to Lotto Server'
  });

  // Authentication handlers
  socket.on('auth:login', async (data) => {
    console.log(`🔐 LOGIN ATTEMPT: ${socket.id} - ${data.username}`);

    try {
      const { username, password } = data;

      if (!username || !password) {
        socket.emit('auth:error', { error: 'กรุณาระบุ username และ password' });
        return;
      }

      const connection = await getConnection();
      try {
        const [users] = await connection.execute(
          'SELECT user_id, username, role, wallet, email, phone, password FROM User WHERE username = ?',
          [username]
        );

        if (users.length === 0) {
          socket.emit('auth:error', { error: 'ไม่พบผู้ใช้นี้' });
          return;
        }

        const user = users[0];
        if (password !== user.password) {
          socket.emit('auth:error', { error: 'รหัสผ่านไม่ถูกต้อง' });
          return;
        }

        // Authenticate user in session
        session.authenticate(user);
        userSessions.set(user.user_id, session);

        // Send success response with complete user data
        const responseUser = {
          user_id: user.user_id,
          username: user.username,
          role: user.role,
          wallet: parseFloat(user.wallet),
          initial_wallet: parseFloat(user.wallet),
          current_wallet: parseFloat(user.wallet),
          email: user.email,
          phone: user.phone,
          password_hash: 'login_hash',
          password_algo: 'bcrypt',
          email_verified_at: null,
          phone_verified_at: null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          sessionInfo: session.getSessionInfo()
        };

        console.log('📤 Sending auth:success response:');
        console.log('Response data:', JSON.stringify({
          user: responseUser,
          isAdmin: user.role === 'owner' || user.role === 'admin',
          message: 'เข้าสู่ระบบสำเร็จ'
        }, null, 2));

        socket.emit('auth:success', {
          user: responseUser,
          isAdmin: user.role === 'owner' || user.role === 'admin',
          message: 'เข้าสู่ระบบสำเร็จ'
        });

        // Broadcast user joined (to admins)
        socket.broadcast.emit('user:joined', {
          userId: user.user_id,
          username: user.username,
          role: user.role
        });

        console.log(`✅ LOGIN SUCCESS: ${username} (${socket.id})`);

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Login error:', error);
      socket.emit('auth:error', { error: 'เกิดข้อผิดพลาดในระบบ' });
    }
  });

  socket.on('auth:register', async (data) => {
    console.log(`📝 REGISTER ATTEMPT: ${socket.id} - ${data.username}`);

    try {
      const { username, email, phone, password, role = 'member', wallet } = data;

      if (!username || !email || !phone || !password) {
        socket.emit('auth:error', { error: 'กรุณาระบุข้อมูลให้ครบถ้วน' });
        return;
      }

      if (wallet === undefined || wallet === null) {
        socket.emit('auth:error', { error: 'กรุณาระบุจำนวนเงินเริ่มต้น' });
        return;
      }

      const walletAmount = parseFloat(wallet);
      if (isNaN(walletAmount) || walletAmount < 0) {
        socket.emit('auth:error', { error: 'จำนวนเงินไม่ถูกต้อง' });
        return;
      }

      const connection = await getConnection();
      try {
        // Check for existing users
        const [existingUsers] = await connection.execute(
          'SELECT user_id, username, email, phone FROM User WHERE username = ? OR email = ? OR phone = ?',
          [username, email, phone]
        );

        if (existingUsers.length > 0) {
          const existing = existingUsers[0];
          if (existing.username === username) {
            socket.emit('auth:error', { error: 'ชื่อผู้ใช้ถูกใช้แล้ว' });
            return;
          }
          if (existing.email === email) {
            socket.emit('auth:error', { error: 'อีเมลนี้ถูกใช้แล้ว' });
            return;
          }
          if (existing.phone === phone) {
            socket.emit('auth:error', { error: 'หมายเลขโทรศัพท์นี้ถูกใช้แล้ว' });
            return;
          }
        }

        // Create new user
        const insertQuery = `
          INSERT INTO User (username, email, phone, role, password, wallet) 
          VALUES (?, ?, ?, ?, ?, ?)
        `;

        const [result] = await connection.execute(insertQuery, [
          username, email, phone, role, password, walletAmount
        ]);

        // Get created user
        const [newUser] = await connection.execute(
          'SELECT user_id, username, role, wallet, email, phone FROM User WHERE user_id = ?',
          [result.insertId]
        );

        const user = newUser[0];

        // Authenticate user in session
        session.authenticate(user);
        userSessions.set(user.user_id, session);

        const responseUser = {
          user_id: user.user_id,
          username: user.username,
          role: user.role,
          wallet: parseFloat(user.wallet),
          initial_wallet: parseFloat(user.wallet),
          current_wallet: parseFloat(user.wallet),
          email: user.email,
          phone: user.phone,
          password_hash: 'register_hash',
          password_algo: 'bcrypt',
          email_verified_at: null,
          phone_verified_at: null,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          sessionInfo: session.getSessionInfo()
        };

        socket.emit('auth:success', {
          user: responseUser,
          isAdmin: false,
          message: 'สมัครสมาชิกสำเร็จ'
        });

        console.log(`✅ REGISTER SUCCESS: ${username} (${socket.id})`);

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Register error:', error);
      socket.emit('auth:error', { error: 'เกิดข้อผิดพลาดในระบบ' });
    }
  });

  // Ticket management handlers
  socket.on('tickets:get-all', async () => {
    console.log(`🎫 GET ALL TICKETS: ${socket.id}`);

    try {
      const connection = await getConnection();
      try {
        const [tickets] = await connection.execute(
          'SELECT ticket_id, number, price, status, created_by AS owner_id FROM Ticket ORDER BY number'
        );

        const allTickets = tickets.map(ticket => ({
          id: ticket.ticket_id,
          number: ticket.number,
          price: parseFloat(ticket.price),
          status: ticket.status,
          owner_id: ticket.owner_id
        }));

        console.log(`📤 Sending ${allTickets.length} tickets to client ${socket.id}`);
        console.log('First 3 tickets:', allTickets.slice(0, 3));

        socket.emit('tickets:list', allTickets);
        console.log(`✅ Tickets sent successfully to ${socket.id}`);
      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Get tickets error:', error);
      socket.emit('error', { error: 'เกิดข้อผิดพลาดในการดึงรายการลอตเตอรี่' });
    }
  });

  socket.on('tickets:get-user', async (data) => {
    console.log(`🎫 GET USER TICKETS: ${socket.id} - User: ${data.userId}`);

    if (!session.isAuthenticated) {
      socket.emit('auth:required', { error: 'กรุณาเข้าสู่ระบบก่อน' });
      return;
    }

    try {
      const connection = await getConnection();
      try {
        const [tickets] = await connection.execute(
          'SELECT ticket_id, number, price, status FROM Ticket WHERE created_by = ? ORDER BY ticket_id DESC',
          [data.userId]
        );

        const userTickets = tickets.map(ticket => ({
          id: ticket.ticket_id,
          number: ticket.number,
          price: parseFloat(ticket.price),
          status: ticket.status,
          owner_id: data.userId
        }));

        socket.emit('tickets:user-list', userTickets);
        console.log(`🎫 Sent ${userTickets.length} user tickets to user ${data.userId}`);
      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Get user tickets error:', error);
      socket.emit('error', { error: 'เกิดข้อผิดพลาดในการดึงลอตเตอรี่ของผู้ใช้' });
    }
  });

  socket.on('tickets:select', (data) => {
    console.log(`🎯 SELECT TICKET: ${socket.id} - Ticket: ${data.ticketId}`);

    if (!session.isAuthenticated) {
      socket.emit('auth:required', { error: 'กรุณาเข้าสู่ระบบก่อน' });
      return;
    }

    session.addSelectedTicket(data.ticketId);

    socket.emit('tickets:selected', {
      ticketId: data.ticketId,
      selectedTickets: session.selectedTickets,
      message: `เลือกลอตเตอรี่ ${data.ticketId} แล้ว`
    });
  });

  socket.on('tickets:deselect', (data) => {
    console.log(`❌ DESELECT TICKET: ${socket.id} - Ticket: ${data.ticketId}`);

    if (!session.isAuthenticated) {
      socket.emit('auth:required', { error: 'กรุณาเข้าสู่ระบบก่อน' });
      return;
    }

    session.removeSelectedTicket(data.ticketId);

    socket.emit('tickets:deselected', {
      ticketId: data.ticketId,
      selectedTickets: session.selectedTickets,
      message: `ยกเลิกลอตเตอรี่ ${data.ticketId} แล้ว`
    });
  });

  socket.on('tickets:purchase', async (data) => {
    console.log(`💰 PURCHASE TICKETS: ${socket.id} - Tickets: ${data.ticketIds}`);

    if (!session.isAuthenticated) {
      socket.emit('auth:required', { error: 'กรุณาเข้าสู่ระบบก่อน' });
      return;
    }

    try {
      const { ticketIds } = data;
      const userId = session.userId;

      if (!ticketIds || !Array.isArray(ticketIds) || ticketIds.length === 0) {
        socket.emit('purchase:error', { error: 'กรุณาเลือกลอตเตอรี่ที่ต้องการซื้อ' });
        return;
      }

      const connection = await getConnection();
      try {
        // Get ticket prices
        const placeholders = ticketIds.map(() => '?').join(',');
        const [tickets] = await connection.execute(
          `SELECT ticket_id, number, price FROM Ticket WHERE ticket_id IN (${placeholders}) AND status = 'available'`,
          ticketIds
        );

        if (tickets.length !== ticketIds.length) {
          socket.emit('purchase:error', { error: 'บางตั๋วไม่พร้อมใช้งานหรือไม่พบ' });
          return;
        }

        const totalCost = tickets.reduce((sum, ticket) => sum + parseFloat(ticket.price), 0);

        if (session.wallet < totalCost) {
          socket.emit('purchase:error', {
            error: 'ยอดเงินไม่เพียงพอ',
            required: totalCost,
            available: session.wallet
          });
          return;
        }

        // Update user wallet
        const newWallet = session.wallet - totalCost;
        await connection.execute(
          'UPDATE User SET wallet = ? WHERE user_id = ?',
          [newWallet, userId]
        );

        // Update ticket status
        await connection.execute(
          `UPDATE Ticket SET status = 'sold', created_by = ? WHERE ticket_id IN (${placeholders})`,
          [userId, ...ticketIds]
        );

        // Create purchase record
        const [purchaseResult] = await connection.execute(
          'INSERT INTO Purchase (user_id, date, total_price) VALUES (?, NOW(), ?)',
          [userId, totalCost]
        );

        // Update ticket with purchase_id
        await connection.execute(
          `UPDATE Ticket SET purchase_id = ? WHERE ticket_id IN (${placeholders})`,
          [purchaseResult.insertId, ...ticketIds]
        );

        // Update session wallet
        session.updateWallet(newWallet);
        session.clearSelectedTickets();

        // Emit success to user
        socket.emit('purchase:success', {
          purchasedTickets: ticketIds,
          totalCost: totalCost,
          remainingWallet: newWallet,
          message: `ซื้อหวย ${ticketIds.length} ใบ เป็นเงิน ${totalCost} บาท เรียบร้อย`
        });

        // Broadcast to all clients about ticket status change
        io.emit('tickets:updated', {
          ticketIds: ticketIds,
          status: 'sold',
          owner: userId
        });

        // Send updated user tickets to the purchasing user
        const [updatedUserTickets] = await connection.execute(
          'SELECT ticket_id, number, price, status FROM Ticket WHERE created_by = ? ORDER BY ticket_id DESC',
          [userId]
        );

        const userTicketsList = updatedUserTickets.map(ticket => ({
          id: ticket.ticket_id,
          number: ticket.number,
          price: parseFloat(ticket.price),
          status: ticket.status,
          owner_id: userId
        }));

        socket.emit('tickets:user-list', userTicketsList);
        console.log(`🎫 Sent updated user tickets (${userTicketsList.length} tickets) to user ${userId}`);

        console.log(`✅ PURCHASE SUCCESS: User ${userId} bought ${ticketIds.length} tickets`);

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Purchase error:', error);
      socket.emit('purchase:error', { error: 'เกิดข้อผิดพลาดในการซื้อลอตเตอรี่' });
    }
  });

  // Admin handlers
  socket.on('admin:get-stats', async () => {
    console.log(`📊 GET ADMIN STATS: ${socket.id}`);

    if (!session.isAuthenticated || (session.role !== 'owner' && session.role !== 'admin')) {
      socket.emit('auth:forbidden', { error: 'ไม่มีสิทธิ์เข้าถึง' });
      return;
    }

    try {
      const connection = await getConnection();
      try {
        const [memberCount] = await connection.execute(
          'SELECT COUNT(*) as total FROM User WHERE role = "member"'
        );
        const [soldTickets] = await connection.execute(
          'SELECT COUNT(*) as total FROM Ticket WHERE status = "sold"'
        );
        const [totalTickets] = await connection.execute(
          'SELECT COUNT(*) as total FROM Ticket'
        );
        const [totalValue] = await connection.execute(
          'SELECT SUM(price) as total FROM Ticket WHERE status = "sold"'
        );

        const stats = {
          totalMembers: memberCount[0].total,
          ticketsSold: soldTickets[0].total,
          ticketsLeft: totalTickets[0].total - soldTickets[0].total,
          totalValue: totalValue[0].total || 0,
          activeConnections: activeConnections.size,
          authenticatedUsers: Array.from(activeConnections.values()).filter(s => s.isAuthenticated).length
        };

        socket.emit('admin:stats', stats);
      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Get stats error:', error);
      socket.emit('error', { error: 'เกิดข้อผิดพลาดในการดึงสถิติ' });
    }
  });

  // Session management
  socket.on('session:get-info', () => {
    socket.emit('session:info', session.getSessionInfo());
  });

  socket.on('session:get-all', () => {
    if (!session.isAuthenticated || (session.role !== 'owner' && session.role !== 'admin')) {
      socket.emit('auth:forbidden', { error: 'ไม่มีสิทธิ์เข้าถึง' });
      return;
    }

    const allSessions = Array.from(activeConnections.values()).map(s => s.getSessionInfo());
    socket.emit('session:all', allSessions);
  });

  // Force create lottery tickets handler
  socket.on('admin:create-tickets', async () => {
    console.log(`🎫 FORCE CREATE TICKETS: ${socket.id}`);

    if (!session.isAuthenticated || (session.role !== 'owner' && session.role !== 'admin')) {
      socket.emit('auth:forbidden', { error: 'ไม่มีสิทธิ์เข้าถึง' });
      return;
    }

    try {
      const connection = await getConnection();
      try {
        console.log('🎫 Force creating 120 lottery tickets...');

        // ลบลอตเตอรี่เก่าทั้งหมดก่อน
        await connection.execute('DELETE FROM Ticket');

        // หา admin user_id สำหรับ created_by
        const [adminUser] = await connection.execute(
          "SELECT user_id FROM User WHERE role IN ('owner', 'admin') ORDER BY user_id LIMIT 1"
        );
        const adminUserId = adminUser.length > 0 ? adminUser[0].user_id : 1;

        const desiredCount = 120;
        const price = 80.00;
        const numbersSet = new Set();

        // สร้างหมายเลขสุ่ม 6 หลัก (000000-999999) จำนวน 120 ชุด
        while (numbersSet.size < desiredCount) {
          const n = Math.floor(Math.random() * 1000000); // 0-999999
          const s = n.toString().padStart(6, '0'); // เติม 0 ข้างหน้าให้ครบ 6 หลัก
          numbersSet.add(s);
        }
        const numbers = Array.from(numbersSet);

        const batchSize = 50;
        let inserted = 0;
        for (let i = 0; i < numbers.length; i += batchSize) {
          const batch = numbers.slice(i, i + batchSize);
          const placeholders = batch.map(() => '(?, ?, ?, ?, ?)').join(',');
          const values = [];
          const currentDate = new Date();
          for (const num of batch) {
            values.push(num, price, currentDate, currentDate, adminUserId); // number, price, start_date, end_date, created_by
          }
          await connection.execute(`INSERT INTO Ticket (number, price, start_date, end_date, created_by) VALUES ${placeholders}`, values);
          inserted += batch.length;
        }

        console.log(`✅ Force created ${inserted} lottery tickets successfully!`);

        // ส่งกลับไปยัง client
        socket.emit('admin:tickets-created', {
          success: true,
          message: `สร้างลอตเตอรี่เรียบร้อย จำนวน ${inserted} ใบ`,
          ticketsCreated: inserted
        });

        // แจ้งให้ client ทั้งหมดทราบ
        io.emit('tickets:updated', {
          message: 'มีลอตเตอรี่ใหม่แล้ว',
          ticketsCreated: inserted
        });

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.log('\n=== CREATE TICKETS ERROR ===');
      console.error('Error details:', error);
      socket.emit('error', {
        error: 'เกิดข้อผิดพลาดในการสร้างลอตเตอรี่',
        details: error.message
      });
    }
  });

  // Admin draw prizes handler - Simplified version using only Prize table
  socket.on('admin:draw-prizes', async (data) => {
    console.log(`🎯 ADMIN DRAW PRIZES REQUEST: ${socket.id}`);

    if (!session.isAuthenticated || (session.role !== 'owner' && session.role !== 'admin')) {
      socket.emit('auth:forbidden', { error: 'ไม่มีสิทธิ์เข้าถึง' });
      return;
    }

    try {
      const { poolType, rewards } = data;

      if (!poolType || !rewards || !Array.isArray(rewards) || rewards.length !== 5) {
        socket.emit('admin:draw-error', { error: 'ข้อมูลไม่ถูกต้อง กรุณาระบุประเภทพูลและรางวัล 5 รางวัล' });
        return;
      }

      // ตรวจสอบว่าจำนวนเงินรางวัลถูกต้อง
      if (rewards.some(r => !r || r <= 0)) {
        socket.emit('admin:draw-error', { error: 'กรุณาระบุจำนวนเงินรางวัลให้ถูกต้อง' });
        return;
      }

      const connection = await getConnection();
      try {
        console.log(`🎯 Drawing prizes with pool type: ${poolType}`);

        // ดึงตั๋วที่จะใช้ในการสุ่ม
        let query;
        let params = [];

        if (poolType === 'sold') {
          query = 'SELECT ticket_id, number FROM Ticket WHERE status = "sold" ORDER BY RAND()';
        } else {
          query = 'SELECT ticket_id, number FROM Ticket ORDER BY RAND()';
        }

        const [ticketPool] = await connection.execute(query, params);

        // ตรวจสอบกรณีเลือกตั๋วที่ขายแล้วแต่ไม่มีตั๋วที่ขายแล้ว
        if (poolType === 'sold' && ticketPool.length === 0) {
          console.log('⚠️ No sold tickets available for drawing');
          socket.emit('admin:draw-error', {
            error: 'ไม่มีตั๋วที่ขายแล้วในระบบ',
            code: 'NO_SOLD_TICKETS',
            suggestion: 'เปลี่ยนเป็นสุ่มจากตั๋วทั้งหมดหรือขายตั๋วก่อน'
          });
          return;
        }

        if (ticketPool.length < 5) {
          console.log(`⚠️ Only ${ticketPool.length} tickets available, need 5 minimum`);

          if (poolType === 'sold') {
            // สำหรับ 'sold' pool type - ไม่เพียงพอ
            socket.emit('admin:draw-error', {
              error: `มีตั๋วที่ขายแล้วเพียง ${ticketPool.length} ใบ ต้องการ 5 ใบขั้นต่ำ`,
              code: 'INSUFFICIENT_SOLD_TICKETS'
            });
          } else {
            // สำหรับ 'all' pool type - ไม่เพียงพอ
            socket.emit('admin:draw-error', {
              error: `มีตั๋วในระบบเพียง ${ticketPool.length} ใบ ต้องการ 5 ใบขั้นต่ำ`,
              code: 'INSUFFICIENT_TICKETS',
              suggestion: 'กรุณาสร้างตั๋วใหม่ก่อนออกรางวัล'
            });
          }
          return;
        }

        console.log(`🎯 Found ${ticketPool.length} tickets in pool for drawing`);

        // สุ่มเลือก 5 ตั๋วที่ไม่ซ้ำกัน
        const shuffled = [...ticketPool].sort(() => 0.5 - Math.random());
        const winningTickets = shuffled.slice(0, 5);

        console.log('🎯 Selected winning tickets:', winningTickets.map(t => t.number));

        // สร้าง Prize records โดยตรงใน Prize table (ใช้เฉพาะ 3 columns)
        const prizePromises = winningTickets.map((ticket, index) => {
          const rank = index + 1;
          const amount = rewards[index];

          return connection.execute(
            'INSERT INTO Prize (amount, `rank`) VALUES (?, ?)',
            [amount, rank]
          );
        });

        await Promise.all(prizePromises);

        // ดึงข้อมูลรางวัลที่เพิ่งสร้าง (ใช้เฉพาะ 3 columns)
        const [newPrizes] = await connection.execute(
          'SELECT prize_id, amount, `rank` FROM Prize ORDER BY prize_id DESC LIMIT 5'
        );

        const drawResultData = {
          id: `draw_${Date.now()}`,
          poolType: poolType,
          createdAt: new Date().toISOString(),
          prizes: newPrizes.reverse().map((p, index) => ({
            tier: p.rank,
            ticketId: winningTickets[index] ? winningTickets[index].number : `หมายเลข ${p.rank}`,
            amount: parseFloat(p.amount), // ใช้ amount แทน amont
            claimed: false
          }))
        };

        console.log('🎯 Draw completed successfully!');
        console.log('🏆 Winning numbers:', winningTickets.map((t, i) => `${i + 1}: ${t.number} (${rewards[i]} บาท)`));

        // ส่งผลลัพธ์กลับไปยัง admin
        socket.emit('admin:draw-success', {
          success: true,
          drawResult: drawResultData,
          message: `ออกรางวัล ${poolType === 'sold' ? 'จากตั๋วที่ขายแล้ว' : 'จากตั๋วทั้งหมด'} เรียบร้อย`
        });

        // แจ้งไปยัง client ทั้งหมดว่ามีการออกรางวัลใหม่
        io.emit('draw:new-result', {
          drawResult: drawResultData,
          message: '🏆 มีการออกรางวัลใหม่!'
        });

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Draw prizes error:', error);
      socket.emit('admin:draw-error', {
        error: 'เกิดข้อผิดพลาดในการออกรางวัล',
        details: error.message
      });
    }
  });

  // Get latest draw result handler - Simplified version
  socket.on('draw:get-latest', async () => {
    console.log(`📊 GET LATEST DRAW: ${socket.id}`);

    try {
      const connection = await getConnection();
      try {
        // ดึงรางวัลล่าสุด 5 รางวัลจาก Prize table (ใช้เฉพาะ 3 columns)
        const [prizes] = await connection.execute(
          'SELECT prize_id, amount, `rank` FROM Prize ORDER BY prize_id DESC LIMIT 5'
        );

        if (prizes.length === 0) {
          socket.emit('draw:latest-result', { drawResult: null });
          return;
        }

        const drawResultData = {
          id: `draw_simple`,
          poolType: 'all',
          createdAt: new Date().toISOString(),
          prizes: prizes.map(p => ({
            tier: p.rank,
            ticketId: `รางวัลที่ ${p.rank}`,
            amount: parseFloat(p.amount), // ใช้ amount แทน amont
            claimed: false
          }))
        };

        socket.emit('draw:latest-result', { drawResult: drawResultData });

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.error('Get latest draw error:', error);
      socket.emit('error', { error: 'เกิดข้อผิดพลาดในการดึงผลรางวัลล่าสุด' });
    }
  });

  // Admin reset handler
  socket.on('admin:reset', async () => {
    console.log(`🔄 ADMIN RESET REQUEST: ${socket.id}`);

    if (!session.isAuthenticated || (session.role !== 'owner' && session.role !== 'admin')) {
      socket.emit('auth:forbidden', { error: 'ไม่มีสิทธิ์เข้าถึง' });
      return;
    }

    try {
      const connection = await getConnection();
      try {
        console.log('🖾️ Resetting system - clearing data...');

        // Clear prizes (lottery draw results)
        try {
          await connection.execute('DELETE FROM Prize');
          await connection.execute('ALTER TABLE Prize AUTO_INCREMENT = 1');
          console.log('✅ Cleared prize data and reset prize_id counter');
        } catch (error) {
          console.log('⚠️ Prize table may not exist yet:', error.message);
        }

        // Clear purchases and tickets
        try {
          await connection.execute('DELETE FROM Purchase');
          await connection.execute('ALTER TABLE Purchase AUTO_INCREMENT = 1');
          console.log('✅ Cleared purchase data and reset purchase_id counter');
        } catch (error) {
          console.log('⚠️ Purchase table may not exist yet:', error.message);
        }

        // Delete all tickets
        await connection.execute('DELETE FROM Ticket');
        console.log('✅ Cleared all ticket data');

        // Reset AUTO_INCREMENT counter for Ticket table
        await connection.execute('ALTER TABLE Ticket AUTO_INCREMENT = 1');
        console.log('✅ Reset ticket_id counter to start from 1');

        // Delete all member users (keep admin and owner)
        await connection.execute("DELETE FROM User WHERE role = 'member'");
        console.log('✅ Cleared member users');

        console.log('=== RESET SUCCESS ===');
        console.log('✅ System reset completed');
        console.log('🎫 No new tickets created - create manually from admin page if needed');
        console.log('👤 Kept admin/owner accounts only');

        // Notify all clients about the reset
        io.emit('admin:reset-success', {
          message: 'รีเซ็ตระบบเรียบร้อย',
          ticketsCreated: 0
        });

        socket.emit('admin:reset-success', {
          success: true,
          message: 'รีเซ็ตระบบเรียบร้อย ตั๋วทั้งหมดถูกลบแล้ว สามารถสร้างตั๋วใหม่จากหน้า admin ได้',
          ticketsCreated: 0
        });

      } finally {
        await connection.end();
      }
    } catch (error) {
      console.log('\n=== RESET ERROR ===');
      console.error('Error details:', error);
      socket.emit('error', {
        error: 'เกิดข้อผิดพลาดในการรีเซ็ตระบบ',
        details: error.message
      });
    }
  });

  // Disconnect handler
  socket.on('disconnect', () => {
    console.log(`🔌 DISCONNECTED: ${socket.id}`);

    const session = activeConnections.get(socket.id);
    if (session && session.isAuthenticated) {
      userSessions.delete(session.userId);

      // Broadcast user left
      socket.broadcast.emit('user:left', {
        userId: session.userId,
        username: session.username,
        role: session.role
      });

      console.log(`👤 USER LEFT: ${session.username} (${socket.id})`);
    }

    activeConnections.delete(socket.id);
    console.log(`📊 Active connections: ${activeConnections.size}`);
  });

  // Error handler
  socket.on('error', (error) => {
    console.error(`❌ SOCKET ERROR: ${socket.id}`, error);
  });
});

// No REST API endpoints - WebSocket only server
require('dotenv').config(); // โหลดค่า .env (คุณมีแล้ว)

// Use the PORT from environment for Render deployment
// const PORT = process.env.PORT || 3000; (moved up)
server.listen(PORT, () => {
  console.log(`🚀 WebSocket Lotto Server running on port ${PORT}`);
  console.log(`🌐 WebSocket Server ready for connections`);
  console.log(`📊 Server Type: Stateful WebSocket with Real-time Updates`);

  // Initialize database and create required tables
  initializeDatabase();

  // Initialize lottery tickets if needed
  initializeLotteryTickets();
});