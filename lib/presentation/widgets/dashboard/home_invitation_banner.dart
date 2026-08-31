import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_invitation.dart';
import '../../../data/models/shared_member.dart';
import '../../../data/repositories/firebase_repository.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../theme/app_theme.dart';
import '../../screens/pet/invitation_received_screen.dart';

class HomeInvitationBanner extends StatelessWidget {
  final List<Pet> allPets;
  final bool isDark;
  final Color textSecondary;

  const HomeInvitationBanner({
    super.key,
    required this.allPets,
    required this.isDark,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PetInvitation>>(
      future: FirebaseRepository().getPendingInvitationsForCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          Pet? pendingPet;
          SharedMember? pendingInvite;
          final user = FirebaseAuth.instance.currentUser;
          final userEmail = user?.email ?? '';
          final userId = user?.uid ?? '';

          for (final pet in allPets) {
            for (final member in pet.members) {
              if (member.status == 'Pending') {
                if (member.id == userId ||
                    (userEmail.isNotEmpty &&
                        member.email.toLowerCase() ==
                            userEmail.toLowerCase())) {
                  pendingPet = pet;
                  pendingInvite = member;
                  break;
                }
              }
            }
            if (pendingPet != null) break;
          }

          if (pendingPet == null || pendingInvite == null) {
            return const SizedBox.shrink();
          }

          return _renderCard(
            context: context,
            petName: pendingPet.name,
            roleName: pendingInvite.role.displayName,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvitationReceivedScreen(
                    pet: pendingPet,
                    invitation: pendingInvite,
                  ),
                ),
              );
              if (context.mounted) {
                context.read<PetBloc>().add(LoadPets());
              }
            },
          );
        }

        final topInvitation = snapshot.data!.first;

        return _renderCard(
          context: context,
          petName: topInvitation.petName,
          roleName: topInvitation.role.displayName,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    InvitationReceivedScreen(petInvitation: topInvitation),
              ),
            );
            if (context.mounted) {
              context.read<PetBloc>().add(LoadPets());
            }
          },
        );
      },
    );
  }

  Widget _renderCard({
    required BuildContext context,
    required String petName,
    required String roleName,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW INVITATION',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Care for $petName as $roleName',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Tap to review permissions & accept',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
