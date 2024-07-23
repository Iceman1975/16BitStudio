grammar miniJava;

goal
	:	mainClassDef
		classDef*
		EOF
	;

mainClassDef
	:	'class' clsName=ID
		'{' 'public' 'static' 'void' 'main' '(' 'String' '[' ']' ID ')' '{' statement '}' '}'
	;

classDef
	:	'class' clsName=ID ('extends' parentName=ID)?
		'{' ( variable )*
			( method )* '}'
	;

variable
	:	varType name=ID ';'
	;

method
	:	'public' varType name=ID parameters
		'{'
			variable*
			statement+
		'}'
	;

parameters
	:	'(' parameterList? ')'
	;

parameterList
	:	parameter
	|   parameter ',' parameterList
	;

parameter
	:	varType name=ID
	;

varType
	:	'int' '[' ']'
	|	'bool'
	|	'int'
	|	ID
	;

statement
	:	'{' statement* '}'
	/* Statement block */
	|	'if' '(' expression ')'
			statement
		( 'else'
			statement )?
	/* Condition statement, with syntax extended: allow if block without else part. */
	|	'while' '(' expression ')'
			statement
	/* While-loop statement*/
	|	'do'
			statement
		'while' '(' expression ')'
	/* Do-while-loop statement, extended syntax */
	|	'for' '(' ( expression )? ';'  ( expression )? ';' ( expression )? ')'
			statement
	/* For-loop statement, extended syntax*/
	|	'for' '(' ID ':' expression ')'
			statement
	|	'System.out.println' '(' expression ')' ';'
	/* Print statement */
	|	ID '=' expression ';'
	/* Assignment statement */
	|	ID '[' expression ']' '=' expression ';'
	/* Array assignment statement*/
	|	'return' expression ';'
	/* Return statement */
	;

expression
	:	expression '[' expression ']'
	/* Array access */
	|	expression '.' 'length'
	/* Array length */
	|	expression '.' ID methodCall
	/* Method call */
	|	'-' expression
	/* Neg */
	|	'!' expression
	/* Not */
	|	'new' 'int' '[' expression ']'
	/* New array */
	|	'new' ID '(' ')'
	/* New object */
	|	expression '+' expression
	/* Add */
	|	expression '-' expression
	/* Subtract */
	|	expression '*' expression
	/* Multiply */
	|	expression '<' expression
	/* Less than */
	|	expression '&&' expression
	/* Logical and */
	|	INT
	|	BOOL
	|	ID
	|	'this'
	|	'(' expression ')'
	/* Paren */
	;

methodCall
	:	'(' ( expression ( ',' expression )* )? ')'
	;

INT
	:	( '0' | [1-9][0-9]* | ( '0x' [0-9a-fA-F]+ ) )
	;

BOOL
	:	'true'
	|	'false'
	;

ID
	:	[a-zA-Z_][0-9a-zA-Z_]*
	;

WS
	:	[ \t\r\n]+ -> skip
	;

COMMENT
	:	'/*' .*? '*/' -> skip
	;

LINE_COMMENT
	:	'//' ~[\r\n]* -> skip
	;
