What makes zqcc different from id's qcc

- "local" is not required before local variables
- semicolon after function body is optional
- redundant semicolons at file scope are allowed
- empty statements are allowed
- empty curly braces are allowed
- variables of type 'void' are forbidden, except for end_sys_fields and end_sys_globals
- C-style function declarations and definitions are allowed
- hexadecimal numeric constants are understood
- const modifier is supported, e.g. "const float IT_SHOTGUN = 0x01;"
	constants may not be assigned to
- varargs builtin functions with some required parms are supported.
	e.g. "void bprint(float level, string s, ...)"

