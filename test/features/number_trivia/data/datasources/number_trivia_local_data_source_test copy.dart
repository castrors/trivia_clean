import 'dart:convert';
import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trivia_clean/core/error/exceptions.dart';
import 'package:trivia_clean/features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'package:trivia_clean/features/number_trivia/data/models/number_trivia_model.dart';

import '../../../../fixtures/fixture_reader.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late NumberTriviaLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = NumberTriviaLocalDataSourceImpl(
        sharedPreferences: mockSharedPreferences);
  });

  group('getLastNumberTrivia', () {
    final tNumberTriviaModel =
        NumberTriviaModel.fromJson(json.decode(fixture('trivia_cached.json')));
    test(
        'should return NumberTrivia from SharedPreferences when there is one in the cache',
        () async {
      // arrange
      when(() => mockSharedPreferences.getString(any()))
          .thenReturn(fixture('trivia_cached.json'));
      // act
      final result = await dataSource.getLastNumberTrivia();
      // assert
      verify(() => mockSharedPreferences.getString(CACHED_NUMBER_TRIVIA));
      expect(result, equals(tNumberTriviaModel));
    });

    test('should thrown CacheException when there is not a cached value',
        () async {
      // arrange
      when(() => mockSharedPreferences.getString(any())).thenReturn(null);
      // act
      final call = dataSource.getLastNumberTrivia;
      // assert
      expect(() => call(), throwsA(const TypeMatcher<CacheException>()));
    });
  });

  group('cacheNumberTrivia', () {
    final tNumberTriviaModel = NumberTriviaModel(text: 'Test Text', number: 1);
    test('should call SharedPreferences to cache the data', () async {
      // arrange
      when(() => mockSharedPreferences.setString(CACHED_NUMBER_TRIVIA, any()))
          .thenAnswer((_) async => true);
      // act
      dataSource.cacheNumberTrivia(tNumberTriviaModel);

      // assert
      final expectedJsonString = json.encode(tNumberTriviaModel.toJson());
      verify(() => mockSharedPreferences.setString(
            CACHED_NUMBER_TRIVIA,
            expectedJsonString,
          ));
    });
  });
}
