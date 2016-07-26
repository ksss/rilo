#include <stdlib.h>
#include "mruby.h"
#include "mruby/array.h"

int
main(int argc, const char **argv)
{
  mrb_state *mrb = mrb_open();
  mrb_value ARGV;
  int i;

  if (mrb == NULL) {
    fputs("Invalid mrb interpreter, exiting rilo\n", stderr);
    return EXIT_FAILURE;
  }

  ARGV = mrb_ary_new_capa(mrb, argc);
  for (i = 1; i < argc; i++) {
    char* utf8 = mrb_utf8_from_locale((char *)argv[i], -1);
    if (utf8) {
      mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, utf8));
      mrb_utf8_free(utf8);
    }
  }
  mrb_define_global_const(mrb, "ARGV", ARGV);
  
  mrb_funcall(mrb, mrb_top_self(mrb), "__main__", 1, ARGV);
  
  if (mrb->exc) {
    mrb_print_error(mrb);
    return EXIT_FAILURE;
  }
  mrb_close(mrb);
  return EXIT_SUCCESS;
}
