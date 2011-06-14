
#define XXX_ERR_SET_ERR(ebufp, pin_err, field_num, descr) \
do { \
       int err = 0; \
       if (! PIN_ERR_IS_ERR(ebufp)) { \
              pin_set_err(ebufp, PIN_ERRLOC_FM, PIN_ERRCLASS_SYSTEM_DETERMINATE, pin_err, field_num, 0, 0); \
       } \
       if (ebufp->argsp == (void *) 0) { \
              pin_errbuf_args_add_str(ebufp, 0, descr, &err); \
       } \
       PIN_ERR_LOG_EBUF(PIN_ERR_LEVEL_ERROR, descr, ebufp); \
} while (0)

