/// Textos multilingües ES/EN/PT/IT/FR — Dart puro, sin framework de
/// localización.
///
/// Deliberadamente simple: cinco idiomas, una clase, getters testeables.
/// Los ids de hallazgo y las constantes de permiso se traducen aquí; el
/// export JSON nunca se traduce.
library;

import '../core/models.dart';

// Los textos que más crecen viven en archivos aparte. Son `part` (misma
// librería) y no imports: así siguen viendo `_pick`, el mecanismo privado de
// traducción, sin tener que hacerlo público solo para poder partir el archivo.
part 'strings/findings.dart';
part 'strings/permissions.dart';

/// Idiomas soportados por la UI. El orden es el de aparición en el selector.
enum AppLang { es, en, pt, it, fr }

/// Resuelve el idioma efectivo a partir del código guardado en la config y
/// del idioma del equipo. `code` vacío (o desconocido) = "automático": se usa
/// el idioma del dispositivo; si tampoco se reconoce, se cae a inglés.
AppLang resolveLanguage(String code, {required String deviceLanguageCode}) {
  AppLang? fromCode(String c) => switch (c.toLowerCase()) {
    'es' => AppLang.es,
    'en' => AppLang.en,
    'pt' => AppLang.pt,
    'it' => AppLang.it,
    'fr' => AppLang.fr,
    _ => null,
  };
  return fromCode(code) ?? fromCode(deviceLanguageCode) ?? AppLang.en;
}

/// Nombre nativo de cada idioma, para el selector (no se traduce: cada uno
/// se muestra en su propia lengua).
String languageNativeName(AppLang lang) => switch (lang) {
  AppLang.es => 'Español',
  AppLang.en => 'English',
  AppLang.pt => 'Português',
  AppLang.it => 'Italiano',
  AppLang.fr => 'Français',
};

/// Código ISO 639-1 de cada idioma; el que se guarda en la config.
String languageCodeOf(AppLang lang) => switch (lang) {
  AppLang.es => 'es',
  AppLang.en => 'en',
  AppLang.pt => 'pt',
  AppLang.it => 'it',
  AppLang.fr => 'fr',
};

/// Autoría de la app, visible en la bienvenida, Acerca y Configuración.
const String nexoraCreatorName = 'Maximiliano Campissi';

class AppStrings {
  const AppStrings(this.lang);

  final AppLang lang;

  /// Compatibilidad puntual: algún sitio aún razona en "¿es español?".
  bool get spanish => lang == AppLang.es;

  String _pick(String es, String en, String pt, String it, String fr) =>
      switch (lang) {
        AppLang.es => es,
        AppLang.en => en,
        AppLang.pt => pt,
        AppLang.it => it,
        AppLang.fr => fr,
      };

  // Tabs
  String get tabSummary =>
      _pick('Resumen', 'Summary', 'Resumo', 'Riepilogo', 'Résumé');
  String get tabApps => _pick('Apps', 'Apps', 'Apps', 'App', 'Apps');
  String get tabFlagged =>
      _pick('Señaladas', 'Flagged', 'Sinalizadas', 'Segnalate', 'Signalées');
  String get tabNetwork => _pick('Red', 'Network', 'Rede', 'Rete', 'Réseau');
  String get tabStorage => _pick(
    'Almacenamiento',
    'Storage',
    'Armazenamento',
    'Archiviazione',
    'Stockage',
  );
  String get tabDevice =>
      _pick('Dispositivo', 'Device', 'Dispositivo', 'Dispositivo', 'Appareil');
  String get tabNearby =>
      _pick('Cercanía', 'Nearby', 'Proximidade', 'Vicinanze', 'À proximité');
  String get tabHistory =>
      _pick('Historial', 'History', 'Histórico', 'Cronologia', 'Historique');
  String get tabSettings => _pick(
    'Configuración',
    'Settings',
    'Configurações',
    'Impostazioni',
    'Réglages',
  );
  String get tabAbout => _pick('Acerca', 'About', 'Sobre', 'Info', 'À propos');

  // Acciones
  String get actionLanguage =>
      _pick('Idioma', 'Language', 'Idioma', 'Lingua', 'Langue');
  String get actionRefresh => _pick(
    'Actualizar captura',
    'Refresh snapshot',
    'Atualizar captura',
    'Aggiorna acquisizione',
    'Actualiser la capture',
  );
  String get actionExport => _pick(
    'Exportar JSON forense',
    'Export forensic JSON',
    'Exportar JSON forense',
    'Esporta JSON forense',
    'Exporter le JSON forensique',
  );
  String get loading => _pick(
    'Capturando estado del dispositivo…',
    'Capturing device state…',
    'Capturando o estado do dispositivo…',
    'Acquisizione dello stato del dispositivo…',
    'Capture de l’état de l’appareil…',
  );
  String exportOk(String path) => _pick(
    'Evidencia copiada al portapapeles y guardada en $path',
    'Evidence copied to clipboard and saved to $path',
    'Evidência copiada para a área de transferência e salva em $path',
    'Prova copiata negli appunti e salvata in $path',
    'Preuve copiée dans le presse-papiers et enregistrée dans $path',
  );
  String get exportFail => _pick(
    'No se pudo exportar la evidencia',
    'Could not export evidence',
    'Não foi possível exportar a evidência',
    'Impossibile esportare la prova',
    'Impossible d’exporter la preuve',
  );

  // Veredicto
  String get verdictNormal => _pick(
    'Sistema estable — sin distorsiones',
    'System stable — no distortions',
    'Sistema estável — sem distorções',
    'Sistema stabile — nessuna distorsione',
    'Système stable — aucune distorsion',
  );
  String get verdictWarning => _pick(
    'Advertencia — hay indicios que revisar',
    'Warning — signals to review',
    'Aviso — há indícios a revisar',
    'Avviso — segnali da verificare',
    'Avertissement — des signaux à examiner',
  );
  String get verdictCritical => _pick(
    'Crítico — distorsión seria en curso',
    'Critical — serious distortion',
    'Crítico — distorção séria em curso',
    'Critico — distorsione grave in corso',
    'Critique — distorsion grave en cours',
  );
  String verdictScore(int score) => _pick(
    'Puntaje: $score',
    'Score: $score',
    'Pontuação: $score',
    'Punteggio: $score',
    'Score : $score',
  );
  String get findingsNone => _pick(
    'Sin hallazgos: el dispositivo se ve estable.',
    'No findings: the device looks stable.',
    'Sem achados: o dispositivo parece estável.',
    'Nessun rilievo: il dispositivo appare stabile.',
    'Aucune constatation : l’appareil semble stable.',
  );
  String get severityNormal =>
      _pick('Normal', 'Normal', 'Normal', 'Normale', 'Normal');
  String get severityWarning =>
      _pick('Advertencia', 'Warning', 'Aviso', 'Avviso', 'Avertissement');
  String get severityCritical =>
      _pick('Crítico', 'Critical', 'Crítico', 'Critico', 'Critique');
  String recommendation(String text) => _pick(
    'Recomendación: $text',
    'Recommendation: $text',
    'Recomendação: $text',
    'Raccomandazione: $text',
    'Recommandation : $text',
  );

  // Memoria / almacenamiento / batería
  String get memTitle =>
      _pick('Memoria', 'Memory', 'Memória', 'Memoria', 'Mémoire');
  String get memUsed => _pick('Usada', 'Used', 'Usada', 'Usata', 'Utilisée');
  String get memAvailable => _pick(
    'Disponible',
    'Available',
    'Disponível',
    'Disponibile',
    'Disponible',
  );
  String get memTotal => _pick('Total', 'Total', 'Total', 'Totale', 'Total');
  String get storageTitle => _pick(
    'Almacenamiento',
    'Storage',
    'Armazenamento',
    'Archiviazione',
    'Stockage',
  );
  String get storageFree => _pick('Libre', 'Free', 'Livre', 'Libero', 'Libre');
  String get storageUsed => _pick('Usado', 'Used', 'Usado', 'Usato', 'Utilisé');
  String get storageTotal =>
      _pick('Total', 'Total', 'Total', 'Totale', 'Total');
  String get cacheTitle => _pick(
    'Caché de esta app',
    'This app\'s cache',
    'Cache deste app',
    'Cache di questa app',
    'Cache de cette app',
  );
  String get cacheSize =>
      _pick('Tamaño', 'Size', 'Tamanho', 'Dimensione', 'Taille');
  String get cacheNote => _pick(
    'Android e iOS no permiten leer la caché de otras apps; esta cifra es la caché propia de Nexora.',
    'Android and iOS do not allow reading other apps\' caches; this figure is Nexora\'s own cache.',
    'Android e iOS não permitem ler o cache de outros apps; este valor é o cache do próprio Nexora.',
    'Android e iOS non permettono di leggere la cache di altre app; questo valore è la cache di Nexora.',
    'Android et iOS n’autorisent pas la lecture du cache des autres apps ; ce chiffre est le cache propre de Nexora.',
  );
  String get cacheClear => _pick(
    'Limpiar caché propia',
    'Clear own cache',
    'Limpar cache próprio',
    'Svuota la cache',
    'Vider le cache propre',
  );
  String cacheCleared(String freed) => _pick(
    'Caché propia liberada: $freed',
    'Own cache cleared: $freed',
    'Cache próprio liberado: $freed',
    'Cache liberata: $freed',
    'Cache propre libéré : $freed',
  );
  String get volumeInternal => _pick(
    'Interno (datos)',
    'Internal (data)',
    'Interno (dados)',
    'Interno (dati)',
    'Interne (données)',
  );
  String get volumeRemovable =>
      _pick('extraíble', 'removable', 'removível', 'rimovibile', 'amovible');
  String get volumesNone => _pick(
    'Sin volúmenes adicionales: este equipo no tiene tarjeta SD ni USB conectado (o el SO no los expone). No es un fallo — se muestran solo cuando existen.',
    'No additional volumes: this device has no SD card or USB attached (or the OS does not expose them). Not a failure — they are listed only when present.',
    'Sem volumes adicionais: este aparelho não tem cartão SD nem USB conectado (ou o SO não os expõe). Não é falha — só aparecem quando existem.',
    'Nessun volume aggiuntivo: questo dispositivo non ha scheda SD né USB collegata (o il SO non li espone). Non è un errore — compaiono solo quando presenti.',
    'Aucun volume supplémentaire : cet appareil n’a ni carte SD ni USB connecté (ou l’OS ne les expose pas). Ce n’est pas une panne — ils n’apparaissent que s’ils existent.',
  );
  String get batteryTitle =>
      _pick('Batería', 'Battery', 'Bateria', 'Batteria', 'Batterie');
  String get batteryLevel =>
      _pick('Nivel', 'Level', 'Nível', 'Livello', 'Niveau');
  String get batteryState =>
      _pick('Estado', 'State', 'Estado', 'Stato', 'État');
  String get batteryCharging =>
      _pick('Cargando', 'Charging', 'Carregando', 'In carica', 'En charge');
  String get batteryDischarging => _pick(
    'Descargando',
    'Discharging',
    'Descarregando',
    'In scarica',
    'En décharge',
  );
  String get batteryTemp => _pick(
    'Temperatura',
    'Temperature',
    'Temperatura',
    'Temperatura',
    'Température',
  );
  String get batteryHealth =>
      _pick('Salud', 'Health', 'Saúde', 'Salute', 'Santé');
  String get notAvailableOnPlatform => _pick(
    'No disponible en este SO',
    'Not available on this OS',
    'Indisponível neste SO',
    'Non disponibile su questo SO',
    'Indisponible sur cet OS',
  );

  // Red
  String get networkTitle => _pick(
    'Estado de red',
    'Network state',
    'Estado da rede',
    'Stato della rete',
    'État du réseau',
  );
  String get netConnected =>
      _pick('Conectado', 'Connected', 'Conectado', 'Connesso', 'Connecté');
  String get netTransport =>
      _pick('Transporte', 'Transport', 'Transporte', 'Trasporto', 'Transport');
  String get netVpn => _pick(
    'VPN activa',
    'VPN active',
    'VPN ativa',
    'VPN attiva',
    'VPN active',
  );
  String get netMetered => _pick(
    'Red medida',
    'Metered network',
    'Rede limitada',
    'Rete a consumo',
    'Réseau facturé',
  );
  String get netDown => _pick(
    'Bajada estimada',
    'Estimated downlink',
    'Download estimado',
    'Download stimato',
    'Débit descendant estimé',
  );
  String get netUp => _pick(
    'Subida estimada',
    'Estimated uplink',
    'Upload estimado',
    'Upload stimato',
    'Débit montant estimé',
  );
  String get netTrafficTitle => _pick(
    'Tráfico acumulado (desde el arranque)',
    'Accumulated traffic (since boot)',
    'Tráfego acumulado (desde a inicialização)',
    'Traffico accumulato (dall’avvio)',
    'Trafic cumulé (depuis le démarrage)',
  );
  String get netRx =>
      _pick('Recibido', 'Received', 'Recebido', 'Ricevuto', 'Reçu');
  String get netTx => _pick('Enviado', 'Sent', 'Enviado', 'Inviato', 'Envoyé');
  String get netTrafficNote => _pick(
    'Contadores globales del SO. Nexora no inspecciona el contenido de tu tráfico.',
    'OS-wide counters. Nexora does not inspect your traffic contents.',
    'Contadores globais do SO. O Nexora não inspeciona o conteúdo do seu tráfego.',
    'Contatori globali del SO. Nexora non ispeziona il contenuto del tuo traffico.',
    'Compteurs globaux de l’OS. Nexora n’inspecte pas le contenu de votre trafic.',
  );
  String get yes => _pick('Sí', 'Yes', 'Sim', 'Sì', 'Oui');
  String get no => _pick('No', 'No', 'Não', 'No', 'Non');

  // Apps
  String get appsTitle => _pick(
    'Auditoría de apps',
    'App audit',
    'Auditoria de apps',
    'Controllo delle app',
    'Audit des apps',
  );
  String get appsTotal => _pick(
    'Apps de usuario',
    'User apps',
    'Apps do usuário',
    'App utente',
    'Apps utilisateur',
  );
  String get appsRiskyCount => _pick(
    'Con superficie riesgosa',
    'With risky surface',
    'Com superfície arriscada',
    'Con superficie a rischio',
    'À surface risquée',
  );
  String get appsHonestyNote => _pick(
    'Un puntaje alto no prueba malicia: mide la superficie de permisos que la app SOLICITA. Android no permite ver el consumo de otras apps.',
    'A high score does not prove malice: it measures the permission surface the app REQUESTS. Android does not allow reading other apps\' resource usage.',
    'Uma pontuação alta não prova malícia: mede a superfície de permissões que o app SOLICITA. O Android não permite ver o consumo de outros apps.',
    'Un punteggio alto non prova malizia: misura la superficie di permessi che l’app RICHIEDE. Android non permette di vedere il consumo di altre app.',
    'Un score élevé ne prouve pas la malveillance : il mesure la surface de permissions que l’app DEMANDE. Android n’autorise pas à voir la consommation des autres apps.',
  );
  String get appsUnsupported => _pick(
    'iOS no permite listar las apps instaladas. No es un fallo de Nexora: es diseño del sistema operativo.',
    'iOS does not allow listing installed apps. This is not a Nexora limitation: it is OS design.',
    'O iOS não permite listar os apps instalados. Não é falha do Nexora: é design do sistema operacional.',
    'iOS non permette di elencare le app installate. Non è un limite di Nexora: è il design del sistema operativo.',
    'iOS n’autorise pas la liste des apps installées. Ce n’est pas une limite de Nexora : c’est la conception du système.',
  );
  String appRiskScore(int score) => _pick(
    'riesgo $score',
    'risk $score',
    'risco $score',
    'rischio $score',
    'risque $score',
  );
  String appUsage(String time) => _pick(
    'Uso 24 h: $time',
    '24 h use: $time',
    'Uso 24 h: $time',
    'Uso 24 h: $time',
    'Utilisation 24 h : $time',
  );
  String get appsUsageGrant => _pick(
    'Ver tiempo en pantalla (permiso opcional)',
    'See screen time (optional permission)',
    'Ver tempo de tela (permissão opcional)',
    'Vedi il tempo di utilizzo (permesso opzionale)',
    'Voir le temps d’écran (permission facultative)',
  );
  String get appsUsageNote => _pick(
    'Con el acceso de uso (lo concedes tú en Ajustes del sistema) cada app muestra su tiempo en pantalla de las últimas 24 h y la lista se ordena por uso — la respuesta directa a "¿qué app me está gastando el teléfono?".',
    'With usage access (you grant it in system Settings) each app shows its screen time over the last 24 h and the list sorts by usage — the direct answer to "which app is draining my phone?".',
    'Com o acesso de uso (você concede nas Configurações do sistema) cada app mostra o tempo de tela das últimas 24 h e a lista é ordenada por uso — a resposta direta a "qual app está gastando meu telefone?".',
    'Con l’accesso all’utilizzo (lo concedi tu nelle Impostazioni di sistema) ogni app mostra il tempo di utilizzo delle ultime 24 h e la lista è ordinata per uso — la risposta diretta a "quale app mi sta consumando il telefono?".',
    'Avec l’accès à l’usage (que vous accordez dans les Réglages système) chaque app affiche son temps d’écran des dernières 24 h et la liste est triée par usage — la réponse directe à « quelle app épuise mon téléphone ? ».',
  );
  String appPerms(String perms) => _pick(
    'Permisos peligrosos: $perms',
    'Dangerous permissions: $perms',
    'Permissões perigosas: $perms',
    'Permessi pericolosi: $perms',
    'Permissions dangereuses : $perms',
  );
  String get appPermsTitle => _pick(
    'Permisos que pide esta app',
    'Permissions this app asks for',
    'Permissões que este app pede',
    'Permessi richiesti da questa app',
    'Permissions demandées par cette app',
  );
  String get appPermGranted =>
      _pick('concedido', 'granted', 'concedido', 'concesso', 'accordé');
  String get appPermRequestedOnly => _pick(
    'pedido, no concedido',
    'requested, not granted',
    'pedido, não concedido',
    'richiesto, non concesso',
    'demandé, non accordé',
  );
  String get appActiveCapsTitle => _pick(
    'Capacidades sensibles activas',
    'Active sensitive capabilities',
    'Capacidades sensíveis ativas',
    'Capacità sensibili attive',
    'Capacités sensibles actives',
  );
  String appDataUsage(String total) => _pick(
    'Datos 24 h: $total',
    '24 h data: $total',
    'Dados 24 h: $total',
    'Dati 24 h: $total',
    'Données 24 h : $total',
  );
  String appFlags(String flags) => _pick(
    'Señales: $flags',
    'Flags: $flags',
    'Sinais: $flags',
    'Segnali: $flags',
    'Signaux : $flags',
  );

  // Pestaña "Señaladas" (apps riesgosas)
  String get flaggedTitle => _pick(
    'Apps señaladas',
    'Flagged apps',
    'Apps sinalizados',
    'App segnalate',
    'Apps signalées',
  );
  String flaggedCount(int count) => _pick(
    '$count app(s) con superficie riesgosa o instaladas fuera de la tienda',
    '$count app(s) with a risky surface or installed outside the store',
    '$count app(s) com superfície arriscada ou instalados fora da loja',
    '$count app con superficie a rischio o installate fuori dallo store',
    '$count app(s) à surface risquée ou installées hors du magasin',
  );
  String get flaggedEmpty => _pick(
    'No hay apps señaladas: ninguna app de usuario pide una superficie de permisos riesgosa ni llegó por sideload. Buena señal.',
    'No flagged apps: no user app requests a risky permission surface or arrived via sideload. Good sign.',
    'Nenhum app sinalizado: nenhum app de usuário pede uma superfície de permissões arriscada nem veio por sideload. Bom sinal.',
    'Nessuna app segnalata: nessuna app utente richiede una superficie di permessi a rischio né è arrivata via sideload. Buon segno.',
    'Aucune app signalée : aucune app utilisateur ne demande une surface de permissions risquée ni n’est arrivée par sideload. Bon signe.',
  );
  String get flaggedNote => _pick(
    'Señalada no significa maliciosa: significa que pide más de lo habitual o no vino de la tienda oficial. Revísala tú y decide.',
    'Flagged does not mean malicious: it means it asks for more than usual or did not come from the official store. Review it yourself and decide.',
    'Sinalizado não significa malicioso: significa que pede mais do que o normal ou não veio da loja oficial. Revise você mesmo e decida.',
    'Segnalata non significa dannosa: significa che chiede più del solito o non proviene dallo store ufficiale. Controllala tu e decidi.',
    'Signalée ne veut pas dire malveillante : elle demande plus que d’habitude ou ne vient pas du magasin officiel. À vous de vérifier et de décider.',
  );

  // Pestaña "Señales" (hallazgos del motor de reglas filtrables, FASE 6)
  String get sigFilterAll => _pick(
    'Todas',
    'All',
    'Todas',
    'Tutte',
    'Toutes',
  );
  String get sigFilterNetwork => _pick(
    'Red',
    'Network',
    'Rede',
    'Rete',
    'Réseau',
  );
  String get sigFilterPermissions => _pick(
    'Permisos',
    'Permissions',
    'Permissões',
    'Permessi',
    'Permissions',
  );
  String get sigFilterBattery => _pick(
    'Batería',
    'Battery',
    'Bateria',
    'Batteria',
    'Batterie',
  );
  String get sigFilterCpu => _pick(
    'CPU',
    'CPU',
    'CPU',
    'CPU',
    'CPU',
  );
  String get sigFilterRam => _pick(
    'RAM',
    'RAM',
    'RAM',
    'RAM',
    'RAM',
  );
  String get sigFilterActivity => _pick(
    'Actividad',
    'Activity',
    'Atividade',
    'Attività',
    'Activité',
  );
  String get sigFilterRisk => _pick(
    'Riesgo',
    'Risk',
    'Risco',
    'Rischio',
    'Risque',
  );
  String get sigFilterStorage => _pick(
    'Almacenamiento',
    'Storage',
    'Armazenamento',
    'Archiviazione',
    'Stockage',
  );
  String get sigOnlyActive => _pick(
    'Solo activas',
    'Active only',
    'Somente ativas',
    'Solo attive',
    'Actives uniquement',
  );
  String get sigShowAll => _pick(
    'MOSTRAR TODAS',
    'SHOW ALL',
    'MOSTRAR TODAS',
    'MOSTRA TUTTE',
    'TOUT AFFICHER',
  );
  String sigHidden(int count) => _pick(
    '+$count inactivas ocultas',
    '+$count inactive hidden',
    '+$count inativas ocultas',
    '+$count inattive nascoste',
    '+$count inactives masquées',
  );
  String get sigNoFindings => _pick(
    'Sin señales activas: el motor no encontró nada fuera de lo habitual en la última captura. Buena señal.',
    'No active signals: the engine found nothing out of the ordinary in the last snapshot. Good sign.',
    'Sem sinais ativas: o mecanismo não encontrou nada fora do comum na última captura. Bom sinal.',
    'Nessun segnale attivo: il motore non ha trovato nulla di anomalo nell’ultima acquisizione. Buon segno.',
    'Aucun signal actif : le moteur n’a rien trouvé d’anormal lors de la dernière capture. Bon signe.',
  );
  String get sigNoMatches => _pick(
    'No hay señales en esta categoría en la última captura.',
    'No signals in this category on the last snapshot.',
    'Não há sinais nesta categoria na última captura.',
    'Nessun segnale in questa categoria nell’ultima acquisizione.',
    'Aucun signal dans cette catégorie sur la dernière capture.',
  );

  // ── Gráficas (FASE 7) ──────────────────────────────────────────────────
  String get chartTitle => _pick(
    'Gráficas',
    'Charts',
    'Gráficos',
    'Grafici',
    'Graphiques',
  );
  String get chartRefresh => _pick(
    'Actualizar',
    'Refresh',
    'Atualizar',
    'Aggiorna',
    'Actualiser',
  );
  String get chartBatteryTemp => _pick(
    'Temperatura de batería',
    'Battery temperature',
    'Temperatura da bateria',
    'Temperatura della batteria',
    'Température de la batterie',
  );
  String get chartMemory => _pick(
    'Memoria disponible',
    'Available memory',
    'Memória disponível',
    'Memoria disponibile',
    'Mémoire disponible',
  );
  String get chartStorage => _pick(
    'Almacenamiento libre',
    'Free storage',
    'Armazenamento livre',
    'Archiviazione libera',
    'Stockage libre',
  );
  String get chartScore => _pick(
    'Puntaje del veredicto',
    'Verdict score',
    'Pontuação do veredicto',
    'Punteggio del verdetto',
    'Score du verdict',
  );
  String get chartNoHistory => _pick(
    'Todavía no hay historial: tomá algunas capturas y la evolución aparece acá.',
    'No history yet: take a few snapshots and the trend will appear here.',
    'Ainda não há histórico: faça algumas capturas e a evolução aparece aqui.',
    'Nessuna cronologia ancora: fai qualche acquisizione e la tendenza apparirà qui.',
    'Pas encore d’historique : effectuez quelques captures et la tendance apparaîtra ici.',
  );
  String get chartStorageNow => _pick(
    'Almacenamiento ahora',
    'Storage right now',
    'Armazenamento agora',
    'Archiviazione adesso',
    'Stockage maintenant',
  );
  String get chartStorageFree => _pick(
    'libre',
    'free',
    'livre',
    'libero',
    'libre',
  );
  String get chartStorageCache => _pick(
    'en caché (apps)',
    'in cache (apps)',
    'em cache (apps)',
    'in cache (app)',
    'en cache (apps)',
  );
  String get chartUsageTitle => _pick(
    'Consumo por app (últimas 24 h)',
    'Per-app usage (last 24 h)',
    'Consumo por app (últimas 24 h)',
    'Consumo per app (ultime 24 h)',
    'Consommation par app (24 dernières h)',
  );
  String get chartUsageEmpty => _pick(
    'Sin detalles de uso por app (necesita acceso de uso o datos de red).',
    'No per-app usage details (needs usage access or network data).',
    'Sem detalhes de uso por app (precisa de acesso de uso ou dados de rede).',
    'Nessun dettaglio d’uso per app (serve l’accesso all’uso o i dati di rete).',
    'Aucun détail d’usage par app (accès à l’utilisation ou données réseau requis).',
  );
  String get chartUsageDownload => _pick(
    'bajado',
    'downloaded',
    'baixado',
    'scaricato',
    'téléchargé',
  );
  String get chartUsageUpload => _pick(
    'subido',
    'uploaded',
    'enviado',
    'caricato',
    'envoyé',
  );
  String get chartUsageScreen => _pick(
    'en pantalla',
    'on screen',
    'na tela',
    'a schermo',
    'à l’écran',
  );
  String get chartUnitCelsius => _pick(
    '°C',
    '°C',
    '°C',
    '°C',
    '°C',
  );
  String chartLastSeconds(int seconds) => _pick(
    'últimas $seconds capturas',
    'last $seconds snapshots',
    'últimas $seconds capturas',
    'ultime $seconds acquisizioni',
    'dernières $seconds captures',
  );

  // ── Perfil (FASE 8) ────────────────────────────────────────────────────
  String get profileTitle => _pick(
    'Mi Perfil',
    'My Profile',
    'Meu Perfil',
    'Il Mio Profilo',
    'Mon Profil',
  );
  String get profileName => _pick(
    'Nombre',
    'Name',
    'Nome',
    'Nome',
    'Nom',
  );
  String get profileUsername => _pick(
    'Usuario',
    'Username',
    'Usuário',
    'Nome utente',
    'Nom d’utilisateur',
  );
  String get profileNameHint => _pick(
    'Cómo querés que te llamemos',
    'What you want to be called',
    'Como você quer ser chamado',
    'Come vuoi essere chiamato',
    'Comment vous voulez être appelé',
  );
  String get profileUsernameHint => _pick(
    'Solo letras, números, punto y guion (3-20)',
    'Only letters, numbers, dot and dash (3-20)',
    'Apenas letras, números, ponto e hífen (3-20)',
    'Solo lettere, numeri, punto e trattino (3-20)',
    'Lettres, chiffres, point et tiret uniquement (3-20)',
  );
  String get profileSave => _pick(
    'GUARDAR',
    'SAVE',
    'SALVAR',
    'SALVA',
    'ENREGISTRER',
  );
  String get profileSaveError => _pick(
    'No se pudo guardar el perfil.',
    'Could not save the profile.',
    'Não foi possível salvar o perfil.',
    'Impossibile salvare il profilo.',
    'Impossible d’enregistrer le profil.',
  );
  // ── FASE 7: cambiar contraseña desde el perfil ──
  String get pwdChangeTitle => _pick(
    'Cambiar contraseña',
    'Change password',
    'Alterar senha',
    'Cambia password',
    'Changer le mot de passe',
  );
  String get pwdChangeBody => _pick(
    'Ingresá tu contraseña actual y elegí una nueva de al menos 6 caracteres.',
    'Enter your current password and choose a new one of at least 6 characters.',
    'Informe sua senha atual e escolha uma nova de pelo menos 6 caracteres.',
    'Inserisci la password attuale e scegline una nuova di almeno 6 caratteri.',
    'Saisissez votre mot de passe actuel et choisissez-en un nouveau d’au moins 6 caractères.',
  );
  String get pwdChangeCurrent => _pick(
    'Contraseña actual',
    'Current password',
    'Senha atual',
    'Password attuale',
    'Mot de passe actuel',
  );
  String get pwdChangeCurrentError => _pick(
    'Ingresá tu contraseña actual.',
    'Enter your current password.',
    'Informe sua senha atual.',
    'Inserisci la password attuale.',
    'Saisissez votre mot de passe actuel.',
  );
  String get pwdChangeNew => _pick(
    'Nueva contraseña',
    'New password',
    'Nova senha',
    'Nuova password',
    'Nouveau mot de passe',
  );
  String get pwdChangeConfirm => _pick(
    'Confirmar nueva contraseña',
    'Confirm new password',
    'Confirmar nova senha',
    'Conferma nuova password',
    'Confirmer le nouveau mot de passe',
  );
  String get pwdChangeButton => _pick(
    'Guardar contraseña',
    'Save password',
    'Salvar senha',
    'Salva password',
    'Enregistrer le mot de passe',
  );
  String get pwdChangeWrongCurrent => _pick(
    'La contraseña actual no es correcta.',
    'The current password is not correct.',
    'A senha atual não está correta.',
    'La password attuale non è corretta.',
    'Le mot de passe actuel n’est pas correct.',
  );
  String get pwdChangeOk => _pick(
    'Contraseña actualizada.',
    'Password updated.',
    'Senha atualizada.',
    'Password aggiornata.',
    'Mot de passe mis à jour.',
  );
  String get profilePlanLabel => _pick(
    'Plan',
    'Plan',
    'Plano',
    'Piano',
    'Offre',
  );
  String get profileStatsTitle => _pick(
    'Estadísticas de esta sesión',
    'Session stats',
    'Estatísticas da sessão',
    'Statistiche della sessione',
    'Statistiques de la session',
  );
  String get profileStatsApps => _pick(
    'apps analizadas',
    'apps analyzed',
    'apps analisados',
    'app analizzate',
    'apps analysées',
  );
  String get profileStatsSignals => _pick(
    'señales activas',
    'active signals',
    'sinais ativos',
    'segnali attivi',
    'signaux actifs',
  );
  String get profileStatsLastSnapshot => _pick(
    'última captura',
    'last snapshot',
    'última captura',
    'ultima acquisizione',
    'dernière capture',
  );
  String get profilePhotoHint => _pick(
    'Agregá una foto de perfil',
    'Add a profile picture',
    'Adicione uma foto de perfil',
    'Aggiungi una foto profilo',
    'Ajoutez une photo de profil',
  );
  String get profilePhotoPick => _pick(
    'Elegir foto',
    'Choose photo',
    'Escolher foto',
    'Scegli foto',
    'Choisir une photo',
  );
  String get profilePhotoRemove => _pick(
    'Quitar foto',
    'Remove photo',
    'Remover foto',
    'Rimuovi foto',
    'Retirer la photo',
  );
  String get profileNameValidation => _pick(
    'El nombre no puede quedar vacío.',
    'Name cannot be empty.',
    'O nome não pode ficar vazio.',
    'Il nome non può essere vuoto.',
    'Le nom ne peut pas être vide.',
  );
  String get profileUsernameValidation => _pick(
    'Usuario inválido: 3-20 caracteres, solo letras, números, punto o guion.',
    'Invalid username: 3-20 chars, only letters, numbers, dot or dash.',
    'Usuário inválido: 3-20 caracteres, apenas letras, números, ponto ou hífen.',
    'Nome utente non valido: 3-20 caratteri, solo lettere, numeri, punto o trattino.',
    'Nom d’utilisateur invalide : 3-20 caractères, lettres, chiffres, point ou tiret.',
  );
  String get profilePhotoKeep => _pick(
    'Foto elegida esta sesión (queda guardada en memoria).',
    'Photo chosen this session (kept in memory).',
    'Foto escolhida nesta sessão (mantida em memória).',
    'Foto scelta in questa sessione (mantenuta in memoria).',
    'Photo choisie cette session (conservée en mémoire).',
  );
  String get profileBackHome => _pick(
    'VOLVER AL INICIO',
    'BACK TO HOME',
    'VOLTAR AO INÍCIO',
    'TORNA ALLA HOME',
    'RETOUR À L’ACCUEIL',
  );

  // ── Premium (FASE 10) ──────────────────────────────────────────────────
  String get premiumFeaturesTitle => _pick(
    'Incluye',
    'Includes',
    'Inclui',
    'Include',
    'Comprend',
  );
  String get premiumFeature1 => _pick(
    'Historial y tendencias en profundidad',
    'Deep history and trends',
    'Histórico e tendências em profundidade',
    'Cronologia e tendenze in profondità',
    'Historique et tendances en profondeur',
  );
  String get premiumFeature2 => _pick(
    'Análisis IA prioritario con contexto completo',
    'Priority AI analysis with full context',
    'Análise de IA prioritária com contexto completo',
    'Analisi IA prioritaria con contesto completo',
    'Analyse IA prioritaire avec contexte complet',
  );
  String get premiumFeature3 => _pick(
    'Comparativas entre capturas y reportes avanzados',
    'Snapshot comparisons and advanced reports',
    'Comparativos entre capturas e relatórios avançados',
    'Confronti tra acquisizioni e report avanzati',
    'Comparaisons entre captures et rapports avancés',
  );
  String get premiumFeature4 => _pick(
    'Alerta temprana de instalaciones extrañas',
    'Early warning on strange installs',
    'Alerta precoce de instalações estranhas',
    'Avviso precoce di installazioni strane',
    'Alerte précoce des installations étranges',
  );
  String get premiumAlready => _pick(
    'Ya tenés NEXORA PROFESSIONAL activo.',
    'You already have NEXORA PROFESSIONAL active.',
    'Você já tem o NEXORA PROFESSIONAL ativo.',
    'Hai già NEXORA PROFESSIONAL attivo.',
    'Vous avez déjà NEXORA PROFESSIONNEL actif.',
  );
  String get premiumComingSoon => _pick(
    'Próximamente',
    'Coming soon',
    'Em breve',
    'Prossimamente',
    'Bientôt',
  );
  String premiumRestoredOk(String provider) => _pick(
    'Compra restaurada por $provider.',
    'Purchase restored via $provider.',
    'Compra restaurada por $provider.',
    'Acquisto ripristinato tramite $provider.',
    'Achat restauré via $provider.',
  );
  String get premiumNotPurchased => _pick(
    'No se encontró ninguna compra previa de Premium.',
    'No previous Premium purchase found.',
    'Nenhuma compra anterior do Premium encontrada.',
    'Nessun acquisto Premium precedente trovato.',
    'Aucun achat Premium antérieur trouvé.',
  );

  // ── Alertas y Protección (FASE 11) ────────────────────────────────────
  String get alertsFilterAll => _pick(
    'Todas',
    'All',
    'Todas',
    'Tutte',
    'Toutes',
  );
  String get alertsFilterCritical => _pick(
    'Críticas',
    'Critical',
    'Críticas',
    'Critiche',
    'Critiques',
  );
  String get alertsFilterWarning => _pick(
    'Advertencias',
    'Warnings',
    'Advertências',
    'Avvisi',
    'Avertissements',
  );
  String get alertsEmptyActive => _pick(
    'Sin alertas activas. Todo tranquilo.',
    'No active alerts. All quiet.',
    'Sem alertas ativas. Tudo tranquilo.',
    'Nessun avviso attivo. Tutto tranquillo.',
    'Aucune alerte active. Tout est calme.',
  );
  String get alertsEmptyFilter => _pick(
    'No hay alertas en esta categoría.',
    'No alerts in this category.',
    'Não há alertas nesta categoria.',
    'Nessun avviso in questa categoria.',
    'Aucune alerte dans cette catégorie.',
  );
  String get protectionTitle => _pick(
    'Protección Web',
    'Web Protection',
    'Proteção Web',
    'Protezione Web',
    'Protection Web',
  );
  String get protectionNoData => _pick(
    'Sin datos todavía',
    'No data yet',
    'Sem dados ainda',
    'Ancora nessun dato',
    'Pas encore de données',
  );
  String protectionConnected(String transport) => _pick(
    'Conectado · $transport',
    'Connected · $transport',
    'Conectado · $transport',
    'Connesso · $transport',
    'Connecté · $transport',
  );
  String get protectionDisconnected => _pick(
    'Sin conexión',
    'Disconnected',
    'Sem conexão',
    'Disconnesso',
    'Déconnecté',
  );
  String get protectionVpnActive => _pick(
    'VPN detectada en el sistema',
    'VPN detected on the system',
    'VPN detectada no sistema',
    'VPN rilevata nel sistema',
    'VPN détectée sur le système',
  );
  String get protectionVpnNone => _pick(
    'Sin VPN activa en el sistema',
    'No VPN active on the system',
    'Sem VPN ativa no sistema',
    'Nessuna VPN attiva nel sistema',
    'Aucune VPN active sur le système',
  );
  String get protectionDown => _pick(
    'Bajada',
    'Download',
    'Download',
    'Download',
    'Téléchargement',
  );
  String get protectionUp => _pick(
    'Subida',
    'Upload',
    'Upload',
    'Upload',
    'Envoi',
  );
  String get protectionMetered => _pick(
    'Medida',
    'Metered',
    'Medido',
    'Tariffata',
    'Compté',
  );
  String get protectionFindingsTitle => _pick(
    'Hallazgos de red',
    'Network findings',
    'Achados de rede',
    'Riscontri di rete',
    'Constatations réseau',
  );
  String get protectionFindingsNone => _pick(
    'No hay hallazgos de red en el último análisis.',
    'No network findings on the latest analysis.',
    'Não há achados de rede na última análise.',
    'Nessun riscontro di rete nell’ultima analisi.',
    'Aucune constatation réseau sur la dernière analyse.',
  );

  // Dispositivo
  String get deviceTitle =>
      _pick('Dispositivo', 'Device', 'Dispositivo', 'Dispositivo', 'Appareil');
  String get deviceManufacturer => _pick(
    'Fabricante',
    'Manufacturer',
    'Fabricante',
    'Produttore',
    'Fabricant',
  );
  String get deviceModel =>
      _pick('Modelo', 'Model', 'Modelo', 'Modello', 'Modèle');
  String get deviceOs => _pick(
    'Sistema operativo',
    'Operating system',
    'Sistema operacional',
    'Sistema operativo',
    'Système d’exploitation',
  );
  String get deviceSkin => _pick(
    'Capa del fabricante',
    'Vendor skin',
    'Camada do fabricante',
    'Interfaccia del produttore',
    'Surcouche du fabricant',
  );
  String get devicePatch => _pick(
    'Parche de seguridad',
    'Security patch',
    'Patch de segurança',
    'Patch di sicurezza',
    'Correctif de sécurité',
  );
  String get deviceCores => _pick(
    'Núcleos de CPU',
    'CPU cores',
    'Núcleos de CPU',
    'Core della CPU',
    'Cœurs du CPU',
  );
  String get deviceUptime => _pick(
    'Tiempo encendido',
    'Uptime',
    'Tempo ligado',
    'Tempo di accensione',
    'Temps allumé',
  );
  String get rootTitle => _pick(
    'Indicadores de root/jailbreak',
    'Root/jailbreak indicators',
    'Indicadores de root/jailbreak',
    'Indicatori di root/jailbreak',
    'Indicateurs de root/jailbreak',
  );
  String get rootNone => _pick(
    'Sin indicadores conocidos.',
    'No known indicators.',
    'Sem indicadores conhecidos.',
    'Nessun indicatore noto.',
    'Aucun indicateur connu.',
  );
  String get rootNote => _pick(
    'Un indicador es un indicio, no una prueba. Un equipo rooteado a propósito genera el mismo indicio.',
    'An indicator is a signal, not proof. A deliberately rooted device produces the same signal.',
    'Um indicador é um indício, não uma prova. Um aparelho rooteado de propósito gera o mesmo indício.',
    'Un indicatore è un indizio, non una prova. Un dispositivo rootato di proposito produce lo stesso indizio.',
    'Un indicateur est un indice, pas une preuve. Un appareil rooté volontairement produit le même indice.',
  );

  // Historial
  String historyTitle(int count) => _pick(
    'Últimas $count capturas',
    'Last $count snapshots',
    'Últimas $count capturas',
    'Ultime $count acquisizioni',
    '$count dernières captures',
  );
  String get historyEmpty => _pick(
    'Aún no hay historial. Cada actualización guarda una captura local.',
    'No history yet. Every refresh stores a local snapshot.',
    'Ainda não há histórico. Cada atualização salva uma captura local.',
    'Ancora nessuna cronologia. Ogni aggiornamento salva un’acquisizione locale.',
    'Pas encore d’historique. Chaque actualisation enregistre une capture locale.',
  );
  String historyRow(int mem, int storage, int risky) => _pick(
    'RAM disp. $mem % · Disco libre $storage % · Apps riesgosas $risky',
    'RAM avail. $mem % · Free disk $storage % · Risky apps $risky',
    'RAM disp. $mem % · Disco livre $storage % · Apps arriscados $risky',
    'RAM disp. $mem % · Disco libero $storage % · App a rischio $risky',
    'RAM dispo. $mem % · Disque libre $storage % · Apps risquées $risky',
  );

  // Acerca
  String get aboutVersion =>
      _pick('Versión', 'Version', 'Versão', 'Versione', 'Version');
  String get aboutAuthor =>
      _pick('Autor', 'Author', 'Autor', 'Autore', 'Auteur');
  String get aboutLicense =>
      _pick('Licencia', 'License', 'Licença', 'Licenza', 'Licence');
  String get aboutPhilosophyTitle =>
      _pick('Filosofía', 'Philosophy', 'Filosofia', 'Filosofia', 'Philosophie');
  String get aboutPhilosophyBody => _pick(
    'Cualquier distorsión anómala de los recursos del dispositivo puede ser el primer indicio de que algo está ocurriendo. Nexora vigila esas distorsiones, las correlaciona y explica la causa con evidencia. Diagnóstico primero, intervención después.',
    'Any anomalous distortion of device resources can be the first sign that something is happening. Nexora watches those distortions, correlates them and explains the cause with evidence. Diagnosis first, intervention second.',
    'Qualquer distorção anômala dos recursos do dispositivo pode ser o primeiro indício de que algo está acontecendo. O Nexora vigia essas distorções, correlaciona-as e explica a causa com evidência. Diagnóstico primeiro, intervenção depois.',
    'Qualsiasi distorsione anomala delle risorse del dispositivo può essere il primo indizio che qualcosa sta accadendo. Nexora sorveglia queste distorsioni, le correla e spiega la causa con prove. Prima la diagnosi, poi l’intervento.',
    'Toute distorsion anormale des ressources de l’appareil peut être le premier signe que quelque chose se passe. Nexora surveille ces distorsions, les corrèle et explique la cause avec des preuves. Le diagnostic d’abord, l’intervention ensuite.',
  );
  String get aboutPrivacyTitle => _pick(
    'Privacidad local',
    'Local privacy',
    'Privacidade local',
    'Privacy locale',
    'Confidentialité locale',
  );
  String get aboutPrivacyBody => _pick(
    'Esta app no usa internet: no declara el permiso INTERNET en release. El historial vive en el sandbox de la app y la evidencia solo sale del dispositivo si tú la exportas.',
    'This app does not use the internet: it does not declare the INTERNET permission in release. History lives in the app sandbox and evidence only leaves the device if you export it.',
    'Este app não usa a internet: não declara a permissão INTERNET em release. O histórico vive no sandbox do app e a evidência só sai do dispositivo se você a exportar.',
    'Questa app non usa internet: non dichiara il permesso INTERNET in release. La cronologia vive nella sandbox dell’app e la prova esce dal dispositivo solo se la esporti tu.',
    'Cette app n’utilise pas internet : elle ne déclare pas la permission INTERNET en release. L’historique réside dans le sandbox de l’app et la preuve ne quitte l’appareil que si vous l’exportez.',
  );
  String snapshotTaken(String when) => _pick(
    'Captura tomada: $when',
    'Snapshot taken: $when',
    'Captura feita: $when',
    'Acquisizione effettuata: $when',
    'Capture prise : $when',
  );

  // Acciones de intervención (abren la pantalla del sistema)
  String get actionFreeSpace => _pick(
    'Liberar espacio',
    'Free up space',
    'Liberar espaço',
    'Libera spazio',
    'Libérer de l’espace',
  );
  String get actionBatteryUsage => _pick(
    'Ver batería',
    'View battery',
    'Ver bateria',
    'Vedi batteria',
    'Voir la batterie',
  );
  String get actionAppDetails => _pick(
    'Ver en el sistema',
    'View in system',
    'Ver no sistema',
    'Apri nel sistema',
    'Voir dans le système',
  );
  String get actionSystemUpdate => _pick(
    'Buscar actualizaciones',
    'Check for updates',
    'Buscar atualizações',
    'Cerca aggiornamenti',
    'Rechercher des mises à jour',
  );
  String get actionUnavailable => _pick(
    'Esa pantalla del sistema no está disponible en este equipo.',
    'That system screen is not available on this device.',
    'Essa tela do sistema não está disponível neste aparelho.',
    'Quella schermata di sistema non è disponibile su questo dispositivo.',
    'Cet écran système n’est pas disponible sur cet appareil.',
  );

  // Configuración
  String get settingsCaptureTitle =>
      _pick('Captura', 'Capture', 'Captura', 'Acquisizione', 'Capture');
  String get settingsInterval => _pick(
    'Auto-captura con la app abierta',
    'Auto-capture while the app is open',
    'Autocaptura com o app aberto',
    'Acquisizione automatica con l’app aperta',
    'Capture auto quand l’app est ouverte',
  );
  String get settingsIntervalOff =>
      _pick('Apagada', 'Off', 'Desligada', 'Spenta', 'Désactivée');
  String settingsIntervalMinutes(int m) => _pick(
    'Cada $m min',
    'Every $m min',
    'A cada $m min',
    'Ogni $m min',
    'Toutes les $m min',
  );
  String get settingsBackground => _pick(
    'Captura en segundo plano (mín. 15 min, lo impone Android)',
    'Background capture (min. 15 min, enforced by Android)',
    'Captura em segundo plano (mín. 15 min, imposto pelo Android)',
    'Acquisizione in background (min. 15 min, imposto da Android)',
    'Capture en arrière-plan (min. 15 min, imposé par Android)',
  );
  String get settingsChargingOnly => _pick(
    'Solo cuando está cargando',
    'Only while charging',
    'Somente ao carregar',
    'Solo durante la carica',
    'Uniquement en charge',
  );
  String get settingsNotifyCritical => _pick(
    'Notificar si una captura en segundo plano pasa a Crítico',
    'Notify if a background capture turns Critical',
    'Notificar se uma captura em segundo plano ficar Crítica',
    'Notifica se un’acquisizione in background diventa Critica',
    'Notifier si une capture en arrière-plan devient Critique',
  );
  String get settingsBackgroundUnsupported => _pick(
    'No disponible en este SO.',
    'Not available on this OS.',
    'Indisponível neste SO.',
    'Non disponibile su questo SO.',
    'Indisponible sur cet OS.',
  );
  String get settingsThresholdsTitle => _pick(
    'Umbrales de detección',
    'Detection thresholds',
    'Limiares de detecção',
    'Soglie di rilevamento',
    'Seuils de détection',
  );
  String get settingsThresholdsNote => _pick(
    'Los cambios aplican al instante y quedan guardados. El export JSON registra siempre la evidencia cruda, no el umbral.',
    'Changes apply instantly and are saved. The JSON export always records raw evidence, not the threshold.',
    'As mudanças aplicam-se na hora e ficam salvas. O export JSON registra sempre a evidência crua, não o limiar.',
    'Le modifiche si applicano subito e restano salvate. L’export JSON registra sempre la prova grezza, non la soglia.',
    'Les changements s’appliquent aussitôt et sont enregistrés. L’export JSON consigne toujours la preuve brute, pas le seuil.',
  );
  String get thresholdMemWarning => _pick(
    'Memoria: advertencia si disponible <',
    'Memory: warning if available <',
    'Memória: aviso se disponível <',
    'Memoria: avviso se disponibile <',
    'Mémoire : avertissement si disponible <',
  );
  String get thresholdMemCritical => _pick(
    'Memoria: crítico si disponible <',
    'Memory: critical if available <',
    'Memória: crítico se disponível <',
    'Memoria: critico se disponibile <',
    'Mémoire : critique si disponible <',
  );
  String get thresholdStorageWarning => _pick(
    'Disco: advertencia si libre <',
    'Storage: warning if free <',
    'Disco: aviso se livre <',
    'Disco: avviso se libero <',
    'Disque : avertissement si libre <',
  );
  String get thresholdStorageCritical => _pick(
    'Disco: crítico si libre <',
    'Storage: critical if free <',
    'Disco: crítico se livre <',
    'Disco: critico se libero <',
    'Disque : critique si libre <',
  );
  String get thresholdBatteryWarning => _pick(
    'Batería: advertencia si temperatura ≥',
    'Battery: warning if temperature ≥',
    'Bateria: aviso se temperatura ≥',
    'Batteria: avviso se temperatura ≥',
    'Batterie : avertissement si température ≥',
  );
  String get thresholdBatteryCritical => _pick(
    'Batería: crítico si temperatura ≥',
    'Battery: critical if temperature ≥',
    'Bateria: crítico se temperatura ≥',
    'Batteria: critico se temperatura ≥',
    'Batterie : critique si température ≥',
  );
  String get settingsRestoreDefaults => _pick(
    'Restaurar valores por defecto',
    'Restore defaults',
    'Restaurar padrões',
    'Ripristina valori predefiniti',
    'Restaurer les valeurs par défaut',
  );
  String get settingsLanguageTitle =>
      _pick('Idioma', 'Language', 'Idioma', 'Lingua', 'Langue');
  String get settingsLanguageAuto => _pick(
    'Automático (sistema)',
    'Automatic (system)',
    'Automático (sistema)',
    'Automatico (sistema)',
    'Automatique (système)',
  );
  String get settingsViewModeTitle => _pick(
    'Modo de visualización',
    'Display mode',
    'Modo de exibição',
    'Modalità di visualizzazione',
    'Mode d’affichage',
  );
  String get viewModeSimple =>
      _pick('Simple', 'Simple', 'Simples', 'Semplice', 'Simple');
  String get viewModeNormal =>
      _pick('Normal', 'Normal', 'Normal', 'Normale', 'Normal');
  String get viewModeAdvanced =>
      _pick('Avanzado', 'Advanced', 'Avançado', 'Avanzato', 'Avancé');
  String get settingsViewModeNote => _pick(
    'Simple muestra solo lo esencial (Resumen, Señaladas y Configuración), ideal para quien no es técnico. Normal añade red, almacenamiento, dispositivo e historial. Avanzado muestra todo, incluida Cercanía Bluetooth.',
    'Simple shows only the essentials (Summary, Flagged and Settings), ideal for non-technical people. Normal adds network, storage, device and history. Advanced shows everything, including Bluetooth Nearby.',
    'Simples mostra só o essencial (Resumo, Sinalizadas e Configurações), ideal para quem não é técnico. Normal adiciona rede, armazenamento, dispositivo e histórico. Avançado mostra tudo, incluindo Proximidade Bluetooth.',
    'Semplice mostra solo l’essenziale (Riepilogo, Segnalate e Impostazioni), ideale per chi non è tecnico. Normale aggiunge rete, archiviazione, dispositivo e cronologia. Avanzato mostra tutto, incluse le Vicinanze Bluetooth.',
    'Simple n’affiche que l’essentiel (Résumé, Signalées et Réglages), idéal pour les non-techniciens. Normal ajoute réseau, stockage, appareil et historique. Avancé affiche tout, y compris la proximité Bluetooth.',
  );
  String get settingsNearbyHistory => _pick(
    'Histórico de Cercanía entre sesiones (detecta rastreadores multi-día)',
    'Cross-session Nearby history (detects multi-day trackers)',
    'Histórico de Proximidade entre sessões (detecta rastreadores multi-dias)',
    'Cronologia Vicinanze tra sessioni (rileva tracker multi-giorno)',
    'Historique de proximité entre sessions (détecte les traceurs multi-jours)',
  );

  // Evidencia (backup / restaurar / borrar / informe)
  String get evidenceTitle =>
      _pick('Evidencia', 'Evidence', 'Evidência', 'Prove', 'Preuves');
  String get evidenceNote => _pick(
    'Tu evidencia es tuya: respáldala para que sobreviva a desinstalar o cambiar de teléfono, o bórrala cuando quieras. Nada sale del dispositivo salvo que tú lo compartas.',
    'Your evidence is yours: back it up so it survives uninstalling or switching phones, or wipe it whenever you want. Nothing leaves the device unless you share it.',
    'Sua evidência é sua: faça backup para que sobreviva à desinstalação ou à troca de telefone, ou apague quando quiser. Nada sai do dispositivo a menos que você compartilhe.',
    'Le tue prove sono tue: fai il backup così sopravvivono alla disinstallazione o al cambio di telefono, oppure cancellale quando vuoi. Nulla esce dal dispositivo se non lo condividi tu.',
    'Vos preuves sont à vous : sauvegardez-les pour qu’elles survivent à une désinstallation ou à un changement de téléphone, ou effacez-les quand vous voulez. Rien ne quitte l’appareil sauf si vous le partagez.',
  );
  String get evidenceBackup => _pick(
    'Exportar backup',
    'Export backup',
    'Exportar backup',
    'Esporta backup',
    'Exporter la sauvegarde',
  );
  String get evidenceRestore => _pick(
    'Restaurar backup',
    'Restore backup',
    'Restaurar backup',
    'Ripristina backup',
    'Restaurer la sauvegarde',
  );
  String get evidenceWipe => _pick(
    'Borrar evidencia',
    'Wipe evidence',
    'Apagar evidência',
    'Cancella prove',
    'Effacer les preuves',
  );
  String get evidenceReport => _pick(
    'Generar informe forense',
    'Generate forensic report',
    'Gerar relatório forense',
    'Genera rapporto forense',
    'Générer le rapport forensique',
  );
  String backupDone(String path) => _pick(
    'Backup guardado en $path',
    'Backup saved to $path',
    'Backup salvo em $path',
    'Backup salvato in $path',
    'Sauvegarde enregistrée dans $path',
  );
  String get restoreOk => _pick(
    'Backup restaurado. Actualizando…',
    'Backup restored. Refreshing…',
    'Backup restaurado. Atualizando…',
    'Backup ripristinato. Aggiornamento…',
    'Sauvegarde restaurée. Actualisation…',
  );
  String get restoreFail => _pick(
    'El archivo no es un backup válido de Nexora.',
    'The file is not a valid Nexora backup.',
    'O arquivo não é um backup válido do Nexora.',
    'Il file non è un backup valido di Nexora.',
    'Le fichier n’est pas une sauvegarde Nexora valide.',
  );
  String get wipeConfirmTitle => _pick(
    '¿Borrar toda la evidencia?',
    'Wipe all evidence?',
    'Apagar toda a evidência?',
    'Cancellare tutte le prove?',
    'Effacer toutes les preuves ?',
  );
  String get wipeConfirmBody => _pick(
    'Se eliminarán historial, baseline, cercanía y exports de este dispositivo. La configuración se conserva. No se puede deshacer.',
    'History, baseline, nearby and exports will be deleted from this device. Settings are kept. This cannot be undone.',
    'Serão excluídos histórico, baseline, proximidade e exports deste dispositivo. As configurações são mantidas. Não pode ser desfeito.',
    'Verranno eliminati cronologia, baseline, vicinanze ed export da questo dispositivo. Le impostazioni vengono mantenute. Non è reversibile.',
    'L’historique, la baseline, la proximité et les exports seront supprimés de cet appareil. Les réglages sont conservés. Irréversible.',
  );
  String get wipeDone => _pick(
    'Evidencia borrada.',
    'Evidence wiped.',
    'Evidência apagada.',
    'Prove cancellate.',
    'Preuves effacées.',
  );
  String get cancel =>
      _pick('Cancelar', 'Cancel', 'Cancelar', 'Annulla', 'Annuler');
  String get confirm =>
      _pick('Borrar', 'Wipe', 'Apagar', 'Cancella', 'Effacer');
  String get reportShareTitle => _pick(
    'Informe forense Nexora',
    'Nexora forensic report',
    'Relatório forense Nexora',
    'Rapporto forense Nexora',
    'Rapport forensique Nexora',
  );
  String get shareFailed => _pick(
    'No se pudo compartir en este equipo.',
    'Could not share on this device.',
    'Não foi possível compartilhar neste aparelho.',
    'Impossibile condividere su questo dispositivo.',
    'Impossible de partager sur cet appareil.',
  );

  // Diagnóstico (registro de errores)
  String get diagTitle => _pick(
    'Diagnóstico',
    'Diagnostics',
    'Diagnóstico',
    'Diagnostica',
    'Diagnostic',
  );
  String get diagNone => _pick(
    'Sin errores registrados.',
    'No errors recorded.',
    'Nenhum erro registrado.',
    'Nessun errore registrato.',
    'Aucune erreur enregistrée.',
  );
  String get diagShare => _pick(
    'Compartir registro',
    'Share log',
    'Compartilhar registro',
    'Condividi registro',
    'Partager le journal',
  );
  String get diagClear => _pick(
    'Borrar registro',
    'Clear log',
    'Apagar registro',
    'Cancella registro',
    'Effacer le journal',
  );
  String get diagNote => _pick(
    'Si la app falla, el error queda aquí (local, nunca se envía). Compártelo para reportar el problema.',
    'If the app fails, the error stays here (local, never sent). Share it to report the problem.',
    'Se o app falhar, o erro fica aqui (local, nunca enviado). Compartilhe para relatar o problema.',
    'Se l’app va in errore, l’errore resta qui (locale, mai inviato). Condividilo per segnalare il problema.',
    'Si l’app échoue, l’erreur reste ici (locale, jamais envoyée). Partagez-la pour signaler le problème.',
  );

  // Onboarding
  String get onboardTitle1 => _pick(
    'Diagnóstico primero',
    'Diagnosis first',
    'Diagnóstico primeiro',
    'Prima la diagnosi',
    'Le diagnostic d’abord',
  );
  String get onboardBody1 => _pick(
    'Nexora vigila memoria, almacenamiento, batería, red y apps de tu teléfono, y explica con evidencia si algo se comporta distinto.',
    'Nexora watches your phone\'s memory, storage, battery, network and apps, and explains with evidence when something behaves differently.',
    'O Nexora vigia memória, armazenamento, bateria, rede e apps do seu telefone, e explica com evidência se algo se comporta diferente.',
    'Nexora sorveglia memoria, archiviazione, batteria, rete e app del tuo telefono e spiega con prove se qualcosa si comporta in modo diverso.',
    'Nexora surveille la mémoire, le stockage, la batterie, le réseau et les apps de votre téléphone, et explique avec des preuves si quelque chose se comporte différemment.',
  );
  String get onboardTitle2 => _pick(
    'Lo que NO hace',
    'What it does NOT do',
    'O que NÃO faz',
    'Cosa NON fa',
    'Ce qu’il NE fait PAS',
  );
  String get onboardBody2 => _pick(
    'No es antivirus ni "limpiador": no elimina malware ni mata apps (Android no lo permite). Te muestra indicios y te lleva a la pantalla del sistema donde tú decides.',
    'It is not an antivirus or "cleaner": it does not remove malware or kill apps (Android forbids it). It shows you signals and takes you to the system screen where you decide.',
    'Não é antivírus nem "limpador": não remove malware nem mata apps (o Android não permite). Mostra indícios e leva você à tela do sistema onde você decide.',
    'Non è un antivirus né un "pulitore": non rimuove malware né chiude app (Android lo vieta). Ti mostra indizi e ti porta alla schermata di sistema dove decidi tu.',
    'Ce n’est pas un antivirus ni un « nettoyeur » : il ne supprime pas les malwares et ne ferme pas les apps (Android l’interdit). Il vous montre des indices et vous mène à l’écran système où vous décidez.',
  );
  String get onboardTitle3 => _pick(
    'Todo local',
    'All local',
    'Tudo local',
    'Tutto locale',
    'Tout en local',
  );
  String get onboardBody3 => _pick(
    'Sin internet, sin cuentas, sin telemetría: la app ni siquiera declara el permiso de red. Tu evidencia solo sale si tú la compartes.',
    'No internet, no accounts, no telemetry: the app does not even declare the network permission. Your evidence only leaves if you share it.',
    'Sem internet, sem contas, sem telemetria: o app nem declara a permissão de rede. Sua evidência só sai se você compartilhar.',
    'Niente internet, niente account, niente telemetria: l’app non dichiara nemmeno il permesso di rete. La tua prova esce solo se la condividi tu.',
    'Pas d’internet, pas de comptes, pas de télémétrie : l’app ne déclare même pas la permission réseau. Vos preuves ne sortent que si vous les partagez.',
  );
  String get onboardNext =>
      _pick('Siguiente', 'Next', 'Próximo', 'Avanti', 'Suivant');
  String get onboardStart =>
      _pick('Empezar', 'Get started', 'Começar', 'Inizia', 'Commencer');

  // Elección de interfaz en el arranque (v0.8.0). La opción básica viene
  // marcada: quien no sepa qué elegir se queda con la que menos abruma.
  String get onboardTitleMode => _pick(
    '¿Cómo quieres verla?',
    'How do you want to see it?',
    'Como você quer vê-lo?',
    'Come vuoi vederla?',
    'Comment voulez-vous la voir ?',
  );
  String get onboardBodyMode => _pick(
    'Elige cuánta información quieres en pantalla. Puedes cambiarlo cuando quieras en Configuración.',
    'Choose how much information you want on screen. You can change it any time in Settings.',
    'Escolha quanta informação quer na tela. Você pode mudar quando quiser em Configurações.',
    'Scegli quante informazioni vuoi sullo schermo. Puoi cambiarlo quando vuoi in Impostazioni.',
    'Choisissez la quantité d’informations à l’écran. Vous pouvez la changer à tout moment dans Réglages.',
  );
  String get onboardModeRecommended => _pick(
    'Recomendada',
    'Recommended',
    'Recomendada',
    'Consigliata',
    'Recommandée',
  );
  String get viewModeSimpleHint => _pick(
    'Lo esencial: el semáforo, las apps señaladas y poco más.',
    'The essentials: the traffic light, flagged apps and little else.',
    'O essencial: o semáforo, os apps sinalizados e pouco mais.',
    'L’essenziale: il semaforo, le app segnalate e poco altro.',
    'L’essentiel : le feu tricolore, les apps signalées et peu d’autre.',
  );
  String get viewModeNormalHint => _pick(
    'Añade red, almacenamiento, dispositivo e historial.',
    'Adds network, storage, device and history.',
    'Adiciona rede, armazenamento, dispositivo e histórico.',
    'Aggiunge rete, archiviazione, dispositivo e cronologia.',
    'Ajoute réseau, stockage, appareil et historique.',
  );
  String get viewModeAdvancedHint => _pick(
    'Todo, incluida la Cercanía Bluetooth.',
    'Everything, including Bluetooth Nearby.',
    'Tudo, incluindo Proximidade Bluetooth.',
    'Tutto, incluse le Vicinanze Bluetooth.',
    'Tout, y compris la proximité Bluetooth.',
  );

  // Cercanía (BLE)
  String get nearbyTitle => _pick(
    'Cercanía Bluetooth',
    'Bluetooth nearby',
    'Proximidade Bluetooth',
    'Vicinanze Bluetooth',
    'Bluetooth à proximité',
  );
  String get nearbyIntro => _pick(
    'Escaneo manual de dispositivos Bluetooth LE cercanos. 100 % local y bajo demanda: nada se guarda ni se exporta, y la app sigue sin usar internet.',
    'Manual scan of nearby Bluetooth LE devices. 100% local and on demand: nothing is stored or exported, and the app still uses no internet.',
    'Varredura manual de dispositivos Bluetooth LE próximos. 100 % local e sob demanda: nada é salvo nem exportado, e o app continua sem usar internet.',
    'Scansione manuale dei dispositivi Bluetooth LE vicini. 100 % locale e su richiesta: nulla viene salvato o esportato e l’app continua a non usare internet.',
    'Balayage manuel des appareils Bluetooth LE proches. 100 % local et à la demande : rien n’est stocké ni exporté, et l’app n’utilise toujours pas internet.',
  );
  String nearbyScan(int seconds) => _pick(
    'Escanear ($seconds s)',
    'Scan ($seconds s)',
    'Escanear ($seconds s)',
    'Scansiona ($seconds s)',
    'Balayer ($seconds s)',
  );
  String get nearbyScanning => _pick(
    'Escaneando…',
    'Scanning…',
    'Escaneando…',
    'Scansione…',
    'Balayage…',
  );
  String get nearbyPermissionDenied => _pick(
    'Sin permiso de Bluetooth no hay escaneo. Concédelo e inténtalo de nuevo.',
    'Without the Bluetooth permission there is no scan. Grant it and try again.',
    'Sem permissão de Bluetooth não há varredura. Conceda e tente novamente.',
    'Senza il permesso Bluetooth non c’è scansione. Concedilo e riprova.',
    'Sans la permission Bluetooth, pas de balayage. Accordez-la et réessayez.',
  );
  String get nearbyUnsupported => _pick(
    'El escaneo BLE no está disponible en este equipo (sin Bluetooth o SO sin soporte).',
    'BLE scanning is not available on this device (no Bluetooth or unsupported OS).',
    'A varredura BLE não está disponível neste aparelho (sem Bluetooth ou SO sem suporte).',
    'La scansione BLE non è disponibile su questo dispositivo (senza Bluetooth o SO non supportato).',
    'Le balayage BLE n’est pas disponible sur cet appareil (pas de Bluetooth ou OS non pris en charge).',
  );
  String nearbySummary(int devices, int scans) => _pick(
    '$devices dispositivo(s) vistos en $scans escaneo(s) de esta sesión',
    '$devices device(s) seen across $scans scan(s) this session',
    '$devices dispositivo(s) vistos em $scans varredura(s) desta sessão',
    '$devices dispositivo/i visti in $scans scansione/i di questa sessione',
    '$devices appareil(s) vus sur $scans balayage(s) de cette session',
  );
  String get nearbyPersistent => _pick(
    'PERSISTENTE',
    'PERSISTENT',
    'PERSISTENTE',
    'PERSISTENTE',
    'PERSISTANT',
  );
  String nearbyPersistentNote(int count) => _pick(
    '$count dispositivo(s) reaparecen a lo largo de la sesión. Un rastreador ajeno se comporta así — pero unos audífonos tuyos también: indicio, no prueba.',
    '$count device(s) keep reappearing across the session. A foreign tracker behaves like this — but so do your own earbuds: a signal, not proof.',
    '$count dispositivo(s) reaparecem ao longo da sessão. Um rastreador alheio se comporta assim — mas seus fones também: indício, não prova.',
    '$count dispositivo/i riappaiono nel corso della sessione. Un tracker estraneo si comporta così — ma anche i tuoi auricolari: indizio, non prova.',
    '$count appareil(s) réapparaissent au fil de la session. Un traceur étranger se comporte ainsi — mais vos écouteurs aussi : indice, pas preuve.',
  );
  String get nearbyHonestyNote => _pick(
    'Las direcciones BLE modernas rotan (MAC aleatorizada): un mismo aparato puede aparecer como varios. Los escaneos son solo de esta sesión.',
    'Modern BLE addresses rotate (randomized MAC): one device may appear as several. Scans belong to this session only.',
    'Os endereços BLE modernos rotacionam (MAC aleatório): um mesmo aparelho pode aparecer como vários. As varreduras são só desta sessão.',
    'Gli indirizzi BLE moderni ruotano (MAC casuale): uno stesso dispositivo può apparire come più. Le scansioni valgono solo per questa sessione.',
    'Les adresses BLE modernes tournent (MAC aléatoire) : un même appareil peut apparaître comme plusieurs. Les balayages ne valent que pour cette session.',
  );
  String nearbySeen(int scans) => _pick(
    'visto en $scans escaneo(s)',
    'seen in $scans scan(s)',
    'visto em $scans varredura(s)',
    'visto in $scans scansione/i',
    'vu sur $scans balayage(s)',
  );

  // Alerta local de veredicto crítico
  String get alertCriticalTitle => _pick(
    'Nexora: veredicto CRÍTICO',
    'Nexora: CRITICAL verdict',
    'Nexora: veredito CRÍTICO',
    'Nexora: verdetto CRITICO',
    'Nexora : verdict CRITIQUE',
  );
  String get alertCriticalBody => _pick(
    'La última captura en segundo plano detectó una distorsión seria. Abre la app para ver la evidencia.',
    'The latest background snapshot detected a serious distortion. Open the app to see the evidence.',
    'A última captura em segundo plano detectou uma distorção séria. Abra o app para ver a evidência.',
    'L’ultima acquisizione in background ha rilevato una distorsione grave. Apri l’app per vedere la prova.',
    'La dernière capture en arrière-plan a détecté une distorsion grave. Ouvrez l’app pour voir la preuve.',
  );
  String get alertNewAppTitle => _pick(
    'Nexora: app nueva con superficie riesgosa',
    'Nexora: new app with risky surface',
    'Nexora: novo app com superfície arriscada',
    'Nexora: nuova app con superficie a rischio',
    'Nexora : nouvelle app à surface risquée',
  );
  String alertNewAppBody(String names) => _pick(
    'Se instaló $names con permisos peligrosos o por sideload mientras Nexora vigilaba. Revísala en la pestaña Apps.',
    '$names was installed with dangerous permissions or via sideload while Nexora was watching. Review it in the Apps tab.',
    '$names foi instalado com permissões perigosas ou por sideload enquanto o Nexora vigiava. Revise na aba Apps.',
    '$names è stata installata con permessi pericolosi o via sideload mentre Nexora sorvegliava. Controllala nella scheda App.',
    '$names a été installée avec des permissions dangereuses ou par sideload pendant que Nexora surveillait. Vérifiez-la dans l’onglet Apps.',
  );

  // Historial: tendencia y comparación
  String get trendTitle => _pick(
    'Tendencia de las últimas capturas',
    'Trend across recent snapshots',
    'Tendência das últimas capturas',
    'Andamento delle ultime acquisizioni',
    'Tendance des dernières captures',
  );
  String get trendMemLegend => _pick(
    'RAM disponible %',
    'Available RAM %',
    'RAM disponível %',
    'RAM disponibile %',
    'RAM disponible %',
  );
  String get trendStorageLegend => _pick(
    'Disco libre %',
    'Free storage %',
    'Disco livre %',
    'Disco libero %',
    'Disque libre %',
  );
  String get trendTempLegend => _pick(
    'Temp. batería (0–60 °C)',
    'Battery temp (0–60 °C)',
    'Temp. bateria (0–60 °C)',
    'Temp. batteria (0–60 °C)',
    'Temp. batterie (0–60 °C)',
  );
  String get compareHint => _pick(
    'Toca dos capturas para compararlas (A → B).',
    'Tap two snapshots to compare them (A → B).',
    'Toque em duas capturas para compará-las (A → B).',
    'Tocca due acquisizioni per confrontarle (A → B).',
    'Touchez deux captures pour les comparer (A → B).',
  );
  String get compareTitle => _pick(
    'Comparación A → B',
    'Comparison A → B',
    'Comparação A → B',
    'Confronto A → B',
    'Comparaison A → B',
  );
  String get compareClear => _pick(
    'Quitar selección',
    'Clear selection',
    'Limpar seleção',
    'Rimuovi selezione',
    'Effacer la sélection',
  );
  String get compareMem => _pick(
    'RAM disponible',
    'Available RAM',
    'RAM disponível',
    'RAM disponibile',
    'RAM disponible',
  );
  String get compareStorage => _pick(
    'Disco libre',
    'Free storage',
    'Disco livre',
    'Disco libero',
    'Disque libre',
  );
  String get compareScore =>
      _pick('Puntaje', 'Score', 'Pontuação', 'Punteggio', 'Score');
  String get compareRisky => _pick(
    'Apps riesgosas',
    'Risky apps',
    'Apps arriscados',
    'App a rischio',
    'Apps risquées',
  );

  // Informe (PDF) — títulos y frases propias del informe forense
  String get reportTitle => _pick(
    'Informe forense',
    'Forensic report',
    'Relatório forense',
    'Rapporto forense',
    'Rapport forensique',
  );
  String get reportGenerated =>
      _pick('Generado', 'Generated', 'Gerado', 'Generato', 'Généré');
  String get reportDevice =>
      _pick('Equipo', 'Device', 'Aparelho', 'Dispositivo', 'Appareil');
  String get reportVerdict =>
      _pick('Veredicto', 'Verdict', 'Veredito', 'Verdetto', 'Verdict');
  String get reportFindings =>
      _pick('Hallazgos', 'Findings', 'Achados', 'Rilievi', 'Constatations');
  String get reportMetrics =>
      _pick('Métricas', 'Metrics', 'Métricas', 'Metriche', 'Métriques');
  String reportAvailableOf(String total) => _pick(
    'disponibles de $total',
    'available of $total',
    'disponíveis de $total',
    'disponibili di $total',
    'disponibles sur $total',
  );
  String reportFreeOf(String total) => _pick(
    'libres de $total',
    'free of $total',
    'livres de $total',
    'liberi di $total',
    'libres sur $total',
  );
  String reportAppsLine(int total, int risky) => _pick(
    '$total apps de usuario, $risky con superficie riesgosa',
    '$total user apps, $risky with risky surface',
    '$total apps do usuário, $risky com superfície arriscada',
    '$total app utente, $risky con superficie a rischio',
    '$total apps utilisateur, $risky à surface risquée',
  );
  String get reportColSnapshot =>
      _pick('Captura', 'Snapshot', 'Captura', 'Acquisizione', 'Capture');
  String get reportColStorage =>
      _pick('Disco', 'Storage', 'Disco', 'Disco', 'Disque');
  String get reportColScore =>
      _pick('Puntaje', 'Score', 'Pontuação', 'Punteggio', 'Score');
  String get reportIntegrityTitle => _pick(
    'Integridad de la evidencia',
    'Evidence integrity',
    'Integridade da evidência',
    'Integrità delle prove',
    'Intégrité des preuves',
  );
  String reportChainOk(int sealed, int total) => _pick(
    'Cadena de hashes VERIFICADA: $sealed de $total capturas selladas (SHA-256 encadenado).',
    'Hash chain VERIFIED: $sealed of $total snapshots sealed (chained SHA-256).',
    'Cadeia de hashes VERIFICADA: $sealed de $total capturas seladas (SHA-256 encadeado).',
    'Catena di hash VERIFICATA: $sealed di $total acquisizioni sigillate (SHA-256 concatenato).',
    'Chaîne de hachages VÉRIFIÉE : $sealed sur $total captures scellées (SHA-256 chaîné).',
  );
  String get reportChainTampered => _pick(
    'ATENCIÓN: la cadena de hashes NO verifica — el historial pudo ser alterado.',
    'WARNING: the hash chain does NOT verify — the history may have been tampered with.',
    'ATENÇÃO: a cadeia de hashes NÃO verifica — o histórico pode ter sido alterado.',
    'ATTENZIONE: la catena di hash NON verifica — la cronologia potrebbe essere stata alterata.',
    'ATTENTION : la chaîne de hachages NE se vérifie PAS — l’historique a pu être altéré.',
  );
  String get reportFooter => _pick(
    'Generado localmente por NEXORA GUARD (sin permiso INTERNET: nada salió del dispositivo hasta que su dueño compartió este archivo).',
    'Generated locally by NEXORA GUARD (no INTERNET permission: nothing left the device until its owner shared this file).',
    'Gerado localmente pelo NEXORA GUARD (sem permissão INTERNET: nada saiu do dispositivo até o dono compartilhar este arquivo).',
    'Generato localmente da NEXORA GUARD (senza permesso INTERNET: nulla è uscito dal dispositivo finché il proprietario non ha condiviso questo file).',
    'Généré localement par NEXORA GUARD (sans permission INTERNET : rien n’a quitté l’appareil jusqu’à ce que son propriétaire partage ce fichier).',
  );

  // Cuentas locales (pantalla de bienvenida y sesión)

  String get authTagline => _pick(
    'Sensor forense de diagnóstico',
    'Forensic diagnostic sensor',
    'Sensor forense de diagnóstico',
    'Sensore forense diagnostico',
    'Capteur forensique de diagnostic',
  );
  String get authSignIn =>
      _pick('Iniciar sesión', 'Sign in', 'Entrar', 'Accedi', 'Se connecter');
  String get authSignUp => _pick(
    'Crear cuenta',
    'Create account',
    'Criar conta',
    'Crea account',
    'Créer un compte',
  );
  String get authEmail => _pick(
    'Correo electrónico',
    'Email address',
    'Endereço de e-mail',
    'Indirizzo e-mail',
    'Adresse e-mail',
  );
  String get authPassword =>
      _pick('Contraseña', 'Password', 'Senha', 'Password', 'Mot de passe');
  String get authConfirmPassword => _pick(
    'Repetir contraseña',
    'Repeat password',
    'Repetir senha',
    'Ripeti password',
    'Répéter le mot de passe',
  );
  String get authEnterButton =>
      _pick('Entrar', 'Enter', 'Entrar', 'Entra', 'Entrer');
  String get authCreateButton => _pick(
    'Crear mi cuenta',
    'Create my account',
    'Criar minha conta',
    'Crea il mio account',
    'Créer mon compte',
  );
  String get authErrInvalidEmail => _pick(
    'Ingresá un correo válido',
    'Enter a valid email address',
    'Digite um e-mail válido',
    'Inserisci un indirizzo e-mail valido',
    'Saisissez une adresse e-mail valide',
  );
  String get authErrWeakPassword => _pick(
    'La contraseña necesita al menos 6 caracteres',
    'The password needs at least 6 characters',
    'A senha precisa de pelo menos 6 caracteres',
    'La password richiede almeno 6 caratteri',
    'Le mot de passe exige au moins 6 caractères',
  );
  String get authErrMismatch => _pick(
    'Las contraseñas no coinciden',
    'Passwords do not match',
    'As senhas não coincidem',
    'Le password non coincidono',
    'Les mots de passe ne coïncident pas',
  );
  String get authErrEmailTaken => _pick(
    'Ya hay una cuenta en este teléfono: iniciá sesión',
    'An account already exists on this phone: sign in',
    'Já existe uma conta neste telefone: entre',
    'Esiste già un account su questo telefono: accedi',
    "Un compte existe déjà sur ce téléphone : connectez-vous",
  );
  String get authErrWrongCredentials => _pick(
    'Correo o contraseña incorrectos',
    'Wrong email or password',
    'E-mail ou senha incorretos',
    'E-mail o password non corretti',
    'E-mail ou mot de passe incorrects',
  );
  String get authLocalNote => _pick(
    'Tu cuenta vive solo en este teléfono. Sin internet: nada sale de él.',
    'Your account lives only on this phone. No internet: nothing leaves it.',
    'Sua conta vive só neste telefone. Sem internet: nada sai dele.',
    'Il tuo account vive solo su questo telefono. Niente internet: nulla esce.',
    'Votre compte vit uniquement sur ce téléphone. Sans internet : rien n’en sort.',
  );
  String get authLogout => _pick(
    'Cerrar sesión',
    'Sign out',
    'Sair da conta',
    'Esci dall’account',
    'Se déconnecter',
  );
  String get coverSlogan => _pick(
    'Protegemos lo que más importa.',
    'We protect what matters most.',
    'Protegemos o que mais importa.',
    'Proteggiamo ciò che conta di più.',
    'Nous protégeons ce qui compte le plus.',
  );
  String get coverSubtitle => _pick(
    'Ecosistema de seguridad digital',
    'Digital security ecosystem',
    'Ecossistema de segurança digital',
    'Ecosistema di sicurezza digitale',
    'Écosystème de sécurité numérique',
  );
  String get authRememberMe => _pick(
    'Recordarme en este dispositivo',
    'Remember me on this device',
    'Lembrar-me neste dispositivo',
    'Ricordami su questo dispositivo',
    'Se souvenir de moi sur cet appareil',
  );
  String get authForgotPassword => _pick(
    '¿Olvidaste tu contraseña?',
    'Forgot your password?',
    'Esqueceu sua senha?',
    'Hai dimenticato la password?',
    'Mot de passe oublié ?',
  );
  String get authSwitchSignUp => _pick(
    '¿No tienes cuenta? Crear cuenta',
    'No account? Create account',
    'Não tem conta? Criar conta',
    'Non hai un account? Crea account',
    'Pas de compte ? Créer un compte',
  );
  String get authSwitchSignIn => _pick(
    'Ya tengo cuenta',
    'I already have an account',
    'Já tenho conta',
    'Ho già un account',
    'J''ai déjà un compte',
  );
  String get authRecoverTitle => _pick(
    'Recuperar contraseña',
    'Recover password',
    'Recuperar senha',
    'Recupera password',
    'Récupérer le mot de passe',
  );
  String get authRecoverBack => _pick(
    'Volver a iniciar sesión',
    'Back to sign in',
    'Voltar a entrar',
    'Torna ad accedere',
    'Retour à la connexion',
  );
  String get authRecoverNote => _pick(
    'El restablecimiento se envía por un servicio remoto que esta versión '
      'offline no tiene: la recuperación ya está preparada en la arquitectura, '
      'pero solo se activará cuando NEXORA GUARD cuente con ese servicio. '
      'Nada se envía hoy.',
    'Password reset is sent by a remote service this offline version does '
      'not have: recovery is already prepared in the architecture, but it '
      'will only activate when NEXORA GUARD has that service. Nothing is '
      'sent today.',
    'A redefinição é enviada por um serviço remoto que esta versão offline '
      'não tem: a recuperação já está preparada na arquitetura, mas só será '
      'ativada quando a NEXORA GUARD tiver esse serviço. Nada é enviado hoje.',
    'Il reset viene inviato da un servizio remoto che questa versione offline '
      'non possiede: il recupero è già pronto nell’architettura, ma si attiverà '
      'solo quando NEXORA GUARD avrà quel servizio. Oggi non viene inviato nulla.',
    'La réinitialisation est envoyée par un service distant que cette version '
      'hors ligne ne possède pas : la récupération est déjà prête dans '
      'l’architecture, mais elle ne s’activera que lorsque NEXORA GUARD aura '
      'ce service. Rien n’est envoyé aujourd’hui.',
  );
  String get authTerms => _pick(
    'Acepto los términos de uso y la política de privacidad',
    'I accept the terms of use and the privacy policy',
    'Aceito os termos de uso e a política de privacidade',
    'Accetto i termini di utilizzo e l''informativa sulla privacy',
    'J''accepte les conditions d''utilisation et la politique de confidentialité',
  );
  String get authErrTerms => _pick(
    'Aceptá los términos de uso para continuar',
    'Accept the terms of use to continue',
    'Aceite os termos de uso para continuar',
    'Accetta i termini di utilizzo per continuare',
    'Acceptez les conditions d''utilisation pour continuer',
  );
  String get authName => _pick(
    'Nombre (opcional)',
    'Name (optional)',
    'Nome (opcional)',
    'Nome (opzionale)',
    'Nom (facultatif)',
  );
  String get authUsername => _pick(
    'Usuario',
    'Username',
    'Usuário',
    'Nome utente',
    'Nom d''utilisateur',
  );
  String get authAvatarLabel => _pick(
    'Cambiar foto',
    'Change photo',
    'Alterar foto',
    'Cambia foto',
    'Changer la photo',
  );
  String get authRecoverBody => _pick(
    'Solo esta versión local: no hay servicio de envío.',
    'This local version only: there is no sending service.',
    'Somente esta versão local: não há serviço de envio.',
    'Solo questa versione locale: non c’è un servizio di invio.',
    'Version locale uniquement : aucun service d''envoi.',
  );
  String get authRecoverSend => _pick(
    'Enviar enlace de restablecimiento',
    'Send reset link',
    'Enviar link de redefinição',
    'Invia link di ripristino',
    'Envoyer le lien de réinitialisation',
  );
  String get authRecoverSent => _pick(
    'Si el correo existe, el enlace ya viaja hacia él (servicio remoto).',
    'If the email exists, the link is already on its way (remote service).',
    'Se o e-mail existir, o link já está a caminho (serviço remoto).',
    'Se l''e-mail esiste, il link è già in viaggio (servizio remoto).',
    'Si l''e-mail existe, le lien est déjà en route (service distant).',
  );
  // ── FASE 7: recuperación por código local ──
  String get authRecoverStepEmailTitle => _pick(
    '¿Cuál es tu email?',
    'What is your email?',
    'Qual é o seu e-mail?',
    'Qual è la tua e-mail?',
    'Quel est votre e-mail ?',
  );
  String get authRecoverStepEmailBody => _pick(
    'Ingresá el email de tu cuenta local para generar el código de verificación.',
    'Enter your local account email to generate the verification code.',
    'Informe o e-mail da sua conta local para gerar o código de verificação.',
    'Inserisci l''e-mail del tuo account locale per generare il codice di verifica.',
    'Saisissez l''e-mail de votre compte local pour générer le code de vérification.',
  );
  String get authRecoverContinue => _pick(
    'Continuar',
    'Continue',
    'Continuar',
    'Continua',
    'Continuer',
  );
  String get authRecoverErrorNoAccount => _pick(
    'No hay una cuenta local con ese email.',
    'There is no local account with that email.',
    'Não há conta local com esse e-mail.',
    'Non esiste un account locale con questa e-mail.',
    'Aucun compte local avec cet e-mail.',
  );
  String get authRecoverCodeTitle => _pick(
    'Escribe el código',
    'Type the code',
    'Digite o código',
    'Inserisci il codice',
    'Saisissez le code',
  );
  String get authRecoverCodeBody => _pick(
    'Verificamos el código antes de darte la nueva contraseña.',
    'We verify the code before letting you set a new password.',
    'Verificamos o código antes de definir a nova senha.',
    'Verifichiamo il codice prima di impostare la nuova password.',
    'Nous vérifions le code avant de définir le nouveau mot de passe.',
  );
  String get authRecoverCodeWelcome => _pick(
    'TU CÓDIGO',
    'YOUR CODE',
    'SEU CÓDIGO',
    'IL TUO CODICE',
    'VOTRE CODE',
  );
  String get authRecoverCodeShown => _pick(
    'En esta versión sin red el código no se envía por correo: se genera y '
      'se muestra aquí para completar el flujo. Con el servicio remoto, '
      'este mismo código viajaría por email.',
    'In this offline version the code is not emailed: it is generated and '
      'shown here to complete the flow. With the remote service, this same '
      'code would be emailed.',
    'Nesta versão sem rede o código não é enviado por e-mail: ele é gerado e '
      'mostrado aqui para completar o fluxo. Com o serviço remoto, este mesmo '
      'código iria por e-mail.',
    'In questa versione senza rete il codice non viene inviato via e-mail: '
      'viene generato e mostrato qui per completare il flusso. Con il servizio '
      'remoto, lo stesso codice arriverebbe via e-mail.',
    'Dans cette version hors ligne le code n’est pas envoyé par e-mail : il '
      'est généré et affiché ici pour terminer le parcours. Avec le service '
      'distant, ce même code serait envoyé par e-mail.',
  );
  String get authRecoverCodeField => _pick(
    'Código de 6 dígitos',
    '6-digit code',
    'Código de 6 dígitos',
    'Codice a 6 cifre',
    'Code à 6 chiffres',
  );
  String get authRecoverCodeInvalid => _pick(
    'El código no coincide. Revisalo e intentá de nuevo.',
    'The code does not match. Check it and try again.',
    'O código não confere. Verifique e tente novamente.',
    'Il codice non corrisponde. Controlla e riprova.',
    'Le code ne correspond pas. Vérifiez et réessayez.',
  );
  String get authRecoverCodeResend => _pick(
    'Regenerar código',
    'Regenerate code',
    'Gerar novo código',
    'Rigenera codice',
    'Régénérer le code',
  );
  String get authRecoverVerify => _pick(
    'Verificar y continuar',
    'Verify and continue',
    'Verificar e continuar',
    'Verifica e continua',
    'Vérifier et continuer',
  );
  String get authRecoverNewTitle => _pick(
    'Nueva contraseña',
    'New password',
    'Nova senha',
    'Nuova password',
    'Nouveau mot de passe',
  );
  String get authRecoverNewBody => _pick(
    'Elegí una contraseña de al menos 6 caracteres.',
    'Choose a password of at least 6 characters.',
    'Escolha uma senha de pelo menos 6 caracteres.',
    'Scegli una password di almeno 6 caratteri.',
    'Choisissez un mot de passe d’au moins 6 caractères.',
  );
  String get authRecoverNewField => _pick(
    'Nueva contraseña',
    'New password',
    'Nova senha',
    'Nuova password',
    'Nouveau mot de passe',
  );
  String get authRecoverNewConfirmField => _pick(
    'Confirmar nueva contraseña',
    'Confirm new password',
    'Confirmar nova senha',
    'Conferma nuova password',
    'Confirmer le nouveau mot de passe',
  );
  String get authRecoverNewButton => _pick(
    'Guardar nueva contraseña',
    'Save new password',
    'Salvar nova senha',
    'Salva nuova password',
    'Enregistrer le nouveau mot de passe',
  );
  String get authRecoverDoneTitle => _pick(
    '¡Listo!',
    'Done!',
    'Pronto!',
    'Fatto!',
    'Terminé !',
  );
  String get authRecoverDoneBody => _pick(
    'Tu contraseña fue actualizada. Ya podés iniciar sesión con la nueva.',
    'Your password was updated. You can now sign in with the new one.',
    'Sua senha foi atualizada. Agora você pode entrar com a nova.',
    'La password è stata aggiornata. Ora puoi accedere con quella nuova.',
    'Votre mot de passe a été mis à jour. Vous pouvez vous connecter avec le nouveau.',
  );
  String get authRecoverDoneButton => _pick(
    'Ir a iniciar sesión',
    'Go to sign in',
    'Ir para entrar',
    'Vai ad accedere',
    'Aller à la connexion',
  );
  String get authErrUsername => _pick(
    'El usuario necesita al menos 3 caracteres, sin espacios',
    'The username needs at least 3 characters and no spaces',
    'O usuário precisa de pelo menos 3 caracteres, sem espaços',
    'Il nome utente richiede almeno 3 caratteri e senza spazi',
    'Le nom d''utilisateur doit avoir au moins 3 caractères sans espaces',
  );
  String get authErrEmptyPassword => _pick(
    'Escribí tu contraseña',
    'Type your password',
    'Digite sua senha',
    'Scrivi la tua password',
    'Saisissez votre mot de passe',
  );
  String get authPwdHint => _pick(
    '8+ caracteres, mayúscula, minúscula y número',
    '8+ characters, uppercase, lowercase and a number',
    '8+ caracteres, maiúscula, minúscula e número',
    '8+ caratteri, maiuscola, minuscola e numero',
    '8+ caractères, majuscule, minuscule et chiffre',
  );

  // Panel interactivo (dona de riesgo y métricas animadas)
  String get donutTitle => _pick(
    'Composición del riesgo',
    'Risk composition',
    'Composição do risco',
    'Composizione del rischio',
    'Composition du risque',
  );
  String get donutHint => _pick(
    'Tocá un arco o la leyenda para ver el detalle.',
    'Tap an arc or the legend for details.',
    'Toque em um arco ou na legenda para ver o detalhe.',
    'Tocca un arco o la legenda per i dettagli.',
    'Touchez un arc ou la légende pour le détail.',
  );
  String get donutEmpty => _pick(
    'Sin hallazgos que desglosar: todo en orden.',
    'No findings to break down: all clear.',
    'Sem achados a detalhar: tudo em ordem.',
    'Nessun rilievo da analizzare: tutto ok.',
    'Rien à détailler : tout est en ordre.',
  );
  String get metricSignals => _pick(
    'Señales activas',
    'Active signals',
    'Sinais ativos',
    'Segnali attivi',
    'Signaux actifs',
  );

  // Crédito de autoría
  String get createdBy =>
      _pick('Creado por', 'Created by', 'Criado por', 'Creato da', 'Créé par');

  // ── Shell nueva (bottom nav + top bar) ─────────────────────────────────
  String get tabHome =>
      _pick('Inicio', 'Home', 'Início', 'Home', 'Accueil');
  String get tabAnalyze => _pick(
    'Análisis',
    'Analyze',
    'Análise',
    'Analisi',
    'Analyse',
  );
  String get tabSignals => _pick(
    'Señales',
    'Signals',
    'Sinais',
    'Segnali',
    'Signaux',
  );
  String get tabProfile => _pick(
    'Perfil',
    'Profile',
    'Perfil',
    'Profilo',
    'Profil',
  );
  String get tabProtection => _pick(
    'Protección',
    'Protection',
    'Proteção',
    'Protezione',
    'Protection',
  );
  String get topAlerts =>
      _pick('Alertas', 'Alerts', 'Alertas', 'Notifiche', 'Alertes');
  String get topSettings =>
      _pick('Configuración', 'Settings', 'Configurações', 'Impostazioni', 'Réglages');

  // ── Niveles de riesgo (4 niveles; el color NUNCA viaja solo) ───────────
  String get riskLevelTitle => _pick(
    'Nivel de riesgo',
    'Risk level',
    'Nível de risco',
    'Livello di rischio',
    'Niveau de risque',
  );
  String get riskSafe =>
      _pick('Seguro', 'Safe', 'Seguro', 'Sicuro', 'Sûr');
  String get riskAttention => _pick(
    'Atención',
    'Attention',
    'Atenção',
    'Attenzione',
    'À surveiller',
  );
  String get riskSuspicious => _pick(
    'Sospechoso',
    'Suspicious',
    'Suspeito',
    'Sospetto',
    'Suspect',
  );
  String get riskCritical => _pick(
    'Crítico',
    'Critical',
    'Crítico',
    'Critico',
    'Critique',
  );

  // ── Sistema de planes Basic/Professional ──────────────────────────────
  String get premiumTitle => _pick('NEXORA PROFESSIONAL', 'NEXORA PROFESSIONAL', 'NEXORA PROFESSIONAL', 'NEXORA PROFESSIONAL', 'NEXORA PROFESSIONAL');
  String get premiumTagline => _pick(
    'Modo Professional: funciones avanzadas, una sola suscripción.',
    'Professional mode: advanced features, one subscription.',
    'Modo Professional: recursos avançados, uma única assinatura.',
    'Modalità Professional: funzioni avanzate, un solo abbonamento.',
    'Mode Professional : des fonctions avancées, un seul abonnement.',
  );
  String get planBasic =>
      _pick('BASIC', 'BASIC', 'BASIC', 'BASE', 'BASE');
  String get planProfessional =>
      _pick('PROFESSIONAL', 'PROFESSIONAL', 'PROFESSIONAL', 'PROFESSIONAL', 'PROFESSIONNEL');
  String get premiumPerMonth => _pick(
    '/ mes',
    '/ month',
    '/ mês',
    '/ mese',
    '/ mois',
  );
  String get premiumPriceArs => _pick(
    '\$10.000 ARS',
    'ARS \$10,000',
    '\$10.000 ARS',
    '10.000 ARS',
    '10 000 ARS',
  );
  String get premiumCtaStart => _pick(
    'PASSAR A PROFESSIONAL',
    'GO PROFESSIONAL',
    'COMEÇAR O PROFESSIONAL',
    'PASSA A PROFESSIONAL',
    'PASSER EN PROFESSIONNEL',
  );
  String get premiumRestore => _pick(
    'Restaurar compra',
    'Restore purchase',
    'Restaurar compra',
    'Ripristina acquisto',
    'Restaurer l’achat',
  );
  String get premiumLockedTitle => _pick(
    'Función PROFESSIONAL',
    'PROFESSIONAL feature',
    'Recurso PROFESSIONAL',
    'Funzione PROFESSIONAL',
    'Fonction PROFESSIONNEL',
  );
  String get premiumLockedDesc => _pick(
    'Disponible con el plan NEXORA PROFESSIONAL.',
    'Available with the NEXORA PROFESSIONAL plan.',
    'Disponível com o plano NEXORA PROFESSIONAL.',
    'Disponibile con il piano NEXORA PROFESSIONAL.',
    'Disponible avec le forfait NEXORA PROFESSIONNEL.',
  );
  String get premiumSee => _pick(
    'Ver Professional',
    'View Professional',
    'Ver Professional',
    'Vedi Professional',
    'Voir Professionnel',
  );
  String get premiumUnavailable => _pick(
    'Los pagos reales se habilitarán cuando conectes tu proveedor de pagos.',
    'Real payments will be enabled once you connect your payments provider.',
    'Os pagamentos reais serão habilitados quando você conectar seu provedor de pagamentos.',
    'I pagamenti reali verranno attivati quando colleghi il tuo provider di pagamenti.',
    'Les paiements réels seront activés dès que vous connecterez votre prestataire de paiements.',
  );
  String get premiumActiveMsg => _pick(
    'Ya tenés NEXORA PROFESSIONAL activo',
    'NEXORA PROFESSIONAL is already active',
    'NEXORA PROFESSIONAL já está ativo',
    'NEXORA PROFESSIONAL è già attivo',
    'NEXORA PROFESSIONNEL est déjà actif',
  );

  // ── Nexora AI (chat local contextual) ──────────────────────────────────
  String get aiTitle =>
      _pick('NEXORA AI', 'NEXORA AI', 'NEXORA AI', 'NEXORA AI', 'NEXORA AI');
  String get aiGreeting => _pick(
    '¿En qué puedo ayudarte?',
    'How can I help you?',
    'Como posso ajudar você?',
    'Come posso aiutarti?',
    'Comment puis-je vous aider ?',
  );
  String get aiTypeMessage => _pick(
    'Escribí tu pregunta…',
    'Type your question…',
    'Escreva sua pergunta…',
    'Scrivi la tua domanda…',
    'Écrivez votre question…',
  );
  String get aiThinking =>
      _pick('Analizando…', 'Thinking…', 'Analisando…', 'Analizzo…', 'Analyse…');
  String get aiQuickDevice => _pick(
    '¿Mi teléfono está seguro?',
    'Is my phone secure?',
    'Meu celular está seguro?',
    'Il mio telefono è sicuro?',
    'Mon téléphone est-il sûr ?',
  );
  String get aiQuickAlert => _pick(
    '¿Qué significa esta alerta?',
    'What does this alert mean?',
    'O que este alerta significa?',
    'Cosa significa questo avviso?',
    'Que signifie cette alerte ?',
  );
  String get aiQuickApp => _pick(
    '¿Esta aplicación es peligrosa?',
    'Is this app dangerous?',
    'Este app é perigoso?',
    'Questa app è pericolosa?',
    'Cette application est-elle dangereuse ?',
  );
  String get aiQuickPermission => _pick(
    '¿Qué es este permiso?',
    'What is this permission?',
    'O que é essa permissão?',
    'Cos’è questo permesso?',
    'Qu’est-ce que cette autorisation ?',
  );
  String get aiQuickProtect => _pick(
    '¿Cómo protejo mi teléfono?',
    'How do I protect my phone?',
    'Como proteger meu celular?',
    'Come proteggo il mio telefono?',
    'Comment protéger mon téléphone ?',
  );
  String get aiIntro => _pick(
    'Soy Nexora AI, tu asistente local de seguridad. Analizo los datos de tu dispositivo sin que nada salga del teléfono.',
    'I am Nexora AI, your local security assistant. I analyze your device data without anything leaving the phone.',
    'Sou a Nexora AI, seu assistente local de segurança. Analiso os dados do seu dispositivo sem que nada saia do telefone.',
    'Sono Nexora AI, il tuo assistente di sicurezza locale. Analizzo i dati del dispositivo senza che nulla esca dal telefono.',
    'Je suis Nexora AI, votre assistant de sécurité local. J’analyse les données de votre appareil sans que rien ne quitte le téléphone.',
  );
  String get aiHonestNote => _pick(
    'Basado solo en señales locales. No soy un veredicto definitivo: revisá la evidencia antes de actuar.',
    'Based only on local signals. I am not a final verdict: review the evidence before acting.',
    'Baseado apenas em sinais locais. Não sou um veredicto definitivo: revise a evidência antes de agir.',
    'Basato solo su segnali locali. Non sono un verdetto definitivo: rivedi le prove prima di agire.',
    'Basé uniquement sur les signaux locaux. Je ne suis pas un verdict définitif : examinez les preuves avant d’agir.',
  );
  String get aiNoData => _pick(
    'No tengo datos para responder eso en este momento.',
    'I have no data to answer that right now.',
    'Não tenho dados para responder isso agora.',
    'Non ho dati per rispondere a questo adesso.',
    'Je n’ai pas de données pour répondre à cela pour le moment.',
  );
  String get aiEvActive => _pick(
    'Capacidad concedida y ACTIVA ahora: ',
    'Granted capability ACTIVE right now: ',
    'Capacidade concedida e ATIVA agora: ',
    'Capacità concessa e ATTIVA adesso: ',
    'Capacité accordée et ACTIVE maintenant : ',
  );
  String get aiEvGranted => _pick(
    'Permisos sensibles efectivamente concedidos: ',
    'Sensitive permissions actually granted: ',
    'Permissões sensíveis efetivamente concedidas: ',
    'Autorizzazioni sensibili effettivamente concesse: ',
    'Autorisations sensibles effectivement accordées : ',
  );
  String get aiEvDeclared => _pick(
    'Solo declarados en el manifiesto, sin conceder: ',
    'Only declared in the manifest, not granted: ',
    'Apenas declarados no manifesto, sem conceder: ',
    'Solo dichiarati nel manifest, non concessi: ',
    'Uniquement déclarées dans le manifeste, non accordées : ',
  );
  String get aiEvSideload => _pick(
    'origen no verificado (instalada fuera de la tienda oficial)',
    'unverified origin (installed outside the official store)',
    'origem não verificada (instalada fora da loja oficial)',
    'origine non verificata (installata fuori dallo store ufficiale)',
    'origine non vérifiée (installée hors du store officiel)',
  );
  String aiEvAndMore(int n) => _pick(
    ' y $n señal(es) más.',
    ' and $n more signal(s).',
    ' e $n sinal(is) a mais.',
    ' e altri $n segnale(i).',
    ' et $n signal(aux) de plus.',
  );
  String get aiEvSafe => _pick(
    'Sin señales relevantes: no hay permisos sensibles concedidos ni flags activos.',
    'No relevant signals: no sensitive permissions granted nor active flags.',
    'Sem sinais relevantes: sem permissões sensíveis concedidas nem flags ativos.',
    'Nessun segnale rilevante: nessuna autorizzazione sensibile concessa né flag attivi.',
    'Aucun signal pertinent : aucune autorisation sensible accordée ni drapeau actif.',
  );
  String aiAlertSummary(String intro, String items, String reco) => _pick(
    '$intro $items.\n\nRecomendación principal: $reco',
    '$intro $items.\n\nMain recommendation: $reco',
    '$intro $items.\n\nRecomendação principal: $reco',
    '$intro $items.\n\nRaccomandazione principale: $reco',
    '$intro $items.\n\nRecommandation principale : $reco',
  );
  String get aiAlertNone => _pick(
    'No hay alertas activas: tu dispositivo está en orden.',
    'No active alerts: your device is all clear.',
    'Sem alertas ativas: seu dispositivo está em ordem.',
    'Nessun avviso attivo: il dispositivo è a posto.',
    'Aucune alerte active : votre appareil est en ordre.',
  );
  String get aiTempOk =>
      _pick('Temperatura normal.', 'Temperature is normal.', 'Temperatura normal.', 'Temperatura normale.', 'Température normale.');
  String get aiTempWarm => _pick(
    'Temperatura elevada: cuidá la batería, evitá cargar y jugar a la vez.',
    'Temperature is elevated: protect the battery — avoid charging and gaming at once.',
    'Temperatura elevada: cuide a bateria, evite carregar e jogar ao mesmo tempo.',
    'Temperatura elevata: proteggi la batteria, evita carica e gioco insieme.',
    'Température élevée : protégez la batterie, évitez de charger et jouer en même temps.',
  );
  String get aiTempHot => _pick(
    'Temperatura crítica: detené el uso intensivo y enfriá el equipo.',
    'Critical temperature: stop heavy use and cool the device.',
    'Temperatura crítica: pare o uso intenso e resfrie o aparelho.',
    'Temperatura critica: ferma l’uso intensivo e raffredda il dispositivo.',
    'Température critique : arrêtez l’utilisation intensive et refroidissez l’appareil.',
  );
  String get aiMemPressure => _pick(
    'hay presión de memoria.',
    'memory is under pressure.',
    'há pressão de memória.',
    'la memoria è sotto pressione.',
    'la mémoire est sous pression.',
  );
  String get aiAppNoAudit => _pick(
    'Este dispositivo no permite auditar aplicaciones instaladas.',
    'This device does not allow auditing installed apps.',
    'Este dispositivo não permite auditar os aplicativos instalados.',
    'Questo dispositivo non consente di controllare le app installate.',
    'Cet appareil ne permet pas d’auditer les applications installées.',
  );
  String get aiGreetReply => _pick(
    '¡Hola! Preguntame sobre la seguridad de tu dispositivo, batería, temperatura, memoria o cualquier app instalada.',
    'Hi! Ask me about your device security, battery, temperature, memory, or any installed app.',
    'Olá! Pergunte sobre a segurança do dispositivo, bateria, temperatura, memória ou qualquer app instalada.',
    'Ciao! Chiedimi della sicurezza del dispositivo, batteria, temperatura, memoria o di qualsiasi app installata.',
    'Bonjour ! Interrogez-moi sur la sécurité de votre appareil, la batterie, la température, la mémoire ou une application installée.',
  );
  String get aiProtectTips => _pick(
    '1) Mantené Android/iOS actualizado y el instalador solo desde las tiendas oficiales. 2) Revisá los permisos concedidos en las apps que más usás. 3) Activá la captura en segundo plano de Nexora para detectar cambios mientras dormís. 4) Desconfiá de SMS/los y links que te apuran. 5) Usá verificación en dos pasos.',
    '1) Keep Android/iOS updated and install only from official stores. 2) Review permissions granted to the apps you use most. 3) Enable Nexora background capture to detect changes while you sleep. 4) Be wary of urgent SMS/links that pressure you. 5) Use two-factor authentication.',
    '1) Mantenha Android/iOS atualizado e instale apenas nas lojas oficiais. 2) Revise as permissões concedidas aos apps que mais usa. 3) Ative a captura em segundo plano da Nexora para detectar mudanças enquanto dorme. 4) Desconfie de SMS/links urgentes que pressionam. 5) Use verificação em duas etapas.',
    '1) Tieni Android/iOS aggiornati e installa solo dagli store ufficiali. 2) Rivedi le autorizzazioni concesse alle app che usi di più. 3) Attiva la cattura in background di Nexora per rilevare cambiamenti mentre dormi. 4) Attento a SMS/link urgenti che fanno pressione. 5) Usa la verifica in due passaggi.',
    '1) Tenez Android/iOS à jour et installez uniquement depuis les stores officiels. 2) Revoyez les autorisations accordées aux applications les plus utilisées. 3) Activez la capture en arrière-plan de Nexora pour détecter les changements pendant votre sommeil. 4) Méfiez-vous des SMS/liens urgents qui font pression. 5) Utilisez la double authentification.',
  );
  String get aiHelp => _pick(
    'Podés preguntarme: si tu teléfono está seguro, qué significa una alerta, si una app es peligrosa, qué es un permiso, cómo está tu batería o temperatura, o cómo proteger tu equipo.',
    'You can ask me: whether your phone is secure, what an alert means, whether an app is dangerous, what a permission is, how your battery or temperature are, or how to protect your device.',
    'Você pode me perguntar: se seu celular está seguro, o que um alerta significa, se um app é perigoso, o que é uma permissão, como está sua bateria ou temperatura, ou como proteger seu aparelho.',
    'Puoi chiedermi: se il telefono è sicuro, cosa significa un avviso, se un’app è pericolosa, cos’è un permesso, come stanno batteria o temperatura, o come proteggere il dispositivo.',
    'Vous pouvez me demander : si votre téléphone est sûr, ce que signifie une alerte, si une application est dangereuse, ce qu’est une autorisation, l’état de la batterie ou de la température, ou comment protéger votre appareil.',
  );

  String aiReplyBattery(String pct, String state, String temp) => _pick(
    'Batería al $pct%. Estado: $state. Temperatura: $temp.',
    'Battery at $pct%. State: $state. Temperature: $temp.',
    'Bateria em $pct%. Estado: $state. Temperatura: $temp.',
    'Batteria al $pct%. Stato: $state. Temperatura: $temp.',
    'Batterie à $pct%. État : $state. Température : $temp.',
  );
  String aiReplyBatteryNoTemp(String pct, String state) => _pick(
    'Batería al $pct%. Estado: $state. (La plataforma no expone la temperatura aquí.)',
    'Battery at $pct%. State: $state. (This platform does not expose temperature here.)',
    'Bateria em $pct%. Estado: $state. (Esta plataforma não expõe a temperatura aqui.)',
    'Batteria al $pct%. Stato: $state. (Questa piattaforma non espone la temperatura qui.)',
    'Batterie à $pct%. État : $state. (Cette plateforme n’expose pas la température ici.)',
  );
  String aiReplyTemp(double temp, String status) => _pick(
    'La batería está a $temp°C. $status',
    'The battery is at $temp°C. $status',
    'A bateria está a $temp°C. $status',
    'La batteria è a $temp°C. $status',
    'La batterie est à $temp°C. $status',
  );
  String aiReplyMemory(String used, String available, int pct, String note) => _pick(
    'RAM: $used en uso, $available libres ($pct% de presión). $note',
    'RAM: $used in use, $available available ($pct% pressure). $note',
    'RAM: $used em uso, $available livres ($pct% de pressão). $note',
    'RAM: $used in uso, $available disponibili ($pct% di pressione). $note',
    'RAM : $used utilisées, $available libres ($pct% de pression). $note',
  );
  String aiReplyStorage(String free, String total, int pct) => _pick(
    'Almacenamiento: $free libres de $total ($pct% disponible).',
    'Storage: $free free of $total ($pct% available).',
    'Armazenamento: $free livres de $total ($pct% disponível).',
    'Archiviazione: $free liberi su $total ($pct% disponibile).',
    'Stockage : $free libres sur $total ($pct% disponible).',
  );
  String aiAppLevel(String name, String level, String evidence) => _pick(
    '$name → NIVEL: $level. $evidence',
    '$name → LEVEL: $level. $evidence',
    '$name → NÍVEL: $level. $evidence',
    '$name → LIVELLO: $level. $evidence',
    '$name → NIVEAU : $level. $evidence',
  );
  String aiAppNotFound(String name) => _pick(
    'No encuentro "$name" entre las apps que puedo ver. Revisá el nombre exacto en la lista de Apps.',
    'I cannot find "$name" among the apps I can see. Check the exact name in the Apps list.',
    'Não encontro "$name" entre os apps que posso ver. Verifique o nome exato na lista de Apps.',
    'Non trovo "$name" tra le app che posso vedere. Controlla il nome esatto nell’elenco delle app.',
    'Je ne trouve pas « $name » parmi les applications que je peux voir. Vérifiez le nom exact dans la liste des applications.',
  );
  String aiReplyOverall(String level, int score, int warnings, int criticals) =>
      _pick(
        'Tu dispositivo está en nivel $level (puntaje $score). Alerta(s) para revisar: $warnings · Críticas: $criticals.',
        'Your device is at $level level (score $score). Alerts to review: $warnings · Critical: $criticals.',
        'Seu dispositivo está no nível $level (pontuação $score). Alertas para revisar: $warnings · Críticas: $criticals.',
        'Il tuo dispositivo è a livello $level (punteggio $score). Avvisi da rivedere: $warnings · Critici: $criticals.',
        'Votre appareil est au niveau $level (score $score). Alertes à revoir : $warnings · Critiques : $criticals.',
      );
  String aiTopRisky(String items) => _pick(
    'Las apps con más señales de riesgo ahora: $items.',
    'The apps with the most risk signals right now: $items.',
    'Os apps com mais sinais de risco agora: $items.',
    'Le app con più segnali di rischio adesso: $items.',
    'Les applications avec le plus de signaux de risque : $items.',
  );
  String get aiTopRiskyNone => _pick(
    'No hay apps con señales de riesgo destacadas ahora.',
    'No apps with notable risk signals right now.',
    'Não há apps com sinais de risco relevantes agora.',
    'Nessuna app con segnali di rischio rilevanti adesso.',
    'Aucune application avec des signaux de risque notables.',
  );
  String aiPermissionExplain(String id) => switch (id) {
    'CAMERA' => _pick(
      'El permiso de Cámara permite a la app tomar fotos y video. Preguntate: ¿esta app necesita cámara para lo que hace? Si no, podés revocarlo desde su ficha en Configuración del sistema.',
      'The Camera permission lets the app take photos and video. Ask yourself: does this app need a camera for what it does? If not, revoke it from its system settings page.',
      'A permissão de Câmera permite ao app tirar fotos e vídeos. Pergunte-se: este app precisa de câmera para o que faz? Se não, revogue na página de sistema.',
      'Il permesso Camera consente all’app di scattare foto e video. Chiediti: questa app ha bisogno della fotocamera per ciò che fa? Se no, revocalo dalla pagina di sistema.',
      'L’autorisation Appareil photo permet à l’application de prendre des photos et vidéos. Demandez-vous : cette app a-t-elle besoin de la caméra pour ce qu’elle fait ? Sinon, révoquez-la depuis sa fiche système.',
    ),
    'RECORD_AUDIO' => _pick(
      'Micrófono: la app puede grabar audio. Es sensible porque puede captar conversaciones; revocá si no lo precisa.',
      'Microphone: the app can record audio. Sensitive because it can capture conversations; revoke if not needed.',
      'Microfone: o app pode gravar áudio. É sensível porque pode captar conversas; revogue se não precisar.',
      'Microfono: l’app può registrare audio. Sensibile perché può catturare conversazioni; revoca se non serve.',
      'Microphone : l’application peut enregistrer l’audio. Sensible car il peut capter des conversations ; révoquez s’il n’est pas nécessaire.',
    ),
    'ACCESS_FINE_LOCATION' => _pick(
      'Ubicación precisa: la app ve tu posición GPS. Preguntate si necesita ubicación exacta o si le alcanza con la aproximada.',
      'Precise location: the app sees your GPS position. Ask whether it needs exact location or approximate is enough.',
      'Localização precisa: o app vê sua posição GPS. Pergunte se ele precisa de localização exata ou a aproximada basta.',
      'Posizione precisa: l’app vede la tua posizione GPS. Chiediti se serve la posizione esatta o basta quella approssimata.',
      'Localisation précise : l’application voit votre position GPS. Demandez-vous si elle a besoin de la position exacte ou si l’approximative suffit.',
    ),
    'ACCESS_BACKGROUND_LOCATION' => _pick(
      'Ubicación en segundo plano: la app te sigue ubicando aunque esté cerrada. Es un permiso fuerte: revocado salvo que tengas un motivo claro.',
      'Background location: the app keeps tracking you even when closed. A strong permission: revoke unless you have a clear reason.',
      'Localização em segundo plano: o app continua te localizando mesmo fechado. Permissão forte: revogue a menos que haja motivo claro.',
      'Posizione in background: l’app continua a tracciarti anche da chiusa. Permesso forte: revoca a meno che non ci sia un chiaro motivo.',
      'Localisation en arrière-plan : l’application continue de vous localiser même fermée. Autorisation forte : révoquez sauf motif clair.',
    ),
    'READ_CONTACTS' => _pick(
      'Contactos: la app puede leer tu agenda. Es útil para apps de mensajería, pero no para un juego o una lámpara.',
      'Contacts: the app can read your address book. Useful for messaging apps, not for a game or a flashlight.',
      'Contatos: o app pode ler sua agenda. Útil para apps de mensagem, não para um jogo ou lanterna.',
      'Contatti: l’app può leggere la tua rubrica. Utile per la messaggistica, non per un gioco o una torcia.',
      'Contacts : l’application peut lire votre répertoire. Utile pour la messagerie, pas pour un jeu ni une lampe.',
    ),
    'READ_SMS' => _pick(
      'SMS: la app puede leer tus mensajes de texto, incluidos códigos de verificación. Poco permiso legítimo en apps modernas; revisalo de cerca.',
      'SMS: the app can read your text messages, including verification codes. Rarely legitimate in modern apps; review closely.',
      'SMS: o app pode ler seus mensagens de texto, incluindo códigos de verificação. Raro de ser legítimo em apps modernos; revise de perto.',
      'SMS: l’app può leggere i tuoi messaggi, inclusi i codici di verifica. Raramente legittimo nelle app moderne; verifica bene.',
      'SMS : l’application peut lire vos messages, y compris les codes de vérification. Rarement légitime dans les apps modernes ; à examiner de près.',
    ),
    _ => _pick(
      'Este permiso permite a la app acceder a un dato sensible tuyo. Si no entendés por qué lo necesita, revocalo desde la ficha de la app en Configuración del sistema.',
      'This permission lets the app access sensitive data of yours. If you do not understand why it needs it, revoke it from the app’s system settings page.',
      'Esta permissão permite ao app acessar um dado sensível seu. Se você não entende por que ele precisa, revogue na página do app nas Configurações do sistema.',
      'Questo permesso consente all’app di accedere a un dato sensibile. Se non capisci perché serve, revocalo dalla pagina dell’app nelle impostazioni di sistema.',
      'Cette autorisation permet à l’application d’accéder à une donnée sensible. Si vous ne comprenez pas pourquoi, révoquez-la depuis la fiche de l’application dans les réglages du système.',
    ),
  };

  // Hallazgos (ids estables → texto localizado)

  // ── Dashboard (Inicio) ────────────────────────────────────────────────
  String get dashProtectionTitle => _pick(
    'Nivel de protección',
    'Protection level',
    'Nível de proteção',
    'Livello di protezione',
    'Niveau de protection',
  );
  String get dashStatusNormal => _pick(
    'BIEN PROTEGIDO',
    'WELL PROTECTED',
    'BEM PROTEGIDO',
    'BENE PROTETTO',
    'BIEN PROTÉGÉ',
  );
  String get dashStatusWarning => _pick(
    'PRECAUCIÓN',
    'CAUTION',
    'CUIDADO',
    'ATTENZIONE',
    'PRUDENCE',
  );
  String get dashStatusCritical => _pick(
    'EN RIESGO',
    'AT RISK',
    'EM RISCO',
    'A RISCHIO',
    'EN DANGER',
  );
  String get dashHello => _pick(
    'Hola de nuevo',
    'Welcome back',
    'Bem-vindo de volta',
    'Bentornato',
    'Bon retour',
  );
  String get dashAllGood => _pick(
    'Todo está bajo control',
    'Everything is under control',
    'Está tudo sob controle',
    'Tutto sotto controllo',
    'Tout est sous contrôle',
  );
  String dashFindings(int n) => _pick(
    '$n hallazgo(s)',
    '$n finding(s)',
    '$n achado(s)',
    '$n rilevazione(i)',
    '$n constatation(s)',
  );
  String get dashResourceTitle => _pick(
    'Recursos en vivo',
    'Live resources',
    'Recursos ao vivo',
    'Risorse in tempo reale',
    'Ressources en direct',
  );
  String get dashCpuCores => _pick(
    'Núcleos',
    'Cores',
    'Núcleos',
    'Core',
    'Cœurs',
  );
  String get dashCpuLoad => _pick(
    'Carga de CPU',
    'CPU load',
    'Carga da CPU',
    'Carico CPU',
    'Charge CPU',
  );
  String get dashCpuUnavailable => _pick(
    'El sistema no expone la carga de CPU en este momento',
    'The system does not expose CPU load right now',
    'O sistema não expõe a carga da CPU neste momento',
    'Il sistema non espone il carico della CPU al momento',
    'Le système n’expose pas la charge du CPU pour le moment',
  );
  String get dashNetworkDown => _pick(
    'Descarga',
    'Download',
    'Download',
    'Download',
    'Réception',
  );
  String get dashNetworkUp => _pick(
    'Subida',
    'Upload',
    'Upload',
    'Upload',
    'Envoi',
  );
  String get dashNetworkOff => _pick(
    'Sin conexión',
    'Offline',
    'Sem conexão',
    'Nessuna connessione',
    'Hors ligne',
  );
  String get dashNetworkOn => _pick(
    'Conectado',
    'Connected',
    'Conectado',
    'Connessa',
    'Connecté',
  );
  String get dashNetworkNote => _pick(
    'Velocidad medida en vivo',
    'Live measured speed',
    'Velocidade medida ao vivo',
    'Velocità misurata in tempo reale',
    'Vitesse mesurée en direct',
  );
  String get dashVpnActive => _pick(
    'VPN activa',
    'VPN active',
    'VPN ativa',
    'VPN attiva',
    'VPN active',
  );
  String get dashAppsTitle => _pick(
    'Aplicaciones',
    'Applications',
    'Aplicativos',
    'Applicazioni',
    'Applications',
  );
  String get dashAppsSub => _pick(
    'Revisar aplicaciones',
    'Review apps',
    'Revisar aplicativos',
    'Rivedi le app',
    'Examiner les apps',
  );
  String get dashSignalsTitle => _pick(
    'Señales',
    'Signals',
    'Sinais',
    'Segnali',
    'Signaux',
  );
  String get dashSignalsSub => _pick(
    'Ver hallazgos',
    'View findings',
    'Ver achados',
    'Vedi rilevazioni',
    'Voir constatations',
  );
  String get dashNetworkKebab => _pick(
    'Red',
    'Network',
    'Rede',
    'Rete',
    'Réseau',
  );
  String get dashViewAll => _pick(
    'Ver todas',
    'View all',
    'Ver todas',
    'Vedi tutte',
    'Tout voir',
  );
  String get dashViewAnalysis => _pick(
    'VER ANÁLISIS',
    'VIEW ANALYSIS',
    'VER ANÁLISE',
    'VEDI ANALISI',
    'VOIR ANALYSE',
  );
  String get dashRecentTitle => _pick(
    'Actividad reciente',
    'Recent activity',
    'Atividade recente',
    'Attività recente',
    'Activité récente',
  );
  String get dashHistEmpty => _pick(
    'Todavía no hay capturas. Tirá hacia abajo para analizar por primera vez.',
    'No captures yet. Pull down to analyze for the first time.',
    'Ainda não há capturas. Puxe para baixo para analisar pela primeira vez.',
    'Ancora nessuna acquisizione. Trascina verso il basso per la prima analisi.',
    'Aucune capture pour l’instant. Tirez vers le bas pour analyser la première fois.',
  );
  String get dashHistNormal => _pick(
    'Análisis completado',
    'Analysis completed',
    'Análise concluída',
    'Analisi completata',
    'Analyse terminée',
  );
  String get dashHistWarning => _pick(
    'Se detectaron precauciones',
    'Caution items detected',
    'Foram detectadas precauções',
    'Rilevate raccomandazioni',
    'Des précautions détectées',
  );
  String get dashHistCritical => _pick(
    'Riesgo alto detectado',
    'High risk detected',
    'Risco alto detectado',
    'Rischio alto rilevato',
    'Risque élevé détecté',
  );
  String dashRiskScore(int s) => _pick(
    'riesgo $s',
    'risk $s',
    'risco $s',
    'rischio $s',
    'risque $s',
  );
  String get dashNoRiskyApps => _pick(
    'Sin apps con señales destacadas',
    'No apps with notable signals',
    'Sem apps com sinais relevantes',
    'Nessuna app con segnali rilevanti',
    'Aucune application avec des signaux notables',
  );

  // ── Apps (FASE 5: lista 4 niveles + detalle con permisos) ──────────────
  String get appSearch => _pick(
    'Buscar app…',
    'Search apps…',
    'Buscar app…',
    'Cerca app…',
    'Rechercher une app…',
  );
  String get appDetailVersion => _pick(
    'Versión',
    'Version',
    'Versão',
    'Versione',
    'Version',
  );
  String get appDetailSideload => _pick(
    'Instalada fuera de la tienda oficial',
    'Installed outside the official store',
    'Instalada fora da loja oficial',
    'Installata fuori dallo store ufficiale',
    'Installée hors du store officiel',
  );
  String get appDetailPermsGranted => _pick(
    'Permisos concedidos hoy',
    'Permissions granted today',
    'Permissões concedidas hoje',
    'Autorizzazioni concesse oggi',
    'Autorisations accordées aujourd’hui',
  );
  String get appDetailPermsRequested => _pick(
    'Permisos solicitados, no concedidos',
    'Permissions requested, not granted',
    'Permissões solicitadas, não concedidas',
    'Autorizzazioni richieste, non concesse',
    'Autorisations demandées, non accordées',
  );
  String get appPermExplainTitle => _pick(
    '¿Qué significa este permiso?',
    'What does this permission mean?',
    'O que esta permissão significa?',
    'Cosa significa questa autorizzazione?',
    'Que signifie cette autorisation ?',
  );
  String get appDetailOpenSettings => _pick(
    'Abrir ajustes del sistema',
    'Open system settings',
    'Abrir configurações do sistema',
    'Apri impostazioni di sistema',
    'Ouvrir les réglages système',
  );
  String get appDetailOpenApp => _pick(
    'Abrir ficha del sistema',
    'Open system app page',
    'Abrir página do app no sistema',
    'Apri la scheda dell’app',
    'Ouvrir la fiche système de l’app',
  );
  String get appDetailHonest => _pick(
    'NEXORA no revoca permisos por vos ni simula hacerlo: la ficha abre los Ajustes reales del sistema, donde sí podés gestionarlos.',
    'NEXORA does not revoke permissions for you nor fakes it: the page opens the real system settings, where you can manage them.',
    'A NEXORA não revoga permissões por você nem simula: a página abre as Configurações reais do sistema, onde você pode gerenciá-las.',
    'NEXORA non revoca le autorizzazioni per te né lo simula: la scheda apre le reali impostazioni di sistema, dove puoi gestirle.',
    'NEXORA ne révoque pas les autorisations à votre place et ne le simule pas : la fiche ouvre les vrais réglages système, où vous pouvez les gérer.',
  );
  String get appDetailNoPerms => _pick(
    'Esta app no solicita permisos sensibles.',
    'This app requests no sensitive permissions.',
    'Este app não solicita permissões sensíveis.',
    'Questa app non richiede autorizzazioni sensibili.',
    'Cette application ne demande aucune autorisation sensible.',
  );
  String get appSearchNone => _pick(
    'No hay apps para esa búsqueda.',
    'No apps match that search.',
    'Não há apps para essa busca.',
    'Nessuna app per quella ricerca.',
    'Aucune application pour cette recherche.',
  );

  // ── FASE 4: gráfica interactiva ──
  String get chartTrendTitle => _pick(
    'Tendencia de métricas',
    'Metric trends',
    'Tendência de métricas',
    'Andamento delle metriche',
    'Tendance des métriques',
  );
  String get chartWin1h => _pick('1H', '1H', '1H', '1H', '1H');
  String get chartWin6h => _pick('6H', '6H', '6H', '6H', '6H');
  String get chartWin24h => _pick('24H', '24H', '24H', '24H', '24H');
  String get chartWin7d => _pick('7D', '7D', '7D', '7D', '7D');
  String get chartSeriesAll => _pick('TODAS', 'ALL', 'TODAS', 'TUTTE', 'TOUTES');
  String get chartSeriesSecurity => _pick(
    'Seguridad',
    'Security',
    'Segurança',
    'Sicurezza',
    'Sécurité',
  );
  String get chartSeriesMemory => _pick(
    'RAM libre',
    'Free RAM',
    'RAM livre',
    'RAM libera',
    'RAM libre',
  );
  String get chartSeriesStorage => _pick(
    'Almacenamiento', 
    'Storage', 
    'Armazenamento', 
    'Archiviazione', 
    'Stockage',
  );
  String get chartSeriesApps => _pick(
    'Apps en riesgo',
    'Risky apps',
    'Apps em risco',
    'App a rischio',
    'Apps à risque',
  );
  String get chartSeriesTemp => _pick(
    'Temperatura',
    'Battery temp',
    'Temperatura',
    'Temperatura',
    'Température',
  );
  String get chartSeriesCpu => _pick('CPU', 'CPU', 'CPU', 'CPU', 'CPU');
  String get chartCpuUnavailable => _pick(
    'La carga de CPU no la expone esta plataforma: la serie se omite, no se inventa.',
    'This platform does not expose CPU load: the series is omitted, never faked.',
    'Esta plataforma não expõe a carga da CPU: a série é omitida, nunca inventada.',
    'Questa piattaforma non espone il carico della CPU: la serie è omessa, mai inventata.',
    'Cette plateforme n\'expose pas la charge CPU : la série est omise, jamais inventée.',
  );
  String get chartNoData => _pick(
    'Faltan capturas en este rango.',
    'No captures in this range.',
    'Faltam capturas neste intervalo.',
    'Mancano catture in questo intervallo.',
    'Aucune capture dans cette plage.',
  );
  String get chartTapHint => _pick(
    'Tocá o arrastrá un punto para el detalle',
    'Tap or drag a point for details',
    'Toque ou arraste um ponto para detalhes',
    'Tocca o trascina un punto per i dettagli',
    'Touchez ou faites glisser un point pour les détails',
  );
  String get chartStatMax => _pick('MÁX', 'MAX', 'MÁX', 'MAX', 'MAX');
  String get chartStatMin => _pick('MÍN', 'MIN', 'MÍN', 'MIN', 'MIN');
  String get chartStatAvg => _pick('PROM', 'AVG', 'MÉD', 'MEDIA', 'MOY');
  String get chartVariationLabel => _pick(
    'vs inicial',
    'vs initial',
    'vs inicial',
    'vs iniziale',
    'vs initial',
  );
  String get chartAdvTitle => _pick(
    'Análisis avanzado',
    'Advanced analysis',
    'Análise avançada',
    'Analisi avanzata',
    'Analyse avancée',
  );
  String get chartAdvNeedsHistory => _pick(
    'Hacé al menos 2 capturas para ver el análisis avanzado.',
    'Take at least 2 captures to see the advanced analysis.',
    'Faça pelo menos 2 capturas para ver a análise avançada.',
    'Esegui almeno 2 catture per vedere l’analisi avanzata.',
    'Prenez au moins 2 captures pour voir l’analyse avancée.',
  );
  String get chartAdvScore => _pick(
    'Puntaje de seguridad',
    'Security score',
    'Pontuação de segurança',
    'Punteggio di sicurezza',
    'Score de sécurité',
  );
  String get chartAdvWave => _pick('Onda', 'Wave', 'Onda', 'Onda', 'Onde');
  String get chartAdvArea => _pick('Área', 'Area', 'Área', 'Area', 'Zone');
  String get chartAdvBars => _pick('Barras', 'Bars', 'Barras', 'Barre', 'Barres');
  String get chartAdvScatter => _pick(
    'Dispersión',
    'Scatter',
    'Dispersão',
    'Dispersione',
    'Nuage de points',
  );
  String get chartUnitPct => _pick('%', '%', '%', '%', '%');
  String get chartUnitApps => _pick(
    'apps',
    'apps',
    'apps',
    'app',
    'apps',
  );
  String get chartUnitTemp => _pick('°C', '°C', '°C', '°C', '°C');

  // ── FASE 4: dona interactiva ──
  String get donutStatusTitle => _pick(
    'Estado por área',
    'Status by area',
    'Estado por área',
    'Stato per area',
    'État par zone',
  );
  String get donutCenterTitle => _pick(
    'EQUIPO',
    'DEVICE',
    'EQUIPAMENTO',
    'DISPOSITIVO',
    'APPAREIL',
  );
  String donutCenterHealth(int active) => _pick(
    'SALUD $active/5 sensores',
    'HEALTH $active/5 sensors',
    'SAÚDE $active/5 sensores',
    'SALUTE $active/5 sensori',
    'SANTÉ $active/5 capteurs',
  );
  String donutNareas(int n) => _pick(
    '$n áreas',
    '$n areas',
    '$n áreas',
    '$n aree',
    '$n zones',
  );
  String get donutLegendApps => _pick(
    'Apps en riesgo',
    'Risky apps',
    'Apps em risco',
    'App a rischio',
    'Apps à risque',
  );
  String get donutLegendNetwork => _pick(
    'Red activa',
    'Network active',
    'Rede ativa',
    'Rete attiva',
    'Réseau actif',
  );
  String get donutNetworkOff => _pick(
    'Red inactiva',
    'Network off',
    'Rede inativa',
    'Rete inattiva',
    'Réseau inactif',
  );
  String get donutLegendBattery => _pick(
    'Batería',
    'Battery',
    'Bateria',
    'Batteria',
    'Batterie',
  );
  String get donutLegendStorage => _pick(
    'Almacenamiento libre',
    'Free storage',
    'Armazenamento livre',
    'Archiviazione libera',
    'Stockage libre',
  );

  // ── FASE 6 · NEXORA PLAY ────────────────────────────────────────────

  String get playTitle => _pick(
    'NEXORA PLAY',
    'NEXORA PLAY',
    'NEXORA PLAY',
    'NEXORA PLAY',
    'NEXORA PLAY',
  );
  String get playSubtitle => _pick(
    'Entrena tu ojo cibernético con juegos sin conexión',
    'Sharpen your cyber eye with offline games',
    'Afie seu olhar cibernético com jogos offline',
    'Affina il tuo occhio informatico con giochi offline',
    'Aiguisez votre œil cyber avec des jeux hors ligne',
  );
  String get playPrivate => _pick(
    '100% local: nada sale del dispositivo',
    '100% local: nothing leaves your device',
    '100% local: nada sai do dispositivo',
    '100% locale: nulla esce dal dispositivo',
    '100% local : rien ne sort de l\'appareil',
  );
  String get playGamesTitle => _pick(
    'Juegos',
    'Games',
    'Jogos',
    'Giochi',
    'Jeux',
  );
  String get playScoresTitle => _pick(
    'Mejores puntajes',
    'Best scores',
    'Melhores pontuações',
    'Migliori punteggi',
    'Meilleurs scores',
  );
  String get playNoScores => _pick(
    'Aún no jugaste',
    'No games yet',
    'Você ainda não jogou',
    'Ancora nessuna partita',
    'Aucune partie encore',
  );
  String get playBest => _pick('Mejor', 'Best', 'Melhor', 'Migliore', 'Meilleur');
  String get playLast => _pick('Última', 'Last', 'Última', 'Ultima', 'Dernière');
  String get playOpen => _pick('Jugar', 'Play', 'Jogar', 'Gioca', 'Jouer');
  String get playScoreUnit => _pick('pts', 'pts', 'pts', 'pts', 'pts');
  String get playAchievementsTitle => _pick(
    'Logros',
    'Achievements',
    'Conquistas',
    'Obiettivi',
    'Succès',
  );
  String get playAchievementsUnlocked => _pick(
    'desbloqueados',
    'unlocked',
    'desbloqueados',
    'sbloccati',
    'débloqués',
  );
  String get playLockedBadge => _pick(
    'Bloqueado',
    'Locked',
    'Bloqueado',
    'Bloccato',
    'Verrouillé',
  );

  // ── Catálogo de juegos ──────────────────────────────────────────────

  String get gmMines => _pick(
    'Cyber Minesweeper',
    'Cyber Minesweeper',
    'Cyber Minesweeper',
    'Cyber Minesweeper',
    'Cyber Minesweeper',
  );
  String get gmMinesTag => _pick(
    'Despejá el campo minado sin pisar minas',
    'Clear the minefield without stepping on mines',
    'Limpe o campo minado sem pisar em minas',
    'Libera il campo minato senza toccare mine',
    'Déminnez le terrain sans toucher une mine',
  );
  String get gmChess => _pick(
    'Cyber Chess',
    'Cyber Chess',
    'Cyber Chess',
    'Cyber Chess',
    'Cyber Chess',
  );
  String get gmChessTag => _pick(
    'Ajedrez didáctico contra un rival simple',
    'Didactic chess against a simple rival',
    'Xadrez didático contra um rival simples',
    'Scacchi didattici contro un rivale semplice',
    'Échecs pédagogiques contre un rival simple',
  );
  String get gmFirewall => _pick(
    'Firewall',
    'Firewall',
    'Firewall',
    'Firewall',
    'Firewall',
  );
  String get gmFirewallTag => _pick(
    'Bloqueá los paquetes hostiles antes del núcleo',
    'Block hostile packets before the core',
    'Bloqueie pacotes hostis antes do núcleo',
    'Blocca i pacchetti ostili prima del nucleo',
    'Bloquez les paquets hostiles avant le noyau',
  );
  String get gmPhishing => _pick(
    'Phishing Detector',
    'Phishing Detector',
    'Detector de Phishing',
    'Rilevatore di Phishing',
    'Détecteur de Phishing',
  );
  String get gmPhishingTag => _pick(
    'Aprendé a distinguir un fraude de un mensaje real',
    'Learn to tell a scam from a real message',
    'Aprenda a distinguir fraude de mensagem real',
    'Impara a distinguere una truffa da un messaggio reale',
    'Apprenez à distinguer une fraude d\'un vrai message',
  );

  // ── Común de partida ────────────────────────────────────────────────

  String get gBack => _pick(
    'Volver al hub',
    'Back to hub',
    'Voltar ao hub',
    'Torna all\'hub',
    'Retour au hub',
  );
  String get gScore => _pick('Puntaje', 'Score', 'Pontuação', 'Punteggio', 'Score');
  String get gNewGame => _pick(
    'Nueva partida',
    'New game',
    'Nova partida',
    'Nuova partita',
    'Nouvelle partie',
  );
  String get gWin => _pick('¡Victoria!', 'Victory!', 'Vitória!', 'Vittoria!', 'Victoire !');
  String get gLost => _pick('Perdida', 'Lost', 'Derrota', 'Persa', 'Perdu');

  // ── Cyber Minesweeper ───────────────────────────────────────────────

  String get minesRemaining => _pick(
    'Minas restantes',
    'Mines left',
    'Minas restantes',
    'Mine rimaste',
    'Mines restantes',
  );
  String get minesCleared => _pick(
    'Casillas libres',
    'Safe cells',
    'Células livres',
    'Celle libere',
    'Cellules sûres',
  );
  String get minesExploded => _pick(
    '¡Bum! Pisaste una mina.',
    'Boom! You stepped on a mine.',
    'Boom! Você pisou numa mina.',
    'Boom! Hai calpestato una mina.',
    'Boum ! Vous avez marché sur une mine.',
  );
  String get minesWon => _pick(
    '¡Tablero limpio!',
    'Board cleared!',
    'Tabuleiro limpo!',
    'Campo liberato!',
    'Champ déminé !',
  );
  String get minesModeReveal => _pick(
    'Destapar',
    'Reveal',
    'Revelar',
    'Scopri',
    'Révéler',
  );
  String get minesModeFlag => _pick(
    'Marcar',
    'Flag',
    'Marcar',
    'Bandiera',
    'Drapeau',
  );

  // ── Cyber Chess ─────────────────────────────────────────────────────

  String get chessYouWhite => _pick(
    'Jugás con las blancas',
    'You play White',
    'Você joga com as brancas',
    'Giochi con il Bianco',
    'Vous jouez les Blancs',
  );
  String get chessTurnWhite => _pick(
    'Turno: blancas',
    'Turn: White',
    'Vez: brancas',
    'Turno: Bianco',
    'Tour : Blancs',
  );
  String get chessTurnBlack => _pick(
    'Turno: negras',
    'Turn: Black',
    'Vez: pretas',
    'Turno: Nero',
    'Tour : Noirs',
  );
  String get chessCheck => _pick(
    '¡Jaque!',
    'Check!',
    'Xeque!',
    'Scacco!',
    'Échec !',
  );
  String get chessCheckmate => _pick(
    'Jaque mate',
    'Checkmate',
    'Xeque-mate',
    'Scacco matto',
    'Échec et mat',
  );
  String get chessStalemate => _pick(
    'Ahogado (empate)',
    'Stalemate (draw)',
    'Afogado (empate)',
    'Stallo (patta)',
    'Pat (nulle)',
  );
  String get chessYouWin => _pick(
    '¡Ganaste!',
    'You won!',
    'Você venceu!',
    'Hai vinto!',
    'Vous avez gagné !',
  );
  String get chessYouLose => _pick(
    'El rival te dio jaque mate',
    'You were checkmated',
    'Você sofreu xeque-mate',
    'Hai subito scacco matto',
    'Vous êtes mat',
  );
  String get chessHonest => _pick(
    'Variante didáctica: sin enroque ni en passant; promoción automática a dama; el rival elige una movida legal al azar.',
    'Didactic variant: no castling or en passant; automatic pawn promotion; the rival picks a random legal move.',
    'Variante didática: sem roque nem en passant; promoção automática a dama; o rival escolhe uma jogada legal ao acaso.',
    'Variante didattica: niente arrocco né en passant; promozione automatica a donna; il rivale sceglie una mossa legale a caso.',
    'Variante pédagogique : pas de roque ni de en passant ; promotion automatique en dame ; le rival joue une coudée légale au hasard.',
  );
  String get chessYourCaptures => _pick(
    'Tus capturas',
    'Your captures',
    'Suas capturas',
    'I tuoi pezzi catturati',
    'Vos pièces capturées',
  );
  String get chessRivalCaptures => _pick(
    'Capturas rival',
    'Rival captures',
    'Capturas do rival',
    'Pezzi del rivale',
    'Pièces du rival',
  );

  // ── Firewall ────────────────────────────────────────────────────────

  String get fwBlcked => _pick(
    'Bloqueados',
    'Blocked',
    'Bloqueados',
    'Bloccati',
    'Bloqués',
  );
  String get fwLives => _pick(
    'Escudos',
    'Shields',
    'Escudos',
    'Scudi',
    'Boucliers',
  );
  String get fwWave => _pick('Ola', 'Wave', 'Onda', 'Onda', 'Vague');
  String get fwGameOver => _pick(
    'El núcleo quedó expuesto: paquetes sin bloquear llegaron al final.',
    'The core was exposed: unblocked packets reached the end.',
    'O núcleo ficou exposto: pacotes não bloqueados chegaram ao fim.',
    'Il nucleo è rimasto esposto: pacchetti non bloccati sono arrivati in fondo.',
    'Le noyau est exposé : des paquets non bloqués sont arrivés au bout.',
  );
  String get fwHint => _pick(
    'Tocá un paquete hostil para bloquearlo antes de que llegue al núcleo.',
    'Tap a hostile packet to block it before it reaches the core.',
    'Toque um pacote hostil para bloqueá-lo antes de chegar ao núcleo.',
    'Tocca un pacchetto ostile per bloccarlo prima che arrivi al nucleo.',
    'Touchez un paquet hostile pour le bloquer avant le noyau.',
  );

  // ── Phishing Detector ───────────────────────────────────────────────

  String get phLegit => _pick(
    'Legítimo',
    'Legitimate',
    'Legítimo',
    'Legittimo',
    'Légitime',
  );
  String get phFraud => _pick(
    'Fraude',
    'Fraud',
    'Fraude',
    'Frode',
    'Fraude',
  );
  String get phCorrect => _pick(
    'Correcto',
    'Correct',
    'Correto',
    'Corretto',
    'Correct',
  );
  String get phWasLegit => _pick(
    'Era legítimo',
    'It was legitimate',
    'Era legítimo',
    'Era legittimo',
    'C\'était légitime',
  );
  String get phWasFraud => _pick(
    'Era fraude',
    'It was fraud',
    'Era fraude',
    'Era frode',
    'C\'était une fraude',
  );
  String get phSender => _pick(
    'Remitente',
    'Sender',
    'Remetente',
    'Mittente',
    'Expéditeur',
  );
  String get phAction => _pick(
    'Contenido',
    'Content',
    'Conteúdo',
    'Contenuto',
    'Contenu',
  );
  String get phCaseOf => _pick(
    'Mensaje',
    'Message',
    'Mensagem',
    'Messaggio',
    'Message',
  );
  String get phPerfect => _pick(
    '¡Perfecto!',
    'Perfect!',
    'Perfeito!',
    'Perfetto!',
    'Parfait !',
  );
  String get phResultLine => _pick(
    'acertaste',
    'you got right',
    'você acertou',
    'ne hai azzeccati',
    'bonnes réponses',
  );
  String get phRemainingOne => _pick(
    'restante',
    'left',
    'restante',
    'rimasto',
    'restant',
  );
  String get phHonest => _pick(
    'Casos generados localmente para practicar: ningún correo real sale de tu dispositivo.',
    'Cases generated locally for practice: no real email ever leaves your device.',
    'Casos gerados localmente para praticar: nenhum e-mail real sai do seu dispositivo.',
    'Casi generati localmente per esercitarsi: nessuna email reale lascia il dispositivo.',
    'Cas générés localement pour s\'entraîner : aucun vrai e-mail ne quitte l\'appareil.',
  );

  // ── Logros ──────────────────────────────────────────────────────────

  String achName(String id) {
    switch (id) {
      case 'first_capture':
        return _pick('Primera captura', 'First capture', 'Primeira captura', 'Prima cattura', 'Première capture');
      case 'captures_5':
        return _pick('Cinco capturas', 'Five captures', 'Cinco capturas', 'Cinque catture', 'Cinq captures');
      case 'first_signal':
        return _pick('Señal detectada', 'Signal detected', 'Sinal detectado', 'Segnale rilevato', 'Signal détecté');
      case 'score_100':
        return _pick('Centenar', 'Century', 'Centenário', 'Centinaio', 'Centaine');
      case 'mines_win':
        return _pick('Limpia minas', 'Mine sweeper', 'Caça-minas', 'Spazza mine', 'Démineur');
      case 'chess_win':
        return _pick('Estratega', 'Strategist', 'Estrategista', 'Stratega', 'Stratège');
      case 'firewall_win':
        return _pick('Muro', 'Wall', 'Muro', 'Muro', 'Mur');
      case 'phishing_all':
        return _pick('Ojo infalible', 'Unfailing eye', 'Olho infalível', 'Occhio infallibile', 'Œil infaillible');
    }
    return id;
  }

  String achDesc(String id) {
    switch (id) {
      case 'first_capture':
        return _pick('Registraste tu primera captura.', 'You recorded your first capture.', 'Você registrou sua primeira captura.', 'Hai registrato la tua prima cattura.', 'Vous avez enregistré votre première capture.');
      case 'captures_5':
        return _pick('Cinco capturas en tu historial.', 'Five captures in your history.', 'Cinco capturas no seu histórico.', 'Cinque catture nella cronologia.', 'Cinq captures dans votre historique.');
      case 'first_signal':
        return _pick('Apareció el primer hallazgo de riesgo.', 'Your first risk finding appeared.', 'Seu primeiro achado de risco apareceu.', 'È apparso il primo avviso di rischio.', 'Votre premier signalement de risque est apparu.');
      case 'score_100':
        return _pick('Alcanzaste 100 puntos en un juego.', 'You reached 100 points in a game.', 'Você atingiu 100 pontos em um jogo.', 'Hai raggiunto 100 punti in un gioco.', 'Vous avez atteint 100 points dans un jeu.');
      case 'mines_win':
        return _pick('Limpaste el tablero sin explotar.', 'You cleared the board without exploding.', 'Você limpou o tabuleiro sem explodir.', 'Hai liberato il campo senza esplodere.', 'Vous avez déminé le champ sans exploser.');
      case 'chess_win':
        return _pick('Ganaste una partida de ajedrez.', 'You won a chess game.', 'Você venceu uma partida de xadrez.', 'Hai vinto una partita a scacchi.', 'Vous avez gagné une partie d\'échecs.');
      case 'firewall_win':
        return _pick('Bloqueaste 50 paquetes hostiles.', 'You blocked 50 hostile packets.', 'Você bloqueou 50 pacotes hostis.', 'Hai bloccato 50 pacchetti ostili.', 'Vous avez bloqué 50 paquets hostiles.');
      case 'phishing_all':
        return _pick('Identificaste todos los mensajes.', 'You identified every message.', 'Você identificou todas as mensagens.', 'Hai identificato tutti i messaggi.', 'Vous avez identifié chaque message.');
    }
    return id;
  }

  String get achLockedText => _pick(
    'Se desbloquea con un hecho real',
    'Unlocks with a real fact',
    'Desbloqueia com um fato real',
    'Si sblocca con un fatto reale',
    'Se débloque avec un vrai fait',
  );

  // ── Casos de Phishing (texto por idioma) ────────────────────────────
  // Orden y veredicto viven en `lib/core/games/phishing_cases.dart`.

  List<(int, String, String)> get phishingCaseLines => [
    // (id, sender, action) — el veredicto lo da el catálogo puro.
    (1, _pick('Seguridad Bancaria', 'Banking Security', 'Segurança Bancária', 'Sicurezza Bancaria', 'Sécurité bancaire'), _pick('Verificación urgente: hacé clic para confirmar tu cuenta.', 'Urgent verification: click to confirm your account.', 'Verificação urgente: clique para confirmar sua conta.', 'Verifica urgente: fai clic per confermare il conto.', 'Vérification urgente : cliquez pour confirmer votre compte.')),
    (2, _pick('Stream Movies', 'Stream Movies', 'Stream Movies', 'Stream Movies', 'Stream Movies'), _pick('Tu resumen de abril: plan estándar.', 'Your April summary: standard plan.', 'Seu resumo de abril: plano padrão.', 'Il tuo riepilogo di aprile: piano standard.', 'Votre récapitulatif d\'avril : forfait standard.')),
    (3, _pick('Lotería Nacional', 'National Lottery', 'Loteria Nacional', 'Lotteria Nazionale', 'Loterie Nationale'), _pick('¡Premio no reclamado! Entrá a este enlace para cobrarlo hoy.', 'Unclaimed prize! Open this link to claim it today.', 'Prêmio não reclamado! Entre neste link para recebê-lo hoje.', 'Premio non reclamato! Apri questo link per ritirarlo oggi.', 'Prix non réclamé ! Ouvrez ce lien pour l\'encaisser aujourd\'hui.')),
    (4, _pick('SeguridadByte', 'SeguridadByte', 'SeguridadByte', 'SeguridadByte', 'SeguridadByte'), _pick('Restablecé tu contraseña: el enlace vence en 24 h.', 'Reset your password: the link expires in 24 h.', 'Redefina sua senha: o link expira em 24 h.', 'Reimposta la password: il link scade tra 24 h.', 'Réinitialisez votre mot de passe : le lien expire dans 24 h.')),
    (5, _pick('CineCity', 'CineCity', 'CineCity', 'CineCity', 'CineCity'), _pick('Tus entradas están listas: revisá el código QR del mensaje.', 'Your tickets are ready: check the QR code in the message.', 'Seus ingressos estão prontos: confira o QR code da mensagem.', 'I tuoi biglietti sono pronti: controlla il QR code del messaggio.', 'Vos billets sont prêts : vérifiez le QR code du message.')),
    (6, _pick('FacturaRed', 'InvoiceNet', 'FaturaNet', 'FatturaNet', 'FactureNet'), _pick('Factura vencida: descargá el PDF adjunto para pagar.', 'Overdue invoice: download the attached PDF to pay.', 'Fatura vencida: baixe o PDF anexo para pagar.', 'Fattura scaduta: scarica il PDF allegato per pagare.', 'Facture en retard : téléchargez le PDF joint pour payer.')),
  ];

  // ── FASE 8: contraseñas fuertes y verificación humana ────────────────
  String get authPwdReqTitle => _pick(
    'Requisitos de la contraseña',
    'Password requirements',
    'Requisitos da senha',
    'Requisiti della password',
    'Exigences du mot de passe',
  );
  String get pwdReqLength => _pick(
    '8 caracteres o más',
    '8 characters or more',
    '8 caracteres ou mais',
    '8 caratteri o più',
    '8 caractères ou plus',
  );
  String get pwdReqUpper => _pick(
    'Al menos una mayúscula',
    'At least one uppercase letter',
    'Pelo menos uma maiúscula',
    'Almeno una maiuscola',
    'Au moins une majuscule',
  );
  String get pwdReqLower => _pick(
    'Al menos una minúscula',
    'At least one lowercase letter',
    'Pelo menos uma minúscula',
    'Almeno una minuscola',
    'Au moins une minuscule',
  );
  String get pwdReqDigit => _pick(
    'Al menos un número',
    'At least one number',
    'Pelo menos um número',
    'Almeno un numero',
    'Au moins un chiffre',
  );
  String get authHumanTitle => _pick(
    'Verificación humana',
    'Human verification',
    'Verificação humana',
    'Verifica umana',
    'Vérification humaine',
  );
  String get authHumanDesc => _pick(
    'Confirmá que sos una persona para continuar.',
    'Confirm you are a person to continue.',
    'Confirme que você é uma pessoa para continuar.',
    'Conferma di essere una persona per continuare.',
    'Confirmez que vous êtes une personne pour continuer.',
  );
  String get authHumanCheckbox => _pick(
    'No soy un robot',
    'I am not a robot',
    'Não sou um robô',
    'Non sono un robot',
    'Je ne suis pas un robot',
  );
  String get authHumanVerified => _pick(
    'Verificado',
    'Verified',
    'Verificado',
    'Verificato',
    'Vérifié',
  );
  String get authHumanError => _pick(
    'Completá la verificación humana para continuar.',
    'Complete the human verification to continue.',
    'Complete a verificação humana para continuar.',
    'Completa la verifica umana per continuare.',
    'Terminez la vérification humaine pour continuer.',
  );

  // ── FASE 8: escala de colores de la esfera ───────────────────────────
  String get donutScaleTitle => _pick(
    'Qué significa el color',
    'What the color means',
    'O que a cor significa',
    'Cosa significa il colore',
    'Ce que signifie la couleur',
  );
  String get donutScaleIntro => _pick(
    'El color del círculo central indica la salud agregada de este equipo.',
    'The center circle color shows the overall health of this device.',
    'A cor do círculo central indica a saúde geral deste dispositivo.',
    'Il colore del cerchio centrale indica la salute complessiva del dispositivo.',
    'La couleur du cercle central indique la santé globale de l’appareil.',
  );
  String get donutScaleGood => _pick(
    'Verde — estado óptimo (80 % o más).',
    'Green — optimal state (80 % or more).',
    'Verde — estado ótimo (80 % ou mais).',
    'Verde — stato ottimale (80 % o più).',
    'Vert — état optimal (80 % ou plus).',
  );
  String get donutScaleFair => _pick(
    'Ámbar — atención (60 % a 79 %).',
    'Amber — attention (60 % to 79 %).',
    'Âmbar — atenção (60 % a 79 %).',
    'Ambra — attenzione (dal 60 % al 79 %).',
    'Ambre — à surveiller (60 % à 79 %).',
  );
  String get donutScaleWarn => _pick(
    'Naranja — sospechoso (40 % a 59 %).',
    'Orange — suspicious (40 % to 59 %).',
    'Laranja — suspeito (40 % a 59 %).',
    'Arancione — sospetto (dal 40 % al 59 %).',
    'Orange — suspect (40 % à 59 %).',
  );
  String get donutScaleBad => _pick(
    'Rojo — crítico (menos del 40 %).',
    'Red — critical (below 40 %).',
    'Vermelho — crítico (menos de 40 %).',
    'Rosso — critico (sotto il 40 %).',
    'Rouge — critique (moins de 40 %).',
  );
  String get donutCenterHint => _pick(
    'Tocá el círculo para ver esta escala.',
    'Tap the circle to see this scale.',
    'Toque o círculo para ver esta escala.',
    'Tocca il cerchio per vedere questa scala.',
    'Touchez le cercle pour voir cette échelle.',
  );
  String donutScaleSensors(int active) => _pick(
    'Basado en $active de 5 sensores.',
    'Based on $active of 5 sensors.',
    'Com base em $active de 5 sensores.',
    'Basato su $active di 5 sensori.',
    'Basé sur $active des 5 capteurs.',
  );

  // ── FASE 8: almacenamiento interactivo ───────────────────────────────
  String get storageCriticalTitle => _pick(
    'ALMACENAMIENTO CRÍTICO',
    'CRITICAL STORAGE',
    'ARMAZENAMENTO CRÍTICO',
    'ARCHIVIAZIONE CRITICA',
    'STOCKAGE CRITIQUE',
  );
  String get storageCriticalBody => _pick(
    'Queda menos del 10 % de espacio libre: revisá tus archivos y videos y liberá espacio.',
    'Less than 10 % free space left: review your files and videos and free up space.',
    'Menos de 10 % de espaço livre: revise seus arquivos e vídeos e libere espaço.',
    'Meno del 10 % di spazio libero: controlla file e video e libera spazio.',
    'Moins de 10 % d’espace libre : vérifiez vos fichiers et vidéos et libérez de l’espace.',
  );
  String get storageFreeDesc => _pick(
    'Espacio disponible en este dispositivo.',
    'Space available on this device.',
    'Espaço disponível neste dispositivo.',
    'Spazio disponibile sul dispositivo.',
    'Espace disponible sur l’appareil.',
  );
  String get storageUsedDesc => _pick(
    'Espacio ocupado por apps, fotos, música y documentos.',
    'Space used by apps, photos, music and documents.',
    'Espaço ocupado por apps, fotos, músicas e documentos.',
    'Spazio occupato da app, foto, musica e documenti.',
    'Espace occupé par les apps, photos, musique et documents.',
  );
  String get storageCacheDesc => _pick(
    'Caché propia de NEXORA GUARD. Android e iOS no permiten leer la caché de otras apps.',
    'NEXORA GUARD’s own cache. Android and iOS do not allow reading other apps’ caches.',
    'Cache próprio do NEXORA GUARD. Android e iOS não permitem ler o cache de outros apps.',
    'Cache di NEXORA GUARD. Android e iOS non permettono di leggere la cache di altre app.',
    'Cache propre de NEXORA GUARD. Android et iOS n’autorisent pas la lecture du cache des autres apps.',
  );
  String get storageTapHint => _pick(
    'Tocá un segmento para ver su detalle.',
    'Tap a segment to see its detail.',
    'Toque um segmento para ver o detalhe.',
    'Tocca un segmento per vedere il dettaglio.',
    'Touchez un segment pour voir son détail.',
  );

  // ── FASE 8: detalle de alertas ───────────────────────────────────────
  String get alertDetailTitle => _pick(
    'Detalle de la alerta',
    'Alert detail',
    'Detalhe da alerta',
    'Dettaglio dell’avviso',
    'Détail de l’alerte',
  );
  String get alertDetailLevel => _pick(
    'Nivel',
    'Level',
    'Nível',
    'Livello',
    'Niveau',
  );
  String get alertDetailWhat => _pick(
    '¿Qué ocurrió?',
    'What happened?',
    'O que aconteceu?',
    'Cosa è successo?',
    'Que s’est-il passé ?',
  );
  String get alertDetailMeans => _pick(
    '¿Qué significa?',
    'What does it mean?',
    'O que isso significa?',
    'Cosa significa?',
    'Qu’est-ce que cela signifie ?',
  );
  String get alertDetailDo => _pick(
    '¿Qué podés hacer?',
    'What can you do?',
    'O que você pode fazer?',
    'Cosa puoi fare?',
    'Que pouvez-vous faire ?',
  );
  String get alertDetailHint => _pick(
    'Tocá cada hallazgo para verlo completo.',
    'Tap any finding to see it in full.',
    'Toque cada achado para vê-lo completo.',
    'Tocca ogni avviso per vederlo per intero.',
    'Touchez chaque signalement pour le voir en entier.',
  );

  // ── FASE 8: Aplicaciones en Protección ───────────────────────────────
  String get protectionAppsTitle => _pick(
    'Aplicaciones',
    'Applications',
    'Aplicativos',
    'Applicazioni',
    'Applications',
  );
  String get protectionAppsHint => _pick(
    'Permisos y riesgo de cada app instalada. Tocá una para ver el detalle y abrir su configuración real.',
    'Permissions and risk for every installed app. Tap one to see the detail and open its real settings.',
    'Permissões e risco de cada app instalada. Toque uma para ver o detalhe e abrir suas configurações reais.',
    'Permessi e rischio di ogni app installata. Tocca una per vedere il dettaglio e aprire le sue impostazioni reali.',
    'Autorisations et risque de chaque app installée. Touchez-en une pour voir le détail et ouvrir ses réglages réels.',
  );
  String get protectionAppsNone => _pick(
    'Todavía no hay datos de aplicaciones: analizá el equipo.',
    'No app data yet: run a scan.',
    'Ainda não há dados de aplicativos: faça uma análise.',
    'Ancora nessun dato sulle app: esegui un’analisi.',
    'Aucune donnée d’app pour l’instant : lancez une analyse.',
  );

  // ── FASE 8: Ajustes ──────────────────────────────────────────────────
  String get settingsAccount => _pick(
    'Cuenta',
    'Account',
    'Conta',
    'Account',
    'Compte',
  );
  String get settingsSecurity => _pick(
    'Seguridad',
    'Security',
    'Segurança',
    'Sicurezza',
    'Sécurité',
  );
  String get settingsAppGroup => _pick(
    'Aplicación',
    'Application',
    'Aplicativo',
    'Applicazione',
    'Application',
  );
  String get settingsAccountEmail => _pick(
    'Correo de la cuenta local',
    'Local account email',
    'E-mail da conta local',
    'Email dell’account locale',
    'E-mail du compte local',
  );
  String get settingsChangePassword => _pick(
    'Cambiar contraseña',
    'Change password',
    'Alterar senha',
    'Cambia password',
    'Changer le mot de passe',
  );
  String get settingsLogout => _pick(
    'Cerrar sesión',
    'Sign out',
    'Sair',
    'Esci',
    'Se déconnecter',
  );
  String get settingsNotifications => _pick(
    'Notificaciones',
    'Notifications',
    'Notificações',
    'Notifiche',
    'Notifications',
  );
  String get settingsNotificationsDesc => _pick(
    'Centro de avisos y permiso de sistema.',
    'Notice center and system permission.',
    'Central de avisos e permissão do sistema.',
    'Centro avvisi e permesso di sistema.',
    'Centre d’avis et permission système.',
  );
  String get settingsPermissionsApps => _pick(
    'Permisos de las apps',
    'App permissions',
    'Permissões dos apps',
    'Permessi delle app',
    'Autorisations des apps',
  );
  String get settingsPermissionsAppsDesc => _pick(
    'Qué solicita cada app en este equipo.',
    'What each app asks for on this device.',
    'O que cada app solicita neste dispositivo.',
    'Cosa chiede ogni app su questo dispositivo.',
    'Ce que chaque app demande sur cet appareil.',
  );
  String get settingsProtectionRow => _pick(
    'Protección',
    'Protection',
    'Proteção',
    'Protezione',
    'Protection',
  );
  String get settingsProtectionRowDesc => _pick(
    'Red, VPN y hallazgos actuales.',
    'Network, VPN and current findings.',
    'Rede, VPN e achados atuais.',
    'Rete, VPN e avvisi attuali.',
    'Réseau, VPN et signalements actuels.',
  );
  String get settingsAboutRow => _pick(
    'Acerca de',
    'About',
    'Sobre',
    'Informazioni',
    'À propos',
  );
  String get settingsAboutRowDesc => _pick(
    'Versión, autor y licencia.',
    'Version, author and license.',
    'Versão, autor e licença.',
    'Versione, autore e licenza.',
    'Version, auteur et licence.',
  );
  String get settingsPrefsRow => _pick(
    'Preferencias',
    'Preferences',
    'Preferências',
    'Preferenze',
    'Préférences',
  );
  String get settingsPrefsRowDesc => _pick(
    'Idioma, captura de fondo y vista.',
    'Language, background capture and view.',
    'Idioma, captura em segundo plano e visualização.',
    'Lingua, acquisizione in background e vista.',
    'Langue, capture en arrière-plan et vue.',
  );
  String get settingsPlanRow => _pick(
    'Plan',
    'Plan',
    'Plano',
    'Piano',
    'Forfait',
  );
  String get settingsPlanRowDesc => _pick(
    'Modo Basic o Professional.',
    'Basic or Professional mode.',
    'Modo Basic ou Professional.',
    'Modalità Basic o Professional.',
    'Mode Basic ou Professionnel.',
  );

  // ── FASE 8: centro de notificaciones ─────────────────────────────────
  String get ncTitle => _pick(
    'Centro de notificaciones',
    'Notification center',
    'Central de notificações',
    'Centro notifiche',
    'Centre de notifications',
  );
  String get ncEmptyTitle => _pick(
    'Todavía no hay notificaciones',
    'No notifications yet',
    'Ainda não há notificações',
    'Ancora nessuna notifica',
    'Aucune notification pour l’instant',
  );
  String get ncEmptyBody => _pick(
    'Cada análisis completado quedará registrado aquí.',
    'Every completed analysis will be recorded here.',
    'Cada análise concluída ficará registrada aqui.',
    'Ogni analisi completata verrà registrata qui.',
    'Chaque analyse terminée sera consignée ici.',
  );
  String get ncMarkAllRead => _pick(
    'Marcar todas como leídas',
    'Mark all as read',
    'Marcar todas como lidas',
    'Segna tutte come lette',
    'Tout marquer comme lu',
  );
  String get ncUnreadCount => _pick(
    'sin leer',
    'unread',
    'não lidas',
    'non lette',
    'non lues',
  );
  String get ncNewLabel => _pick(
    'NUEVA',
    'NEW',
    'NOVA',
    'NUOVA',
    'NOUVELLE',
  );
  String get ncToday => _pick('Hoy', 'Today', 'Hoje', 'Oggi', 'Aujourd’hui');
  String get ncYesterday => _pick(
    'Ayer',
    'Yesterday',
    'Ontem',
    'Ieri',
    'Hier',
  );
  String get ncAnalysisTitle => _pick(
    'Análisis completado',
    'Analysis completed',
    'Análise concluída',
    'Analisi completata',
    'Analyse terminée',
  );
  String ncAnalysisBody(int findings, int score) => _pick(
    '$findings hallazgo(s) · puntaje $score / 100.',
    '$findings finding(s) · score $score / 100.',
    '$findings achado(s) · pontuação $score / 100.',
    '$findings avviso(i) · punteggio $score / 100.',
    '$findings signalement(s) · score $score / 100.',
  );
  String get ncSeveritySafe => _pick(
    'ESTADO NORMAL',
    'NORMAL STATE',
    'ESTADO NORMAL',
    'STATO NORMALE',
    'ÉTAT NORMAL',
  );
  String get ncSeverityWarning => _pick(
    'ATENCIÓN',
    'ATTENTION',
    'ATENÇÃO',
    'ATTENZIONE',
    'ATTENTION',
  );
  String get ncSeverityCritical => _pick(
    'CRÍTICO',
    'CRITICAL',
    'CRÍTICO',
    'CRITICO',
    'CRITIQUE',
  );

  // ── FASE 8: planes en el perfil y paneles ────────────────────────────
  String get profBasicLocked => _pick(
    'Modo Basic: NEXORA GUARD protege tu equipo con todas sus funciones básicas.',
    'Basic mode: NEXORA GUARD protects your device with all its basic features.',
    'Modo Basic: o NEXORA GUARD protege seu dispositivo com todos os recursos básicos.',
    'Modalità Basic: NEXORA GUARD protegge il dispositivo con tutte le funzioni base.',
    'Mode Basic : NEXORA GUARD protège l’appareil avec toutes ses fonctions de base.',
  );
}
