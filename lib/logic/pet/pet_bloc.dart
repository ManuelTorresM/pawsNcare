import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/pet.dart';
import '../../data/repositories/repository_selector.dart';
import '../../data/services/local_media_service.dart';

// Events
abstract class PetEvent extends Equatable {
  const PetEvent();
  @override
  List<Object?> get props => [];
}

class LoadPets extends PetEvent {}

class AddPet extends PetEvent {
  final Pet pet;
  const AddPet(this.pet);
  @override
  List<Object?> get props => [pet];
}

class UpdatePet extends PetEvent {
  final Pet pet;
  const UpdatePet(this.pet);
  @override
  List<Object?> get props => [pet];
}

class DeletePet extends PetEvent {
  final String petId;
  const DeletePet(this.petId);
  @override
  List<Object?> get props => [petId];
}

class SearchPets extends PetEvent {
  final String query;
  const SearchPets(this.query);
  @override
  List<Object?> get props => [query];
}

// States
abstract class PetState extends Equatable {
  const PetState();
  @override
  List<Object?> get props => [];
}

class PetInitial extends PetState {}

class PetLoading extends PetState {}

class PetLoaded extends PetState {
  final List<Pet> pets;
  final List<Pet> filteredPets;
  final String searchQuery;

  const PetLoaded({
    required this.pets,
    required this.filteredPets,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [pets, filteredPets, searchQuery];
}

class PetError extends PetState {
  final String message;
  const PetError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PetBloc extends Bloc<PetEvent, PetState> {
  final RepositorySelector repositorySelector;

  PetBloc({required this.repositorySelector}) : super(PetInitial()) {
    on<LoadPets>(_onLoadPets);
    on<AddPet>(_onAddPet);
    on<UpdatePet>(_onUpdatePet);
    on<DeletePet>(_onDeletePet);
    on<SearchPets>(_onSearchPets);
  }

  Future<List<Pet>> _enrichWithLocalMedia(List<Pet> pets) async {
    final enriched = <Pet>[];
    for (final pet in pets) {
      final localAvatar = await LocalMediaService.getLocalAvatar(pet.id);
      final localPhotos = await LocalMediaService.getLocalPhotos(pet.id);

      final avatarToUse = (localAvatar != null && localAvatar.isNotEmpty)
          ? localAvatar
          : pet.avatarUrl;

      final combinedPhotos = List<String>.from(pet.photos);
      for (final p in localPhotos) {
        if (!combinedPhotos.contains(p)) {
          combinedPhotos.add(p);
        }
      }

      enriched.add(
        pet.copyWith(
          avatarUrl: avatarToUse,
          photos: combinedPhotos,
        ),
      );
    }
    return enriched;
  }

  Future<void> _onLoadPets(LoadPets event, Emitter<PetState> emit) async {
    emit(PetLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      final pets = await repo.getPets();
      final enrichedPets = await _enrichWithLocalMedia(pets);
      emit(PetLoaded(pets: enrichedPets, filteredPets: enrichedPets));
    } catch (e) {
      emit(PetError(e.toString()));
    }
  }

  Future<void> _onAddPet(AddPet event, Emitter<PetState> emit) async {
    try {
      if (event.pet.avatarUrl.isNotEmpty) {
        await LocalMediaService.saveLocalAvatar(
          event.pet.id,
          event.pet.avatarUrl,
        );
      }
      if (event.pet.photos.isNotEmpty) {
        await LocalMediaService.saveLocalPhotos(
          event.pet.id,
          event.pet.photos,
        );
      }

      final repo = await repositorySelector.getActiveRepository();
      await repo.addPet(event.pet);
      final pets = await repo.getPets();
      final enrichedPets = await _enrichWithLocalMedia(pets);
      emit(PetLoaded(pets: enrichedPets, filteredPets: enrichedPets));
    } catch (e) {
      emit(PetError(e.toString()));
    }
  }

  Future<void> _onUpdatePet(UpdatePet event, Emitter<PetState> emit) async {
    try {
      if (event.pet.avatarUrl.isNotEmpty) {
        await LocalMediaService.saveLocalAvatar(
          event.pet.id,
          event.pet.avatarUrl,
        );
      }
      if (event.pet.photos.isNotEmpty) {
        await LocalMediaService.saveLocalPhotos(
          event.pet.id,
          event.pet.photos,
        );
      }

      final repo = await repositorySelector.getActiveRepository();
      await repo.updatePet(event.pet);
      final pets = await repo.getPets();
      final enrichedPets = await _enrichWithLocalMedia(pets);
      emit(PetLoaded(pets: enrichedPets, filteredPets: enrichedPets));
    } catch (e) {
      emit(PetError(e.toString()));
    }
  }

  Future<void> _onDeletePet(DeletePet event, Emitter<PetState> emit) async {
    try {
      final repo = await repositorySelector.getActiveRepository();
      await repo.deletePet(event.petId);
      final pets = await repo.getPets();
      final enrichedPets = await _enrichWithLocalMedia(pets);
      emit(PetLoaded(pets: enrichedPets, filteredPets: enrichedPets));
    } catch (e) {
      emit(PetError(e.toString()));
    }
  }

  void _onSearchPets(SearchPets event, Emitter<PetState> emit) {
    if (state is PetLoaded) {
      final currentState = state as PetLoaded;
      final query = event.query.toLowerCase();
      if (query.isEmpty) {
        emit(PetLoaded(
          pets: currentState.pets,
          filteredPets: currentState.pets,
          searchQuery: '',
        ));
      } else {
        final filtered = currentState.pets.where((pet) {
          return pet.name.toLowerCase().contains(query) ||
              pet.breed.toLowerCase().contains(query);
        }).toList();
        emit(PetLoaded(
          pets: currentState.pets,
          filteredPets: filtered,
          searchQuery: event.query,
        ));
      }
    }
  }
}
