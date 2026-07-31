// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Tienda de Aplicaciones Linyaps Edición Comunitaria';

  @override
  String get recommend => 'Recomendar';

  @override
  String get allApps => 'Todas las Aplicaciones';

  @override
  String get ranking => 'Clasificación';

  @override
  String get myApps => 'Mis Aplicaciones';

  @override
  String get update => 'Actualizar';

  @override
  String get settings => 'Configuración';

  @override
  String get category => 'Categoría';

  @override
  String get office => 'Oficina';

  @override
  String get system => 'Sistema';

  @override
  String get develop => 'Desarrollo';

  @override
  String get entertainment => 'Entretenimiento';

  @override
  String get searchPlaceholder => 'Buscar aplicaciones aquí';

  @override
  String get search => 'Buscar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get linglongRecommend => 'Recomendados de Linyaps';

  @override
  String get loading => 'Cargando...';

  @override
  String get installing => 'Instalando...';

  @override
  String get success => 'Éxito';

  @override
  String get failed => 'Fallido';

  @override
  String get cancel => 'Cancelar';

  @override
  String get noMoreData => 'No hay más datos';

  @override
  String get install => 'Instalar';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get open => 'Abrir';

  @override
  String get update_action => 'Actualizar';

  @override
  String get run => 'Ejecutar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get viewDetail => 'Ver Detalles';

  @override
  String get screenShots => 'Capturas de Pantalla';

  @override
  String get versionSelect => 'Selección de Versión';

  @override
  String get versionNumber => 'Número de Versión';

  @override
  String get appType => 'Tipo de Aplicación';

  @override
  String get channel => 'Canal';

  @override
  String get mode => 'Modo';

  @override
  String get repoSource => 'Fuente del Repositorio';

  @override
  String get fileSize => 'Tamaño del Archivo';

  @override
  String get downloadCount => 'Descargas';

  @override
  String get operation => 'Operación';

  @override
  String get linglongProcess => 'Proceso de Linyaps';

  @override
  String get baseSetting => 'Configuración';

  @override
  String get about => 'Acerca de';

  @override
  String get envMissing => 'Entorno de Linyaps no encontrado';

  @override
  String get envMissingDetail =>
      'Los componentes de Linyaps están desactualizados o no existen. Por favor, instálelos primero.';

  @override
  String get autoInstall => 'Instalación Automática';

  @override
  String get manualInstall => 'Instalación Manual';

  @override
  String get recheck => 'Verificar de Nuevo';

  @override
  String get exitStore => 'Salir';

  @override
  String get errorNetwork => 'Error de conexión de red';

  @override
  String get errorNetworkDetail =>
      'Por favor, verifique su conexión de red e intente de nuevo';

  @override
  String get errorInstallFailed => 'Error de instalación';

  @override
  String get errorUninstallFailed => 'Error de desinstalación';

  @override
  String get errorUpdateFailed => 'Error de actualización';

  @override
  String get errorUnknown => 'Error desconocido';

  @override
  String get retry => 'Reintentar';

  @override
  String get downloading => 'Descargando...';

  @override
  String get downloadComplete => 'Descarga completada';

  @override
  String get installComplete => 'Instalación completada';

  @override
  String get uninstallComplete => 'Desinstalación completada';

  @override
  String get updateComplete => 'Actualización completada';

  @override
  String get noApps => 'No hay aplicaciones disponibles';

  @override
  String get noInstalledApps => 'No hay aplicaciones instaladas';

  @override
  String get noInstalledAppsHint =>
      'Aún no ha instalado ninguna aplicación de Linyaps. Visite la página de recomendados para descubrirlas';

  @override
  String get noUpdateApps => 'No hay actualizaciones disponibles';

  @override
  String get version => 'Versión';

  @override
  String get size => 'Tamaño';

  @override
  String get description => 'Descripción';

  @override
  String get developer => 'Desarrollador';

  @override
  String get confirmDelete => 'Confirmar Eliminación';

  @override
  String get confirmDeleteMessage =>
      '¿Está seguro de que desea eliminar este elemento? Esta acción no se puede deshacer.';

  @override
  String get confirmUninstall => 'Confirmar Desinstalación';

  @override
  String get confirmUninstallMessage =>
      '¿Está seguro de que desea desinstalar esta aplicación?';

  @override
  String get noData => 'Sin datos';

  @override
  String get noDataDescription => 'No hay contenido disponible aquí';

  @override
  String get searchApps => 'Buscar aplicaciones...';

  @override
  String get languageSettings => 'Configuración de Idioma';

  @override
  String get themeSettings => 'Configuración de Tema';

  @override
  String get fontSettings => 'Configuración de Fuente';

  @override
  String get cacheManagement => 'Gestión de Caché';

  @override
  String get storeOptions => 'Opciones de Tienda';

  @override
  String get fontSettingsHint =>
      'La configuración del sistema se usa como valor base. Los ajustes aquí realizados se aplicarán sobre ella.';

  @override
  String get fontSizeAdjustment => 'Tamaño de Fuente';

  @override
  String get fontWeightAdjustmentLabel => 'Grosor de Fuente';

  @override
  String get fontWeightLighter => 'Más Fina';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightBolder => 'Más Gruesa';

  @override
  String fontScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get checkUpdate => 'Buscar Actualizaciones';

  @override
  String currentVersion(String version) {
    return 'Versión actual: $version';
  }

  @override
  String newVersionFound(String tagName, String currentVersion) {
    return 'Nueva versión $tagName encontrada, versión actual $currentVersion';
  }

  @override
  String alreadyLatest(String version) {
    return 'Ya tiene la última versión $version';
  }

  @override
  String get checkingUpdate => 'Buscando actualizaciones...';

  @override
  String get goDownload => 'Ir a Descargar';

  @override
  String get cacheSize => 'Tamaño de Caché';

  @override
  String get startupCheckUpdate => 'Buscar actualizaciones al iniciar';

  @override
  String get startupCheckUpdateDesc =>
      'Verificar si hay nuevas versiones disponibles cada vez que se inicia';

  @override
  String get systemNotifications => 'Notificaciones del sistema';

  @override
  String get systemNotificationsDescription =>
      'Mostrar el resultado en una notificación de escritorio cuando finalice Actualizar Todo';

  @override
  String updateBatchAllSucceededTitle(int count) {
    return '$count aplicaciones actualizadas';
  }

  @override
  String get updateBatchFinishedTitle => 'Actualización por lotes finalizada';

  @override
  String get updateBatchNoSuccessTitle =>
      'No se completaron las actualizaciones';

  @override
  String updateBatchResultSummary(String summary) {
    return 'Resultado: $summary';
  }

  @override
  String get updateBatchResultSeparator => ', ';

  @override
  String updateBatchSucceededCount(int count) {
    return '$count correctas';
  }

  @override
  String updateBatchFailedCount(int count) {
    return '$count fallidas';
  }

  @override
  String updateBatchCancelledCount(int count) {
    return '$count canceladas';
  }

  @override
  String updateBatchInterruptedCount(int count) {
    return '$count interrumpidas';
  }

  @override
  String get updateBatchAppNameSeparator => ', ';

  @override
  String updateBatchUpdatedApps(String names) {
    return 'Actualizadas: $names';
  }

  @override
  String updateBatchUpdatedAppsOverflow(String names, int remainingCount) {
    return 'Actualizadas: $names y $remainingCount más';
  }

  @override
  String get softwareRendering => 'Renderizado por Software';

  @override
  String get softwareRenderingEnabled => 'Renderizado por Software';

  @override
  String get hardwareRenderingEnabled => 'Renderizado por Hardware';

  @override
  String get rendererModeDetecting => 'Detectando estado de renderizado...';

  @override
  String get rendererModeDetectFailed =>
      'No se pudo obtener el estado de renderizado actual, pero puede guardar la configuración para el próximo inicio.';

  @override
  String rendererModeCurrentStatus(Object mode, Object reason) {
    return 'Uso actual: $mode. $reason';
  }

  @override
  String rendererModeReasonEnvironment(Object value) {
    return 'El modo de renderizado actual está controlado por la variable de entorno $value.';
  }

  @override
  String get rendererModeReasonUserPreference =>
      'Se está aplicando la configuración guardada.';

  @override
  String get rendererModeReasonCpuFallback =>
      'Para mejorar la compatibilidad, este dispositivo usa renderizado por software de forma predeterminada.';

  @override
  String get rendererModeReasonDefault =>
      'Este dispositivo usa renderizado por hardware de forma predeterminada.';

  @override
  String rendererModeEnvLocked(Object value) {
    return 'Se detectó la variable de entorno $value. El modo de renderizado actual está controlado por el sistema y no se puede modificar aquí.';
  }

  @override
  String rendererModeNextLaunchStatus(Object mode) {
    return 'Se usará $mode en el próximo inicio.';
  }

  @override
  String get rendererModeWhitelistHint =>
      'Se recomienda mantener el renderizado por software en este dispositivo para una visualización más estable.';

  @override
  String get rendererModeHardwareRiskHint =>
      'Se usará renderizado por hardware en el próximo inicio. Si la interfaz no se muestra correctamente, puede usar el siguiente comando para recuperarla.';

  @override
  String get rendererModeDisableWarningTitle =>
      'Confirmar desactivación del renderizado por software';

  @override
  String get rendererModeDisableWarningMessage =>
      'Al desactivar el renderizado por software, las aplicaciones podrían no mostrarse correctamente. Se recomienda mantener el renderizado por software para una visualización más estable.';

  @override
  String rendererModeDetectedCpu(Object cpu) {
    return 'Procesador detectado: $cpu';
  }

  @override
  String get rendererModeDisableBlackScreenHint =>
      'Si la aplicación no se muestra correctamente después del próximo inicio, ejecute el siguiente comando en la terminal y vuelva a abrir la aplicación.';

  @override
  String get rendererModeDataDirectoryLabel => 'Directorio de Datos';

  @override
  String get rendererModeDeleteCommandLabel => 'Comando de Eliminación';

  @override
  String get rendererModeSaveCommandHint =>
      'Se recomienda copiar y guardar este comando para poder recuperar la aplicación si no se muestra correctamente.';

  @override
  String get rendererModeDisableConfirm => 'Continuar Desactivación';

  @override
  String get rendererModeSavedSoftware =>
      'Cambiado a renderizado por software, surtirá efecto en el próximo inicio.';

  @override
  String get rendererModeSavedHardware =>
      'Cambiado a renderizado por hardware, surtirá efecto en el próximo inicio.';

  @override
  String get rendererModeSaveFailed =>
      'Error al guardar la configuración de renderizado. Por favor, intente de nuevo más tarde.';

  @override
  String get showBaseServices => 'Mostrar Servicios Base del Sistema';

  @override
  String get showBaseServicesDesc =>
      'Mostrar servicios base del sistema en la lista de aplicaciones instaladas';

  @override
  String get cleanDeprecatedServices => 'Limpiar Servicios Base Obsoletos';

  @override
  String get cleanDeprecatedServicesDesc =>
      'Eliminar servicios base que ya no están en uso para liberar espacio en disco';

  @override
  String get checkNewVersion => 'Buscar Nueva Versión';

  @override
  String get feedbackMenu => 'Comentarios';

  @override
  String get officialWebsite => 'Sitio Web Oficial';

  @override
  String get communityExchange => 'Comunidad';

  @override
  String get aboutDevelopers => 'Acerca de los Desarrolladores';

  @override
  String get feedbackTitle => 'Comentarios';

  @override
  String get uploadLog => 'Subir archivo de registro también';

  @override
  String get noPrivacyInfo => 'El registro no contiene información personal';

  @override
  String get submitFeedback => 'Enviar';

  @override
  String get feedbackHint => 'Por favor, describa el problema o su opinión';

  @override
  String get feedbackSuccess => '¡Gracias por sus comentarios!';

  @override
  String get feedbackFailed =>
      'Error al enviar los comentarios. Por favor, intente de nuevo más tarde';

  @override
  String get confirmExit => 'Confirmar Salida';

  @override
  String get exitWithInstalling =>
      'Hay tareas de instalación en curso. ¿Está seguro de que desea salir?';

  @override
  String get exitBtn => 'Salir';

  @override
  String get downloadManager => 'Gestor de Descargas';

  @override
  String ogInstallRequestReceived(String appName) {
    return 'Solicitud de instalación recibida desde el navegador: $appName';
  }

  @override
  String ogInstallEnqueued(String appName) {
    return 'Añadido al gestor de descargas: $appName';
  }

  @override
  String get ogInstallInvalidLink =>
      'No se pudo reconocer el enlace de instalación web, solo se admite og://appId';

  @override
  String get ogInstallEnvironmentUnavailable =>
      'El entorno de ejecución de Linyaps no está disponible. No se puede instalar automáticamente desde el navegador';

  @override
  String ogInstallDuplicate(String appName) {
    return '$appName ya está en el gestor de descargas';
  }

  @override
  String get ogInstallDetailFailed =>
      'No se pudo obtener la información de la aplicación, la instalación no se ha iniciado';

  @override
  String ogInstallDetailFailedWithError(String error) {
    return 'No se pudo obtener la información de la aplicación, la instalación no se ha iniciado: $error';
  }

  @override
  String get clearRecords => 'Borrar Registros';

  @override
  String get noDownloadTasks => 'No hay tareas de descarga';

  @override
  String cannotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String get envCheckPassed =>
      'Instalación completada, verificación de entorno superada';

  @override
  String get envCheckFailed =>
      'Instalación completada, pero el entorno sigue presentando problemas';

  @override
  String launching(String appName) {
    return 'Iniciando $appName...';
  }

  @override
  String launchFailed(String error) {
    return 'Error al iniciar: $error';
  }

  @override
  String copied(String value) {
    return 'Copiado: $value';
  }

  @override
  String get shareLink => 'Compartir';

  @override
  String shareMessage(String name) {
    return 'Mira esta aplicación: \"$name\"';
  }

  @override
  String get linkCopied => 'Enlace copiado, ¡compártelo con tus amigos!';

  @override
  String get shareFailed => 'Error al compartir';

  @override
  String get createDesktopShortcut => 'Crear Acceso Directo en el Escritorio';

  @override
  String get appDetailTitle => 'Detalles de la Aplicación';

  @override
  String get appNotFound => 'No se encontró la información de la aplicación';

  @override
  String get noVersionHistory => 'No hay historial de versiones';

  @override
  String get installedBadge => 'Instalado';

  @override
  String get versionInstallTargetMissing =>
      'No se encontró la versión instalada correspondiente. Por favor, actualice e intente de nuevo';

  @override
  String uninstallFailed(String result) {
    return 'Error de desinstalación: $result';
  }

  @override
  String uninstallSuccess(String name) {
    return '$name ha sido desinstalado';
  }

  @override
  String uninstallError(String error) {
    return 'Excepción durante la desinstalación: $error';
  }

  @override
  String get commandCopied =>
      'Comando copiado al portapapeles, péguelo en la terminal para ejecutarlo';

  @override
  String get copy => 'Copiar';

  @override
  String get copyLog => 'Copiar Registro';

  @override
  String get copySucceeded => 'Copia exitosa';

  @override
  String get copyErrorMessage => 'Copiar mensaje de error';

  @override
  String get skipCheck => 'Omitir Verificación';

  @override
  String get loadFailed => 'Error al cargar';

  @override
  String get shortcutCreated => 'Acceso directo creado';

  @override
  String get appComments => 'Comentarios';

  @override
  String get appCommentsEmpty =>
      'Aún no hay comentarios. ¡Sé el primero en comentar!';

  @override
  String get commentInputHint => 'Comparta su experiencia con esta aplicación';

  @override
  String get submitComment => 'Publicar Comentario';

  @override
  String get commentVersionLabel => 'Versión Asociada';

  @override
  String get anonymousComment => 'Visitante Anónimo';

  @override
  String get commentHelpful => 'Útil';

  @override
  String get commentNotHelpful => 'No Útil';

  @override
  String get commentAnonymousHint =>
      'Comentarios anónimos, ordenados por fecha de publicación';

  @override
  String get commentSubmitSuccess => 'Comentario enviado';

  @override
  String commentSubmitFailed(String error) {
    return 'Error al enviar el comentario: $error';
  }

  @override
  String shortcutCreateFailed(String error) {
    return 'Error al crear: $error';
  }

  @override
  String get envCheckTitle => 'Verificación de Entorno';

  @override
  String get checkingLinglongEnv => 'Verificando entorno de Linyaps...';

  @override
  String get unknownStatus => 'Estado Desconocido';

  @override
  String get llCliVersion => 'Versión de ll-cli';

  @override
  String get notDetected => 'No detectado';

  @override
  String get errorMessage => 'Mensaje de Error';

  @override
  String get repoShowFailureTitle =>
      'Error al ejecutar el comando de lectura del repositorio';

  @override
  String repoShowFailureCommand(String command) {
    return 'Error al ejecutar $command para leer la configuración del repositorio de Linyaps.';
  }

  @override
  String get repoShowFailureReason =>
      'Este comando necesita acceder a la configuración del repositorio a través del servicio del sistema org.deepin.linglong.PackageManager.service. El servicio devuelve error cuando no está ejecutándose.';

  @override
  String get repoShowFailureInstalledQuestion =>
      '¿Ya tiene instalado el entorno de aplicaciones?';

  @override
  String get repoShowFailureRestartHint =>
      'Si ya tiene instalado ll-cli y el entorno de aplicaciones, intente reiniciar el servicio del sistema y verificar de nuevo.';

  @override
  String get restartPackageManagerService =>
      'Intentar reiniciar org.deepin.linglong.PackageManager.service';

  @override
  String get restartingPackageManagerService =>
      'Reiniciando org.deepin.linglong.PackageManager.service...';

  @override
  String get packageManagerServiceRestartPassed =>
      'Servicio reiniciado, verificación de entorno superada';

  @override
  String get packageManagerServiceRestartStillFailed =>
      'Servicio reiniciado, pero el entorno sigue presentando problemas. Consulte el mensaje de error';

  @override
  String packageManagerServiceRestartFailed(String error) {
    return 'Error al reiniciar el servicio: $error';
  }

  @override
  String get installingLinglong => 'Instalando...';

  @override
  String get openInstallLogDirectory => 'Abrir Directorio de Registros';

  @override
  String cannotOpenDirectory(String path) {
    return 'No se pudo abrir el directorio: $path';
  }

  @override
  String get appIntroduction => 'Descripción de la Aplicación';

  @override
  String get collapse => 'Contraer';

  @override
  String get expandAll => 'Expandir Todo';

  @override
  String get packageName => 'Nombre del Paquete';

  @override
  String get architecture => 'Arquitectura';

  @override
  String get channelLabel => 'Canal';

  @override
  String get runtime => 'Tiempo de Ejecución';

  @override
  String get license => 'Licencia';

  @override
  String get homepage => 'Página Principal';

  @override
  String get appInfo => 'Información de la Aplicación';

  @override
  String get versionHistory => 'Historial de Versiones';

  @override
  String get versionListLoadFailed =>
      'Error al cargar la lista de versiones. Por favor, intente de nuevo';

  @override
  String get versionListUpdateFailed =>
      'Error al actualizar la lista de versiones, mostrando el último resultado';

  @override
  String get uninstallApp => 'Desinstalar Aplicación';

  @override
  String uninstallConfirmMessage(String name) {
    return '¿Está seguro de que desea desinstalar $name?\nLos datos de la aplicación se eliminarán. Esta acción no se puede deshacer.';
  }

  @override
  String get noDescription => 'Sin descripción';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get searchNotFound => 'No se encontraron aplicaciones relacionadas';

  @override
  String get searchTryOtherKeywords => 'Intente con otras palabras clave';

  @override
  String get searchInputHint =>
      'Escriba palabras clave en el cuadro de búsqueda superior';

  @override
  String get searchPressEnter => 'Presione Enter para buscar aplicaciones';

  @override
  String searchResultCount(int count) {
    return 'Se encontraron $count resultados';
  }

  @override
  String get searchInstalledApps => 'Buscar aplicaciones instaladas';

  @override
  String get noMatchingApp => 'No se encontró ninguna aplicación coincidente';

  @override
  String noMatchingAppHint(String query) {
    return 'No se encontraron aplicaciones relacionadas con \"$query\"';
  }

  @override
  String updateCount(int count) {
    return '$count aplicaciones se pueden actualizar';
  }

  @override
  String ignoredUpdatesCount(int count) {
    return 'Ignorados ($count)';
  }

  @override
  String get ignoredUpdatesTitle => 'Actualizaciones Ignoradas';

  @override
  String get ignoredUpdatesEmptyTitle => 'No hay aplicaciones ignoradas';

  @override
  String get ignoredUpdatesEmptyDescription =>
      'Desde el menú de más opciones de las aplicaciones actualizables, puede ignorar permanentemente las actualizaciones que no desee.';

  @override
  String get ignoreAppUpdates => 'Ignorar esta actualización';

  @override
  String get restoreUpdateNotifications =>
      'Restaurar Notificaciones de Actualización';

  @override
  String ignoredVersion(String version) {
    return 'Versión al ignorar: $version';
  }

  @override
  String ignoreUpdateSuccess(String appName) {
    return 'Se han ignorado las actualizaciones de $appName. Puede restaurarlas desde \"Ignorados\"';
  }

  @override
  String ignoreUpdateActiveTask(String appName) {
    return '$appName está en la cola de actualizaciones, no se puede ignorar por el momento';
  }

  @override
  String get ignoreUpdateFailed =>
      'Error al guardar la configuración de ignorar actualización. Por favor, intente de nuevo';

  @override
  String get ignoreUpdateInvalidApp =>
      'No se puede ignorar esta aplicación: identificador de aplicación no válido';

  @override
  String restoreUpdateSuccess(String appName) {
    return 'Se han restaurado las notificaciones de actualización de $appName';
  }

  @override
  String get restoreUpdateFailed =>
      'Error al restaurar las notificaciones de actualización. Por favor, intente de nuevo';

  @override
  String get restoreUpdateRefreshFailed =>
      'Notificaciones de actualización restauradas, pero falló la búsqueda de actualizaciones. Puede intentarlo más tarde';

  @override
  String a11yManageIgnoredUpdates(int count) {
    return 'Gestionar actualizaciones ignoradas, $count aplicaciones en total';
  }

  @override
  String a11yIgnoreAppUpdates(String appName) {
    return 'Ignorar actualizaciones de $appName';
  }

  @override
  String a11yUpdateAppMoreActions(String appName) {
    return 'Más acciones de actualización para $appName';
  }

  @override
  String a11yRestoreAppUpdates(String appName) {
    return 'Restaurar notificaciones de actualización de $appName';
  }

  @override
  String a11yIgnoredUpdateItem(String appName, String appId, String version) {
    return '$appName, ID de aplicación $appId, versión al ignorar $version';
  }

  @override
  String get updating => 'Actualizando...';

  @override
  String get updateAll => 'Actualizar Todo';

  @override
  String get updateCheckFailed => 'Error al buscar actualizaciones';

  @override
  String get noUpdate => 'No hay actualizaciones';

  @override
  String get allAppsUpToDate => 'Todas sus aplicaciones están actualizadas';

  @override
  String get noMore => 'No hay más';

  @override
  String get appTitleShort => 'Tienda de Aplicaciones Linyaps';

  @override
  String get detectingEnv => 'Verificando entorno de Linyaps...';

  @override
  String get stepEnvCheck => 'Verificación de Entorno';

  @override
  String get stepAppLoad => 'Carga de Aplicaciones';

  @override
  String get stepUpdateCheck => 'Búsqueda de Actualizaciones';

  @override
  String get stepQueueRecovery => 'Recuperación de Cola';

  @override
  String get launchFailedTitle => 'Error al Iniciar';

  @override
  String get skip => 'Omitir';

  @override
  String get cannotGetVersion => 'No se pudo obtener la información de versión';

  @override
  String newVersionAvailable(String version, String current) {
    return '¡Nueva versión $version disponible!\nVersión actual: $current';
  }

  @override
  String get languageZh => 'Chino';

  @override
  String get languageSelfName => 'Español';

  @override
  String get themeFollowSystem => 'Seguir Sistema';

  @override
  String get themeLight => 'Modo Claro';

  @override
  String get themeDark => 'Modo Oscuro';

  @override
  String get clearingCache => 'Limpiando...';

  @override
  String get clearCache => 'Limpiar Caché';

  @override
  String get clearCacheDesc =>
      'Limpiar la caché puede liberar espacio de almacenamiento, pero se volverán a descargar los iconos de las aplicaciones y algunos datos.';

  @override
  String get clearCacheConfirm => 'Confirmar Limpieza de Caché';

  @override
  String get clearCacheMessage =>
      '¿Está seguro de que desea limpiar toda la caché?';

  @override
  String get cacheCleared => 'Caché limpiada';

  @override
  String get clearCacheFailed => 'Error al limpiar la caché';

  @override
  String get appVersion => 'Versión de la Aplicación';

  @override
  String get appCount => 'Aplicaciones Registradas';

  @override
  String get systemArch => 'Arquitectura del Sistema';

  @override
  String get linglongVersion => 'Versión de Linyaps';

  @override
  String get checkNetwork =>
      'Por favor, verifique su conexión de red e intente de nuevo';

  @override
  String get copyContainerCommand => 'Copiar Comando de Contenedor';

  @override
  String get commandCopiedToClipboard => 'Comando copiado al portapapeles';

  @override
  String get copyAppId => 'Copiar ID de Aplicación';

  @override
  String stopSuccess(String name) {
    return '$name ha sido detenido';
  }

  @override
  String get stopFailed => 'Error al detener';

  @override
  String get processRefreshFailed =>
      'Error al actualizar la lista de procesos...';

  @override
  String get noRunningApps =>
      'No hay aplicaciones de Linyaps en ejecución actualmente';

  @override
  String get notRefreshed => 'Aún no se ha actualizado';

  @override
  String get lastRefresh => 'Última actualización';

  @override
  String get refreshing => 'Actualizando';

  @override
  String get appName => 'Nombre de la Aplicación';

  @override
  String get versionNo => 'Número de Versión';

  @override
  String get source => 'Fuente';

  @override
  String get containerId => 'ID del Contenedor';

  @override
  String get appRunningTitle => 'La Aplicación Está en Ejecución';

  @override
  String get appRunningMessage =>
      'La aplicación está en ejecución. Debe cerrarla antes de poder desinstalarla';

  @override
  String get downgradeConfirm => 'Confirmar Degradación';

  @override
  String get downgradeMessage =>
      'La versión objetivo es inferior a la versión actual. ¿Está seguro de que desea degradar?';

  @override
  String get alreadyInstalledVersion => 'Esta versión ya está instalada';

  @override
  String get waiting => 'En Espera';

  @override
  String get completed => 'Completado';

  @override
  String get remove => 'Eliminar';

  @override
  String get feedbackCategories =>
      'Error de Tienda,Actualización de Aplicación,Fallo de Aplicación';

  @override
  String get feedbackCategory => 'Categoría del Problema';

  @override
  String get overview => 'Resumen';

  @override
  String get overviewHint => 'Describa brevemente el problema';

  @override
  String get detailDescription => 'Descripción Detallada';

  @override
  String get none => 'Ninguno';

  @override
  String get clearSearch => 'Borrar Búsqueda';

  @override
  String get minimize => 'Minimizar';

  @override
  String get restore => 'Restaurar';

  @override
  String get maximize => 'Maximizar';

  @override
  String get close => 'Cerrar';

  @override
  String get goRecommend =>
      'Visite la página de recomendados para descubrirlas';

  @override
  String get processRefreshFailedHint =>
      'Error al actualizar la lista de procesos. Se muestran los datos obtenidos en la última actualización exitosa';

  @override
  String get moreActions => 'Más Acciones';

  @override
  String appRunningUninstallMessage(String name) {
    return '$name está en ejecución actualmente. Debe cerrar todas las instancias antes de desinstalar.\n¿Desea forzar el cierre y desinstalar?';
  }

  @override
  String get forceCloseAndUninstall => 'Forzar Cierre y Desinstalar';

  @override
  String downgradeMessageWithVersion(
    String appName,
    String currentVersion,
    String targetVersion,
  ) {
    return 'Tiene $appName v$currentVersion instalado. Está intentando instalar una versión inferior v$targetVersion.\nLa instalación de una versión inferior podría causar problemas de funcionamiento. ¿Desea continuar?';
  }

  @override
  String get confirmDowngrade => 'Confirmar Degradación';

  @override
  String reinstallMessage(String appName, String version) {
    return '$appName v$version ya está instalado.\n¿Desea reinstalar (se sobrescribirá la instalación actual)?';
  }

  @override
  String get forceReinstall => 'Forzar Reinstalación';

  @override
  String get installingLabel => 'Instalando';

  @override
  String waitingCount(int count) {
    return 'En Espera ($count)';
  }

  @override
  String get detailDescriptionHint =>
      'Describa detalladamente el problema que ha encontrado';

  @override
  String get linglongCommunity => 'Comunidad de Linyaps';

  @override
  String get unknown => 'Desconocido';

  @override
  String get copyPid => 'Copiar PID';

  @override
  String get copyContainerId => 'Copiar ID del Contenedor';

  @override
  String get refreshProcessList => 'Actualizar Lista de Procesos';

  @override
  String get stopProcess => 'Detener Proceso';

  @override
  String get checkUpdateNetworkError =>
      'Error al buscar actualizaciones. Por favor, verifique su conexión de red';

  @override
  String get pruneServiceTitle => 'Limpiar Servicios Base Obsoletos';

  @override
  String get pruneServiceMessage =>
      'Se ejecutará el comando ll-cli prune para eliminar todos los servicios base del sistema que ya no están siendo utilizados por ninguna aplicación.\n\nEsto liberará espacio en disco, pero es posible que se deban descargar elementos de nuevo si otras operaciones están en curso.';

  @override
  String get pruneServiceSuccess => 'Servicios base obsoletos eliminados';

  @override
  String get pruneServiceFailed =>
      'Error al limpiar. Por favor, intente de nuevo más tarde';

  @override
  String get clearCacheHint =>
      'Limpiar la caché puede liberar espacio de almacenamiento, pero podría causar que las aplicaciones deban recargar datos.';

  @override
  String get pruneBaseServiceMessage =>
      'Se ejecutará el comando ll-cli prune para eliminar todos los servicios base del sistema que ya no están siendo utilizados por ninguna aplicación.\n\nEsto liberará espacio en disco, pero es posible que se deban descargar elementos de nuevo si otras operaciones están en curso.';

  @override
  String get clean => 'Limpiar';

  @override
  String get baseServiceCleaned => 'Servicios base obsoletos eliminados';

  @override
  String get cleanFailed =>
      'Error al limpiar. Por favor, intente de nuevo más tarde';

  @override
  String appCountValue(int count) {
    return '$count aplicaciones';
  }

  @override
  String get llCliVersionLabel => 'Versión de ll-cli';

  @override
  String get rankingTabDownload => 'Descargas';

  @override
  String get rankingTabRising => 'Tendencias';

  @override
  String get rankingTabUpdate => 'Actualizaciones';

  @override
  String get rankingTabHot => 'Populares';

  @override
  String get sidebarAllApps => 'Todas';

  @override
  String get sidebarRanking => 'Clasificación';

  @override
  String get installErrorGeneric => 'Error de instalación';

  @override
  String get installErrorTimeout =>
      'Error de instalación: Tiempo de espera agotado';

  @override
  String get installCancelled => 'Instalación cancelada';

  @override
  String get installErrorUnknown => 'Error de instalación: Error desconocido';

  @override
  String get installErrorAppNotFoundRemote =>
      'Error de instalación: Aplicación no encontrada en el repositorio remoto';

  @override
  String get installErrorAppNotFoundLocal =>
      'Error de instalación: Aplicación no encontrada localmente';

  @override
  String get installFailed => 'Error de instalación';

  @override
  String get installErrorAppNotInRemote =>
      'Error de instalación: La aplicación no está disponible de forma remota';

  @override
  String get installErrorSameVersion =>
      'Error de instalación: Ya está instalada la misma versión';

  @override
  String get installErrorDowngrade =>
      'Error de instalación: Se requiere instalación de versión inferior';

  @override
  String get installErrorModuleVersionNotAllowed =>
      'Error de instalación: No se permite especificar versión al instalar módulos';

  @override
  String get installErrorModuleRequiresApp =>
      'Error de instalación: Se debe instalar la aplicación antes de instalar módulos';

  @override
  String get installErrorModuleExists =>
      'Error de instalación: El módulo ya existe';

  @override
  String get installErrorArchMismatch =>
      'Error de instalación: Incompatibilidad de arquitectura';

  @override
  String get installErrorModuleNotInRemote =>
      'Error de instalación: El módulo no está disponible de forma remota';

  @override
  String get installErrorMissingErofs =>
      'Error de instalación: Falta el comando de descompresión erofs';

  @override
  String get installErrorUnsupportedFormat =>
      'Error de instalación: Formato de archivo no compatible';

  @override
  String get installErrorNetwork => 'Error de instalación: Error de red';

  @override
  String get installErrorInvalidRef =>
      'Error de instalación: Referencia no válida';

  @override
  String get installErrorUnknownArch =>
      'Error de instalación: Arquitectura desconocida';

  @override
  String installErrorCode(int code) {
    return 'Error de instalación: Código de error $code';
  }

  @override
  String get installStatusStarting => 'Iniciando instalación';

  @override
  String get installStatusInstallingApp => 'Instalando aplicación';

  @override
  String get installStatusInstallingRuntime => 'Instalando tiempo de ejecución';

  @override
  String get installStatusInstallingBase => 'Instalando paquete base';

  @override
  String get installStatusDownloadingMeta => 'Descargando metadatos';

  @override
  String get installStatusDownloadingFiles => 'Descargando archivos';

  @override
  String get installStatusPostProcessing =>
      'Procesamiento posterior a la instalación';

  @override
  String get installStatusCompleted => 'Instalación completada';

  @override
  String get installStatusProcessing => 'Procesando';

  @override
  String waitingForOperation(String operation) {
    return 'Esperando $operation...';
  }

  @override
  String get operationInstall => 'instalación';

  @override
  String get operationUpdate => 'actualización';

  @override
  String operationPreparing(String operation, String appId) {
    return 'Preparando $operation de $appId...';
  }

  @override
  String operationCancelled(String operation) {
    return '$operation cancelada';
  }

  @override
  String operationCompleted(String operation) {
    return '$operation completada';
  }

  @override
  String operationUnknown(String operation) {
    return 'Estado de $operation desconocido';
  }

  @override
  String operationConfirmFailed(String operation) {
    return 'No se pudo confirmar el resultado de la $operation';
  }

  @override
  String operationTimeout(String operation) {
    return 'Tiempo de espera de $operation agotado';
  }

  @override
  String operationFailed(String operation) {
    return 'Error de $operation';
  }

  @override
  String get taskCrashInterrupted => 'La aplicación falló, tarea interrumpida';

  @override
  String get taskCrashRetryHint =>
      'La aplicación falló durante la ejecución. Por favor, intente de nuevo';

  @override
  String uninstallFailedWithError(String error) {
    return 'Error de desinstalación: $error';
  }

  @override
  String uninstallException(String error) {
    return 'Excepción durante la desinstalación: $error';
  }

  @override
  String stopFailedWithError(String error) {
    return 'Error al terminar: $error';
  }

  @override
  String stopException(String error) {
    return 'Excepción al terminar: $error';
  }

  @override
  String shortcutCreatedWithPath(String path) {
    return 'Acceso directo creado: $path';
  }

  @override
  String shortcutCreateFailedWithError(String error) {
    return 'Error al crear: $error';
  }

  @override
  String pruneFailedWithError(String error) {
    return 'Error al limpiar: $error';
  }

  @override
  String pruneException(String error) {
    return 'Excepción durante la limpieza: $error';
  }

  @override
  String get getVersionFailed => 'Error al obtener la versión';

  @override
  String get llCliNotInstalled => 'll-cli no está instalado';

  @override
  String get uosEnvInstallHint =>
      'Antes de instalar el entorno de Linyaps en el sistema UOS, primero active el modo de desarrollador del sistema y asegúrese de que la cuenta actual pueda obtener permisos de root (Configuración > General > Opciones de Desarrollador > Activar Modo de Desarrollador. En sistemas corporativos, se recomienda consultar con el departamento de TI antes de proceder).';

  @override
  String get uosAppInstallFailureHint =>
      'Si está usando el sistema UOS, confirme que ha activado el modo de desarrollador del sistema (Configuración > General > Opciones de Desarrollador > Activar Modo de Desarrollador. En sistemas corporativos, se recomienda consultar con el departamento de TI antes de proceder).';

  @override
  String get appInfoUnavailable =>
      'No se pudo obtener la información de la aplicación';

  @override
  String shortcutCreateException(String error) {
    return 'Error al crear el acceso directo: $error';
  }

  @override
  String get waitingForInstall => 'Esperando instalación';

  @override
  String get cancelInstall => 'Cancelar Instalación';

  @override
  String get uninstallBlockedTitle => 'No se Puede Desinstalar';

  @override
  String uninstallBlockedMessage(String activeTaskName) {
    return 'Se está instalando/actualizando \"$activeTaskName\" actualmente. Linyaps no admite ejecutar instalación y desinstalación simultáneamente. Espere a que se complete la tarea actual, o cancélela antes de desinstalar.';
  }

  @override
  String get iKnow => 'Entendido';

  @override
  String get viewDownloadManager => 'Ver Gestor de Descargas';

  @override
  String a11ySearchByTag(Object tag) {
    return 'Buscar por etiqueta: $tag';
  }

  @override
  String a11yRemoveSearchTag(Object tag) {
    return 'Eliminar etiqueta de búsqueda: $tag';
  }

  @override
  String a11yInstallApp(Object appName) {
    return 'Instalar $appName';
  }

  @override
  String a11yUpdateApp(Object appName) {
    return 'Actualizar $appName';
  }

  @override
  String a11yOpenApp(Object appName) {
    return 'Abrir $appName';
  }

  @override
  String a11yUninstallApp(Object appName) {
    return 'Desinstalar $appName';
  }

  @override
  String get a11ySearchBox => 'Buscar aplicaciones';

  @override
  String get a11ySearchInputHint => 'Escriba palabras clave para buscar';

  @override
  String get a11yCommentInputHint => 'Escriba su comentario';

  @override
  String get a11ySidebarNav => 'Navegación de barra lateral';

  @override
  String a11yAppCard(Object appName, Object version, Object status) {
    return '$appName, versión $version, $status';
  }

  @override
  String a11yRankingItem(Object rank, Object appName) {
    return 'Posición $rank, $appName';
  }

  @override
  String a11yProcessItem(Object name, Object pid) {
    return 'Proceso $name, PID $pid';
  }

  @override
  String a11yDownloadItem(Object appName, Object percent) {
    return 'Descargando $appName, progreso $percent%';
  }

  @override
  String get a11yRecommendPage => 'Recomendados';

  @override
  String get a11yAllAppsPage => 'Todas las Aplicaciones';

  @override
  String get a11yRankingPage => 'Clasificación';

  @override
  String get a11yMyAppsPage => 'Mis Aplicaciones';

  @override
  String get a11ySettingsPage => 'Configuración';

  @override
  String get a11yAppDetailPage => 'Detalles de la Aplicación';

  @override
  String get a11yScreenshotArea => 'Área de capturas de pantalla';

  @override
  String get a11yCommentSection => 'Sección de comentarios';

  @override
  String get a11yCarouselArea => 'Área de carrusel';

  @override
  String get a11yAppListArea => 'Lista de aplicaciones';

  @override
  String get a11ySidebarArea => 'Barra lateral';

  @override
  String get a11yMinimize => 'Minimizar';

  @override
  String get a11yMaximize => 'Maximizar';

  @override
  String get a11yRestore => 'Restaurar';

  @override
  String get a11yClose => 'Cerrar';

  @override
  String get a11yPrevious => 'Anterior';

  @override
  String get a11yNext => 'Siguiente';

  @override
  String get a11yTabSelected => 'Seleccionado';

  @override
  String get a11yTabNotSelected => 'No seleccionado';

  @override
  String get a11yStatusInstalled => 'Instalado';

  @override
  String get a11yStatusUpdatable => 'Actualizable';

  @override
  String get a11yStatusNotInstalled => 'No instalado';

  @override
  String get noAppsInCategory => 'No hay aplicaciones en esta categoría';

  @override
  String get noRanking => 'No hay clasificación disponible';

  @override
  String get noRecommend => 'No hay recomendaciones disponibles';

  @override
  String get installTimeout =>
      'Tiempo de instalación agotado: Sin actualizaciones de progreso durante un largo período';

  @override
  String get downloadManagerSlowInstallHint =>
      'Si el progreso parece lento, es posible que se estén instalando dependencias necesarias. Por favor, espere un poco más...';

  @override
  String get loadingInstalledApps => 'Cargando aplicaciones instaladas...';

  @override
  String get appDescriptionPlaceholder => 'Descripción de la Aplicación';

  @override
  String get rankingTabNewUpload => 'Últimas Publicaciones';

  @override
  String get rankingTabDownloadCount => 'Más Descargadas';

  @override
  String uploadedXHoursAgo(int count) {
    return 'Publicado hace $count horas';
  }

  @override
  String uploadedXDaysAgo(int count) {
    return 'Publicado hace $count días';
  }

  @override
  String uploadedOnDate(String date) {
    return 'Publicado el $date';
  }

  @override
  String downloadedXTimes(String count) {
    return 'Descargado $count veces';
  }

  @override
  String get envManagementWarning =>
      'Esta función aún está en desarrollo y tiene estabilidad limitada. Solo se recomienda para equipos de prueba. No la utilice en entornos corporativos de producción. Si presenta problemas después de usarla, no intente repetidamente. Le recomendamos registrar los síntomas y buscar ayuda.';

  @override
  String get repoManagementHintTitle =>
      'Solo se ofrece gestión de repositorios';

  @override
  String get repoManagementHintMessage =>
      'Esta tienda solo puede obtener datos de aplicaciones del repositorio oficial stable. No elimine el repositorio stable, ya que esto impedirá la instalación de aplicaciones.';

  @override
  String get envManagementTitle => 'Gestión del Entorno de Linyaps';

  @override
  String get envManagementDescription =>
      'Analizar el entorno, gestionar repositorios, reparar el entorno base y mover la ubicación de almacenamiento';

  @override
  String get envManagementAnalysisTab => 'Entorno';

  @override
  String get envManagementRepositoryTab => 'Repositorios';

  @override
  String get envManagementStorageTab => 'Almacenamiento';

  @override
  String get envManagementAnalyzing => 'Analizando el entorno de Linyaps...';

  @override
  String get envManagementApplying => 'Ejecutando la operación...';

  @override
  String get envManagementNotAnalyzed =>
      'El análisis del entorno aún no ha finalizado';

  @override
  String get envManagementHealthyTitle =>
      'No hay problemas que requieran atención';

  @override
  String get envManagementHealthyMessage =>
      'El entorno base, los repositorios y los datos locales de Linyaps funcionan correctamente.';

  @override
  String get envManagementBaseEnvironment => 'Entorno base';

  @override
  String get envManagementRepositoryMetric => 'Repositorio';

  @override
  String get envManagementLocalData => 'Datos locales';

  @override
  String get envManagementStorageLocation => 'Ubicación de almacenamiento';

  @override
  String get envManagementNotDetected => 'No detectado';

  @override
  String get envManagementUnknown => 'Desconocido';

  @override
  String envManagementUsagePercent(int percent) {
    return '$percent% utilizado';
  }

  @override
  String get envManagementEnvironmentHealthyUpgrade =>
      'Correcto (se recomienda actualizar)';

  @override
  String get envManagementEnvironmentHealthy => 'Correcto';

  @override
  String get envManagementRepositoryReadFailed =>
      'No se pudo leer la configuración del repositorio';

  @override
  String get envManagementEnvironmentAbnormal => 'Problema del entorno';

  @override
  String get envRepoStatusNormal => 'Normal';

  @override
  String get envRepoStatusNotConfigured => 'Sin configurar';

  @override
  String get envRepoStatusMisconfigured => 'Configuración incorrecta';

  @override
  String get envRepoStatusUnavailable => 'No disponible';

  @override
  String get envRepoStatusUnknown => 'Desconocido';

  @override
  String get envLocalDataDetectionFailed => 'Error de comprobación';

  @override
  String get envLocalDataUnavailable => 'No disponibles';

  @override
  String get envLocalDataNormal => 'Normales';

  @override
  String get envIssueLlCliUnavailableTitle => 'll-cli no está disponible';

  @override
  String get envIssueLlCliUnavailableDescription =>
      'No se detectó un entorno de línea de comandos de Linyaps utilizable.';

  @override
  String get envIssueRepositoryNotConfiguredTitle =>
      'No hay un repositorio de Linyaps configurado';

  @override
  String get envIssueRepositoryNotConfiguredDescription =>
      'No hay ningún repositorio de Linyaps utilizable. Añada o repare primero un repositorio.';

  @override
  String get envIssueDataPermissionTitle =>
      'Los permisos del directorio de datos de Linyaps no son válidos';

  @override
  String envIssueDataPermissionDescription(String serviceUser) {
    return 'll-package-manager se ejecuta como $serviceUser, pero el directorio de datos de Linyaps o los archivos de estado importantes tienen un propietario incorrecto. La migración del repositorio, la descarga de objetos o la creación de capas pueden fallar.';
  }

  @override
  String get envIssueLocalDataDetectionTitle =>
      'Falló la comprobación de datos locales de Linyaps';

  @override
  String get envIssueLocalDataDetectionDescription =>
      'No se pudo ejecutar la comprobación de lectura de datos locales de linyaps. Verifique el estado de ll-cli y del servicio package-manager.';

  @override
  String get envIssueLocalDataUnavailableTitle =>
      'Los datos locales de Linyaps no están disponibles';

  @override
  String get envIssueLocalDataUnavailableDescription =>
      'No se pueden leer los datos de las aplicaciones instaladas mediante la ruta de ejecución de linyaps. La lista, instalación o ejecución de aplicaciones pueden verse afectadas. Compruebe los permisos y el entorno base antes de reparar.';

  @override
  String get envIssueStorageSpaceTitle =>
      'Queda poco espacio en la ubicación de Linyaps';

  @override
  String envIssueStorageSpaceDescription(String path, int percent) {
    return 'El sistema de archivos que contiene $path está aproximadamente al $percent%. Libere espacio o mueva la ubicación de almacenamiento.';
  }

  @override
  String get envIssueRunningAppsTitle =>
      'Hay aplicaciones de Linyaps en ejecución';

  @override
  String envIssueRunningAppsDescription(int count) {
    return 'Aún hay $count aplicaciones de Linyaps en ejecución. Ciérrelas antes de mover la ubicación de almacenamiento.';
  }

  @override
  String get envRepairAction => 'Reparar';

  @override
  String get envHandleAction => 'Resolver';

  @override
  String get envRepairLocalDataTitle => 'Reparar los datos locales de Linyaps';

  @override
  String get envRepairLocalDataMessage =>
      'Se intentarán reparar los datos locales de Linyaps con privilegios de administrador. Si es necesario volver a descargar datos de aplicaciones o del entorno base, el proceso puede tardar bastante. ¿Desea continuar?';

  @override
  String get envRepairLocalDataConfirm => 'Ejecutar reparación';

  @override
  String get envRepairPermissionTitle =>
      'Reparar los permisos del directorio de datos de Linyaps';

  @override
  String envRepairPermissionMessage(String rootPath, String serviceUser) {
    return 'Se restaurará con privilegios de administrador el propietario de los directorios y archivos de estado importantes de $rootPath a $serviceUser, y después se reiniciará package-manager. ¿Desea continuar?';
  }

  @override
  String get envRepairPermissionConfirm => 'Reparar permisos';

  @override
  String get envMoveStorageTitle =>
      'Mover la ubicación de almacenamiento de Linyaps';

  @override
  String envMoveStorageMessage(String rootPath, String targetPath) {
    return 'Se copiará $rootPath a $targetPath y se creará un bind mount de systemd. Confirme que el sistema de archivos de destino tiene espacio suficiente.';
  }

  @override
  String get envMoveStorageConfirm => 'Iniciar traslado';

  @override
  String get envAddRepositoryTitle => 'Añadir repositorio de Linyaps';

  @override
  String get envRepositoryName => 'Nombre del repositorio';

  @override
  String get envRepositoryAddress => 'Dirección del repositorio';

  @override
  String get envRepositoryAliasOptional => 'Alias (opcional)';

  @override
  String get envAddAction => 'Añadir';

  @override
  String get envSaveAction => 'Guardar';

  @override
  String get envDeleteAction => 'Eliminar';

  @override
  String envUpdateRepositoryTitle(String name) {
    return 'Editar dirección del repositorio: $name';
  }

  @override
  String envSetPriorityTitle(String name) {
    return 'Establecer prioridad: $name';
  }

  @override
  String get envRepositoryPriority => 'Prioridad';

  @override
  String get envPriorityMustBeNumber => 'La prioridad debe ser un número';

  @override
  String get envRemoveRepositoryTitle => 'Eliminar repositorio';

  @override
  String envRemoveRepositoryMessage(String name) {
    return '¿Desea eliminar el repositorio $name?';
  }

  @override
  String get envRepositoryAdded => 'Repositorio añadido';

  @override
  String envRepositoryAddFailed(String error) {
    return 'No se pudo añadir el repositorio: $error';
  }

  @override
  String get envRepositoryUpdated => 'Repositorio actualizado';

  @override
  String envRepositoryUpdateFailed(String error) {
    return 'No se pudo actualizar el repositorio: $error';
  }

  @override
  String get envPriorityUpdated => 'Prioridad actualizada';

  @override
  String envPriorityUpdateFailed(String error) {
    return 'No se pudo establecer la prioridad: $error';
  }

  @override
  String get envRepositoryRemoved => 'Repositorio eliminado';

  @override
  String envRepositoryRemoveFailed(String error) {
    return 'No se pudo eliminar el repositorio: $error';
  }

  @override
  String get envDefaultRepositoryUpdated =>
      'Repositorio predeterminado actualizado';

  @override
  String envDefaultRepositoryUpdateFailed(String error) {
    return 'No se pudo establecer el repositorio predeterminado: $error';
  }

  @override
  String get envMirrorEnabled => 'Espejo activado';

  @override
  String get envMirrorDisabled => 'Espejo desactivado';

  @override
  String envMirrorUpdateFailed(String error) {
    return 'No se pudo cambiar el estado del espejo: $error';
  }

  @override
  String get envOpenLogDirectoryFailed =>
      'No se pudo abrir la carpeta de registros';

  @override
  String get envRepositoryNotLoaded =>
      'La configuración del repositorio aún no se ha cargado';

  @override
  String envRepositoryDefaultValue(String name) {
    return 'Repositorio predeterminado: $name';
  }

  @override
  String get envNotSet => 'Sin establecer';

  @override
  String get envAddRepository => 'Añadir repositorio';

  @override
  String get envNoRepositories => 'No hay repositorios configurados';

  @override
  String get envDefaultBadge => 'Predeterminado';

  @override
  String envRepositoryDetails(String name, String priority) {
    return 'name=$name  priority=$priority';
  }

  @override
  String get envRepositoryActions => 'Acciones del repositorio';

  @override
  String get envEditAddress => 'Editar dirección';

  @override
  String get envSetDefault => 'Establecer como predeterminado';

  @override
  String get envSetPriority => 'Establecer prioridad';

  @override
  String get envEnableMirror => 'Activar espejo';

  @override
  String get envDisableMirror => 'Desactivar espejo';

  @override
  String get envCurrentStorageLocation => 'Ubicación de almacenamiento actual';

  @override
  String get envStorageNotAnalyzed =>
      'El análisis de la ubicación aún no ha finalizado';

  @override
  String envStorageSummary(String path, int percent) {
    return '$path  $percent% utilizado';
  }

  @override
  String get envNewStorageLocation => 'Nueva ubicación de almacenamiento';

  @override
  String get envStorageMoveMethod => 'Método de traslado';

  @override
  String envStorageMoveMethodDescription(String rootPath) {
    return 'Linyaps no permite cambiar directamente el directorio de instalación. Esta operación copia los datos y crea un bind mount de systemd en $rootPath.';
  }

  @override
  String get envMoveStorageAction => 'Mover ubicación de almacenamiento';

  @override
  String get envCloseAppsBeforeMoveTitle =>
      'Cierre las aplicaciones antes de mover';

  @override
  String envCloseAppsBeforeMoveMessage(int count) {
    return 'Aún hay $count aplicaciones de Linyaps en ejecución.';
  }

  @override
  String get envResultDataPermissionCompleted =>
      'Se repararon los permisos del directorio de datos de Linyaps';

  @override
  String get envResultDataPermissionFailed =>
      'No se pudieron reparar los permisos del directorio de datos de Linyaps';

  @override
  String get envResultLocalDataUnsupported =>
      'Los componentes actuales del sistema no pueden eliminar automáticamente los objetos problemáticos. Actualice los componentes pertinentes o utilice las herramientas de su distribución para reparar los datos locales de Linyaps.';

  @override
  String get envResultLocalDataCompleted =>
      'Se completó la reparación de los datos locales de Linyaps';

  @override
  String get envResultLocalDataCompletedLegacy =>
      'Se completó la reparación de los datos locales de Linyaps usando parámetros de sistemas antiguos';

  @override
  String get envResultLocalDataFailed =>
      'Falló la reparación de los datos locales de Linyaps';

  @override
  String get envResultLocalDataChecksumMismatch =>
      'La verificación todavía encontró objetos con checksum incorrecto después de la limpieza automática. Si reaparecen tras descargar los datos, puede ser necesario corregir el repositorio de origen o la compatibilidad del almacenamiento local de linyaps.';

  @override
  String get envPartialCommitsUnknown => 'algunos partial commits';

  @override
  String envPartialCommitsCount(int count) {
    return '$count partial commits';
  }

  @override
  String envResultLocalDataRepullCompleted(String partialCommits) {
    return 'Se eliminaron los objetos problemáticos, se descargaron de nuevo $partialCommits y la verificación fue correcta.';
  }

  @override
  String envResultLocalDataRepullCompletedLegacy(String partialCommits) {
    return 'Se eliminaron los objetos problemáticos, se descargaron de nuevo $partialCommits y la verificación fue correcta usando parámetros de sistemas antiguos.';
  }

  @override
  String envResultLocalDataRepullFailed(String partialCommits) {
    return 'Se eliminaron los objetos reparables automáticamente y se descargaron de nuevo $partialCommits, pero la verificación siguió fallando. Consulte el registro para identificar el ref que no pudo descargarse o verificarse.';
  }

  @override
  String envResultLocalDataRepullFailedLegacy(String partialCommits) {
    return 'Se eliminaron los objetos reparables automáticamente y se descargaron de nuevo $partialCommits usando parámetros de sistemas antiguos, pero la verificación siguió fallando. Consulte el registro para identificar el ref afectado.';
  }

  @override
  String envResultLocalDataRepullChecksumMismatch(String partialCommits) {
    return 'Se eliminaron los objetos reparables automáticamente y se descargaron de nuevo $partialCommits, pero la verificación siguió encontrando checksum incorrectos. Los datos del repositorio de origen pueden ser incompatibles con el modo de almacenamiento local de linyaps.';
  }

  @override
  String envResultLocalDataRepullChecksumMismatchLegacy(String partialCommits) {
    return 'Se eliminaron los objetos reparables automáticamente y se descargaron de nuevo $partialCommits usando parámetros de sistemas antiguos, pero la verificación siguió encontrando checksum incorrectos. Los datos del repositorio de origen pueden ser incompatibles con el almacenamiento local de linyaps.';
  }

  @override
  String envResultStorageBlockedRunningApps(int count) {
    return 'Aún hay $count aplicaciones de Linyaps en ejecución. Ciérrelas antes de mover la ubicación.';
  }

  @override
  String get envResultStorageBlockedActiveTask =>
      'Hay una instalación o actualización activa en el gestor de descargas. Espere a que termine o cancélela antes de mover la ubicación de Linyaps.';

  @override
  String envResultStorageBlockedNamedTask(String name) {
    return 'Se está procesando $name. Espere a que termine o cancele la tarea antes de mover la ubicación de Linyaps.';
  }

  @override
  String envResultStorageAlreadyBindMounted(String path) {
    return '$path ya es un bind mount. Revise la configuración de montaje existente antes de migrar.';
  }

  @override
  String envResultStorageFilesystemUnavailable(String path) {
    return 'No se pudo leer el espacio del sistema de archivos de destino: $path';
  }

  @override
  String get envResultStorageSpaceUnknown =>
      'No se pudo determinar el espacio disponible del directorio actual o de destino. Compruébelo e inténtelo de nuevo.';

  @override
  String envResultStorageInsufficientSpace(
    String requiredSpace,
    String availableSpace,
  ) {
    return 'La ruta de destino necesita al menos $requiredSpace, pero solo hay $availableSpace disponibles.';
  }

  @override
  String get envResultStorageTargetNotAbsolute =>
      'La ruta de destino debe ser absoluta.';

  @override
  String get envResultStorageTargetContainsLineBreak =>
      'La ruta de destino no puede contener saltos de línea.';

  @override
  String get envResultStorageTargetUnsafeSystemPath =>
      'La ruta de destino no puede ser un directorio raíz del sistema ni el directorio actual de Linyaps.';

  @override
  String get envResultStorageTargetInsideCurrentRoot =>
      'La ruta de destino no puede estar dentro del directorio actual de Linyaps.';

  @override
  String get envResultStorageMoveCompleted =>
      'Se movió la ubicación de almacenamiento de Linyaps';

  @override
  String get envResultStorageMoveFailed =>
      'No se pudo mover la ubicación de almacenamiento de Linyaps';

  @override
  String envResultUnexpectedFailure(String error) {
    return 'La operación falló: $error';
  }

  @override
  String get errorSolutionHelpTooltip => 'Ver solución';

  @override
  String get a11yErrorSolutionHelp =>
      'Consultar la solución para este error de instalación';

  @override
  String get errorSolutionNoSolution => 'No hay solución disponible';

  @override
  String get errorSolutionQueryFailed =>
      'Error en la consulta. Por favor, intente de nuevo';

  @override
  String get errorSolutionRetry => 'Consultar de Nuevo';

  @override
  String get errorSolutionCommunityPost => 'Publicar en la Comunidad';

  @override
  String get errorSolutionRepair => 'Reparación Automática';

  @override
  String get errorSolutionClose => 'Cerrar Solución';

  @override
  String get errorSolutionRemoteImage => 'Imagen remota de la solución';

  @override
  String get errorSolutionImageBlocked => 'Imagen no web bloqueada';

  @override
  String get errorSolutionImageLoadFailed => 'Error al cargar la imagen remota';

  @override
  String get scriptReviewTitle => 'Vista Previa del Script';

  @override
  String get scriptReviewSemanticLabel =>
      'Script de reparación completo que se va a ejecutar';

  @override
  String get executeRepairScript => 'Confirmar y Ejecutar';

  @override
  String get repairExecutionTitle => 'Reparación Automática';

  @override
  String get repairExecuting => 'Ejecutando script de reparación...';

  @override
  String get repairOutputTitle => 'Salida en Tiempo Real';

  @override
  String get repairOutputEmpty => 'Esperando la salida del script...';

  @override
  String repairOutputTruncated(int count) {
    return 'Se omitieron $count líneas anteriores en la interfaz. Para ver el contenido completo, consulte el registro.';
  }

  @override
  String get repairCompleteRetry =>
      'Reparación completada. Por favor, intente instalar de nuevo.';

  @override
  String repairFailedWithExitCode(int exitCode) {
    return 'El script de reparación falló (código de salida $exitCode).';
  }

  @override
  String get repairTimedOut =>
      'El script de reparación se ejecutó durante más de 30 minutos. Se dejó de esperar. Consulte el registro para verificar el estado del sistema.';

  @override
  String repairExecutionError(String message) {
    return 'No se pudo ejecutar el script de reparación: $message';
  }

  @override
  String get repairInvalidSignature =>
      'La firma del script de reparación no es válida. Se bloqueó la ejecución.';

  @override
  String get openRepairLog => 'Abrir Directorio de Registros';

  @override
  String get copyRepairOutput => 'Copiar Salida Actual';

  @override
  String repairElapsedTime(String elapsed) {
    return 'Tiempo transcurrido: $elapsed';
  }
}
