import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/diary_entry.dart';
import '../../data/repositories/repository_selector.dart';

// Events
abstract class DiaryEvent extends Equatable {
  const DiaryEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiary extends DiaryEvent {
  final String? petId;
  const LoadDiary({this.petId});
  @override
  List<Object?> get props => [petId];
}

class AddDiaryEntryEvent extends DiaryEvent {
  final DiaryEntry entry;
  const AddDiaryEntryEvent(this.entry);
  @override
  List<Object?> get props => [entry];
}

class UpdateDiaryEntryEvent extends DiaryEvent {
  final DiaryEntry entry;
  final String? currentPetId;
  const UpdateDiaryEntryEvent(this.entry, {this.currentPetId});
  @override
  List<Object?> get props => [entry, currentPetId];
}

class DeleteDiaryEntryEvent extends DiaryEvent {
  final String entryId;
  final String? currentPetId;
  const DeleteDiaryEntryEvent(this.entryId, {this.currentPetId});
  @override
  List<Object?> get props => [entryId, currentPetId];
}

// States
abstract class DiaryState extends Equatable {
  const DiaryState();
  @override
  List<Object?> get props => [];
}

class DiaryInitial extends DiaryState {}

class DiaryLoading extends DiaryState {}

class DiaryLoaded extends DiaryState {
  final List<DiaryEntry> entries;
  const DiaryLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}

class DiaryError extends DiaryState {
  final String message;
  const DiaryError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final RepositorySelector repositorySelector;

  DiaryBloc({required this.repositorySelector}) : super(DiaryInitial()) {
    on<LoadDiary>(_onLoadDiary);
    on<AddDiaryEntryEvent>(_onAddDiaryEntry);
    on<UpdateDiaryEntryEvent>(_onUpdateDiaryEntry);
    on<DeleteDiaryEntryEvent>(_onDeleteDiaryEntry);
  }

  Future<void> _onLoadDiary(LoadDiary event, Emitter<DiaryState> emit) async {
    emit(DiaryLoading());
    try {
      final repo = await repositorySelector.getActiveRepository();
      List<DiaryEntry> entries;
      if (event.petId == null) {
        entries = await repo.getAllDiaryEntries();
      } else {
        entries = await repo.getDiaryEntries(event.petId!);
      }
      emit(DiaryLoaded(entries));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onAddDiaryEntry(AddDiaryEntryEvent event, Emitter<DiaryState> emit) async {
    try {
      final repo = await repositorySelector.getActiveRepository();
      await repo.addDiaryEntry(event.entry);
      // Reload based on current view
      List<DiaryEntry> entries;
      if (event.entry.petId.isEmpty) {
        entries = await repo.getAllDiaryEntries();
      } else {
        entries = await repo.getDiaryEntries(event.entry.petId);
      }
      emit(DiaryLoaded(entries));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onUpdateDiaryEntry(UpdateDiaryEntryEvent event, Emitter<DiaryState> emit) async {
    try {
      final repo = await repositorySelector.getActiveRepository();
      await repo.updateDiaryEntry(event.entry);
      List<DiaryEntry> entries;
      if (event.currentPetId == null) {
        entries = await repo.getAllDiaryEntries();
      } else {
        entries = await repo.getDiaryEntries(event.currentPetId!);
      }
      emit(DiaryLoaded(entries));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }

  Future<void> _onDeleteDiaryEntry(DeleteDiaryEntryEvent event, Emitter<DiaryState> emit) async {
    try {
      final repo = await repositorySelector.getActiveRepository();
      await repo.deleteDiaryEntry(event.entryId);
      // Reload based on current view/filter
      List<DiaryEntry> entries;
      if (event.currentPetId == null) {
        entries = await repo.getAllDiaryEntries();
      } else {
        entries = await repo.getDiaryEntries(event.currentPetId!);
      }
      emit(DiaryLoaded(entries));
    } catch (e) {
      emit(DiaryError(e.toString()));
    }
  }
}
