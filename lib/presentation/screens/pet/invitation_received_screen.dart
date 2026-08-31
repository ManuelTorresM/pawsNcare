import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_invitation.dart';
import '../../../data/models/pet_role.dart';
import '../../../data/models/shared_member.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_badge.dart';

class InvitationReceivedScreen extends StatefulWidget {
  final PetInvitation? petInvitation;
  final Pet? pet;
  final SharedMember? invitation;

  const InvitationReceivedScreen({
    super.key,
    this.petInvitation,
    this.pet,
    this.invitation,
  });

  @override
  State<InvitationReceivedScreen> createState() =>
      _InvitationReceivedScreenState();
}

class _InvitationReceivedScreenState
    extends State<InvitationReceivedScreen> {
  late Pet _pet;
  late SharedMember _invitation;

  @override
  void initState() {
    super.initState();
    if (widget.petInvitation != null) {
      final pi = widget.petInvitation!;
      _pet = Pet(
        id: pi.petId,
        name: pi.petName,
        breed: pi.petBreed,
        ageString: 'Companion',
        birthDate: DateTime.now(),
        avatarUrl: pi.petAvatarUrl,
        status: 'Healthy',
        weight: 0.0,
        ownerId: pi.ownerId,
      );
      _invitation = SharedMember(
        id: pi.id,
        email: pi.recipientEmail,
        name: pi.recipientUsername.isNotEmpty
            ? pi.recipientUsername
            : pi.recipientEmail.split('@').first,
        role: pi.role,
        joinedAt: pi.createdAt,
        status: pi.status,
      );
    } else {
      _pet = widget.pet ??
          Pet(
            id: '',
            name: '',
            breed: '',
            ageString: '',
            birthDate: DateTime.now(),
            avatarUrl: '',
            status: 'Healthy',
            weight: 0.0,
          );
      _invitation = widget.invitation ??
          SharedMember(
            id: '',
            email: '',
            name: '',
            role: PetRole.coOwner,
            joinedAt: DateTime.now(),
          );
    }
  }

  void _acceptInvitation() async {
    if (widget.petInvitation != null) {
      await FirebaseRepository().acceptInvitation(widget.petInvitation!);
    } else if (widget.pet != null && widget.invitation != null) {
      final updatedMembers = widget.pet!.members.map((m) {
        if (m.id == widget.invitation!.id ||
            m.email.toLowerCase() == widget.invitation!.email.toLowerCase()) {
          return m.copyWith(status: 'Active');
        }
        return m;
      }).toList();
      final updatedPet = widget.pet!.copyWith(members: updatedMembers);
      context.read<PetBloc>().add(UpdatePet(updatedPet));
    }

    if (mounted) {
      context.read<PetBloc>().add(LoadPets());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          content: Text(
            'Invitation accepted! You are now a ${_invitation.role.displayName} for ${_pet.name}.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  void _declineInvitation() async {
    if (widget.petInvitation != null) {
      await FirebaseRepository().declineInvitation(widget.petInvitation!);
    } else if (widget.pet != null && widget.invitation != null) {
      final updatedMembers = widget.pet!.members
          .where(
            (m) =>
                m.id != widget.invitation!.id &&
                m.email.toLowerCase() !=
                    widget.invitation!.email.toLowerCase(),
          )
          .toList();
      final updatedPet = widget.pet!.copyWith(members: updatedMembers);
      context.read<PetBloc>().add(UpdatePet(updatedPet));
    }

    if (mounted) {
      context.read<PetBloc>().add(LoadPets());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Declined invitation to care for ${_pet.name}.'),
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  Widget _buildPetImageWidget(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.pets,
          size: 60,
          color: AppTheme.primary,
        ),
      );
    } else if (url.isNotEmpty && File(url).existsSync()) {
      return Image.file(File(url), fit: BoxFit.cover);
    }
    return Container(
      color: AppTheme.primaryFixedDim,
      child: const Icon(
        Icons.pets,
        size: 60,
        color: AppTheme.primary,
      ),
    );
  }

  List<String> _getRolePermissionsList(PetRole role) {
    switch (role) {
      case PetRole.owner:
        return const [
          'Full administrative control of pet profile',
          'Edit pet details, health history & diary',
          'Invite or remove co-owners & caregivers',
          'Delete pet profile if required',
        ];
      case PetRole.coOwner:
        return const [
          'Edit pet details & medical history',
          'Log daily events, meals, and walks',
          'Receive health alerts & reminders',
          'Invite caregivers and veterinarians',
        ];
      case PetRole.caregiver:
        return const [
          'View pet routine & upcoming reminders',
          'Log daily activities, meals & weight',
          'Log medications given to companion',
        ];
      case PetRole.veterinary:
        return const [
          'Access medical records & vaccine history',
          'Update prescriptions & treatment plans',
          'Log clinical notes & health alerts',
        ];
    }
  }

  String get _inviterDisplay {
    if (widget.petInvitation != null &&
        widget.petInvitation!.ownerName.isNotEmpty) {
      return widget.petInvitation!.ownerName;
    }
    if (_pet.members.isNotEmpty) {
      final ownerMember = _pet.members.firstWhere(
        (m) => m.role == PetRole.owner || m.id == _pet.ownerId,
        orElse: () => _pet.members.firstWhere(
          (m) => m.status == 'Active' && m.role == PetRole.owner,
          orElse: () => _pet.members.first,
        ),
      );
      if (ownerMember.name.isNotEmpty && ownerMember.name != 'User') {
        return ownerMember.name;
      }
      if (ownerMember.email.isNotEmpty) return ownerMember.email;
    }
    return 'Pet Owner';
  }

  @override
  Widget build(BuildContext context) {
    final permissions = _getRolePermissionsList(_invitation.role);

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
        title: Row(
          children: const [
            Icon(Icons.pets, color: AppTheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Paws & Care',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invitation Hero Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.surfaceContainer,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pet Photo with Badge
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _buildPetImageWidget(_pet.avatarUrl),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 6, right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'New Invite',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    'Share care of ${_pet.name}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: '$_inviterDisplay has invited you to join as '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: RoleBadge(role: _invitation.role, isCompact: true),
                        ),
                        TextSpan(text: ' for ${_pet.name}.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: _acceptInvitation,
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'Accept Invitation',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _declineInvitation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppTheme.surfaceContainer,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Bento Grid Section
            // Card 1: Role Permissions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _invitation.role.backgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _invitation.role.color.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _invitation.role.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _invitation.role.icon,
                          color: _invitation.role.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'What is a ${_invitation.role.displayName}?',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _invitation.role.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _invitation.role.description,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...permissions.map((perm) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: _invitation.role.color,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              perm,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: About the Invitation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.surfaceContainerLow),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About the Invite',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryFixed,
                          radius: 20,
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _inviterDisplay,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Pet Owner / Inviter',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppTheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '"Hi! I\'d love for you to help me stay on top of ${_pet.name}\'s schedule. Let\'s keep companion healthy together!"',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
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
