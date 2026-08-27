import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simpleread_flutter_shell/navigation/app_shell.dart';
import 'package:simpleread_flutter_shell/navigation/nav_state_store.dart';

Map<String, dynamic> _link(String href, String label, {String icon = 'book'}) =>
    {'type': 'link', 'href': href, 'label': label, 'icon': icon};

Map<String, dynamic> _group(
  String label,
  List<Map<String, dynamic>> children, {
  String icon = 'school',
}) => {'type': 'group', 'label': label, 'icon': icon, 'children': children};

Widget _wrap(NavStateStore store, {void Function(String href)? onNavigate}) {
  return MaterialApp(
    home: AppShell(
      store: store,
      body: const Text('the body'),
      onNavigate: onNavigate,
    ),
  );
}

void main() {
  group('AppShell — before/without nav items', () {
    testWidgets('renders just the body when no state has arrived yet', (
      tester,
    ) async {
      final store = NavStateStore();

      await tester.pumpWidget(_wrap(store));

      expect(find.text('the body'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('renders just the body when items is empty', (tester) async {
      final store = NavStateStore()..handle({'items': [], 'activeHref': null});

      await tester.pumpWidget(_wrap(store));

      expect(find.text('the body'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });

  group('AppShell — tab bar with <=5 items', () {
    testWidgets('shows one fixed tab per item, no "Mais" tab', (tester) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/learn', 'Biblioteca'),
            _link('/home', 'Início'),
            _link('/exams', 'Provas'),
          ],
          'activeHref': '/learn',
        });

      await tester.pumpWidget(_wrap(store));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Provas'), findsOneWidget);
      expect(find.text('Mais'), findsNothing);
    });

    testWidgets('tapping a link tab calls onNavigate with its href', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [_link('/learn', 'Biblioteca'), _link('/home', 'Início')],
          'activeHref': '/learn',
        });
      final navigated = <String>[];

      await tester.pumpWidget(_wrap(store, onNavigate: navigated.add));
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      expect(navigated, ['/home']);
    });

    testWidgets('tapping a group tab opens a bottom sheet with its children', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/learn', 'Biblioteca'),
            _group('Gestão', [
              _link('/teachers', 'Professores'),
              _link('/classrooms', 'Turmas'),
            ]),
          ],
          'activeHref': '/learn',
        });

      await tester.pumpWidget(_wrap(store));
      await tester.tap(find.text('Gestão'));
      await tester.pumpAndSettle();

      expect(find.text('Professores'), findsOneWidget);
      expect(find.text('Turmas'), findsOneWidget);
    });

    testWidgets('tapping a child in the group sheet navigates and closes it', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/learn', 'Biblioteca'),
            _group('Gestão', [
              _link('/teachers', 'Professores'),
              _link('/classrooms', 'Turmas'),
            ]),
          ],
          'activeHref': '/learn',
        });
      final navigated = <String>[];

      await tester.pumpWidget(_wrap(store, onNavigate: navigated.add));
      await tester.tap(find.text('Gestão'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Professores'));
      await tester.pumpAndSettle();

      expect(navigated, ['/teachers']);
      expect(find.text('Turmas'), findsNothing);
    });

    testWidgets('highlights the tab matching activeHref exactly', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [_link('/learn', 'Biblioteca'), _link('/home', 'Início')],
          'activeHref': '/home',
        });

      await tester.pumpWidget(_wrap(store));

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 1);
    });

    testWidgets(
      'highlights the group tab when activeHref matches one of its children',
      (tester) async {
        final store = NavStateStore()
          ..handle({
            'items': [
              _link('/learn', 'Biblioteca'),
              _group('Gestão', [
                _link('/teachers', 'Professores'),
                _link('/classrooms', 'Turmas'),
              ]),
            ],
            'activeHref': '/classrooms',
          });

        await tester.pumpWidget(_wrap(store));

        final bar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bar.currentIndex, 1);
      },
    );
  });

  group('AppShell — tab bar with >5 items', () {
    testWidgets('shows 4 fixed tabs plus a "Mais" tab', (tester) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/a', 'A'),
            _link('/b', 'B'),
            _link('/c', 'C'),
            _link('/d', 'D'),
            _link('/e', 'E'),
            _link('/f', 'F'),
          ],
          'activeHref': '/a',
        });

      await tester.pumpWidget(_wrap(store));

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.items, hasLength(5));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('Mais'), findsOneWidget);
      expect(find.text('E'), findsNothing);
      expect(find.text('F'), findsNothing);
    });

    testWidgets('tapping "Mais" opens a sheet listing the overflow items', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/a', 'A'),
            _link('/b', 'B'),
            _link('/c', 'C'),
            _link('/d', 'D'),
            _link('/e', 'E'),
            _link('/f', 'F'),
          ],
          'activeHref': '/a',
        });

      await tester.pumpWidget(_wrap(store));
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      expect(find.text('E'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('tapping an overflow link in the "Mais" sheet navigates', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/a', 'A'),
            _link('/b', 'B'),
            _link('/c', 'C'),
            _link('/d', 'D'),
            _link('/e', 'E'),
            _link('/f', 'F'),
          ],
          'activeHref': '/a',
        });
      final navigated = <String>[];

      await tester.pumpWidget(_wrap(store, onNavigate: navigated.add));
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('E'));
      await tester.pumpAndSettle();

      expect(navigated, ['/e']);
    });

    testWidgets('highlights "Mais" when activeHref matches an overflow item', (
      tester,
    ) async {
      final store = NavStateStore()
        ..handle({
          'items': [
            _link('/a', 'A'),
            _link('/b', 'B'),
            _link('/c', 'C'),
            _link('/d', 'D'),
            _link('/e', 'E'),
            _link('/f', 'F'),
          ],
          'activeHref': '/f',
        });

      await tester.pumpWidget(_wrap(store));

      final bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, 4);
    });
  });
}
