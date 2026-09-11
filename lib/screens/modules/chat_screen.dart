import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_upload_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _activeTab = 0; // 0: Members, 1: Groups
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();

  String? _selectedChatName;
  String? _selectedChatSubtitle;

  final List<Map<String, dynamic>> _members = [
    {'name': 'Dhanush', 'subtitle': 'Mmmm', 'time': '03:20 PM', 'avatar': 'D', 'isOnline': true},
    {'name': 'Aruna', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'A', 'isOnline': false},
    {'name': 'Iniya', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'I', 'isOnline': false},
    {'name': 'Kalaivani', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'K', 'isOnline': false},
    {'name': 'Kannan', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'K', 'isOnline': true},
    {'name': 'Kavin', 'subtitle': 'Admin • admin', 'time': '', 'avatar': 'K', 'isOnline': true, 'isAdmin': true},
    {'name': 'Kavin Kumar', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'K', 'isOnline': false},
    {'name': 'Krishna', 'subtitle': 'Full stack developer • employee', 'time': '', 'avatar': 'K', 'isOnline': true},
    {'name': 'Lohit', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'L', 'isOnline': false},
    {'name': 'Sachin', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'S', 'isOnline': false},
    {'name': 'Sri Hari', 'subtitle': 'No messages yet', 'time': '', 'avatar': 'S', 'isOnline': false},
  ];

  final List<Map<String, dynamic>> _groups = [
    {
      'name': 'Developers',
      'subtitle': 'Yudesh: ☕ Coffee Break',
      'time': '03:23 PM',
      'avatar': 'DEV',
      'isGroup': true,
    },
    {
      'name': 'VA Chat Team',
      'subtitle': 'Sabarishwaran: BLoC architecture implemented',
      'time': '11:20 AM',
      'avatar': 'VA',
      'isGroup': true,
    },
    {
      'name': 'SRIVA Announcements',
      'subtitle': 'HR: Monthly review meeting at 4 PM',
      'time': '09:00 AM',
      'avatar': 'SRI',
      'isGroup': true,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _messagesMap = {
    'Dhanush': [
      {'sender': 'Dhanush', 'text': 'Hey Sabari, are you working on the shift tracker mobile app?', 'time': '03:15 PM', 'isMe': false},
      {'sender': 'Me', 'text': 'Yes nanba! Converting all the web dashboard modules into Flutter with BLoC.', 'time': '03:18 PM', 'isMe': true},
      {'sender': 'Dhanush', 'text': 'Mmmm', 'time': '03:20 PM', 'isMe': false},
    ],
    'Developers': [
      {'sender': 'Yudesh', 'text': 'Coffee Break ☕ who is coming?', 'time': '03:23 PM', 'isMe': false},
      {'sender': 'Kavin', 'text': 'Coming down in 5 mins', 'time': '03:24 PM', 'isMe': false},
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _selectedChatName == null) return;
    setState(() {
      final currentList = _messagesMap[_selectedChatName] ?? [];
      currentList.add({
        'sender': 'Me',
        'text': _messageController.text.trim(),
        'time': 'Just now',
        'isMe': true,
      });
      _messagesMap[_selectedChatName!] = currentList;
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            if (isWide) {
              // Side-by-side desktop/tablet view
              return Row(
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildSidebarList(),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: _selectedChatName == null
                        ? _buildEmptyState()
                        : _buildConversationPanel(),
                  ),
                ],
              );
            } else {
              // Mobile view: if chat is selected, show conversation; else show list
              if (_selectedChatName != null) {
                return _buildConversationPanel();
              }
              return _buildSidebarList();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSidebarList() {
    final query = _searchController.text.toLowerCase();
    final items = _activeTab == 0
        ? _members.where((m) => m['name'].toLowerCase().contains(query)).toList()
        : _groups.where((g) => g['name'].toLowerCase().contains(query)).toList();

    return Column(
      children: [
        // Tabs: [Members] vs [Groups]
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(0xFF0F172A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: _activeTab == 0 ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Members',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(0xFF0F172A) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_work_outlined,
                            size: 16,
                            color: _activeTab == 1 ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Groups',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _activeTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _activeTab == 0 ? 'Search members...' : 'Search groups...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Group creation button if in Groups tab
        if (_activeTab == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create Group modal opened')),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Create Group'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),

        // Items List
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = _selectedChatName == item['name'];

              return Container(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                child: ListTile(
                  dense: true,
                  onTap: () {
                    setState(() {
                      _selectedChatName = item['name'];
                      _selectedChatSubtitle = item['subtitle'];
                    });
                  },
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: item['isGroup'] == true
                            ? const Color(0xFFF97316)
                            : const Color(0xFF0F172A),
                        child: Text(
                          item['avatar'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (item['isOnline'] == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    item['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: (item['time'] as String).isNotEmpty
                      ? Text(
                          item['time'] as String,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select a member or group to start chatting',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Private conversations are strictly confidential between participants.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationPanel() {
    final messages = _messagesMap[_selectedChatName] ?? [
      {
        'sender': _selectedChatName,
        'text': 'Hello! This is a secure communication channel.',
        'time': '10:00 AM',
        'isMe': false,
      },
    ];

    return Column(
      children: [
        // Conversation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _selectedChatName = null),
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  _selectedChatName![0],
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedChatName!,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _selectedChatSubtitle ?? 'Active',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Messages List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg['isMe'] as bool;

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe ? Colors.transparent : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Text(
                          msg['sender'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        msg['text'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isMe ? Colors.white : AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        msg['time'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Message Input Field
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_selectedChatName == null) return;
                  FileUploadHelper.showImageSourcePicker(
                    context: context,
                    title: 'Attach Photo or Document',
                    onFileSelected: (path, name) {
                      setState(() {
                        final currentList = _messagesMap[_selectedChatName] ?? [];
                        currentList.add({
                          'sender': 'Me',
                          'text': '📎 Attached photo/document: $name',
                          'time': 'Just now',
                          'isMe': true,
                        });
                        _messagesMap[_selectedChatName!] = currentList;
                      });
                    },
                  );
                },
                icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B)),
                splashRadius: 20,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
