import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_invitation.dart';
import '../../../data/models/pet_role.dart';
import '../../../data/models/shared_member.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_badge.dart';
import '../../widgets/accent_left_card.dart';

class ShareOwnershipScreen extends StatefulWidget {
  final Pet pet;

  const ShareOwnershipScreen({super.key, required this.pet});

  @override
  State<ShareOwnershipScreen> createState() => _ShareOwnershipScreenState();
}

class _ShareOwnershipScreenState extends State<ShareOwnershipScreen> {
  late Pet _pet;
  final _emailController = TextEditingController();
  PetRole _selectedRole = PetRole.coOwner;

  late List<Map<String, String>> _suggestedContacts;
  List<Map<String, String>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _suggestedContacts = [];
    _emailController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onSearchChanged);
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged() async {
    final query = _emailController.text.trim().toLowerCase();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final results = <Map<String, String>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        final uid = doc.id;
        final userCode = (data['userCode'] ?? AppUser.generateUserCode(uid)).toString();
        final username =
            (data['username'] ??
                    (email.isNotEmpty ? email.split('@').first : ''))
                .toString();

        if (name.toLowerCase().contains(query) ||
            email.toLowerCase().contains(query) ||
            username.toLowerCase().contains(query) ||
            userCode.toLowerCase().contains(query) ||
            userCode.contains(query)) {
          final parts = name.trim().split(' ');
          final initials = parts.isNotEmpty && parts.first.isNotEmpty
              ? (parts.length > 1 && parts.last.isNotEmpty
                    ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
                    : parts.first[0].toUpperCase())
              : (email.isNotEmpty ? email[0].toUpperCase() : '?');

          results.add({
            'name': name.isNotEmpty
                ? name
                : (username.isNotEmpty ? username : email),
            'email': email,
            'userCode': userCode,
            'numericId': userCode,
            'username': username,
            'initials': initials,
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = true;
      });
    } catch (_) {
      setState(() {
        _searchResults = [];
        _isSearching = true;
      });
    }
  }

  void _selectUser(Map<String, String> user) {
    _addContactToSuggested(user);
    setState(() {
      _emailController.text = user['userCode']?.isNotEmpty == true
          ? user['userCode']!
          : user['email']!;
      _searchResults = [];
      _isSearching = false;
    });
  }

  void _addContactToSuggested(Map<String, String> user) {
    final email = user['email']!;
    final exists = _suggestedContacts.any((c) => c['email'] == email);
    if (!exists) {
      _suggestedContacts.insert(0, {
        'name': user['name'] ?? user['username'] ?? email.split('@').first,
        'email': email,
        'userCode': user['userCode'] ?? user['numericId'] ?? '',
        'initials':
            user['initials'] ??
            (email.isNotEmpty ? email[0].toUpperCase() : '?'),
        'username': user['username'] ?? '',
      });
    }
  }

  Future<void> _sendInvitation() async {
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address or personal user code.'),
        ),
      );
      return;
    }

    // 1. Check in-memory search results
    Map<String, String>? matchedUser;
    for (var u in _searchResults) {
      if (u['email']?.toLowerCase() == input.toLowerCase() ||
          u['userCode'] == input ||
          u['numericId'] == input ||
          u['username']?.toLowerCase() == input.toLowerCase()) {
        matchedUser = u;
        break;
      }
    }

    // 2. Query Firestore by email or userCode if not cached
    if (matchedUser == null) {
      final appUser = await FirebaseRepository().getUserByEmailOrCode(input);
      if (appUser != null) {
        final parts = appUser.name.trim().split(' ');
        final initials = parts.isNotEmpty && parts.first.isNotEmpty
            ? (parts.length > 1 && parts.last.isNotEmpty
                ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
                : parts.first[0].toUpperCase())
            : (appUser.email.isNotEmpty ? appUser.email[0].toUpperCase() : '?');

        matchedUser = {
          'name': appUser.name.isNotEmpty ? appUser.name : appUser.email.split('@').first,
          'email': appUser.email,
          'userCode': appUser.userCode,
          'numericId': appUser.userCode,
          'username': appUser.email.split('@').first,
          'initials': initials,
        };
      } else if (input.contains('@')) {
        matchedUser = {
          'name': input.split('@').first,
          'email': input,
          'userCode': '',
          'numericId': '',
          'username': input.split('@').first,
          'initials': input[0].toUpperCase(),
        };
      }
    }

    if (matchedUser == null || matchedUser['email'] == null || matchedUser['email']!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.error,
          content: Text('No registered user found for code or email "$input".'),
        ),
      );
      return;
    }

    final targetEmail = matchedUser['email']!;

    // Prevent duplicate invitations
    final hasExistingMember = _pet.members.any(
      (m) =>
          m.email.toLowerCase() == input.toLowerCase() ||
          m.email.toLowerCase() == targetEmail.toLowerCase(),
    );

    if (hasExistingMember) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User $targetEmail already has an active or pending invitation for ${_pet.name}!',
          ),
        ),
      );
      return;
    }

    _addContactToSuggested(matchedUser);

    final invId = 'inv_${DateTime.now().millisecondsSinceEpoch}';
    final currentUser = FirebaseAuth.instance.currentUser;
    final inviterName = (currentUser?.displayName?.isNotEmpty == true)
        ? currentUser!.displayName!
        : (currentUser?.email?.isNotEmpty == true
              ? currentUser!.email!
              : 'Pet Owner');

    final invitation = PetInvitation(
      id: invId,
      petId: _pet.id,
      petName: _pet.name,
      petBreed: _pet.breed,
      petAvatarUrl: _pet.avatarUrl,
      ownerId: _pet.ownerId.isNotEmpty
          ? _pet.ownerId
          : (currentUser?.uid ?? ''),
      ownerName: inviterName,
      recipientEmail: targetEmail,
      recipientUsername: matchedUser['username'] ?? targetEmail.split('@').first,
      role: _selectedRole,
      status: 'Pending',
      createdAt: DateTime.now(),
    );

    // Save invitation to top-level invitations collection in Firestore
    await FirebaseRepository().sendInvitation(invitation);

    // Create new shared member
    final newMember = SharedMember(
      id: invId,
      email: targetEmail,
      name: matchedUser['name'] ?? targetEmail.split('@').first,
      role: _selectedRole,
      joinedAt: DateTime.now(),
      status: 'Pending',
    );

    final updatedMembers = List<SharedMember>.from(_pet.members)
      ..add(newMember);
    final updatedPet = _pet.copyWith(members: updatedMembers);

    if (!mounted) return;
    setState(() {
      _pet = updatedPet;
      _emailController.clear();
    });

    context.read<PetBloc>().add(UpdatePet(updatedPet));

    final isTransfer = _selectedRole == PetRole.owner;
    final message = isTransfer
        ? 'Ownership transfer request sent to $targetEmail!'
        : 'Invitation sent to $targetEmail as ${_selectedRole.displayName}!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppTheme.primary, content: Text(message)),
    );
  }

  Future<void> _showQrCodeModal() async {
    final userCode = await FirebaseRepository().getCurrentUserCode();
    final qrDeepLink =
        'https://pawsncare.app/share?userId=$userCode&petId=${_pet.id}';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'My User QR Code',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scannable by phone camera or in-app scanner',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              // QR Code Graphic Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceContainer),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: QrImageView(
                        data: qrDeepLink,
                        version: QrVersions.auto,
                        size: 180.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppTheme.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ID: $userCode',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons: Use My ID / Scan QR Code
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _emailController.text = userCode;
                        Navigator.pop(bottomSheetContext);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text('Use ID: $userCode'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        _showCameraScannerDialog();
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Scan QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCameraScannerDialog() {
    final MobileScannerController controller = MobileScannerController();
    bool hasDetected = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Scan User QR Code',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.flash_on, size: 20),
                onPressed: () => controller.toggleTorch(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Point camera at a companion user\'s QR Code',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (hasDetected) return;
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null &&
                            barcode.rawValue!.isNotEmpty) {
                          hasDetected = true;
                          final rawValue = barcode.rawValue!.trim();
                          final uri = Uri.tryParse(rawValue);
                          final scannedId =
                              uri?.queryParameters['userId'] ??
                              rawValue.replaceAll(RegExp(r'[^0-9]'), '');

                          final displayId = scannedId.isNotEmpty
                              ? scannedId
                              : rawValue;
                          _emailController.text = displayId;
                          controller.dispose();
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primary,
                              content: Text('Scanned User ID: $displayId'),
                            ),
                          );
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _revokeMember(SharedMember member) {
    final updatedMembers = _pet.members
        .where((m) => m.id != member.id)
        .toList();
    final updatedPet = _pet.copyWith(members: updatedMembers);

    setState(() {
      _pet = updatedPet;
    });

    context.read<PetBloc>().add(UpdatePet(updatedPet));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${member.email} from ${_pet.name}\'s care.'),
      ),
    );
  }

  Widget _buildRoleOptionCard(PetRole role) {
    final isSelected = _selectedRole == role;
    String cardTitle = role.displayName;
    String cardDescription = role.description;

    if (role == PetRole.owner) {
      cardTitle = 'Transfer Ownership';
      cardDescription = 'If you want to give your Pet to another person.';
    }

    return AccentLeftCard(
      accentColor: isSelected ? role.color : Colors.transparent,
      borderWidth: 5.0,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      backgroundColor: isSelected
          ? role.backgroundColor
          : AppTheme.surfaceContainerLow,
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: role.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(role.icon, color: role.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardTitle,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isSelected ? role.color : AppTheme.onSurface,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: role.color, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cardDescription,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingMembers = _pet.members
        .where((m) => m.status == 'Pending')
        .toList();
    final activeMembers = _pet.members
        .where((m) => m.status == 'Active')
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Share Ownership',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceContainer),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.group_add,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Share ${_pet.name}\'s Care',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Invite family members or co-owners to help manage ${_pet.name}\'s wellness journey. Together, you can track health, schedule walks, and sync medical logs.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search & Invite Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceContainerLow),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search by ID, Email, or Name',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'e.g. 84920156 or jane.doe@example.com',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        onPressed: _showQrCodeModal,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.surfaceContainer,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.surfaceContainer,
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryFixed),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _searchResults.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text(
                                    'No matching users found in database.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        color: AppTheme.surfaceContainerLow,
                                      ),
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryFixed,
                                        radius: 16,
                                        child: Text(
                                          user['initials'] ?? '?',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        user['name'] ?? '',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'ID: ${user['numericId']} • ${user['email']}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.north_west,
                                        size: 16,
                                        color: AppTheme.primary,
                                      ),
                                      onTap: () => _selectUser(user),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                  if (_suggestedContacts.isNotEmpty) ...[
                    const SizedBox(height: 14),

                    // Suggested Contacts
                    const Text(
                      'Suggested Contacts',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _suggestedContacts.map((contact) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              avatar: CircleAvatar(
                                backgroundColor: AppTheme.primaryFixed,
                                child: Text(
                                  contact['initials']!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              label: Text(contact['name']!),
                              onPressed: () {
                                setState(() {
                                  _emailController.text = contact['email']!;
                                });
                              },
                              backgroundColor: AppTheme.surfaceContainerLow,
                              side: const BorderSide(
                                color: AppTheme.surfaceContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Assign Role Header
                  const Text(
                    'Assign Role',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 Defined Roles Stack
                  Column(
                    children: [
                      _buildRoleOptionCard(PetRole.coOwner),
                      const SizedBox(height: 10),
                      _buildRoleOptionCard(PetRole.caregiver),
                      const SizedBox(height: 10),
                      _buildRoleOptionCard(PetRole.veterinary),
                      const SizedBox(height: 10),
                      _buildRoleOptionCard(PetRole.owner),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Send Invitation Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _sendInvitation,
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(
                        _selectedRole == PetRole.owner
                            ? 'Transfer Ownership'
                            : 'Send Invitation',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Pending Invitations List
            if (pendingMembers.isNotEmpty) ...[
              const Text(
                'Pending Invitations',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              ...pendingMembers.map((member) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.surfaceContainer,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.secondaryContainer,
                        radius: 18,
                        child: Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.email,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                RoleBadge(role: member.role, isCompact: true),
                                const SizedBox(width: 8),
                                const Text(
                                  '• Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _revokeMember(member),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.error,
                        ),
                        child: const Text(
                          'Revoke',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // Current Members & Access Section
            const Text(
              'Active Companion Members',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Primary Owner Row (Self)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryFixed,
                    child: const Icon(Icons.person, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text(
                              'You (Primary Owner)',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const RoleBadge(role: PetRole.owner, isCompact: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            ...activeMembers.map((member) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceContainerLow),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: member.role.backgroundColor,
                      child: Icon(
                        member.role.icon,
                        color: member.role.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RoleBadge(role: member.role, isCompact: true),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppTheme.secondary,
                      ),
                      onPressed: () => _revokeMember(member),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Informational Role Alert Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.tertiaryFixed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.tertiary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.tertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Primary Owners can remove any member and delete the pet profile. Co-owners have full editing control. Caregivers can view schedules and log daily entries. Veterinarians have full medical record access.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppTheme.tertiary,
                        height: 1.4,
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
}

class UserQrPainter extends CustomPainter {
  final String username;

  UserQrPainter({required this.username});

  @override
  void paint(Canvas canvas, Size size) {
    final darkPaint = Paint()..color = AppTheme.primary;
    final lightPaint = Paint()..color = Colors.white;

    final width = size.width;
    final height = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), lightPaint);

    const matrixSize = 21;
    final cellSize = width / matrixSize;

    void drawFinderPattern(int startRow, int startCol) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          if (isOuter || isInner) {
            final rect = Rect.fromLTWH(
              (startCol + c) * cellSize,
              (startRow + r) * cellSize,
              cellSize,
              cellSize,
            );
            canvas.drawRect(rect, darkPaint);
          }
        }
      }
    }

    // Top-Left Finder
    drawFinderPattern(0, 0);
    // Top-Right Finder
    drawFinderPattern(0, matrixSize - 7);
    // Bottom-Left Finder
    drawFinderPattern(matrixSize - 7, 0);

    // Seeded data modules based on username codeUnits
    final hash = username.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    for (var r = 0; r < matrixSize; r++) {
      for (var c = 0; c < matrixSize; c++) {
        final isTopLeftFinder = r < 7 && c < 7;
        final isTopRightFinder = r < 7 && c >= matrixSize - 7;
        final isBottomLeftFinder = r >= matrixSize - 7 && c < 7;

        if (isTopLeftFinder || isTopRightFinder || isBottomLeftFinder) {
          continue;
        }

        final cellHash = (r * 31 + c * 17 + hash) % 3;
        if (cellHash == 0) {
          final rect = Rect.fromLTWH(
            c * cellSize,
            r * cellSize,
            cellSize,
            cellSize,
          );
          canvas.drawRect(rect, darkPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant UserQrPainter oldDelegate) {
    return oldDelegate.username != username;
  }
}
