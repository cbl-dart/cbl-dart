#pragma once

namespace CBLDart {

/**
 * On Linux (glibc), makes sure that the `_Unwind_*` functions used by all
 * loaded objects resolve to `libgcc_s.so.1`, even if an object that comes
 * earlier in the global lookup scope exports LLVM libunwind's `_Unwind_*`
 * symbols.
 *
 * Since Flutter 3.50, `libflutter_linux_gtk.so` exports such symbols and is
 * loaded before `libgcc_s.so.1`. libstdc++ and libcblite then use the LLVM
 * unwinder together with the GNU personality routine, which makes C++
 * exceptions uncatchable (https://github.com/flutter/flutter/issues/196402).
 *
 * Call this again after operations that can load new objects. It only does
 * work if objects have been loaded or unloaded since the last call. It never
 * fails hard and is a no-op on other platforms or when no conflict is
 * detected.
 */
void EnsureGccUnwinderBinding();

}  // namespace CBLDart
