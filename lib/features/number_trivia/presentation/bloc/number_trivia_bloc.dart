import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:trivia_clean/core/error/failures.dart';
import 'package:trivia_clean/core/usecases/usecase.dart';
import 'package:trivia_clean/core/util/input_converter.dart';
import 'package:trivia_clean/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:trivia_clean/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:trivia_clean/features/number_trivia/domain/usecases/get_random_number_trivia.dart';

part 'number_trivia_event.dart';
part 'number_trivia_state.dart';

const String SERVER_FAILURE_MESSAGE = 'Server Failure';
const String CACHE_FAILURE_MESSAGE = 'Cache Failure';
const String INVALID_INPUT_FAILURE_MESSAGE =
    'Invalid Input - The number must be a positive integer or zero.';

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc({
    required this.getConcreteNumberTrivia,
    required this.getRandomNumberTrivia,
    required this.inputConverter,
  }) : super(Empty()) {
    on<GetTriviaForConcreteNumber>((event, emit) async {
      emit(Empty());
      final inputEither =
          inputConverter.stringToUnsignedInteger(event.numberString);
      await inputEither.fold((failure) async {
        emit(const Error(message: INVALID_INPUT_FAILURE_MESSAGE));
      }, (integer) async {
        emit(Loading());
        await getConcreteNumberTrivia(Params(number: integer)).then(
          (either) => _eitherLoadedOrErrorState(emit, either),
        );
      });
    });

    on<GetTriviaForRandomNumber>((event, emit) async {
      emit(Empty());
      emit(Loading());
      await getRandomNumberTrivia(NoParams()).then(
        (either) => _eitherLoadedOrErrorState(emit, either),
      );
    });
  }

  void _eitherLoadedOrErrorState(Emitter<NumberTriviaState> emit,
      Either<Failure, NumberTrivia> failureOrTrivia) {
    emit(failureOrTrivia.fold(
      (failure) => Error(message: _mapFailureToMessage(failure)),
      (trivia) => Loaded(trivia: trivia),
    ));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return SERVER_FAILURE_MESSAGE;
      case CacheFailure:
        return CACHE_FAILURE_MESSAGE;
      default:
        return 'Unexpected Error';
    }
  }
}
