#include "my_application.h"

#include <cstring>
#include <string.h>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* native_theme_channel;
  FlMethodChannel* linux_renderer_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

namespace {

constexpr char kNativeThemeChannel[] = "org.linglong_store/native_theme";
constexpr char kSetContextMenuDarkThemeMethod[] = "setContextMenuDarkTheme";
constexpr char kLinuxRendererChannel[] = "org.linglong_store/linux_renderer";
constexpr char kGetRendererRuntimeStateMethod[] = "getRendererRuntimeState";
constexpr char kRendererConfigSection[] = "renderer";
constexpr char kRendererConfigPreferredModeKey[] = "preferred_mode";
constexpr char kRendererModeSoftware[] = "software";
constexpr char kRendererModeHardware[] = "hardware";
constexpr char kRendererPreferenceAuto[] = "auto";
constexpr char kRendererDecisionEnvironment[] = "environment";
constexpr char kRendererDecisionUserPreference[] = "userPreference";
constexpr char kRendererDecisionCpuFallback[] = "cpuFallback";
constexpr char kRendererDecisionDefault[] = "default";
constexpr char kRendererConfigDirectoryName[] = "startup";
constexpr char kRendererConfigFileName[] = "renderer_preferences.ini";
constexpr const char* kCpuVendorWhitelist[] = {"GenuineIntel", "AuthenticAMD"};
constexpr const char* kCpuModelWhitelistHints[] = {"Intel", "AMD"};

struct RendererStartupState {
  gboolean is_cpu_whitelisted = TRUE;
  gboolean is_environment_locked = FALSE;
  gchar* current_mode = nullptr;
  gchar* decision_source = nullptr;
  gchar* environment_value = nullptr;
  gchar* cpu_vendor = nullptr;
  gchar* cpu_model = nullptr;
};

RendererStartupState g_renderer_startup_state;

void set_state_string(gchar** target, const gchar* value) {
  g_free(*target);
  *target = g_strdup(value == nullptr ? "" : value);
}

void reset_renderer_startup_state() {
  g_renderer_startup_state.is_cpu_whitelisted = TRUE;
  g_renderer_startup_state.is_environment_locked = FALSE;
  set_state_string(&g_renderer_startup_state.current_mode,
                   kRendererModeHardware);
  set_state_string(&g_renderer_startup_state.decision_source,
                   kRendererDecisionDefault);
  set_state_string(&g_renderer_startup_state.environment_value, "");
  set_state_string(&g_renderer_startup_state.cpu_vendor, "");
  set_state_string(&g_renderer_startup_state.cpu_model, "");
}

const gchar* normalize_renderer_mode(const gchar* value) {
  if (value != nullptr && g_ascii_strcasecmp(value, kRendererModeSoftware) == 0) {
    return kRendererModeSoftware;
  }
  return kRendererModeHardware;
}

const gchar* normalize_renderer_preference(const gchar* value) {
  if (value != nullptr && g_ascii_strcasecmp(value, kRendererModeSoftware) == 0) {
    return kRendererModeSoftware;
  }
  if (value != nullptr && g_ascii_strcasecmp(value, kRendererModeHardware) == 0) {
    return kRendererModeHardware;
  }
  return kRendererPreferenceAuto;
}

gchar* trim_value(const gchar* value) {
  if (value == nullptr) {
    return nullptr;
  }

  g_autofree gchar* copy = g_strdup(value);
  g_strstrip(copy);
  return g_strdup(copy);
}

gchar* extract_cpuinfo_value(const gchar* cpuinfo, const gchar* key) {
  if (cpuinfo == nullptr || key == nullptr) {
    return nullptr;
  }

  g_auto(GStrv) lines = g_strsplit(cpuinfo, "\n", -1);
  for (gsize index = 0; lines[index] != nullptr; ++index) {
    const gchar* line = lines[index];
    if (!g_str_has_prefix(line, key)) {
      continue;
    }

    const gchar* colon = strchr(line, ':');
    if (colon == nullptr) {
      continue;
    }

    return trim_value(colon + 1);
  }

  return nullptr;
}

gboolean contains_ascii_case_insensitive(const gchar* haystack,
                                         const gchar* needle) {
  if (haystack == nullptr || needle == nullptr) {
    return FALSE;
  }

  g_autofree gchar* lowered_haystack = g_ascii_strdown(haystack, -1);
  g_autofree gchar* lowered_needle = g_ascii_strdown(needle, -1);
  return strstr(lowered_haystack, lowered_needle) != nullptr;
}

gboolean is_cpu_whitelisted(const gchar* vendor, const gchar* model) {
  for (const gchar* allowed_vendor : kCpuVendorWhitelist) {
    if (vendor != nullptr && g_strcmp0(vendor, allowed_vendor) == 0) {
      return TRUE;
    }
  }

  for (const gchar* allowed_hint : kCpuModelWhitelistHints) {
    if (contains_ascii_case_insensitive(model, allowed_hint)) {
      return TRUE;
    }
  }

  return FALSE;
}

gchar* resolve_data_home_path() {
  const gchar* xdg_data_home = g_getenv("XDG_DATA_HOME");
  if (xdg_data_home != nullptr && *xdg_data_home != '\0') {
    return g_strdup(xdg_data_home);
  }

  const gchar* home_directory = g_get_home_dir();
  if (home_directory == nullptr || *home_directory == '\0') {
    return nullptr;
  }

  return g_build_filename(home_directory, ".local", "share", nullptr);
}

gchar* resolve_renderer_config_path() {
  g_autofree gchar* data_home = resolve_data_home_path();
  if (data_home == nullptr) {
    return nullptr;
  }

  return g_build_filename(data_home, APPLICATION_ID, kRendererConfigDirectoryName,
                          kRendererConfigFileName, nullptr);
}

gchar* read_renderer_preference() {
  g_autofree gchar* config_path = resolve_renderer_config_path();
  if (config_path == nullptr ||
      !g_file_test(config_path, G_FILE_TEST_EXISTS)) {
    return g_strdup(kRendererPreferenceAuto);
  }

  g_autoptr(GKeyFile) key_file = g_key_file_new();
  g_autoptr(GError) error = nullptr;
  if (!g_key_file_load_from_file(key_file, config_path, G_KEY_FILE_NONE,
                                 &error)) {
    g_warning("Failed to load renderer config %s: %s", config_path,
              error == nullptr ? "unknown error" : error->message);
    return g_strdup(kRendererPreferenceAuto);
  }

  g_autofree gchar* preferred_mode = g_key_file_get_string(
      key_file, kRendererConfigSection, kRendererConfigPreferredModeKey,
      nullptr);
  return g_strdup(normalize_renderer_preference(preferred_mode));
}

void evaluate_renderer_startup_state() {
  reset_renderer_startup_state();

  g_autofree gchar* cpuinfo = nullptr;
  gsize cpuinfo_length = 0;
  if (g_file_get_contents("/proc/cpuinfo", &cpuinfo, &cpuinfo_length,
                          nullptr)) {
    g_autofree gchar* vendor = extract_cpuinfo_value(cpuinfo, "vendor_id");
    g_autofree gchar* model = extract_cpuinfo_value(cpuinfo, "model name");
    if (model == nullptr) {
      model = extract_cpuinfo_value(cpuinfo, "Hardware");
    }
    if (model == nullptr) {
      model = extract_cpuinfo_value(cpuinfo, "Processor");
    }

    g_renderer_startup_state.is_cpu_whitelisted =
        is_cpu_whitelisted(vendor, model);
    set_state_string(&g_renderer_startup_state.cpu_vendor, vendor);
    set_state_string(&g_renderer_startup_state.cpu_model, model);
  } else {
    g_renderer_startup_state.is_cpu_whitelisted = FALSE;
  }

  const gchar* environment_value = g_getenv("FLUTTER_LINUX_RENDERER");
  if (environment_value != nullptr && *environment_value != '\0') {
    g_renderer_startup_state.is_environment_locked = TRUE;
    set_state_string(&g_renderer_startup_state.environment_value,
                     environment_value);
    set_state_string(&g_renderer_startup_state.current_mode,
                     normalize_renderer_mode(environment_value));
    set_state_string(&g_renderer_startup_state.decision_source,
                     kRendererDecisionEnvironment);
    return;
  }

  g_autofree gchar* preferred_mode = read_renderer_preference();
  const gchar* normalized_preference =
      normalize_renderer_preference(preferred_mode);

  if (g_strcmp0(normalized_preference, kRendererModeSoftware) == 0) {
    set_state_string(&g_renderer_startup_state.current_mode,
                     kRendererModeSoftware);
    set_state_string(&g_renderer_startup_state.decision_source,
                     kRendererDecisionUserPreference);
    g_setenv("FLUTTER_LINUX_RENDERER", kRendererModeSoftware, TRUE);
    return;
  }

  if (g_strcmp0(normalized_preference, kRendererModeHardware) == 0) {
    set_state_string(&g_renderer_startup_state.current_mode,
                     kRendererModeHardware);
    set_state_string(&g_renderer_startup_state.decision_source,
                     kRendererDecisionUserPreference);
    return;
  }

  if (!g_renderer_startup_state.is_cpu_whitelisted) {
    set_state_string(&g_renderer_startup_state.current_mode,
                     kRendererModeSoftware);
    set_state_string(&g_renderer_startup_state.decision_source,
                     kRendererDecisionCpuFallback);
    g_setenv("FLUTTER_LINUX_RENDERER", kRendererModeSoftware, TRUE);
  }
}

FlValue* build_renderer_runtime_state_value() {
  FlValue* value = fl_value_new_map();
  fl_value_set_string_take(
      value, "currentMode",
      fl_value_new_string(g_renderer_startup_state.current_mode));
  fl_value_set_string_take(
      value, "decisionSource",
      fl_value_new_string(g_renderer_startup_state.decision_source));
  fl_value_set_string_take(
      value, "cpuVendor",
      fl_value_new_string(g_renderer_startup_state.cpu_vendor));
  fl_value_set_string_take(
      value, "cpuModel",
      fl_value_new_string(g_renderer_startup_state.cpu_model));
  fl_value_set_string_take(
      value, "environmentValue",
      fl_value_new_string(g_renderer_startup_state.environment_value));
  fl_value_set_string_take(
      value, "isCpuWhitelisted",
      fl_value_new_bool(g_renderer_startup_state.is_cpu_whitelisted));
  return value;
}

void set_context_menu_dark_theme(gboolean prefer_dark) {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings == nullptr) {
    return;
  }

  // 原生右键菜单由 GTK 渲染，直接同步应用偏好的深色模式即可。
  g_object_set(settings, "gtk-application-prefer-dark-theme", prefer_dark,
               nullptr);
}

FlMethodResponse* handle_native_theme_method_call(FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, kSetContextMenuDarkThemeMethod) != 0) {
    return FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  FlValue* args = fl_method_call_get_args(method_call);
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad-args", "Expected a map containing isDark.", nullptr));
  }

  FlValue* is_dark_value = fl_value_lookup_string(args, "isDark");
  if (is_dark_value == nullptr ||
      fl_value_get_type(is_dark_value) != FL_VALUE_TYPE_BOOL) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad-args", "Expected bool field isDark.", nullptr));
  }

  set_context_menu_dark_theme(fl_value_get_bool(is_dark_value));
  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_bool(true)));
}

FlMethodResponse* handle_linux_renderer_method_call(FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, kGetRendererRuntimeStateMethod) != 0) {
    return FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  return FL_METHOD_RESPONSE(
      fl_method_success_response_new(build_renderer_runtime_state_value()));
}

void native_theme_method_call_cb(FlMethodChannel* channel,
                                 FlMethodCall* method_call,
                                 gpointer user_data) {
  (void)channel;
  (void)user_data;
  g_autoptr(FlMethodResponse) response =
      handle_native_theme_method_call(method_call);

  fl_method_call_respond(method_call, response, nullptr);
}

void linux_renderer_method_call_cb(FlMethodChannel* channel,
                                   FlMethodCall* method_call,
                                   gpointer user_data) {
  (void)channel;
  (void)user_data;
  g_autoptr(FlMethodResponse) response =
      handle_linux_renderer_method_call(method_call);

  fl_method_call_respond(method_call, response, nullptr);
}

void setup_native_theme_channel(MyApplication* self, FlView* view) {
  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  self->native_theme_channel = fl_method_channel_new(
      messenger, kNativeThemeChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->native_theme_channel,
                                            native_theme_method_call_cb,
                                            self, nullptr);
}

void setup_linux_renderer_channel(MyApplication* self, FlView* view) {
  FlBinaryMessenger* messenger =
      fl_engine_get_binary_messenger(fl_view_get_engine(view));
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  self->linux_renderer_channel = fl_method_channel_new(
      messenger, kLinuxRendererChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(self->linux_renderer_channel,
                                            linux_renderer_method_call_cb,
                                            self, nullptr);
}

}  // namespace

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  evaluate_renderer_startup_state();

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "linglong_store");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "linglong_store");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));
  setup_native_theme_channel(self, view);
  setup_linux_renderer_channel(self, view);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->native_theme_channel);
  g_clear_object(&self->linux_renderer_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
