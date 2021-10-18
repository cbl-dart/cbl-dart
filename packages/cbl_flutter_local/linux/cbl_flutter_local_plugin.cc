#include "include/cbl_flutter_local/cbl_flutter_local_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define CBL_FLUTTER_LOCAL_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), cbl_flutter_local_plugin_get_type(), \
                              CblFlutterLocalPlugin))

struct _CblFlutterLocalPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(CblFlutterLocalPlugin, cbl_flutter_local_plugin, g_object_get_type())

static void cbl_flutter_local_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(cbl_flutter_local_plugin_parent_class)->dispose(object);
}

static void cbl_flutter_local_plugin_class_init(CblFlutterLocalPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = cbl_flutter_local_plugin_dispose;
}

static void cbl_flutter_local_plugin_init(CblFlutterLocalPlugin* self) {}

void cbl_flutter_local_plugin_register_with_registrar(FlPluginRegistrar* registrar) {}
