#include "include/cbl_flutter_ee/cbl_flutter_ee.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define CBL_FLUTTER_PREBUILT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), cbl_flutter_ee_get_type(), \
                              CblFlutterEe))

struct _CblFlutterEe {
  GObject parent_instance;
};

G_DEFINE_TYPE(CblFlutterEe, cbl_flutter_ee, g_object_get_type())

static void cbl_flutter_ee_dispose(GObject* object) {
  G_OBJECT_CLASS(cbl_flutter_ee_parent_class)->dispose(object);
}

static void cbl_flutter_ee_class_init(CblFlutterEeClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = cbl_flutter_ee_dispose;
}

static void cbl_flutter_ee_init(CblFlutterEe* self) {}

void cbl_flutter_ee_register_with_registrar(FlPluginRegistrar* registrar) {}
