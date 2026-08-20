import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Trailwatt';

  @override
  String get splashTagline => 'Sugerir. Exportar. Repetir.';

  @override
  String get authWelcome => 'Bem-vindo';

  @override
  String get authLoginSubtitle => 'Acesse sua conta Trailwatt';

  @override
  String get authSignupSubtitle => 'Leva menos de um minuto';

  @override
  String get authSignIn => 'Entrar';

  @override
  String get authCreateAccount => 'Criar conta';

  @override
  String get authName => 'Nome';

  @override
  String get authNameHint => 'seu nome';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'nome@email.com';

  @override
  String get authBirthDate => 'Data de nascimento';

  @override
  String get authBirthDateHint => 'DD/MM/AAAA';

  @override
  String get authPassword => 'Senha';

  @override
  String get authPasswordHint => 'sua senha';

  @override
  String get authCreatePasswordHint => 'crie uma senha';

  @override
  String get authConfirmPassword => 'Confirmar senha';

  @override
  String get authConfirmPasswordHint => 'repita a senha';

  @override
  String get authForgotPassword => 'Esqueceu a senha?';

  @override
  String get authOr => 'OU';

  @override
  String get authConsentPrefix => 'Concordo com os ';

  @override
  String get authConsentTerms => 'Termos de Uso';

  @override
  String get authConsentMiddle => ' e a ';

  @override
  String get authConsentPrivacy => 'Política de Privacidade';

  @override
  String get profileTitle => 'Criar perfil';

  @override
  String get profileSubtitle => 'Peso e FTP obrigatórios. O resto é opcional.';

  @override
  String get profileWeight => 'Peso (kg)';

  @override
  String get profileFtp => 'FTP (watts)';

  @override
  String get profileSave => 'Salvar perfil';

  @override
  String get profileFootnote => 'Peso e FTP bastam para o motor funcionar. As zonas podem ficar nas faixas genéricas ou ser ajustadas à mão.';

  @override
  String get profilePowerZones => 'ZONAS DE POTÊNCIA';

  @override
  String get profilePowerZonesAnchor => 'Ancoradas no FTP';

  @override
  String get profileHeartRateZones => 'ZONAS DE FREQUÊNCIA CARDÍACA';

  @override
  String get profileHeartRateZonesNote => 'Tabela separada da de potência - o mesmo esforço cai em zonas diferentes nas duas.';

  @override
  String get profileAnchorOn => 'Ancorar em';

  @override
  String get profileAnchorThreshold => 'Limiar (LTHR)';

  @override
  String get profileAnchorMax => 'FC máxima';

  @override
  String get profileThresholdHr => 'FC de limiar (bpm)';

  @override
  String get profileMaxHr => 'FC máxima (bpm)';

  @override
  String get profileOptional => 'opcional';

  @override
  String get profileNoHrAnchor => 'Sem esta medida o app não calcula zonas de FC - e não inventa: o treino em watts continua funcionando.';

  @override
  String get scaleFive => 'Z1-Z5';

  @override
  String get scaleSeven => 'Z1-Z7';

  @override
  String get zoneTableGeneric => 'GENÉRICA';

  @override
  String get zoneTableCustom => 'PERSONALIZADA';

  @override
  String get zoneTableEditBounds => 'Editar limites';

  @override
  String get zoneTableRestoreDefault => 'Restaurar padrão';

  @override
  String get zoneTableRecalculate => 'Recalcular';

  @override
  String get zoneTableAnchorMoved => 'A âncora mudou. Estes limites são os que você digitou e não acompanharam.';

  @override
  String get zoneTableInvalid => 'Cada limite precisa ser maior que o anterior. A tabela não será salva enquanto houver sobreposição.';

  @override
  String get zoneTableProvisional => 'Faixas genéricas, pendentes de revisão fisiológica. Toque em \"Editar limites\" para usar as suas.';

  @override
  String get zoneTableNeedsAnchor => 'Defina a âncora para calcular esta tabela.';

  @override
  String get zoneRecovery => 'Recuperação';

  @override
  String get zoneActiveRecovery => 'Recuperação ativa';

  @override
  String get zoneEndurance => 'Resistência';

  @override
  String get zoneTempo => 'Tempo';

  @override
  String get zoneThreshold => 'Limiar';

  @override
  String get zoneVo2max => 'VO2max';

  @override
  String get zoneAnaerobic => 'Anaeróbico';

  @override
  String get zoneNeuromuscular => 'Neuromuscular';

  @override
  String get metricPower => 'Potência';

  @override
  String get metricHeartRate => 'Frequência cardíaca';

  @override
  String get unitWatts => 'w';

  @override
  String get unitBpm => 'bpm';

  @override
  String get builderTitle => 'Criar treino';

  @override
  String get builderSubtitle => 'Monte o treino e marque onde pedalar';

  @override
  String get builderWatts => 'Watts';

  @override
  String get builderHr => 'FC';

  @override
  String builderTableLabel(String metric, int count) {
    return 'Tabela de $metric · Z1-Z$count';
  }

  @override
  String builderBlock(int number) {
    return 'BLOCO $number';
  }

  @override
  String get builderZone => 'Zona';

  @override
  String get builderDuration => 'Duração (min)';

  @override
  String get builderRepetitions => 'Repetições';

  @override
  String get builderRepetitionsHelp => '1 = sem repetição';

  @override
  String builderMin(String unit) {
    return 'Mínimo ($unit)';
  }

  @override
  String builderMax(String unit) {
    return 'Máximo ($unit)';
  }

  @override
  String get builderRest => 'Descanso entre séries (min)';

  @override
  String get builderAddSet => '+ Adicionar série';

  @override
  String get builderContinue => 'Continuar';

  @override
  String get builderFootnote => 'O nome do bloco usa a mesma nomenclatura de zona do resto do app. O treino é soberano - a rota se adapta ao estímulo, não o contrário.';

  @override
  String get builderNoHrAnchor => 'Defina uma FC de limiar ou máxima no perfil para prescrever por frequência cardíaca.';

  @override
  String get locationTitle => 'Criar treino';

  @override
  String get locationSubtitle => 'Continuação - onde treinar';

  @override
  String get locationWhere => 'ONDE TREINAR';

  @override
  String locationHint(int radius) {
    return 'Toque no mapa para marcar a área · raio $radius km';
  }

  @override
  String get locationGenerate => 'Gerar sugestões de rota';

  @override
  String get todayTitle => 'Treino de hoje';

  @override
  String get todaySubtitle => '4x8min a 180w';

  @override
  String get todayTarget => 'ALVO';

  @override
  String get todayGradient => 'GRADIENTE';

  @override
  String get todaySegment => 'TRECHO';

  @override
  String get routeSubtitle => 'Trecho sugerido para o treino de hoje';

  @override
  String get routeDistance => 'DISTÂNCIA';

  @override
  String get routeGradientLabel => 'GRADIENTE';

  @override
  String get routeMatch => 'MATCH';

  @override
  String get routeEditManually => 'Editar rota manualmente';

  @override
  String get routeExportTo => 'EXPORTAR PARA';

  @override
  String get routeExport => 'Exportar rota';

  @override
  String routeExported(String platform) {
    return 'Rota exportada para $platform';
  }

  @override
  String get routeFootnote => 'A cor do trecho segue a zona de esforço (Z1 a Z5, watts ou FC) prevista para aquele ponto da subida - não só \"dentro ou fora do alvo\".';

  @override
  String get routeDegraded => 'Trecho não verificado contra a malha viária.';

  @override
  String get routeSavedRescored => 'Rota reavaliada e salva';

  @override
  String get editRouteTitle => 'Editar rota';

  @override
  String get editRouteSubtitle => 'O trecho do treino dentro do percurso completo';

  @override
  String get editRouteHint => 'Arraste os pontos para editar. Ao soltar, o ponto encaixa na via mais próxima e a rota é refeita pelas ruas.';

  @override
  String get editRouteTotal => 'PERCURSO TOTAL';

  @override
  String get editRouteSegment => 'TRECHO DO TREINO';

  @override
  String get editRouteImpact => 'Impacto da edição';

  @override
  String get editRouteDeviation => 'Desvio';

  @override
  String get editRouteSnap => 'Encaixe na via';

  @override
  String editRouteSnapMeters(int meters) {
    return '$meters m até a via';
  }

  @override
  String get editRouteSnapUnverified => 'não verificado';

  @override
  String get editRoutePredictedMatch => 'Match previsto';

  @override
  String get editRouteNeedsRoads => 'requer malha viária';

  @override
  String get editRouteImpactNote => 'A aplicação não salva uma alteração material sem reavaliar o matching.';

  @override
  String get editRouteSave => 'Salvar alterações';

  @override
  String get editRouteCancel => 'Cancelar';

  @override
  String get importTitle => 'Resultado do treino';

  @override
  String get importSubtitle => 'Buscado automaticamente via API';

  @override
  String get importConnectedTo => 'CONECTADO AO STRAVA';

  @override
  String get importActivityFound => 'Atividade encontrada';

  @override
  String get importActivityWhen => 'Subida da Serra · hoje, 07:14';

  @override
  String get importAvgPower => 'POTÊNCIA MÉD.';

  @override
  String get importAvgHr => 'FC MÉDIA';

  @override
  String get importDuration => 'DURAÇÃO';

  @override
  String get importConfirm => 'Confirmar e salvar';

  @override
  String get importNoApi => 'SEM CONEXÃO COM A API?';

  @override
  String get importManualPower => 'Potência média (w)';

  @override
  String get importManualHint => 'informar manualmente';

  @override
  String get importManualHelp => 'Menos preciso - use apenas se a importação automática falhar.';

  @override
  String get importManualLink => 'Preencher manualmente por estímulo';

  @override
  String get importFootnote => 'A API busca a atividade correspondente automaticamente. A entrada manual só aparece como último recurso, e fica visualmente secundária.';

  @override
  String get manualIntervalsSubtitle => 'Entrada manual · treino intervalado';

  @override
  String get manualContinuousSubtitle => 'Entrada manual · treino contínuo';

  @override
  String manualStimulus(int number, String duration) {
    return 'ESTÍMULO $number · $duration';
  }

  @override
  String get manualEnduranceRide => 'PEDAL DE RESISTÊNCIA · 60 MIN';

  @override
  String manualTarget(int watts) {
    return 'alvo ${watts}w';
  }

  @override
  String get manualAvgWatts => 'watts médios';

  @override
  String get manualSave => 'Salvar treino';

  @override
  String get historyTitle => 'Seu progresso';

  @override
  String get historyCurrentFtp => 'FTP ATUAL';

  @override
  String get historyAccuracy => 'PRECISÃO';

  @override
  String get historyRecent => 'Treinos recentes';

  @override
  String historyTargetWatts(int watts) {
    return 'alvo ${watts}w';
  }

  @override
  String get calendarTitle => 'Calendário';

  @override
  String get calendarWeek => 'Semana';

  @override
  String get calendarMonth => 'Mês';

  @override
  String get calendarRestDay => 'Dia de descanso - sem treino planejado.';

  @override
  String get calendarDone => 'CONCLUÍDO';

  @override
  String calendarVia(String source) {
    return 'via $source';
  }

  @override
  String get calendarActual => 'REAL';

  @override
  String get calendarPlanned => 'ALVO';

  @override
  String get calendarDuration => 'DURAÇÃO';

  @override
  String calendarWorkoutSummary(String reps, int duration, int min, int max, String unit) {
    return '${reps}x${duration}min a $min-$max$unit';
  }

  @override
  String get navWorkout => 'Treino';

  @override
  String get navCalendar => 'Calendário';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navMore => 'Mais';

  @override
  String get navComingSoon => 'Em breve';

  @override
  String get sourceStrava => 'Strava';

  @override
  String get sourceGarmin => 'Garmin';

  @override
  String get sourceWahoo => 'Wahoo';

  @override
  String get sourceManual => 'entrada manual';

  @override
  String get landingEyebrow => 'PARA CICLISTAS, DO INICIANTE AO PRO';

  @override
  String get landingHeadline => 'Seu treino já diz o percurso ideal.';

  @override
  String get landingSubhead => 'Digite o alvo do treino de hoje e o Trailwatt sugere uma rota real que bate com ele.';

  @override
  String get landingStartFree => 'Começar grátis';

  @override
  String get landingHowItWorks => 'Ver como funciona';

  @override
  String get landingFeature1Title => 'Alvo por potência ou FC';

  @override
  String get landingFeature1Body => 'Do FTP de 150w ao de 300w, o motor calcula o gradiente certo para o seu nível.';

  @override
  String get landingFeature2Title => 'Cálculo 100% local';

  @override
  String get landingFeature2Body => 'O motor físico roda no próprio aparelho. Funciona mesmo sem internet.';

  @override
  String get landingFeature3Title => 'Exporta e importa sozinho';

  @override
  String get landingFeature3Body => 'Manda a rota pronta para o Strava, Garmin ou Wahoo, e busca o resultado de volta.';

  @override
  String get mapAttribution => 'colaboradores do OpenStreetMap';

  @override
  String get routingUnavailable => 'Serviço de rotas indisponível - distância em linha reta.';

  @override
  String get routingNoRoute => 'Nenhuma rota encontrada na malha viária entre estes pontos.';

  @override
  String get routingNeedsTwoPoints => 'Marque pelo menos dois pontos para traçar a rota.';

  @override
  String get importPowerCurveSnack => 'Conexão opcional - preenche a curva via API';
}
