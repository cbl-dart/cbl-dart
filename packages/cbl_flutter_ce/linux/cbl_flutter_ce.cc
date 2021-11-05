#include "include/cbl_flutter_ce/cbl_flutter_ce.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define CBL_FLUTTER_PREBUILT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), cbl_flutter_ce_get_type(), \
                              CblFlutterCe))

struct _CblFlutterCe {
  GObject parent_instance;
};

G_DEFINE_TYPE(CblFlutterCe, cbl_flutter_ce, g_object_get_type())

static void cbl_flutter_ce_dispose(GObject* object) {
  G_OBJECT_CLASS(cbl_flutter_ce_parent_class)->dispose(object);
}

static void cbl_flutter_ce_class_init(CblFlutterCeClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = cbl_flutter_ce_dispose;
}

static void cbl_flutter_ce_init(CblFlutterCe* self) {}

void cbl_flutter_ce_register_with_registrar(FlPluginRegistrar* registrar) {}
