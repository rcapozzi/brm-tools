#include <stdio.h>
#include <string.h>
#include <pcm.h>
#include <pinlog.h>
#include "fm_utils.h"
#include "cm_cache.h"
#include <libxml/tree.h>
#include <libxml/parser.h>


table_a_t *g_table_a = NULL;

typedef struct table_a_t {
	char *source;
	char *action;
	int action_int;
	void *next;
}

void
fm_custom_init(int32 *errp) {
	pin_errbuf_t ebuf;
	PIN_ERR_CLEAR_ERR(&ebuf);
	pinlog(__FILE__, __LINE__, LOG_FLAG_DEBUG, "Initializing fm_custom");
	fm_custom_load_table("config_view_a", fm_custom_load_table_a, ebufp);
	fm_custom_load_table("config_view_b", fm_custom_load_table_b, ebufp);
}

/**
 * Parse the XML into C structs. This function assumes a linked list, but you could also insert struct into a G Hash.
 * 
 * XML from Oracle stored proc looks like the following
 * <ROWSET>
 * 	<ROW>
 * 		<SOURCE>EARTH</SOURCE>
 * 		<ACTION>LEFT<ACTION>
 * 	</ROW>
 * 	<ROW>
 * 		<SOURCE>MARS</SOURCE>
 * 		<ACTION>RIGHT<ACTION>
 * 	</ROW>
 * </ROWSET>
 *
 */
static void
fm_custom_load_table_a(void *root_node)
{
	table_a_t *row = NULL;
	xmlNode *node;
	
	// TODO: Cleanup if getting re-init-ed
	if (g_table_a != NULL){
	}

	PIN_ERR_LOG_MSG(PIN_ERR_LEVEL_DEBUG, "fm_custom_load_table_a enter");

	for (node = root_node; node; node = node->next) {
		if (node->type == XML_ELEMENT_NODE) {

			if (!strcmp(node->name, "ROW")){
				if (row->next){
					//TODO: 
				}
				// Alloc next row. TBD: Alloc the first one.
				row->next = malloc(sizeof(table_a_t));
				row = row->next;
				row->source = NULL;
				row->action = NULL;
				row->action_int = -1;

				xmlNode *row_node = node->xmlChildrenNode;
				while(row_node != NULL){
					char *content = xmlNodeGetContent(row_node);
					if (content == NULL){
						continue;
					}
					if (!strcmp(row_node->name, "SOURCE")){
						row->source = content;
					} else if (!strcmp(row_node->name, "ACTION")){
						row->action = content;
						// Convert user string to int
						if (!strcmp(content, "LEFT")){
							row->action_int = 1;
						} else if (!strcmp(content, "RIGHT")){
							row->action_int = 2;
						}
					} else {
						free(content);
					}
					row_node = row_node->next;

				}
			} else {
				fm_custom_load_table_a(node->children);
			}
		}
	}
	// TODO: Cleanup
	PIN_ERR_LOG_MSG(PIN_ERR_LEVEL_DEBUG, "fm_custom_load_table_a return");
}

static void
fm_custom_load_table_b(void *root_node)
{
	PIN_ERR_LOG_MSG(PIN_ERR_LEVEL_DEBUG, "fm_custom_load_table_b enter");
}

static void
fm_custom_load_table(char *table_name, void (*fp)(), pin_errbuf_t *ebufp){
	pcm_context_t	*ctxp = NULL;
  pin_buf_t *bufp = NULL;
	pin_errbuf_t	ebuf;
	int		err;

	PIN_ERR_CLEAR_ERR(&ebuf);
	sprintf(PinLog_buffer, "load_table enter %s\n", table_name);
	PIN_ERR_LOG_MSG(PIN_ERR_LEVEL_DEBUG, PinLog_buffer);

	PCM_CONTEXT_OPEN(&ctxp, (pin_flist_t *)0, &ebuf);
	if(PIN_ERR_IS_ERR(&ebuf)) {
		pin_set_err(&ebuf, PIN_ERRLOC_FM,
			PIN_ERRCLASS_SYSTEM_DETERMINATE,
			PIN_ERR_DM_CONNECT_FAILED, 0, 0, ebuf.pin_err);
		PIN_FLIST_LOG_ERR("load_table pcm_context_open err", &ebuf);
		return;
	}

	int32 arg_type = 0; // IN OUT
  pin_flist_t *sproc_iflistp = PIN_FLIST_CREATE(ebufp);
  pin_flist_t *sproc_oflistp = NULL;
  poid_t *proc_poidp = PIN_POID_CREATE(1, "/procedure", -1, ebufp);
  PIN_FLIST_FLD_PUT(sproc_iflistp, PIN_FLD_POID, proc_poidp, ebufp);
  PIN_FLIST_FLD_SET(sproc_iflistp, PIN_FLD_PROC_NAME, "XXX.TABLE2XML", ebufp);

  pin_flist_t *arg_flistp = PIN_FLIST_ELEM_ADD(sproc_iflistp, PIN_FLD_ARGS, 1, ebufp);
  PIN_FLIST_FLD_SET(arg_flistp, PIN_FLD_ARG_TYPE, &arg_type, ebufp);
  PIN_FLIST_FLD_SET(arg_flistp, PIN_FLD_NAME, table_name, ebufp);

  arg_flistp = PIN_FLIST_ELEM_ADD(sproc_iflistp, PIN_FLD_ARGS, 2, ebufp);
  arg_type = 1;
  PIN_FLIST_FLD_SET(arg_flistp, PIN_FLD_ARG_TYPE, &arg_type, ebufp);
  PIN_FLIST_FLD_SET(arg_flistp, PIN_FLD_BUFFER, NULL, ebufp);

  PCM_OPREF(ctxp, PCM_OP_EXEC_SPROC, 0, sproc_iflistp, &sproc_oflistp, ebufp);
  if (PIN_ERR_IS_ERR(ebufp)) {
    ebufp->location = PIN_ERRLOC_DM;
		return;
  }

  arg_flistp = PIN_FLIST_ELEM_GET(sproc_oflistp, PIN_FLD_ARGS, 2, 0, ebufp);
  bufp = PIN_FLIST_FLD_GET(arg_flistp, PIN_FLD_BUFFER, 1, ebufp);
  if (bufp == NULL) {
    ebufp->location = PIN_ERRLOC_DM;
		PIN_FLIST_LOG_ERR("Missing BUFFER results", &ebuf);
		return;
  }

	xmlDoc *doc = xmlReadMemory(bufp->data, bufp->size, NULL, NULL, 0);
	if (doc == NULL){
		pin_set_err(&ebuf, PIN_ERRLOC_FM, PIN_ERRCLASS_SYSTEM_DETERMINATE, PIN_ERR_BAD_ARG, 0, 0, ebuf.pin_err);
		PIN_FLIST_LOG_ERR("xmlReadMemory err", &ebuf);
		return;
	}

	xmlNode *root_element = xmlDocGetRootElement(doc);
	if (root_element == NULL){
		pin_set_err(&ebuf, PIN_ERRLOC_FM, PIN_ERRCLASS_SYSTEM_DETERMINATE, PIN_ERR_BAD_ARG, 0, 0, ebuf.pin_err);
		PIN_FLIST_LOG_ERR("bad xmlDocGetRootElement err", &ebuf);
	}
	fp(root_element);

	xmlFreeDoc(doc);
	xmlCleanupParser();
  PIN_FLIST_DESTROY_EX(&sproc_iflistp, NULL);
  PIN_FLIST_DESTROY_EX(&sproc_oflistp, NULL);
	PCM_CONTEXT_CLOSE(ctxp, 0, &ebuf);
	PIN_ERR_LOG_MSG(PIN_ERR_LEVEL_DEBUG, "load_table return");
	return;
}
