grammar AmigaScript;

goal
	:	classDef*
		EOF
	;

classDef
	:	'class' clsName=ID 'extends' parentName=parentNames
		'{' ( staticVar )*
			( constant )*
			( variable )*
			( method )* '}'
	;

variable
	:	varType name=ID '=' INT ';'
	;
	
staticVar
	:	'static' varType name=ID '=' INT ';'
	;
	
constant
	:	'const' varType name=ID '=' INT ';'
	;

method
	:	'public' 'void' name=methodName parameters
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
	|	'boolean'
	|	'byte'
	|	'byte' '[' ']'
	|	'short' '[' ']'
	|	'short'	
	|	'int'
	|	ID
	|   THIS
	;
	
methodName
	:	'update'
	|	'collide'
	|	'onHit'
	|	'onCreate'
	|	'onEnable'
	|	'onDisable'
	|	'onKill'
	|	'onCollision'	
	;
	
parentNames
	:	'EnemyBehaviour'
	|	'BulletBehaviour'
	|	'PlayerBehaviour'	
	;
	
statement
	:	'{' statement* '}'
	|	statementAssign
	|	statementIf
	| 	statementWhile
	| 	statementFor
	| 	statementAssignArray
	| 	statementForArray
	| 	statementReturn
	|	methodCall
	;

statementAssign
	:	ID '=' expression ';'
	;
statementAssignArray
	:	ID '[' expression ']' '=' expression ';'
	;
	
statementIf
	:	'if' '(' expression ')'
			statement
		( 'else'
			statement )?
	;

statementWhile
	:	'while' '(' expression ')'
			statement
	;


statementFor
	:	'for' '(' ( expression )? ';'  ( expression )? ';' ( expression )? ')'
			statement
	;
	
statementForArray
	:	'for' '(' ID ':' expression ')'
			statement
	;

statementReturn
	:	'return' expression ';'
	;

expression
	:	expression '[' expression ']'		#array
	|	expression '.' 'length'				#arrayLength
	|	expression '.' ID methodCall		#idCall
	|	'-' expression						#sub
	|	'!' expression						#not
	|	'new' 'int' '[' expression ']'		#newArray
	|	'new' ID '(' ')'					#new
	|	expression '+' expression			#add
	|	expression '-' expression			#sub
	|	expression '*' expression			#mul
	|	expression '/' expression			#div
	|	expression '<' expression			#lt
	|	expression '<=' expression			#lte
	|	expression '>' expression			#gt
	|	expression '>=' expression			#gte
	|	expression '==' expression			#eq
	|	expression '!=' expression			#ne
	|	expression '&&' expression			#and
	|	expression '||' expression			#or
	|	INT									#int
	|	BOOL								#bool
	|	ID									#id
	|	'this'								#this
	|	'(' expression ')'					#exp
	;



methodCall
	:	methodCallName=ID'(' ( methodCallParameter ( ',' methodCallParameter )* )? ')' ';'
	; 
	

methodCallParameter
	:	attribute=(ID|INT)
	;

INT
	:	( '0' | [1-9][0-9]* | ( '0x' [0-9a-fA-F]+ ) )
	;

BOOL
	:	'true'
	|	'false'
	;

ID
	:	[a-zA-Z_][0-9a-zA-Z_\.]*
	;

THIS
	:	'this.'[a-zA-Z_][0-9a-zA-Z_\.]*
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
