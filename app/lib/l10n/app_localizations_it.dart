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
  String get projectsEmptyMessage => 'Crea un progetto per iniziare.';

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
  String get visitStateSubmitted => 'Inviata';

  @override
  String get visitDetailTitle => 'Dettagli visita';

  @override
  String get visitDetailStatus => 'Stato di validazione';

  @override
  String get visitStatusSubmitted => 'Inviata';

  @override
  String get visitStatusValidated => 'Validata';

  @override
  String get visitStatusRejected => 'Rifiutata';

  @override
  String get visitDetailCorrectionsHeading => 'Correzioni';

  @override
  String get visitDetailCorrectionsEmpty => 'Questa visita non ha correzioni.';

  @override
  String get visitDetailLoadFailed =>
      'Impossibile caricare la visita. Riprova.';

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
  String get authEmail => 'Email';

  @override
  String get authPassword => 'Password';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authSignInFailed =>
      'Accesso non riuscito. Controlla email e password.';

  @override
  String get authSignOut => 'Esci';

  @override
  String authSignedInAs(String name) {
    return 'Accesso effettuato come $name';
  }

  @override
  String get authName => 'Nome';

  @override
  String get authSignUp => 'Crea account';

  @override
  String get authSwitchToSignUp => 'Crea un account';

  @override
  String get authSwitchToSignIn => 'Torna all\'accesso';

  @override
  String get authNameRequired => 'Inserisci il tuo nome.';

  @override
  String get authEmailInvalid => 'Inserisci un\'email valida.';

  @override
  String get authPasswordTooShort => 'Usa almeno 8 caratteri.';

  @override
  String get authSignUpFailed =>
      'Impossibile creare l\'account. Controlla i dati e riprova.';

  @override
  String get evidencePhoto => 'Foto';

  @override
  String get evidenceAudio => 'Audio';

  @override
  String get evidenceStop => 'Ferma';

  @override
  String get evidenceCaptureFailed =>
      'Impossibile acquisire la prova. Riprova.';

  @override
  String get visitCovariatesHeading => 'Covariate della visita';

  @override
  String get measurementManualFallback =>
      'Inserimento manuale (sensore non disponibile)';

  @override
  String get measurementLowConfidence =>
      'Bassa affidabilità (sensore non calibrato)';

  @override
  String get measurementMethod => 'Metodo';

  @override
  String get measurementMissingMethod => 'Seleziona un metodo per ogni valore.';

  @override
  String get measurementSave => 'Salva misurazioni';

  @override
  String get projectsCreateProject => 'Crea progetto';

  @override
  String get projectEditorNewTitle => 'Nuovo progetto';

  @override
  String get projectEditorName => 'Nome del progetto';

  @override
  String get projectEditorReferenceId => 'Riferimento tassonomico';

  @override
  String get projectEditorReferenceVersion =>
      'Versione del riferimento tassonomico';

  @override
  String get projectEditorValidation => 'Validazione';

  @override
  String get projectEditorObfuscation => 'Oscuramento dei taxa sensibili';

  @override
  String get projectEditorSave => 'Salva progetto';

  @override
  String get projectEditorNameRequired => 'Inserisci un nome del progetto.';

  @override
  String get projectEditorReferenceRequired =>
      'Seleziona un riferimento tassonomico.';

  @override
  String get projectEditorVersionRequired =>
      'Inserisci una versione del riferimento tassonomico.';

  @override
  String get projectEditorCreateFailed =>
      'Impossibile creare il progetto. Riprova.';

  @override
  String get projectEditorReferenceIdHelper =>
      'La checklist rispetto a cui vengono risolti i nomi dei taxa del progetto.';

  @override
  String get projectEditorReferenceVersionHelper =>
      'La versione esatta della checklist fissata al progetto; i nomi dei taxa vengono risolti rispetto ad essa prima dell\'invio.';

  @override
  String get projectEditorSaveFailed =>
      'Impossibile salvare il progetto. Riprova.';

  @override
  String get projectSettingsNotFound =>
      'Questo progetto non è su questo dispositivo.';

  @override
  String get projectSettingsTitle => 'Impostazioni del progetto';

  @override
  String get protocolVersionTitle => 'Versione del protocollo';

  @override
  String get protocolVersionNewTitle => 'Nuova versione del protocollo';

  @override
  String get protocolVersionProtocolId => 'ID del protocollo';

  @override
  String get protocolVersionTaxonomicScope => 'Ambito tassonomico';

  @override
  String get protocolVersionCompleteListMode => 'Modalità elenco completo';

  @override
  String get protocolVersionTargetList => 'Lista dei taxa bersaglio';

  @override
  String get protocolVersionDetectionMethods => 'Metodi di rilevamento';

  @override
  String get protocolVersionRequiredEffort => 'Campi di sforzo obbligatori';

  @override
  String get protocolVersionVisitCovariates => 'Covariate della visita';

  @override
  String get protocolVersionSiteCovariates => 'Covariate del sito';

  @override
  String get effortFieldStart => 'Inizio';

  @override
  String get effortFieldDuration => 'Durata';

  @override
  String get effortFieldObservers => 'Osservatori';

  @override
  String get effortFieldDetectionMethods => 'Metodi di rilevamento';

  @override
  String get protocolVersionSave => 'Salva versione del protocollo';

  @override
  String get protocolVersionFrozen => 'Congelata';

  @override
  String get protocolVersionCreateNew => 'Crea una nuova versione';

  @override
  String protocolVersionVersion(int version) {
    return 'Versione $version';
  }

  @override
  String get protocolVersionReadOnly =>
      'Questa versione è congelata e non può più cambiare. Crea una nuova versione per apportare modifiche.';

  @override
  String get protocolVersionProtocolIdRequired =>
      'Inserisci un ID del protocollo.';

  @override
  String get protocolVersionScopeRequired =>
      'Inserisci almeno un taxon nell\'ambito.';

  @override
  String get protocolVersionTargetListRequired =>
      'Inserisci almeno un taxon bersaglio o usa la modalità elenco completo.';

  @override
  String get protocolVersionDetectionMethodsRequired =>
      'Inserisci almeno un metodo di rilevamento.';

  @override
  String get protocolVersionEffortRequired =>
      'Seleziona almeno un campo di sforzo obbligatorio.';

  @override
  String get protocolVersionInvalidCovariates =>
      'Inserisci ogni covariata come nome:tipo[:unità], oppure lascia vuoto il campo.';

  @override
  String get protocolVersionCreateFailed =>
      'Impossibile salvare la versione del protocollo. Riprova.';

  @override
  String get membersTitle => 'Membri';

  @override
  String get membersEmpty => 'Nessun membro.';

  @override
  String get membersLoadFailed => 'Impossibile caricare i membri. Riprova.';

  @override
  String get membersAddHeading => 'Aggiungi membro';

  @override
  String get membersEmail => 'Email';

  @override
  String get membersRole => 'Ruolo';

  @override
  String get membersAdd => 'Aggiungi membro';

  @override
  String get membersEmailRequired => 'Inserisci un\'email valida.';

  @override
  String get membersRoleRequired => 'Seleziona un ruolo.';

  @override
  String get membersAddFailed => 'Impossibile aggiungere il membro. Riprova.';

  @override
  String get membershipRoleCreator => 'Creatore';

  @override
  String get membershipRoleCollector => 'Raccoglitore';

  @override
  String get membershipRoleValidator => 'Validatore';

  @override
  String get surveyPeriodsTitle => 'Periodi di indagine';

  @override
  String get surveyPeriodsEmpty => 'Nessun periodo di indagine.';

  @override
  String get surveyPeriodsLoadFailed =>
      'Impossibile caricare i periodi di indagine. Riprova.';

  @override
  String get surveyPeriodsAddHeading => 'Aggiungi periodo di indagine';

  @override
  String get surveyPeriodName => 'Nome';

  @override
  String get surveyPeriodStartDate => 'Data di inizio';

  @override
  String get surveyPeriodEndDate => 'Data di fine';

  @override
  String get surveyPeriodsAdd => 'Aggiungi periodo di indagine';

  @override
  String get surveyPeriodNameRequired => 'Inserisci un nome.';

  @override
  String get surveyPeriodStartRequired => 'Inserisci una data di inizio.';

  @override
  String get surveyPeriodEndRequired => 'Inserisci una data di fine.';

  @override
  String get surveyPeriodInvalidDate => 'Inserisci ogni data come AAAA-MM-GG.';

  @override
  String get surveyPeriodEndBeforeStart =>
      'La data di fine non può precedere quella di inizio.';

  @override
  String get surveyPeriodsAddFailed =>
      'Impossibile aggiungere il periodo di indagine. Riprova.';

  @override
  String get syncIndicatorQueued => 'In coda';

  @override
  String get syncIndicatorSyncing => 'Sincronizzazione in corso';

  @override
  String get syncIndicatorSynced => 'Sincronizzata';

  @override
  String get syncIndicatorFailed => 'Sincronizzazione non riuscita';

  @override
  String get syncIndicatorRetry => 'Riprova';

  @override
  String get helpTitle => 'Manuale';

  @override
  String get helpOpen => 'Apri il manuale';

  @override
  String get helpCreateProjectTitle => 'Crea un Progetto';

  @override
  String get helpCreateProjectBody =>
      'Dall\'elenco Progetti, tocca + per creare un Progetto — nessun account richiesto. Assegna un nome e fissa un riferimento tassonomico; potrai aggiungere una versione del Protocollo, i Periodi di indagine e i Siti in seguito.';

  @override
  String get helpCaptureVisitTitle => 'Registra una Visita';

  @override
  String get helpCaptureVisitBody =>
      'Apri un Progetto e avvia una Visita in un Sito; parte il timer dello sforzo di campionamento. Registra ogni taxon obiettivo come rilevato o non rilevato, aggiungi taxa opportunistici ed Evidenze, poi termina la Visita.';

  @override
  String get helpSubmitVisitTitle => 'Invia la Visita';

  @override
  String get helpSubmitVisitBody =>
      'Invia una Visita terminata quando hai connessione. L\'invio può essere ritentato senza rischi, la Visita diventa immutabile e un validatore può convalidarla quando il Progetto attiva la convalida.';
}
