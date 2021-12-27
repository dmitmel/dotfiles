/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/src/cmark-gfm.h>
*******************************************************************************/

char *cmark_markdown_to_html(const char *text, size_t len, int options);

static const int CMARK_NODE_TYPE_PRESENT = 0x8000;
static const int CMARK_NODE_TYPE_BLOCK = CMARK_NODE_TYPE_PRESENT | 0x0000;
static const int CMARK_NODE_TYPE_INLINE = CMARK_NODE_TYPE_PRESENT | 0x4000;
static const int CMARK_NODE_TYPE_MASK = 0xc000;
static const int CMARK_NODE_VALUE_MASK = 0x3fff;

typedef enum cmark_node_type {
  CMARK_NODE_NONE = 0x0000,

  CMARK_NODE_DOCUMENT = CMARK_NODE_TYPE_BLOCK | 0x0001,
  CMARK_NODE_BLOCK_QUOTE = CMARK_NODE_TYPE_BLOCK | 0x0002,
  CMARK_NODE_LIST = CMARK_NODE_TYPE_BLOCK | 0x0003,
  CMARK_NODE_ITEM = CMARK_NODE_TYPE_BLOCK | 0x0004,
  CMARK_NODE_CODE_BLOCK = CMARK_NODE_TYPE_BLOCK | 0x0005,
  CMARK_NODE_HTML_BLOCK = CMARK_NODE_TYPE_BLOCK | 0x0006,
  CMARK_NODE_CUSTOM_BLOCK = CMARK_NODE_TYPE_BLOCK | 0x0007,
  CMARK_NODE_PARAGRAPH = CMARK_NODE_TYPE_BLOCK | 0x0008,
  CMARK_NODE_HEADING = CMARK_NODE_TYPE_BLOCK | 0x0009,
  CMARK_NODE_THEMATIC_BREAK = CMARK_NODE_TYPE_BLOCK | 0x000a,
  CMARK_NODE_FOOTNOTE_DEFINITION = CMARK_NODE_TYPE_BLOCK | 0x000b,

  CMARK_NODE_TEXT = CMARK_NODE_TYPE_INLINE | 0x0001,
  CMARK_NODE_SOFTBREAK = CMARK_NODE_TYPE_INLINE | 0x0002,
  CMARK_NODE_LINEBREAK = CMARK_NODE_TYPE_INLINE | 0x0003,
  CMARK_NODE_CODE = CMARK_NODE_TYPE_INLINE | 0x0004,
  CMARK_NODE_HTML_INLINE = CMARK_NODE_TYPE_INLINE | 0x0005,
  CMARK_NODE_CUSTOM_INLINE = CMARK_NODE_TYPE_INLINE | 0x0006,
  CMARK_NODE_EMPH = CMARK_NODE_TYPE_INLINE | 0x0007,
  CMARK_NODE_STRONG = CMARK_NODE_TYPE_INLINE | 0x0008,
  CMARK_NODE_LINK = CMARK_NODE_TYPE_INLINE | 0x0009,
  CMARK_NODE_IMAGE = CMARK_NODE_TYPE_INLINE | 0x000a,
  CMARK_NODE_FOOTNOTE_REFERENCE = CMARK_NODE_TYPE_INLINE | 0x000b,
} cmark_node_type;

extern cmark_node_type CMARK_NODE_LAST_BLOCK;
extern cmark_node_type CMARK_NODE_LAST_INLINE;

typedef enum cmark_list_type {
  CMARK_NO_LIST,
  CMARK_BULLET_LIST,
  CMARK_ORDERED_LIST
} cmark_list_type;

typedef enum cmark_delim_type {
  CMARK_NO_DELIM,
  CMARK_PERIOD_DELIM,
  CMARK_PAREN_DELIM
} cmark_delim_type;

typedef struct cmark_node cmark_node;
typedef struct cmark_parser cmark_parser;
typedef struct cmark_iter cmark_iter;
typedef struct cmark_syntax_extension cmark_syntax_extension;

typedef struct cmark_mem {
  void *(*calloc)(size_t, size_t);
  void *(*realloc)(void *, size_t);
  void (*free)(void *);
} cmark_mem;

cmark_mem *cmark_get_default_mem_allocator();
cmark_mem *cmark_get_arena_mem_allocator();
void cmark_arena_reset(void);

typedef void (*cmark_free_func)(cmark_mem *mem, void *user_data);

typedef struct _cmark_llist {
  struct _cmark_llist *next;
  void *data;
} cmark_llist;

cmark_llist *cmark_llist_append(cmark_mem *mem, cmark_llist *head, void *data);
void cmark_llist_free_full(cmark_mem *mem, cmark_llist *head,
                           cmark_free_func free_func);
void cmark_llist_free(cmark_mem *mem, cmark_llist *head);

cmark_node *cmark_node_new(cmark_node_type type);
cmark_node *cmark_node_new_with_mem(cmark_node_type type, cmark_mem *mem);
cmark_node *cmark_node_new_with_ext(cmark_node_type type,
                                    cmark_syntax_extension *extension);
cmark_node *cmark_node_new_with_mem_and_ext(cmark_node_type type,
                                            cmark_mem *mem,
                                            cmark_syntax_extension *extension);
void cmark_node_free(cmark_node *node);
cmark_node *cmark_node_next(cmark_node *node);
cmark_node *cmark_node_previous(cmark_node *node);
cmark_node *cmark_node_parent(cmark_node *node);
cmark_node *cmark_node_first_child(cmark_node *node);
cmark_node *cmark_node_last_child(cmark_node *node);

typedef enum cmark_event_type {
  CMARK_EVENT_NONE,
  CMARK_EVENT_DONE,
  CMARK_EVENT_ENTER,
  CMARK_EVENT_EXIT
} cmark_event_type;

cmark_iter *cmark_iter_new(cmark_node *root);
void cmark_iter_free(cmark_iter *iter);
cmark_event_type cmark_iter_next(cmark_iter *iter);
cmark_node *cmark_iter_get_node(cmark_iter *iter);
cmark_event_type cmark_iter_get_event_type(cmark_iter *iter);
cmark_node *cmark_iter_get_root(cmark_iter *iter);
void cmark_iter_reset(cmark_iter *iter, cmark_node *current,
                      cmark_event_type event_type);

void *cmark_node_get_user_data(cmark_node *node);
int cmark_node_set_user_data(cmark_node *node, void *user_data);
int cmark_node_set_user_data_free_func(cmark_node *node,
                                       cmark_free_func free_func);

cmark_node_type cmark_node_get_type(cmark_node *node);
const char *cmark_node_get_type_string(cmark_node *node);
const char *cmark_node_get_literal(cmark_node *node);
int cmark_node_set_literal(cmark_node *node, const char *content);
int cmark_node_get_heading_level(cmark_node *node);
int cmark_node_set_heading_level(cmark_node *node, int level);
cmark_list_type cmark_node_get_list_type(cmark_node *node);
int cmark_node_set_list_type(cmark_node *node, cmark_list_type type);
cmark_delim_type cmark_node_get_list_delim(cmark_node *node);
int cmark_node_set_list_delim(cmark_node *node, cmark_delim_type delim);
int cmark_node_get_list_start(cmark_node *node);
int cmark_node_set_list_start(cmark_node *node, int start);
int cmark_node_get_list_tight(cmark_node *node);
int cmark_node_set_list_tight(cmark_node *node, int tight);
const char *cmark_node_get_fence_info(cmark_node *node);
int cmark_node_set_fence_info(cmark_node *node, const char *info);
int cmark_node_set_fenced(cmark_node *node, int fenced, int length, int offset,
                          char character);
int cmark_node_get_fenced(cmark_node *node, int *length, int *offset,
                          char *character);
const char *cmark_node_get_url(cmark_node *node);
int cmark_node_set_url(cmark_node *node, const char *url);
const char *cmark_node_get_title(cmark_node *node);
int cmark_node_set_title(cmark_node *node, const char *title);

const char *cmark_node_get_on_enter(cmark_node *node);
int cmark_node_set_on_enter(cmark_node *node, const char *on_enter);
const char *cmark_node_get_on_exit(cmark_node *node);
int cmark_node_set_on_exit(cmark_node *node, const char *on_exit);
int cmark_node_get_start_line(cmark_node *node);
int cmark_node_get_start_column(cmark_node *node);
int cmark_node_get_end_line(cmark_node *node);
int cmark_node_get_end_column(cmark_node *node);

void cmark_node_unlink(cmark_node *node);
int cmark_node_insert_before(cmark_node *node, cmark_node *sibling);
int cmark_node_insert_after(cmark_node *node, cmark_node *sibling);
int cmark_node_replace(cmark_node *oldnode, cmark_node *newnode);
int cmark_node_prepend_child(cmark_node *node, cmark_node *child);
int cmark_node_append_child(cmark_node *node, cmark_node *child);
void cmark_consolidate_text_nodes(cmark_node *root);

void cmark_node_own(cmark_node *root);

cmark_parser *cmark_parser_new(int options);
cmark_parser *cmark_parser_new_with_mem(int options, cmark_mem *mem);
void cmark_parser_free(cmark_parser *parser);
void cmark_parser_feed(cmark_parser *parser, const char *buffer, size_t len);
cmark_node *cmark_parser_finish(cmark_parser *parser);
cmark_node *cmark_parse_document(const char *buffer, size_t len, int options);
cmark_node *cmark_parse_file(struct FILE *f, int options);

char *cmark_render_xml(cmark_node *root, int options);
char *cmark_render_xml_with_mem(cmark_node *root, int options, cmark_mem *mem);
char *cmark_render_html(cmark_node *root, int options, cmark_llist *extensions);
char *cmark_render_html_with_mem(cmark_node *root, int options,
                                 cmark_llist *extensions, cmark_mem *mem);
char *cmark_render_man(cmark_node *root, int options, int width);
char *cmark_render_man_with_mem(cmark_node *root, int options, int width,
                                cmark_mem *mem);
char *cmark_render_commonmark(cmark_node *root, int options, int width);
char *cmark_render_commonmark_with_mem(cmark_node *root, int options, int width,
                                       cmark_mem *mem);
char *cmark_render_plaintext(cmark_node *root, int options, int width);
char *cmark_render_plaintext_with_mem(cmark_node *root, int options, int width,
                                      cmark_mem *mem);
char *cmark_render_latex(cmark_node *root, int options, int width);
char *cmark_render_latex_with_mem(cmark_node *root, int options, int width,
                                  cmark_mem *mem);

static const int CMARK_OPT_DEFAULT = 0;
static const int CMARK_OPT_SOURCEPOS = 1 << 1;
static const int CMARK_OPT_HARDBREAKS = 1 << 2;
static const int CMARK_OPT_SAFE = 1 << 3;
static const int CMARK_OPT_UNSAFE = 1 << 17;
static const int CMARK_OPT_NOBREAKS = 1 << 4;
static const int CMARK_OPT_NORMALIZE = 1 << 8;
static const int CMARK_OPT_VALIDATE_UTF8 = 1 << 9;
static const int CMARK_OPT_SMART = 1 << 10;
static const int CMARK_OPT_GITHUB_PRE_LANG = 1 << 11;
static const int CMARK_OPT_LIBERAL_HTML_TAG = 1 << 12;
static const int CMARK_OPT_FOOTNOTES = 1 << 13;
static const int CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE = 1 << 14;
static const int CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES = 1 << 15;
static const int CMARK_OPT_FULL_INFO_STRING = 1 << 16;

int cmark_version(void);
const char *cmark_version_string(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/src/cmark-gfm-extension_api.h>
*******************************************************************************/

struct cmark_renderer;
struct cmark_html_renderer;
struct cmark_chunk;
typedef struct cmark_plugin cmark_plugin;
typedef struct subject cmark_inline_parser;
typedef struct delimiter cmark_delimiter;

typedef int (*cmark_plugin_init_func)(cmark_plugin *plugin);

int cmark_plugin_register_syntax_extension(cmark_plugin *plugin,
                                           cmark_syntax_extension *extension);
cmark_syntax_extension *cmark_find_syntax_extension(const char *name);

typedef cmark_node *(*cmark_open_block_func)(cmark_syntax_extension *extension,
                                             int indented, cmark_parser *parser,
                                             cmark_node *parent_container,
                                             unsigned char *input, int len);

typedef cmark_node *(*cmark_match_inline_func)(
    cmark_syntax_extension *extension, cmark_parser *parser, cmark_node *parent,
    unsigned char character, cmark_inline_parser *inline_parser);

typedef cmark_delimiter *(*cmark_inline_from_delim_func)(
    cmark_syntax_extension *extension, cmark_parser *parser,
    cmark_inline_parser *inline_parser, cmark_delimiter *opener,
    cmark_delimiter *closer);

typedef int (*cmark_match_block_func)(cmark_syntax_extension *extension,
                                      cmark_parser *parser,
                                      unsigned char *input, int len,
                                      cmark_node *container);

typedef const char *(*cmark_get_type_string_func)(
    cmark_syntax_extension *extension, cmark_node *node);

typedef int (*cmark_can_contain_func)(cmark_syntax_extension *extension,
                                      cmark_node *node, cmark_node_type child);

typedef int (*cmark_contains_inlines_func)(cmark_syntax_extension *extension,
                                           cmark_node *node);

typedef void (*cmark_common_render_func)(cmark_syntax_extension *extension,
                                         struct cmark_renderer *renderer,
                                         cmark_node *node,
                                         cmark_event_type ev_type, int options);

typedef int (*cmark_commonmark_escape_func)(cmark_syntax_extension *extension,
                                            cmark_node *node, int c);

typedef const char *(*cmark_xml_attr_func)(cmark_syntax_extension *extension,
                                           cmark_node *node);

typedef void (*cmark_html_render_func)(cmark_syntax_extension *extension,
                                       struct cmark_html_renderer *renderer,
                                       cmark_node *node,
                                       cmark_event_type ev_type, int options);

typedef int (*cmark_html_filter_func)(cmark_syntax_extension *extension,
                                      const unsigned char *tag, size_t tag_len);

typedef cmark_node *(*cmark_postprocess_func)(cmark_syntax_extension *extension,
                                              cmark_parser *parser,
                                              cmark_node *root);

typedef int (*cmark_ispunct_func)(char c);

typedef void (*cmark_opaque_alloc_func)(cmark_syntax_extension *extension,
                                        cmark_mem *mem, cmark_node *node);

typedef void (*cmark_opaque_free_func)(cmark_syntax_extension *extension,
                                       cmark_mem *mem, cmark_node *node);

void cmark_syntax_extension_free(cmark_mem *mem,
                                 cmark_syntax_extension *extension);

cmark_syntax_extension *cmark_syntax_extension_new(const char *name);
cmark_node_type cmark_syntax_extension_add_node(int is_inline);
void cmark_syntax_extension_set_emphasis(cmark_syntax_extension *extension,
                                         int emphasis);
void cmark_syntax_extension_set_open_block_func(
    cmark_syntax_extension *extension, cmark_open_block_func func);
void cmark_syntax_extension_set_match_block_func(
    cmark_syntax_extension *extension, cmark_match_block_func func);
void cmark_syntax_extension_set_match_inline_func(
    cmark_syntax_extension *extension, cmark_match_inline_func func);
void cmark_syntax_extension_set_inline_from_delim_func(
    cmark_syntax_extension *extension, cmark_inline_from_delim_func func);
void cmark_syntax_extension_set_special_inline_chars(
    cmark_syntax_extension *extension, cmark_llist *special_chars);
void cmark_syntax_extension_set_get_type_string_func(
    cmark_syntax_extension *extension, cmark_get_type_string_func func);
void cmark_syntax_extension_set_can_contain_func(
    cmark_syntax_extension *extension, cmark_can_contain_func func);
void cmark_syntax_extension_set_contains_inlines_func(
    cmark_syntax_extension *extension, cmark_contains_inlines_func func);
void cmark_syntax_extension_set_commonmark_render_func(
    cmark_syntax_extension *extension, cmark_common_render_func func);
void cmark_syntax_extension_set_plaintext_render_func(
    cmark_syntax_extension *extension, cmark_common_render_func func);
void cmark_syntax_extension_set_latex_render_func(
    cmark_syntax_extension *extension, cmark_common_render_func func);
void cmark_syntax_extension_set_xml_attr_func(cmark_syntax_extension *extension,
                                              cmark_xml_attr_func func);
void cmark_syntax_extension_set_man_render_func(
    cmark_syntax_extension *extension, cmark_common_render_func func);
void cmark_syntax_extension_set_html_render_func(
    cmark_syntax_extension *extension, cmark_html_render_func func);
void cmark_syntax_extension_set_html_filter_func(
    cmark_syntax_extension *extension, cmark_html_filter_func func);
void cmark_syntax_extension_set_commonmark_escape_func(
    cmark_syntax_extension *extension, cmark_commonmark_escape_func func);
void cmark_syntax_extension_set_private(cmark_syntax_extension *extension,
                                        void *priv, cmark_free_func free_func);
void *cmark_syntax_extension_get_private(cmark_syntax_extension *extension);
void cmark_syntax_extension_set_postprocess_func(
    cmark_syntax_extension *extension, cmark_postprocess_func func);
void cmark_syntax_extension_set_opaque_alloc_func(
    cmark_syntax_extension *extension, cmark_opaque_alloc_func func);
void cmark_syntax_extension_set_opaque_free_func(
    cmark_syntax_extension *extension, cmark_opaque_free_func func);
void cmark_parser_set_backslash_ispunct_func(cmark_parser *parser,
                                             cmark_ispunct_func func);

int cmark_parser_get_line_number(cmark_parser *parser);
int cmark_parser_get_offset(cmark_parser *parser);
int cmark_parser_get_column(cmark_parser *parser);
int cmark_parser_get_first_nonspace(cmark_parser *parser);
int cmark_parser_get_first_nonspace_column(cmark_parser *parser);
int cmark_parser_get_indent(cmark_parser *parser);
int cmark_parser_is_blank(cmark_parser *parser);
int cmark_parser_has_partially_consumed_tab(cmark_parser *parser);
int cmark_parser_get_last_line_length(cmark_parser *parser);
cmark_node *cmark_parser_add_child(cmark_parser *parser, cmark_node *parent,
                                   cmark_node_type block_type,
                                   int start_column);
void cmark_parser_advance_offset(cmark_parser *parser, const char *input,
                                 int count, int columns);
void cmark_parser_feed_reentrant(cmark_parser *parser, const char *buffer,
                                 size_t len);
int cmark_parser_attach_syntax_extension(cmark_parser *parser,
                                         cmark_syntax_extension *extension);

int cmark_node_set_type(cmark_node *node, cmark_node_type type);
const char *cmark_node_get_string_content(cmark_node *node);
int cmark_node_set_string_content(cmark_node *node, const char *content);
cmark_syntax_extension *cmark_node_get_syntax_extension(cmark_node *node);
int cmark_node_set_syntax_extension(cmark_node *node,
                                    cmark_syntax_extension *extension);

typedef int (*cmark_inline_predicate)(int c);

void cmark_inline_parser_advance_offset(cmark_inline_parser *parser);
int cmark_inline_parser_get_offset(cmark_inline_parser *parser);
void cmark_inline_parser_set_offset(cmark_inline_parser *parser, int offset);
struct cmark_chunk *cmark_inline_parser_get_chunk(cmark_inline_parser *parser);
int cmark_inline_parser_in_bracket(cmark_inline_parser *parser, int image);

void cmark_node_unput(cmark_node *node, int n);

unsigned char cmark_inline_parser_peek_char(cmark_inline_parser *parser);
unsigned char cmark_inline_parser_peek_at(cmark_inline_parser *parser, int pos);
int cmark_inline_parser_is_eof(cmark_inline_parser *parser);
char *cmark_inline_parser_take_while(cmark_inline_parser *parser,
                                     cmark_inline_predicate pred);
void cmark_inline_parser_push_delimiter(cmark_inline_parser *parser,
                                        unsigned char c, int can_open,
                                        int can_close, cmark_node *inl_text);
void cmark_inline_parser_remove_delimiter(cmark_inline_parser *parser,
                                          cmark_delimiter *delim);
cmark_delimiter *
cmark_inline_parser_get_last_delimiter(cmark_inline_parser *parser);
int cmark_inline_parser_get_line(cmark_inline_parser *parser);
int cmark_inline_parser_get_column(cmark_inline_parser *parser);
int cmark_inline_parser_scan_delimiters(cmark_inline_parser *parser,
                                        int max_delims, unsigned char c,
                                        int *left_flanking, int *right_flanking,
                                        int *punct_before, int *punct_after);

void cmark_manage_extensions_special_characters(cmark_parser *parser, int add);

cmark_llist *cmark_parser_get_syntax_extensions(cmark_parser *parser);

void cmark_arena_push(void);
int cmark_arena_pop(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/cmark-gfm-core-extensions.h>
*******************************************************************************/

void cmark_gfm_core_extensions_ensure_registered(void);

uint16_t cmark_gfm_extensions_get_table_columns(cmark_node *node);
uint8_t *cmark_gfm_extensions_get_table_alignments(cmark_node *node);
int cmark_gfm_extensions_get_table_row_is_header(cmark_node *node);

char *cmark_gfm_extensions_get_tasklist_state(cmark_node *node);
// This declaration is for 0.29.0.gfm.2
bool cmark_gfm_extensions_get_tasklist_item_checked(cmark_node *node);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/table.h>
*******************************************************************************/

extern cmark_node_type CMARK_NODE_TABLE;
extern cmark_node_type CMARK_NODE_TABLE_ROW;
extern cmark_node_type CMARK_NODE_TABLE_CELL;

cmark_syntax_extension *create_table_extension(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/strikethrough.h>
*******************************************************************************/

extern cmark_node_type CMARK_NODE_STRIKETHROUGH;
cmark_syntax_extension *create_strikethrough_extension(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/autolink.h>
*******************************************************************************/

cmark_syntax_extension *create_autolink_extension(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/tagfilter.h>
*******************************************************************************/

cmark_syntax_extension *create_tagfilter_extension(void);

/*******************************************************************************
<https://github.com/github/cmark-gfm/blob/0.29.0.gfm.0/extensions/tasklist.h>
*******************************************************************************/

cmark_syntax_extension *create_tasklist_extension(void);
