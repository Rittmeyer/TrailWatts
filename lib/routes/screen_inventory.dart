/// Full inventory of screens designed in trailwatt_fluxo.html, mapped to
/// their intended Flutter routes. Screens with `implemented: true` have a
/// working widget under lib/screens/. The "exemplo preenchido" screens
/// (01b, 02b, 02b2, 02b3) are not separate routes - they are the same
/// screen as 01a/02a/02a2 shown with sample data, which is how the
/// prototype itself describes them ("mesmo formulario da 01a, agora com
/// dados de exemplo preenchidos").
class ScreenSpec {
  final String code; // matches the HTML prototype's eyebrow numbering
  final String route;
  final String title;
  final bool implemented;

  const ScreenSpec({
    required this.code,
    required this.route,
    required this.title,
    this.implemented = false,
  });
}

const screenInventory = <ScreenSpec>[
  ScreenSpec(
      code: '01', route: '/splash', title: 'Abertura', implemented: true),
  ScreenSpec(
      code: '01a',
      route: '/auth',
      title: 'Login / Criar conta',
      implemented: true),
  ScreenSpec(code: '02', route: '/profile', title: 'Perfil', implemented: true),
  ScreenSpec(
      code: '02a',
      route: '/workout-builder',
      title: 'Criar treino (1/2)',
      implemented: true),
  ScreenSpec(
      code: '02a2',
      route: '/workout-builder/map',
      title: 'Criar treino (2/2) - mapa',
      implemented: true),
  ScreenSpec(
      code: '03', route: '/home', title: 'Treino do dia', implemented: true),
  ScreenSpec(
      code: '04',
      route: '/route-map',
      title: 'Rota no mapa',
      implemented: true),
  ScreenSpec(
      code: '05',
      route: '/route-edit',
      title: 'Editar rota',
      implemented: true),
  ScreenSpec(
      code: '06',
      route: '/import-result',
      title: 'Importar resultado',
      implemented: true),
  ScreenSpec(
      code: '06a',
      route: '/import-result/manual-intervals',
      title: 'Manual - intervalado',
      implemented: true),
  ScreenSpec(
      code: '06b',
      route: '/import-result/manual-continuous',
      title: 'Manual - continuo',
      implemented: true),
  ScreenSpec(
      code: '07', route: '/history', title: 'Historico', implemented: true),
  ScreenSpec(
      code: '08a',
      route: '/calendar/week',
      title: 'Calendario - semana / dia concluido',
      implemented: true),
  ScreenSpec(
      code: '08c',
      route: '/calendar/month',
      title: 'Calendario - mes',
      implemented: true),
  ScreenSpec(
      code: 'web', route: '/', title: 'Landing page (web)', implemented: true),
];
