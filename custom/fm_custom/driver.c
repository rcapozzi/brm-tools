#include <libgen.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include "pcm.h"
#include "pin_errs.h"
#include "pinlog.h"
#include "cm_fm.h"
#include "custom_flds.h"
#include "ops/custom_ops.h"

int is_verbose = 0;
void *g_dl_handle = NULL;

static int
read_file(const char *filename, char **content)
{
	if (is_verbose)
		fprintf(stdout, "XXX reading file %s\n", filename);
	char *source = NULL;
	FILE *fp = fopen(filename, "r");
	if (fp == NULL)
	{
		return 1;
	}
	/* Go to the end of the file. */
	if (fseek(fp, 0L, SEEK_END) == 0)
	{
		/* Get the size of the file. */
		long bufsize = ftell(fp);
		if (bufsize == -1)
		{ /* Error */
		}

		/* Allocate our buffer to that size. */
		source = malloc(sizeof(char) * (bufsize + 1));

		/* Go back to the start of the file. */
		if (fseek(fp, 0L, SEEK_SET) != 0)
		{ /* Error */
		}

		/* Read the entire file into memory. */
		size_t newLen = fread(source, sizeof(char), bufsize, fp);
		if (ferror(fp) != 0)
		{
			fputs("Error reading file", stderr);
		}
		else
		{
			source[newLen++] = '\0'; /* Just to be safe. */
		}
	}
	fclose(fp);
	*content = source;
	return 0;
}

static pin_flist_t *
flist_from_file(const char *filename, pin_errbuf_t *ebufp)
{
	char *data;
	pin_flist_t *buf_flistp = NULL;
	if (0 != read_file(filename, &data))
	{
		fputs("Error reading file", stderr);
		exit(1);
	}
	PIN_STR_TO_FLIST(data, 1, &buf_flistp, ebufp);
	free(data);
	return buf_flistp;
}

void *
load_opcode(const char *fm, const char *opcode)
{
	char *error;
	if ((g_dl_handle == NULL) && 
	   ((g_dl_handle = dlopen(fm, RTLD_LAZY)) == NULL)) {
		fprintf(stderr, "ERROR calling dlopen()\n%s\n", dlerror());
		exit(1);
	}

	void (*opcode_ptr)();
	opcode_ptr = dlsym(g_dl_handle, opcode);
	if ((error = dlerror()) != NULL)	{
		fputs(error, stderr);
		exit(1);
	}
	return opcode_ptr;	
}
void *
conn_open(cm_nap_connection_t **connpp, pin_errbuf_t *ebufp){
	cm_nap_connection_t *connp = NULL;
	pcm_context_t *ctxp = NULL;
	int64 database;
	PCM_CONNECT(&ctxp, &database, ebufp);
	if (PIN_ERR_IS_ERR(ebufp)){
		fprintf(stderr, "ERROR: Bad PCM_CONNECT\n");
		exit(1);
	}

	connp = (cm_nap_connection_t *)malloc(sizeof(cm_nap_connection_t));
	connp->dm_ctx = ctxp;
	*connpp = connp;
	if(is_verbose)
		fprintf(stdout, "XXX called PCM_CONNECT\n");

}

void *
conn_close(cm_nap_connection_t **connpp, pin_errbuf_t *ebufp){
	pcm_context_t *ctxp = (*connpp)->dm_ctx;
	PCM_CONTEXT_CLOSE(ctxp, 0, ebufp);
	free(*connpp);
	*connpp = NULL;
	if(is_verbose)
		fprintf(stdout, "XXX called PCM_CONTEXT_CLOSE\n");
}

static int 
doit(pin_flist_t *in_flistp, pin_flist_t **out_flistpp, pin_errbuf_t *ebufp)
{
	cm_nap_connection_t *connp = NULL;
	const char * fm_path = "../../../lib/fm_custom.so";
	const char *opname = "op_custom_foo";
	void (*opcode_ptr)();

	conn_open(&connp, ebufp);

	opcode_ptr = load_opcode(fm_path, opname);

	if(is_verbose)
	fprintf(stdout, "XXX Calling opcode %s\n", opname);
	opcode_ptr = load_opcode(fm_path, opname);
	(*opcode_ptr)(connp, CUSTOM_OP_FOO, 0, in_flistp, out_flistpp, ebufp);

	if (PIN_ERR_IS_ERR(ebufp)){
		fprintf(stderr, "ERROR: ebufp is error\n");
	} else {
		if(is_verbose)
		fprintf(stderr, "ebufp is clean\n");
	}

	conn_close(&connp, ebufp);
	return 0;
}

int
write_outfile(char *filename, pin_flist_t *flistp){
	pin_errbuf_t ebuf;
	PIN_ERR_CLEAR_ERR(&ebuf);
	FILE *fptr;
	fptr = fopen(filename,"w");
   if(fptr == NULL)   {
      fprintf(stderr, "Error opening output file %s\n", filename); 
      exit(1);             
   }
	if (is_verbose)
		fprintf(stdout, "# write output flist to file %s\n", filename); 
	if (flistp){
		PIN_FLIST_PRINT(flistp, fptr, &ebuf);
	}
	fclose(fptr);
}

int main(int argc, char **argv)
{
	int is_debug = 0;
	pin_flist_t *opts_flistp = NULL;
	pin_flist_t *in_flistp = NULL;
	pin_flist_t *out_flistp = NULL;
	pin_errbuf_t ebuf, *ebufp;
	char *output_file = NULL;

	g_dl_handle = NULL;
	ebufp = &ebuf;
	PIN_ERR_CLEAR_ERR(&ebuf);
	PIN_ERR_SET_PROGRAM((char *)basename(argv[0]));
	PIN_ERR_SET_LEVEL(PIN_ERR_LEVEL_DEBUG);

	opts_flistp = PIN_FLIST_CREATE(ebufp);

	optind = 1;
	opterr = 0;
	char c;
	while ((c = getopt(argc, argv, "di:o:v")) != (char)EOF)
	{
		switch (c)
		{
		case 'i':
			PIN_FLIST_FLD_SET(opts_flistp, PIN_FLD_FILENAME, optarg, ebufp);
			in_flistp = flist_from_file(optarg, ebufp);
			if (PIN_ERR_IS_ERR(ebufp)){
				fprintf(stderr, "ERROR: Bad read of flist from %s\n", optarg);
				exit(1);
			}
			break;
		case 'd':
			PIN_ERR_SET_LEVEL(PIN_ERR_LEVEL_DEBUG);
			is_debug = 1;
			break;
		case 'o':
			output_file = strdup(optarg);
			break;
		case 'v':
			is_verbose = 1;
			break;
		default:
			break;
		}
	}

	//time_t now_t = pin_virtual_time(NULL);
	//PIN_FLIST_FLD_SET(in_flistp, PIN_FLD_WHEN_T, &now_t, ebufp);

	if (is_verbose){
		fprintf(stdout, "# input flist:\n");
		PIN_FLIST_PRINT(in_flistp, NULL, ebufp);
	}

	doit(in_flistp, &out_flistp, &ebuf);
	if (output_file){
		write_outfile(output_file, out_flistp);
	}
	if (is_verbose){
		fprintf(stdout, "# return flist:\n");
	PIN_FLIST_PRINT(out_flistp, NULL, ebufp);
	}

	dlclose(g_dl_handle);
	PIN_FLIST_DESTROY_EX(&opts_flistp, NULL);
	PIN_FLIST_DESTROY_EX(&in_flistp, NULL);
	PIN_FLIST_DESTROY_EX(&out_flistp, NULL);
	exit(0);
}
