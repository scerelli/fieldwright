// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'IBIS';

  @override
  String get navProjects => 'Progetti';

  @override
  String get navSites => 'Siti';

  @override
  String get navVisits => 'Visite';

  @override
  String get navAccount => 'Account';

  @override
  String get projectsEmptyTitle => 'Nessun progetto';

  @override
  String get projectsEmptyMessage =>
      'Crea o unisciti a un progetto per iniziare.';

  @override
  String get sitesEmptyTitle => 'Nessun sito';

  @override
  String get sitesEmptyMessage => 'Aggiungi un sito pianificato per iniziare.';

  @override
  String get sitesAddSite => 'Aggiungi sito';

  @override
  String get sitesCreateHere => 'Crea sito qui';

  @override
  String get sitesCreateHereFailed =>
      'Impossibile ottenere la posizione. Riprova.';

  @override
  String get siteEditorNewTitle => 'Nuovo sito';

  @override
  String get siteEditorUpdateTitle => 'Aggiorna sito';

  @override
  String get siteGeometryPoint => 'Punto';

  @override
  String get siteGeometryLine => 'Linea';

  @override
  String get siteGeometryPolygon => 'Poligono';

  @override
  String get siteEditorLatitude => 'Latitudine';

  @override
  String get siteEditorLongitude => 'Longitudine';

  @override
  String get siteEditorAddVertex => 'Aggiungi punto';

  @override
  String get siteEditorRemoveVertex => 'Rimuovi punto';

  @override
  String get siteEditorSave => 'Salva sito';

  @override
  String get siteEditorInvalidGeometry => 'Inserisci una geometria valida.';

  @override
  String get siteDetailTitle => 'Dettagli del sito';

  @override
  String get siteDetailName => 'Nome';

  @override
  String get siteDetailGeometry => 'Geometria';

  @override
  String get siteCovariatesTitle => 'Covariate del sito';

  @override
  String get siteCovariatesNone =>
      'Il protocollo non definisce covariate del sito.';

  @override
  String get siteCovariatesMethod => 'Metodo';

  @override
  String get siteCovariatesMissingMethod =>
      'Seleziona un metodo per ogni valore.';

  @override
  String get siteCovariatesSave => 'Salva covariate';

  @override
  String get covariateMethodPhoneSensor => 'Sensore del telefono';

  @override
  String get covariateMethodFieldInstrument => 'Strumento da campo';

  @override
  String get covariateMethodVisualEstimate => 'Stima visiva';

  @override
  String get visitsEmptyTitle => 'Nessuna visita';

  @override
  String get visitsEmptyMessage => 'Avvia una visita da un sito.';

  @override
  String get visitsSitesHeading => 'Siti';

  @override
  String get visitsListHeading => 'Visite';

  @override
  String get visitsStartVisit => 'Avvia visita';

  @override
  String get visitsEndVisit => 'Concludi visita';

  @override
  String get visitsEndVisitTitle => 'Concludere la visita?';

  @override
  String get visitStateInProgress => 'In corso';

  @override
  String get visitStateEnded => 'Conclusa';

  @override
  String get captureTitle => 'Visita';

  @override
  String captureEffortStarted(String time) {
    return 'Sforzo iniziato: $time';
  }

  @override
  String captureState(String state) {
    return 'Stato: $state';
  }

  @override
  String get detectionTargetsHeading => 'Taxa bersaglio';

  @override
  String get detectionDetected => 'Rilevato';

  @override
  String get detectionNotDetected => 'Non rilevato';

  @override
  String get detectionNotRecorded => 'Non registrato';

  @override
  String get detectionNextUnrecorded => 'Prossimo non registrato';

  @override
  String get detectionNoTargets =>
      'Il protocollo non definisce taxa bersaglio.';

  @override
  String visitIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count taxa non registrati',
      one: '1 taxon non registrato',
    );
    return '$_temp0';
  }

  @override
  String get visitAllTargetsRecorded => 'Tutti i taxa registrati';

  @override
  String get opportunisticHeading => 'Taxa occasionali';

  @override
  String get opportunisticSearchLabel => 'Cerca per abbreviazione';

  @override
  String get opportunisticNoResults => 'Nessun taxon corrispondente';

  @override
  String get opportunisticPresenceOnly => 'Rilevato (occasionale)';

  @override
  String accountCount(int count) {
    return 'Conteggio account: $count';
  }

  @override
  String get incrementAccount => 'Incrementa account';
}
