import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/file_upload_helper.dart';
import '../../repositories/admin_repository.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AdminRepository _adminRepo = AdminRepository();

  int _activeTab = 0; // 0: Members, 1: Groups
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _currentMessages = [];

  String? _selectedChatName;
  String? _selectedChatSubtitle;
  String? _selectedChatAvatar;
  String? _selectedConversationId;
  String? _selectedMemberId;
  bool _selectedIsOnline = false;
  bool _selectedChatIsGroup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getToken() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.token ?? '';
    }
    return '';
  }

  String _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      return authState.user.id;
    }
    return '';
  }

  Future<void> _loadChatData() async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _adminRepo.getChatMembers(token),
        _adminRepo.getChatConversations(token),
      ]);

      if (mounted) {
        setState(() {
          _members = results[0];
          _conversations = results[1];
        });
      }
    } catch (e) {
      debugPrint('[ChatScreen] error loading chat data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic>? _findConversationForMember(Map<String, dynamic> member) {
    final memberId = member['id'] as String? ?? '';
    final email = (member['email'] as String? ?? '').toLowerCase();

    for (final conv in _conversations) {
      final other = conv['otherUser'];
      if (other is Map<String, dynamic>) {
        if (other['id'] == memberId ||
            (other['email'] as String? ?? '').toLowerCase() == email) {
          return conv;
        }
      }
      if (conv['createdBy'] == memberId) {
        return conv;
      }
    }
    return null;
  }

  Future<void> _selectMember(Map<String, dynamic> member) async {
    final name = member['name'] as String? ?? 'Member';
    final department = member['department'] as String? ?? member['role'] as String? ?? 'Employee';
    final avatar = member['avatar'] as String?;
    final memberId = member['id'] as String? ?? '';
    final isOnline = member['online'] == true;

    final conv = _findConversationForMember(member);
    final convId = conv?['id'] as String?;

    setState(() {
      _selectedChatName = name;
      _selectedChatSubtitle = department;
      _selectedChatAvatar = avatar;
      _selectedMemberId = memberId;
      _selectedConversationId = convId;
      _selectedIsOnline = isOnline;
      _selectedChatIsGroup = false;
      _currentMessages = [];
    });

    if (convId != null && convId.isNotEmpty) {
      await _fetchMessages(convId);
    }
  }

  Future<void> _selectConversation(Map<String, dynamic> conv) async {
    final convId = conv['id'] as String? ?? '';
    final other = conv['otherUser'] as Map<String, dynamic>? ?? {};
    final isGroup = conv['type'] == 'group';
    final name = conv['name'] as String? ?? other['name'] as String? ?? 'Chat';
    final dept = isGroup ? (conv['description'] as String? ?? 'Group channel') : (other['department'] as String? ?? 'Employee');
    final avatar = conv['avatar'] as String? ?? other['avatar'] as String?;
    final isOnline = other['online'] == true;

    setState(() {
      _selectedChatName = name;
      _selectedChatSubtitle = dept;
      _selectedChatAvatar = avatar;
      _selectedMemberId = isGroup ? convId : other['id'] as String?;
      _selectedConversationId = convId;
      _selectedIsOnline = isOnline;
      _selectedChatIsGroup = isGroup;
      _currentMessages = [];
    });

    if (convId.isNotEmpty) {
      await _fetchMessages(convId);
    }
  }

  Future<void> _fetchMessages(String convId) async {
    final token = _getToken();
    if (token.isEmpty) return;

    setState(() => _isLoadingMessages = true);

    try {
      final messages = await _adminRepo.getChatMessages(token: token, conversationId: convId);
      if (mounted) {
        setState(() {
          _currentMessages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[ChatScreen] error fetching messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final token = _getToken();
    final convId = _selectedConversationId;

    if (token.isEmpty) return;

    // Optimistic message append
    final currentUserId = _getCurrentUserId();
    final tempMsg = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'conversationId': convId ?? '',
      'senderId': currentUserId,
      'senderName': 'You',
      'messageText': text,
      'createdAt': DateTime.now().toIso8601String(),
      'isMe': true,
    };

    setState(() {
      _currentMessages.add(tempMsg);
      _messageController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      if (convId != null && convId.isNotEmpty) {
        await _adminRepo.sendChatMessage(
          token: token,
          conversationId: convId,
          messageText: text,
        );

        // Re-fetch message list from live DB
        final updatedMessages = await _adminRepo.getChatMessages(token: token, conversationId: convId);
        if (mounted) {
          setState(() {
            _currentMessages = updatedMessages;
          });

          // Update conversation subtitle in the list
          final idx = _conversations.indexWhere((c) => c['id'] == convId);
          if (idx != -1) {
            _conversations[idx]['lastMessage'] = text;
            _conversations[idx]['lastMessageTime'] = 'Just now';
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conversation ready. Server sync initialized.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  // =========================================================
  // CREATE NEW GROUP DIALOG (Matches Screenshots 2 & 3)
  // =========================================================
  Future<void> _showCreateGroupDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? localPhotoPath;
    String? uploadedAvatarUrl;
    final selectedMemberIds = <String>{};
    bool isUploadingPhoto = false;
    bool isCreatingGroup = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Title and Close X
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create New Group',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),

                      // Form Body (Scrollable to prevent ANY overflow)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Group Name *
                              Row(
                                children: [
                                  Text(
                                    'Group Name',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameCtrl,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Development Team, Billing Team',
                                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Group Profile Photo (Optional)
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Group Profile Photo (Optional)',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Avatar Preview Container
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFEEF2FF),
                                        border: Border.all(color: const Color(0xFF6366F1), width: 2),
                                      ),
                                      child: ClipOval(
                                        child: localPhotoPath != null
                                            ? Image.file(
                                                File(localPhotoPath!),
                                                fit: BoxFit.cover,
                                                width: 76,
                                                height: 76,
                                              )
                                            : const Icon(
                                                Icons.groups_rounded,
                                                size: 38,
                                                color: Color(0xFF6366F1),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Action buttons for Photo (Upload / Remove)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: isUploadingPhoto
                                              ? null
                                              : () {
                                                  FileUploadHelper.showImageSourcePicker(
                                                    context: dialogContext,
                                                    title: 'Upload Group Photo',
                                                    onFileSelected: (path, fileName) async {
                                                      setDialogState(() {
                                                        localPhotoPath = path;
                                                        isUploadingPhoto = true;
                                                      });

                                                      final token = _getToken();
                                                      final url = await _adminRepo.uploadChatFile(
                                                        token: token,
                                                        filePath: path,
                                                        fileName: fileName,
                                                      );

                                                      setDialogState(() {
                                                        uploadedAvatarUrl = url;
                                                        isUploadingPhoto = false;
                                                      });
                                                    },
                                                  );
                                                },
                                          icon: isUploadingPhoto
                                              ? const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.camera_alt_outlined, size: 14),
                                          label: Text(
                                            isUploadingPhoto ? 'Uploading...' : 'Upload Group Photo',
                                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                        if (localPhotoPath != null) ...[
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setDialogState(() {
                                                localPhotoPath = null;
                                                uploadedAvatarUrl = null;
                                              });
                                            },
                                            icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                            label: Text(
                                              'Remove',
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 3. Group Description (Optional)
                              Text(
                                'Group Description (Optional)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: descCtrl,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Team collaboration and updates',
                                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 4. Select Group Members (Same Organization)
                              Text(
                                'Select Group Members (Same Organization)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Container(
                                height: 190,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: _members.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No members found',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        itemCount: _members.length,
                                        separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        itemBuilder: (context, idx) {
                                          final m = _members[idx];
                                          final mId = m['id'] as String? ?? '';
                                          final mName = m['name'] as String? ?? 'Member';
                                          final mEmail = m['email'] as String? ?? '';
                                          final mAvatar = m['avatar'] as String?;
                                          final isChecked = selectedMemberIds.contains(mId);

                                          return InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                if (isChecked) {
                                                  selectedMemberIds.remove(mId);
                                                } else {
                                                  selectedMemberIds.add(mId);
                                                }
                                              });
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: Checkbox(
                                                      value: isChecked,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                      activeColor: const Color(0xFF4F46E5),
                                                      onChanged: (val) {
                                                        setDialogState(() {
                                                          if (val == true) {
                                                            selectedMemberIds.add(mId);
                                                          } else {
                                                            selectedMemberIds.remove(mId);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _buildAvatarWidget(mAvatar, mName.isNotEmpty ? mName[0].toUpperCase() : 'U', isGroup: false),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          mName,
                                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                        ),
                                                        Text(
                                                          mEmail,
                                                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      // Bottom Actions: [ Cancel ] [ Create Group ]
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isCreatingGroup
                                ? null
                                : () async {
                                    final groupName = nameCtrl.text.trim();
                                    if (groupName.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter Group Name')),
                                      );
                                      return;
                                    }

                                    setDialogState(() => isCreatingGroup = true);

                                    final token = _getToken();
                                    try {
                                      final createdGroup = await _adminRepo.createChatGroup(
                                        token: token,
                                        name: groupName,
                                        description: descCtrl.text.trim(),
                                        avatar: uploadedAvatarUrl,
                                        memberIds: selectedMemberIds.toList(),
                                      );

                                      if (dialogCtx.mounted) {
                                        Navigator.of(dialogCtx).pop();
                                      }

                                      if (!mounted) return;

                                      // Re-load live chat data
                                      await _loadChatData();

                                      if (!mounted) return;

                                      // Select the new group
                                      if (createdGroup.isNotEmpty) {
                                        _selectConversation(createdGroup);
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Group "$groupName" created successfully!'),
                                          backgroundColor: const Color(0xFF10B981),
                                        ),
                                      );
                                    } catch (e) {
                                      if (dialogCtx.mounted) {
                                        setDialogState(() => isCreatingGroup = false);
                                      }
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to create group: $e'),
                                          backgroundColor: const Color(0xFFEF4444),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: isCreatingGroup
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Create Group',
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _getAvatarFullUrl(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty) return null;
    final trimmed = avatar.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    } else if (trimmed.startsWith('/')) {
      return 'https://employee-management.srivagroups.in$trimmed';
    } else {
      return 'https://employee-management.srivagroups.in/$trimmed';
    }
  }

  void _showZoomPhotoDialog(String? avatarUrl, String title) {
    final fullUrl = _getAvatarFullUrl(avatarUrl);
    if (fullUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photo available to zoom'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Failed to load image', style: GoogleFonts.inter(fontSize: 13)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MEMBER DETAILS MODAL (Screenshot 2)
  // =========================================================
  void _showMemberDetailsDialog(Map<String, dynamic> member) {
    final name = member['name'] as String? ?? 'Member';
    final email = member['email'] as String? ?? '-';
    final department = member['department'] as String? ?? member['role'] as String? ?? '-';
    final role = (member['role'] as String? ?? 'employee').toUpperCase();
    final avatar = member['avatar'] as String?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular close button at top right
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Member Avatar (Dark blue circle with bold initial or photo)
                _buildAvatarWidget(avatar, initial, isGroup: false, radius: 42),
                const SizedBox(height: 14),

                // Member Name
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // Role Pill (e.g. ADMIN, MEMBER)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 18),

                // Department Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Department',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        department,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // GROUP INFORMATION DIALOG (Screenshot 2)
  // =========================================================
  Future<void> _showGroupInfoDialog() async {
    final groupId = _selectedConversationId;
    if (groupId == null || groupId.isEmpty) return;

    final token = _getToken();
    if (token.isEmpty) return;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        Map<String, dynamic>? groupDetails;
        bool isLoadingDetails = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void loadDetails() async {
              try {
                final data = await _adminRepo.getGroupDetails(token: token, groupId: groupId);
                if (modalContext.mounted) {
                  setModalState(() {
                    groupDetails = data;
                    isLoadingDetails = false;
                    errorMessage = null;
                  });
                }
              } catch (e) {
                if (modalContext.mounted) {
                  setModalState(() {
                    isLoadingDetails = false;
                    errorMessage = e.toString().replaceAll('Exception: ', '');
                  });
                }
              }
            }

            if (isLoadingDetails && groupDetails == null && errorMessage == null) {
              loadDetails();
            }

            final mediaQuery = MediaQuery.of(modalContext);
            final dialogWidth = (mediaQuery.size.width * 0.92).clamp(320.0, 480.0);
            final dialogMaxHeight = mediaQuery.size.height * 0.88;

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: dialogMaxHeight,
                ),
                child: isLoadingDetails
                    ? const SizedBox(
                        height: 250,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        ),
                      )
                    : errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      isLoadingDetails = true;
                                      errorMessage = null;
                                    });
                                    loadDetails();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _buildGroupInfoContent(
                            context: modalContext,
                            setModalState: setModalState,
                            details: groupDetails ?? {},
                            onReload: loadDetails,
                          ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupInfoContent({
    required BuildContext context,
    required StateSetter setModalState,
    required Map<String, dynamic> details,
    required VoidCallback onReload,
  }) {
    final name = details['name'] as String? ?? 'Group';
    final description = details['description'] as String? ?? '';
    final avatar = details['avatar'] as String?;
    final creatorName = details['creatorName'] as String? ?? 'Admin';
    final members = (details['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final currentUserId = _getCurrentUserId();
    final initial = name.isNotEmpty ? (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase()) : 'GRP';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Group Information & Close [X]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Information',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Scrollable Group Details
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Group Avatar
                  _buildAvatarWidget(avatar, initial, isGroup: true, radius: 36),
                  const SizedBox(height: 10),

                  // Group Name
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // View / Zoom Group Photo Button
                  InkWell(
                    onTap: () => _showZoomPhotoDialog(avatar, name),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE0E7FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF6366F1)),
                          const SizedBox(width: 6),
                          Text(
                            'View / Zoom Group Photo',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Members Count & Description
                  Text(
                    '${members.length} Members',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // Creator Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 5),
                        Text(
                          'Creator: $creatorName',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons: [Edit Group] [Add Members] [Delete Group]
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _showEditGroupDialog(
                            initialGroupData: details,
                            onUpdated: (updated) {
                              setModalState(() {
                                details['name'] = updated['name'] ?? details['name'];
                                details['description'] = updated['description'] ?? details['description'];
                                details['avatar'] = updated['avatar'];
                              });
                              onReload();
                            },
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF334155)),
                        label: Text(
                          'Edit Group',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showAddMembersDialog(
                            groupId: details['id'] as String? ?? '',
                            currentMembers: members,
                            onMembersAdded: onReload,
                          );
                        },
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 14, color: Color(0xFF334155)),
                        label: Text(
                          'Add Members',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _confirmDeleteGroup(
                            parentDialogContext: context,
                            groupId: details['id'] as String? ?? '',
                            groupName: name,
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: Text(
                          'Delete Group',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, color: Color(0xFFF1F5F9)),

                  // Members Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Members (${members.length})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Members List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final m = members[idx];
                      final mId = m['id'] as String? ?? '';
                      final mName = m['name'] as String? ?? 'Member';
                      final mAvatar = m['avatar'] as String?;
                      final mRole = m['role'] as String? ?? 'employee';
                      final isCreator = m['isCreator'] == true;
                      final mOnline = m['online'] == true;
                      final mInitial = mName.isNotEmpty ? mName[0].toUpperCase() : 'M';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            _buildAvatarWidget(mAvatar, mInitial, isGroup: false, radius: 17),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          mName,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (isCreator || mRole.toLowerCase() == 'admin')
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: GoogleFonts.inter(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF4F46E5),
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          'Member',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: mOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        mOnline ? 'Online' : 'Offline',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: mOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action Buttons: Zoom & Remove
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showMemberDetailsDialog(m),
                                  icon: const Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF2563EB)),
                                  label: Text(
                                    'Zoom',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                if (!isCreator && mId != currentUserId) ...[
                                  const SizedBox(width: 6),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _confirmRemoveMember(
                                        parentDialogContext: context,
                                        groupId: details['id'] as String? ?? '',
                                        memberId: mId,
                                        memberName: mName,
                                        onRemoved: onReload,
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 12, color: Color(0xFFEF4444)),
                                    label: Text(
                                      'Remove',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      side: const BorderSide(color: Color(0xFFFECACA)),
                                      backgroundColor: const Color(0xFFFEF2F2),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  // Leave Group Button
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmLeaveGroup(
                        parentDialogContext: context,
                        groupId: details['id'] as String? ?? '',
                        groupName: name,
                        members: members,
                      );
                    },
                    icon: const Icon(Icons.exit_to_app_rounded, size: 14, color: Color(0xFFEF4444)),
                    label: Text(
                      'Leave Group',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EDIT GROUP DIALOG (Screenshot 3)
  // =========================================================
  Future<void> _showEditGroupDialog({
    required Map<String, dynamic> initialGroupData,
    required Function(Map<String, dynamic>) onUpdated,
  }) async {
    final groupId = initialGroupData['id'] as String? ?? '';
    final nameCtrl = TextEditingController(text: initialGroupData['name'] as String? ?? '');
    final descCtrl = TextEditingController(text: initialGroupData['description'] as String? ?? '');
    String? currentAvatar = initialGroupData['avatar'] as String?;
    String? localPhotoPath;
    bool isUploading = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (editCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setEditState) {
            final mediaQuery = MediaQuery.of(modalCtx);
            final dialogWidth = (mediaQuery.size.width * 0.9).clamp(320.0, 440.0);

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: mediaQuery.size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Group Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(editCtx).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Group Profile Photo
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Group Profile Photo',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Avatar Preview
                                    Container(
                                      width: 76,
                                      height: 76,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFEEF2FF),
                                        border: Border.all(color: const Color(0xFF6366F1), width: 2),
                                      ),
                                      child: ClipOval(
                                        child: localPhotoPath != null
                                            ? Image.file(
                                                File(localPhotoPath!),
                                                fit: BoxFit.cover,
                                                width: 76,
                                                height: 76,
                                              )
                                            : currentAvatar != null && currentAvatar!.isNotEmpty
                                                ? Image.network(
                                                    _getAvatarFullUrl(currentAvatar) ?? '',
                                                    fit: BoxFit.cover,
                                                    width: 76,
                                                    height: 76,
                                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                                      Icons.groups_rounded,
                                                      size: 38,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.groups_rounded,
                                                    size: 38,
                                                    color: Color(0xFF6366F1),
                                                  ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Action buttons for Photo
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: isUploading
                                              ? null
                                              : () {
                                                  FileUploadHelper.showImageSourcePicker(
                                                    context: modalCtx,
                                                    title: 'Change Group Photo',
                                                    onFileSelected: (path, fileName) async {
                                                      setEditState(() {
                                                        localPhotoPath = path;
                                                        isUploading = true;
                                                      });

                                                      final token = _getToken();
                                                      final url = await _adminRepo.uploadChatFile(
                                                        token: token,
                                                        filePath: path,
                                                        fileName: fileName,
                                                      );

                                                      setEditState(() {
                                                        currentAvatar = url;
                                                        isUploading = false;
                                                      });
                                                    },
                                                  );
                                                },
                                          icon: isUploading
                                              ? const SizedBox(
                                                  width: 12,
                                                  height: 12,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF4F46E5)),
                                          label: Text(
                                            isUploading ? 'Uploading...' : 'Change Group Photo',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF4F46E5),
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                                            backgroundColor: const Color(0xFFEEF2FF),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        if (currentAvatar != null || localPhotoPath != null) ...[
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              setEditState(() {
                                                localPhotoPath = null;
                                                currentAvatar = null;
                                              });
                                            },
                                            icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                            label: Text(
                                              'Remove',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFFEF4444),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFFECACA)),
                                              backgroundColor: const Color(0xFFFEF2F2),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Group Name
                              Text(
                                'Group Name',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: nameCtrl,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Enter group name',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Group Description
                              Text(
                                'Group Description',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: descCtrl,
                                style: GoogleFonts.inter(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Discussing project milestones',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bottom Buttons: Cancel & Save Changes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(editCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newName = nameCtrl.text.trim();
                                    if (newName.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please enter a group name'),
                                          backgroundColor: Color(0xFFEF4444),
                                        ),
                                      );
                                      return;
                                    }

                                    setEditState(() => isSaving = true);
                                    final token = _getToken();

                                    try {
                                      await _adminRepo.updateChatGroup(
                                        token: token,
                                        groupId: groupId,
                                        name: newName,
                                        description: descCtrl.text.trim(),
                                        avatar: currentAvatar,
                                      );

                                      if (mounted) {
                                        setState(() {
                                          _selectedChatName = newName;
                                          _selectedChatSubtitle = descCtrl.text.trim();
                                          _selectedChatAvatar = currentAvatar;

                                          final idx = _conversations.indexWhere((c) => c['id'] == groupId);
                                          if (idx != -1) {
                                            _conversations[idx]['name'] = newName;
                                            _conversations[idx]['description'] = descCtrl.text.trim();
                                            _conversations[idx]['avatar'] = currentAvatar;
                                          }
                                        });

                                        onUpdated({
                                          'name': newName,
                                          'description': descCtrl.text.trim(),
                                          'avatar': currentAvatar,
                                        });

                                        if (editCtx.mounted) {
                                          Navigator.of(editCtx).pop();
                                        }

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Group updated successfully'),
                                              backgroundColor: Color(0xFF10B981),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (modalCtx.mounted) {
                                        ScaffoldMessenger.of(modalCtx).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to update group: $e'),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (modalCtx.mounted) {
                                        setEditState(() => isSaving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ADD MEMBERS TO GROUP DIALOG (Screenshot 4)
  // =========================================================
  Future<void> _showAddMembersDialog({
    required String groupId,
    required List<dynamic> currentMembers,
    required VoidCallback onMembersAdded,
  }) async {
    final currentIds = currentMembers.map((m) => m['id']?.toString() ?? '').toSet();
    final availableEmployees = _members.where((m) {
      final id = m['id']?.toString() ?? '';
      return id.isNotEmpty && !currentIds.contains(id);
    }).toList();

    final selectedIds = <String>{};
    final searchCtrl = TextEditingController();
    bool isAdding = false;

    await showDialog(
      context: context,
      builder: (addCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setAddState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = availableEmployees.where((emp) {
              final name = (emp['name'] as String? ?? '').toLowerCase();
              final email = (emp['email'] as String? ?? '').toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();

            final mediaQuery = MediaQuery.of(modalCtx);
            final dialogWidth = (mediaQuery.size.width * 0.9).clamp(320.0, 440.0);

            return Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth,
                  maxHeight: mediaQuery.size.height * 0.85,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Members to Group',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(addCtx).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFF1F5F9)),

                      // Title
                      Text(
                        'Select Employees to Add',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Search Input
                      TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setAddState(() {}),
                        style: GoogleFonts.inter(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Search employee by name or email...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Employees list with checkboxes
                      Flexible(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    availableEmployees.isEmpty
                                        ? 'All employees are already in this group.'
                                        : 'No employees found matching search.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  itemBuilder: (ctx, idx) {
                                    final emp = filtered[idx];
                                    final id = emp['id'] as String? ?? '';
                                    final name = emp['name'] as String? ?? 'Employee';
                                    final email = emp['email'] as String? ?? '';
                                    final avatar = emp['avatar'] as String?;
                                    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'E';
                                    final isChecked = selectedIds.contains(id);

                                    return InkWell(
                                      onTap: () {
                                        setAddState(() {
                                          if (isChecked) {
                                            selectedIds.remove(id);
                                          } else {
                                            selectedIds.add(id);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                value: isChecked,
                                                activeColor: const Color(0xFF6366F1),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                onChanged: (val) {
                                                  setAddState(() {
                                                    if (val == true) {
                                                      selectedIds.add(id);
                                                    } else {
                                                      selectedIds.remove(id);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildAvatarWidget(avatar, initial, isGroup: false, radius: 16),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (email.isNotEmpty)
                                                    Text(
                                                      email,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: const Color(0xFF64748B),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Bottom Buttons: Cancel & Add Selected Members
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(addCtx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: (selectedIds.isEmpty || isAdding)
                                ? null
                                : () async {
                                    setAddState(() => isAdding = true);
                                    final token = _getToken();

                                    try {
                                      await _adminRepo.addGroupMembers(
                                        token: token,
                                        groupId: groupId,
                                        memberIds: selectedIds.toList(),
                                      );

                                      if (addCtx.mounted) {
                                        Navigator.of(addCtx).pop();
                                      }

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Members added to group successfully'),
                                            backgroundColor: Color(0xFF10B981),
                                          ),
                                        );
                                        onMembersAdded();
                                        _loadChatData();
                                      }
                                    } catch (e) {
                                      if (modalCtx.mounted) {
                                        ScaffoldMessenger.of(modalCtx).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to add members: $e'),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (modalCtx.mounted) {
                                        setAddState(() => isAdding = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            ),
                            child: isAdding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Add Selected Members (${selectedIds.length})',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // CONFIRMATION POPUPS
  // =========================================================
  Future<void> _confirmRemoveMember({
    required BuildContext parentDialogContext,
    required String groupId,
    required String memberId,
    required String memberName,
    required VoidCallback onRemoved,
  }) async {
    final shouldRemove = await showDialog<bool>(
      context: parentDialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Member',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to remove $memberName from this group?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      final token = _getToken();
      try {
        await _adminRepo.removeGroupMember(token: token, groupId: groupId, memberId: memberId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$memberName removed from group'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        onRemoved();
        _loadChatData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove member: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteGroup({
    required BuildContext parentDialogContext,
    required String groupId,
    required String groupName,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: parentDialogContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Group',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to delete \'$groupName\'? All messages and group data will be permanently deleted. This action cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final token = _getToken();
      try {
        await _adminRepo.deleteChatGroup(token: token, groupId: groupId);
        if (parentDialogContext.mounted) {
          Navigator.of(parentDialogContext).pop(); // Close Group Info modal
        }
        if (mounted) {
          setState(() {
            _selectedConversationId = null;
            _selectedChatName = null;
            _selectedChatAvatar = null;
            _selectedChatSubtitle = null;
            _selectedChatIsGroup = false;
            _currentMessages = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group deleted successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadChatData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmLeaveGroup({
    required BuildContext parentDialogContext,
    required String groupId,
    required String groupName,
    required List<Map<String, dynamic>> members,
  }) async {
    final currentUserId = _getCurrentUserId();
    // Candidates to assign as new admin (all other members in the group)
    final otherMembers = members.where((m) => (m['id']?.toString() ?? '') != currentUserId).toList();
    String? selectedAdminId = otherMembers.isNotEmpty ? otherMembers.first['id']?.toString() : null;

    final shouldLeave = await showDialog<bool>(
      context: parentDialogContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final mediaQuery = MediaQuery.of(dialogCtx);
          final dialogWidth = (mediaQuery.size.width * 0.9).clamp(320.0, 400.0);

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dialogWidth),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amber banner with exit icon (Screenshot 3)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.exit_to_app_rounded,
                        color: Color(0xFFD97706),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Leave Group?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'You will no longer receive messages from this group.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assign New Group Admin Container
                    if (otherMembers.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign New Group Admin Before Leaving:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedAdminId,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
                                  items: otherMembers.map((m) {
                                    final id = m['id']?.toString() ?? '';
                                    final name = m['name'] as String? ?? 'Member';
                                    final role = m['role'] as String? ?? 'employee';
                                    return DropdownMenuItem<String>(
                                      value: id,
                                      child: Text(
                                        '$name ($role)',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => selectedAdminId = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action buttons: Cancel & Leave
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Leave',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (shouldLeave == true) {
      final token = _getToken();
      try {
        await _adminRepo.leaveChatGroup(
          token: token,
          groupId: groupId,
          newAdminId: selectedAdminId,
        );
        if (parentDialogContext.mounted) {
          Navigator.of(parentDialogContext).pop(); // Close Group Info modal
        }
        if (mounted) {
          setState(() {
            _selectedConversationId = null;
            _selectedChatName = null;
            _selectedChatAvatar = null;
            _selectedChatSubtitle = null;
            _selectedChatIsGroup = false;
            _currentMessages = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Left group successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _loadChatData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString();
    if (str.contains('T')) {
      try {
        final dt = DateTime.parse(str).toLocal();
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      } catch (_) {}
    }
    return str;
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
                    width: 330,
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
              // Mobile view: if chat is selected, show conversation; else show sidebar
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
    final query = _searchController.text.trim().toLowerCase();

    final filteredMembers = _members.where((m) {
      final name = (m['name'] as String? ?? '').toLowerCase();
      final dept = (m['department'] as String? ?? '').toLowerCase();
      return name.contains(query) || dept.contains(query);
    }).toList();

    final groupConversations = _conversations.where((c) => c['type'] == 'group').toList();

    final filteredGroups = groupConversations.where((g) {
      final name = (g['name'] as String? ?? '').toLowerCase();
      return name.contains(query);
    }).toList();

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
                          if (_members.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? Colors.white24 : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_members.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _activeTab == 0 ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
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
                          if (groupConversations.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? Colors.white24 : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${groupConversations.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _activeTab == 1 ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
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

        // Group creation button if in Groups tab (Screenshot 1)
        if (_activeTab == 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showCreateGroupDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Create Group'),
              ),
            ),
          ),

        // Items List with Pull-to-Refresh
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatData,
                  color: const Color(0xFF4F46E5),
                  child: _activeTab == 0
                      ? _buildMembersList(filteredMembers)
                      : _buildGroupsList(filteredGroups),
                ),
        ),
      ],
    );
  }

  Widget _buildMembersList(List<Map<String, dynamic>> membersList) {
    if (membersList.isEmpty) {
      return Center(
        child: Text(
          'No members found',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: membersList.length,
      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 64),
      itemBuilder: (context, index) {
        final member = membersList[index];
        final name = member['name'] as String? ?? 'Member';
        final isSelected = _selectedMemberId == member['id'] || _selectedChatName == name;
        final isOnline = member['online'] == true;
        final avatarUrl = member['avatar'] as String?;
        final department = member['department'] as String? ?? member['role'] as String? ?? '';

        final conv = _findConversationForMember(member);
        final lastMsg = conv?['lastMessage'] as String?;
        final subtitleText = (lastMsg != null && lastMsg.isNotEmpty && lastMsg != 'No messages yet')
            ? lastMsg
            : (department.isNotEmpty ? department : 'No messages yet');

        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return Container(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          child: ListTile(
            dense: true,
            onTap: () => _selectMember(member),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatarWidget(avatarUrl, initial, isGroup: false),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitleText,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isOnline
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildGroupsList(List<Map<String, dynamic>> groupsList) {
    if (groupsList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No groups created yet. Click \'Create Group\' to create one.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: groupsList.length,
      separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 64),
      itemBuilder: (context, index) {
        final item = groupsList[index];
        final name = item['name'] as String? ?? 'Group';
        final isSelected = _selectedChatName == name;
        final subtitle = item['lastMessage'] as String? ?? item['description'] as String? ?? 'Group created';
        final initial = name.isNotEmpty ? (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase()) : 'GRP';
        final time = _formatTime(item['lastMessageTime'] ?? item['createdAt']);

        return Container(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent,
          child: ListTile(
            dense: true,
            onTap: () => _selectConversation(item),
            leading: _buildAvatarWidget(item['avatar'] as String?, initial, isGroup: true),
            title: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: time.isNotEmpty
                ? Text(
                    time,
                    style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAvatarWidget(String? avatar, String fallbackInitial, {required bool isGroup, double radius = 18}) {
    final fullUrl = _getAvatarFullUrl(avatar);

    if (fullUrl != null) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isGroup ? const Color(0xFFF97316) : const Color(0xFF0F172A),
        ),
        child: ClipOval(
          child: Image.network(
            fullUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  fallbackInitial,
                  style: GoogleFonts.inter(
                    fontSize: fallbackInitial.length > 2 ? radius * 0.55 : radius * 0.7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: Text(
                  fallbackInitial,
                  style: GoogleFonts.inter(
                    fontSize: fallbackInitial.length > 2 ? radius * 0.55 : radius * 0.7,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isGroup ? const Color(0xFFF97316) : const Color(0xFF0F172A),
      ),
      child: Center(
        child: Text(
          fallbackInitial,
          style: GoogleFonts.inter(
            fontSize: fallbackInitial.length > 2 ? radius * 0.55 : radius * 0.7,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E7FF), width: 2),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF4F46E5), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a member or group to start chatting',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Private conversations are strictly confidential between participants.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationPanel() {
    final name = _selectedChatName ?? 'Chat';
    final subtitle = _selectedChatSubtitle ?? 'Active';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final currentUserId = _getCurrentUserId();

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
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => setState(() => _selectedChatName = null),
                tooltip: 'Back',
              ),
              Stack(
                children: [
                  _buildAvatarWidget(_selectedChatAvatar, initial, isGroup: _selectedChatIsGroup),
                  if (_selectedIsOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _selectedChatIsGroup ? () => _showGroupInfoDialog() : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        _selectedIsOnline ? 'Active Now • $subtitle' : subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _selectedIsOnline ? const Color(0xFF10B981) : AppColors.textSecondary,
                          fontWeight: _selectedIsOnline ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedChatIsGroup) ...[
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, size: 22, color: Color(0xFF64748B)),
                  onPressed: () => _showGroupInfoDialog(),
                  tooltip: 'Group Information',
                ),
              ],
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () {
                  if (_selectedConversationId != null) {
                    _fetchMessages(_selectedConversationId!);
                  }
                },
                tooltip: 'Refresh Messages',
              ),
            ],
          ),
        ),

        // Live Messages List
        Expanded(
          child: _isLoadingMessages
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                )
              : _currentMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_chat_unread_outlined, size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Say hello to $name to start the conversation!',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _currentMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _currentMessages[index];
                        final senderId = msg['senderId'] as String? ?? '';
                        final isMe = msg['isMe'] == true || (senderId.isNotEmpty && senderId == currentUserId);
                        final senderName = msg['senderName'] as String? ?? (isMe ? 'You' : name);
                        final text = msg['messageText'] as String? ?? msg['text'] as String? ?? '';
                        final time = _formatTime(msg['createdAt'] ?? msg['sentAt'] ?? msg['time']);

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                if (!isMe) ...[
                                  Text(
                                    senderName,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Text(
                                  text,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isMe ? Colors.white : AppColors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
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
                  FileUploadHelper.showImageSourcePicker(
                    context: context,
                    title: 'Attach Photo or Document',
                    onFileSelected: (path, fileName) {
                      setState(() {
                        _currentMessages.add({
                          'id': 'temp-att-${DateTime.now().millisecondsSinceEpoch}',
                          'senderName': 'You',
                          'messageText': '📎 Attached file: $fileName',
                          'createdAt': DateTime.now().toIso8601String(),
                          'isMe': true,
                        });
                      });
                      _scrollToBottom();
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
                    hintText: 'Type a message to $name...',
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
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A)),
                      )
                    : const Icon(Icons.send_rounded, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
