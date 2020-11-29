/*
 * Kinect data manipulation utilities for Ruby.
 * (C)2011 Mike Bourgeous
 *
 * References:
 * http://www.rubyinside.com/how-to-create-a-ruby-extension-in-c-in-under-5-minutes-100.html
 * http://www.ruby-doc.org/docs/ProgrammingRuby/html/ext_ruby.html
 */
#include <ctype.h>
#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/thread.h>
#include <nlutils/nlutils.h>

#include "unpack.h"

struct plot_info {
	const uint16_t *in;
	uint8_t *out;
};

struct unpack_info {
	const uint8_t *in;
	uint16_t *out;
	size_t len;
};

struct kvp_info {
	VALUE hash;
	unsigned int symbolize:1;
};

// The KinUtils Ruby module
VALUE KinUtils = Qnil;
static rb_encoding *utf8;

void *unpack_blocking(void *data)
{
	struct unpack_info *info = data;
	size_t i, o;

	for(i = 0, o = 0; i < info->len; i += 11, o += 8) {
		unpack11_to_16(info->in + i, info->out + o);
	}

	return NULL;
}

// Ruby function to unpack 11-bit depth data to 16-bit left-aligned values
VALUE rb_unpack11_to_16(VALUE self, VALUE data)
{
	size_t len, newlen;
	VALUE outbuf;

	Check_Type(data, T_STRING);
	len = RSTRING_LEN(data);
	if(len < 11) {
		rb_raise(rb_eArgError, "Input data must be at least 11 bytes long (got %zu).", len);
	}

	newlen = len * 16 / 11;
	outbuf = rb_str_buf_new(newlen - 1);
	rb_str_resize(outbuf, newlen); // Prevent GC from shrinking the buffer

	rb_thread_call_without_gvl(
			unpack_blocking,
			&(struct unpack_info){.in = (uint8_t *)RSTRING_PTR(data), .out = (uint16_t *)RSTRING_PTR(outbuf), .len = len},
			NULL,
			NULL
			);

	return outbuf;
}

VALUE plot_linear_blocking(void *data)
{
	struct plot_info *info = data;
	plot_linear(info->in, info->out);
	return Qnil;
}

// Ruby function to plot perspective view of linear depth data.  Input:
// 640x480x16bit gray depth image.  Output: 640x480 8-bit gray image.
VALUE rb_plot_linear(VALUE self, VALUE data)
{
	VALUE outbuf;
	size_t len;

	// TODO: Allow reusing a previously-allocated output string

	Check_Type(data, T_STRING);
	len = RSTRING_LEN(data);
	if(len < 640 * 480 * 2) {
		rb_raise(rb_eArgError, "Input data must be at least 640*480*2 bytes (got %zu).", len);
	}

	// It seems rb_str_buf_new() adds a byte for terminating NUL, but
	// rb_str_resize() does not.
	outbuf = rb_str_buf_new(640 * 480 - 1);
	rb_str_resize(outbuf, 640 * 480);

	rb_thread_call_without_gvl(
			plot_linear_blocking,
			&(struct plot_info){.in = (uint16_t *)RSTRING_PTR(data), .out = (uint8_t *)RSTRING_PTR(outbuf)},
			NULL,
			NULL
			);
	return outbuf;
}

VALUE plot_overhead_blocking(void *data)
{
	struct plot_info *info = data;
	plot_overhead(info->in, info->out);
	return Qnil;
}

// Ruby function to plot overhead view of depth data.  Input: 640x480x16bit
// gray depth image.  Output: XPIXxZPIX 8-bit gray image.
VALUE rb_plot_overhead(VALUE self, VALUE data)
{
	VALUE outbuf;
	size_t len;

	// TODO: Allow reusing a previously-allocated output string

	Check_Type(data, T_STRING);
	len = RSTRING_LEN(data);
	if(len < 640 * 480 * 2) {
		rb_raise(rb_eArgError, "Input data must be at least 640*480*2 bytes (got %zu).", len);
	}

	// It seems rb_str_buf_new() adds a byte for terminating NUL, but
	// rb_str_resize() does not.
	outbuf = rb_str_buf_new(XPIX * ZPIX - 1);
	rb_str_resize(outbuf, XPIX * ZPIX);

	rb_thread_call_without_gvl(
			plot_overhead_blocking,
			&(struct plot_info){.in = (uint16_t *)RSTRING_PTR(data), .out = (uint8_t *)RSTRING_PTR(outbuf)},
			NULL,
			NULL
			);
	return outbuf;
}

VALUE plot_side_blocking(void *data)
{
	struct plot_info *info = data;
	plot_side(info->in, info->out);
	return Qnil;
}

// Ruby function to plot side view of depth data.  Input: 640x480x16bit
// gray depth image.  Output: ZPIXxYPIX 8-bit gray image.
VALUE rb_plot_side(VALUE self, VALUE data)
{
	VALUE outbuf;
	size_t len;

	// TODO: Allow reusing a previously-allocated output string

	Check_Type(data, T_STRING);
	len = RSTRING_LEN(data);
	if(len < 640 * 480 * 2) {
		rb_raise(rb_eArgError, "Input data must be at least 640*480*2 bytes (got %zu).", len);
	}

	// It seems rb_str_buf_new() adds a byte for terminating NUL, but
	// rb_str_resize() does not.
	outbuf = rb_str_buf_new(ZPIX * YPIX - 1);
	rb_str_resize(outbuf, ZPIX * YPIX);

	rb_thread_call_without_gvl(
			plot_side_blocking,
			&(struct plot_info){.in = (uint16_t *)RSTRING_PTR(data), .out = (uint8_t *)RSTRING_PTR(outbuf)},
			NULL,
			NULL
			);

	return outbuf;
}

VALUE plot_front_blocking(void *data)
{
	struct plot_info *info = data;
	plot_front(info->in, info->out);
	return Qnil;
}

// Ruby function to plot front view of depth data.  Input: 640x480x16bit
// gray depth image.  Output: XPIXxYPIX 8-bit gray image.
VALUE rb_plot_front(VALUE self, VALUE data)
{
	VALUE outbuf;
	size_t len;

	// TODO: Allow reusing a previously-allocated output string

	Check_Type(data, T_STRING);
	len = RSTRING_LEN(data);
	if(len < 640 * 480 * 2) {
		rb_raise(rb_eArgError, "Input data must be at least 640*480*2 bytes (got %zu).", len);
	}

	// It seems rb_str_buf_new() adds a byte for terminating NUL, but
	// rb_str_resize() does not.
	outbuf = rb_str_buf_new(XPIX * YPIX - 1);
	rb_str_resize(outbuf, XPIX * YPIX);

	rb_thread_call_without_gvl(
			plot_front_blocking,
			&(struct plot_info){.in = (uint16_t *)RSTRING_PTR(data), .out = (uint8_t *)RSTRING_PTR(outbuf)},
			NULL,
			NULL
			);

	return outbuf;
}

// Unescapes a copy of the given string
// TODO: merge with rb_unescape_modify
VALUE rb_unescape(int argc, VALUE *args, VALUE self)
{
	int dequote = 0;
	int include_zero = 0;
	VALUE str;
	long len;
	int ret;

	if(argc > 2) {
		rb_raise(rb_eArgError, "Only 0 to 2 parameters supported.");
	}
	if(argc >= 1) {
		Check_Type(args[0], T_FIXNUM);
		dequote = FIX2INT(args[0]);
		if(dequote < 0 || dequote > 2) {
			rb_raise(rb_eArgError, "First parameter (dequote) must be one of the ESCAPE_* constants.");
		}
	}
	if(argc == 2) {
		if(args[1] == Qtrue) {
			include_zero = 1;
		} else if(args[1] == Qfalse) {
			include_zero = 0;
		} else {
			rb_raise(rb_eArgError, "Second parameter (include_zero) must be true or false.");
		}
	}

	str = rb_str_dup(self);
	if(!rb_enc_asciicompat(rb_enc_get(self))) {
		str = rb_str_export_to_enc(str, utf8);
	}

	len = RSTRING_LEN(str);
	ret = nl_unescape_string(RSTRING_PTR(str), include_zero, dequote);
	if(ret == -1) {
		rb_raise(rb_eRuntimeError, "Error unescaping string.");
	}

	rb_str_resize(str, len - ret);

	return str;
}

// Unescapes the given string in place
VALUE rb_unescape_modify(int argc, VALUE *args, VALUE self)
{
	int dequote = 0;
	int include_zero = 0;
	long len;
	int ret;

	if(argc > 2) {
		rb_raise(rb_eArgError, "Only 0 to 2 parameters supported.");
	}
	if(argc >= 1) {
		Check_Type(args[0], T_FIXNUM);
		dequote = FIX2INT(args[0]);
		if(dequote < 0 || dequote > 2) {
			rb_raise(rb_eArgError, "First parameter (dequote) must be one of the ESCAPE_* constants.");
		}
	}
	if(argc == 2) {
		if(args[1] == Qtrue) {
			include_zero = 1;
		} else if(args[1] == Qfalse) {
			include_zero = 0;
		} else {
			rb_raise(rb_eArgError, "Second parameter (include_zero) must be true or false.");
		}
	}

	rb_check_frozen(self);

	if(!rb_enc_asciicompat(rb_enc_get(self))) {
		rb_raise(rb_eRuntimeError, "This method only works with ASCII-compatible encodings.");
	}

	len = RSTRING_LEN(self);
	ret = nl_unescape_string(RSTRING_PTR(self), include_zero, dequote);
	if(ret == -1) {
		rb_raise(rb_eRuntimeError, "Error unescaping string.");
	}

	rb_str_resize(self, len - ret);

	return self;
}

// Parsing callback for rb_kvp
static void kvp_hashcb(void *data, char *key, char *strvalue, struct nl_variant value)
{
	struct kvp_info *info = data;
	VALUE rbkey;

	if (info->symbolize) {
		rbkey = ID2SYM(rb_intern(key));
	} else {
		rbkey = rb_str_new2(key);
	}

	switch(value.type) {
		case INTEGER:
			rb_hash_aset(info->hash, rbkey, INT2NUM(value.value.integer));
			break;

		case FLOAT:
			rb_hash_aset(info->hash, rbkey, rb_float_new(value.value.floating));
			break;

		case STRING:
			rb_hash_aset(info->hash, rbkey, rb_str_new2(value.value.string));
			break;

		default:
			rb_hash_aset(info->hash, rbkey, rb_str_new2(strvalue));
			break;
	}
}

// Parses a key-value pair string into a hash.  The :symbolize_keys option may
// be specified to use symbols instead of strings for the hash keys.
VALUE rb_kvp(int argc, VALUE *argv, VALUE self)
{
	VALUE hash = rb_hash_new();

	if (argc < 0 || argc > 1 || (argc == 1 && !RB_TYPE_P(argv[0], T_HASH))) {
		rb_raise(rb_eArgError, "Call with no parameters, or with an options Hash.");
	}

	VALUE symbolize = Qnil;

	if (argc == 1) {
		symbolize = rb_hash_lookup(argv[0], ID2SYM(rb_intern("symbolize_keys")));
	}

	struct kvp_info info = {
		.hash = hash,
		.symbolize = RB_TEST(symbolize),
	};

	nl_parse_kvp(RSTRING_PTR(self), nl_kvp_wrapper, &(struct nl_kvp_wrap){kvp_hashcb, &info});

	return hash;
}


void Init_kinutils()
{
	ku_init_lut();

	VALUE nl = rb_define_module("NL");
	VALUE knd_client = rb_define_module_under(nl, "KndClient");

	KinUtils = rb_define_module_under(knd_client, "Kinutils");

	utf8 = rb_enc_find("UTF-8");
	if(!utf8) {
		rb_raise(rb_eException, "No UTF-8 encoding.");
	}

	// FIXME: don't define global constants, put them in a namespace

	rb_define_global_const("KNC_XPIX", INT2FIX(XPIX));
	rb_define_global_const("KNC_YPIX", INT2FIX(YPIX));
	rb_define_global_const("KNC_ZPIX", INT2FIX(ZPIX));
	rb_define_global_const("KNC_PXZMAX", INT2FIX(PXZMAX));
	rb_define_global_const("KNC_XMAX", INT2FIX(XMAX));
	rb_define_global_const("KNC_YMAX", INT2FIX(YMAX));
	rb_define_global_const("KNC_ZMAX", INT2FIX(ZMAX));

	rb_define_global_const("ESCAPE_NO_DEQUOTE", INT2FIX(ESCAPE_NO_DEQUOTE));
	rb_define_global_const("ESCAPE_DEQUOTE", INT2FIX(ESCAPE_DEQUOTE));
	rb_define_global_const("ESCAPE_IF_QUOTED", INT2FIX(ESCAPE_IF_QUOTED));

	rb_define_module_function(KinUtils, "unpack11_to_16", rb_unpack11_to_16, 1);
	rb_define_module_function(KinUtils, "plot_linear", rb_plot_linear, 1);
	rb_define_module_function(KinUtils, "plot_overhead", rb_plot_overhead, 1);
	rb_define_module_function(KinUtils, "plot_side", rb_plot_side, 1);
	rb_define_module_function(KinUtils, "plot_front", rb_plot_front, 1);

	// TODO: Move to a different extension
	rb_define_method(rb_cString, "kin_unescape", rb_unescape, -1);
	rb_define_method(rb_cString, "kin_unescape!", rb_unescape_modify, -1);

	rb_define_method(rb_cString, "kin_kvp", rb_kvp, -1);

	// TODO: Add xworld,yworld,lut,reverse_lut,unpack_to_world/unpack_to_8 functions
}
