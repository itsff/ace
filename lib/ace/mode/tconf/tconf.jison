%lex

digit           [0-9]
letter          [a-zA-Z_]
whitespace      [ \t]
eol             ((\r)|(\n)|(\r\n))

%options flex case-insensitive

%% /* Regular expressions */

#import        { return 'TOKEN_INCLUDE'; }

true           { return 'TOKEN_BOOL'; }
#true          { return 'TOKEN_BOOL'; }

false          { return 'TOKEN_BOOL'; }
#false         { return 'TOKEN_BOOL'; }

and            { return 'TOKEN_LOGICAL_AND'; }
or             { return 'TOKEN_LOGICAL_OR'; }
not            { return 'TOKEN_LOGICAL_NOT'; }

if             { return 'TOKEN_IF';      }
then           { return 'TOKEN_THEN';    }
elseif         { return 'TOKEN_ELSE_IF'; }
else           { return 'TOKEN_ELSE';    }
endif          { return 'TOKEN_ENDIF';   }

in             { return 'TOKEN_IN';      }

#null          { return 'TOKEN_BLANK';   }
null           { return 'TOKEN_BLANK';   }

#blank         { return 'TOKEN_BLANK';   }
#real          { return 'TOKEN_REAL';    } /* FIDMappableTypes::real64_t => Utilities::FixedReal */
#price         { return 'TOKEN_REAL';    } /* FIDMappableTypes::price_t  => Utilities::PriceType => RDFD::Utilities::FixedReal!!! */ 
#double        { return 'TOKEN_DOUBLE';  }

"("                 { return 'TOKEN_L_PAREN'; }
")"                 { return 'TOKEN_R_PAREN'; }

"["                 { return 'TOKEN_L_BRACE'; }
"]"                 { return 'TOKEN_R_BRACE'; }

"{"                 { return 'TOKEN_L_C_BRACE'; }
"}"                 { return 'TOKEN_R_C_BRACE'; }


"=="                { return 'TOKEN_COMP_EQUAL';         }
"!="                { return 'TOKEN_COMP_NOT_EQUAL';     }
">"                 { return 'TOKEN_COMP_GREATER';       }
">="                { return 'TOKEN_COMP_GREATER_EQUAL'; }
"<"                 { return 'TOKEN_COMP_LESS';          }
"<="                { return 'TOKEN_COMP_LESS_EQUAL';    }

"+"                 { return 'TOKEN_ARITHMETIC_ADD'; }
"-"                 { return 'TOKEN_ARITHMETIC_SUB'; }
"*"                 { return 'TOKEN_ARITHMETIC_MUL'; }
"/"                 { return 'TOKEN_ARITHMETIC_DIV'; }
"%"                 { return 'TOKEN_ARITHMETIC_MOD'; }

"."                 { return 'TOKEN_DOT';            }
","                 { return 'TOKEN_COMMA';          }
":"                 { return 'TOKEN_COLON';          }
"="                 { return 'TOKEN_EQUALS';         }

"??"                { return 'TOKEN_2_QUESTION_MARKS';  }



"#"({letter}|{digit})* {
                    return 'TOKEN_BUILTIN_IDENTIFIER';
                }


{letter}({letter}|{digit})* {
                    return 'TOKEN_IDENTIFIER';
                }

{digit}+            { return 'TOKEN_INT';   }
{digit}+"."{digit}* { return 'TOKEN_FLOAT'; }

\"(\\.|[^\\"])*\"   { return 'TOKEN_STRING';}
\'(\\.|[^\\'])*\'   { return 'TOKEN_STRING';}



"\\"{whitespace}*{eol}          { }
{eol}                           { return 'TOKEN_NEW_LINE'; }


    /* ignore whitespace and anything after // */
{whitespace}*                   {}
"//".*                          {}

.                               { return 'LEXICAL_ERROR'; }

<<EOF>>               return 'EOF';
                        
/lex

/* Precedence of operations */
%left 'TOKEN_LOGICAL_NOT'

%left 'TOKEN_ARITHMETIC_ADD' 'TOKEN_ARITHMETIC_SUB'
%left 'TOKEN_ARITHMETIC_MUL' 'TOKEN_ARITHMETIC_DIV' 'TOKEN_ARITHMETIC_MOD'

%left 'TOKEN_COMP_LESS' 'TOKEN_COMP_LESS_EQUAL' 'TOKEN_COMP_GREATER' 'TOKEN_COMP_GREATER_EQUAL'
%left 'TOKEN_COMP_EQUAL' 'TOKEN_COMP_NOT_EQUAL'

%left 'TOKEN_LOGICAL_OR'
%left 'TOKEN_LOGICAL_AND'

%left 'TOKEN_2_QUESTION_MARKS'

%start input
%%

start
    : input EOF
    ;

input
    : /* empty */
    | exp
    | statement_list
    ;


constant
    : TOKEN_INT
    | TOKEN_FLOAT
    | TOKEN_REAL TOKEN_L_PAREN TOKEN_INT TOKEN_COMMA TOKEN_INT TOKEN_R_PAREN
    | TOKEN_REAL TOKEN_L_PAREN TOKEN_FLOAT TOKEN_R_PAREN
    | TOKEN_REAL TOKEN_L_PAREN TOKEN_INT TOKEN_R_PAREN
    | TOKEN_DOUBLE TOKEN_L_PAREN TOKEN_FLOAT TOKEN_R_PAREN
    | TOKEN_DOUBLE TOKEN_L_PAREN TOKEN_INT TOKEN_R_PAREN
    | TOKEN_STRING
    ;

null_constant
    : TOKEN_BLANK
    ;

bool_constant
    : TOKEN_BOOL
    ; 

field_ref
    : TOKEN_IDENTIFIER TOKEN_DOT TOKEN_IDENTIFIER
    ;


atom_exp
    : constant
    | field_ref
    | TOKEN_BUILTIN_IDENTIFIER
    ;

arithmetic_exp
    : atom_exp
    | func_call
    | TOKEN_L_PAREN arithmetic_exp TOKEN_R_PAREN
    | arithmetic_exp TOKEN_2_QUESTION_MARKS arithmetic_exp
    | arithmetic_exp TOKEN_ARITHMETIC_ADD arithmetic_exp
    | arithmetic_exp TOKEN_ARITHMETIC_SUB arithmetic_exp
    | arithmetic_exp TOKEN_ARITHMETIC_MUL arithmetic_exp
    | arithmetic_exp TOKEN_ARITHMETIC_DIV arithmetic_exp
    | arithmetic_exp TOKEN_ARITHMETIC_MOD arithmetic_exp
    | TOKEN_ARITHMETIC_SUB arithmetic_exp
    ;


comp_exp_factor
    : bool_constant
    | arithmetic_exp
    | null_constant
    ;

comp_exp
    : bool_constant
    | comp_exp_factor TOKEN_COMP_EQUAL comp_exp_factor
    | comp_exp_factor TOKEN_COMP_NOT_EQUAL comp_exp_factor
    | comp_exp_factor TOKEN_COMP_GREATER comp_exp_factor
    | comp_exp_factor TOKEN_COMP_GREATER_EQUAL comp_exp_factor
    | comp_exp_factor TOKEN_COMP_LESS comp_exp_factor
    | comp_exp_factor TOKEN_COMP_LESS_EQUAL comp_exp_factor
    | TOKEN_L_PAREN comp_exp TOKEN_R_PAREN
    ;

logic_exp
    : comp_exp
    | in_array_exp
    | logic_exp TOKEN_LOGICAL_AND logic_exp
    | logic_exp TOKEN_LOGICAL_OR logic_exp
    | TOKEN_LOGICAL_NOT logic_exp
    | TOKEN_L_PAREN logic_exp TOKEN_R_PAREN
    ;





/* Maps  */
map_key
   : constant
   | bool_constant
   | null_constant
   ;

map_value
   : atom_exp
   | bool_constant
   | null_constant
   ;

map_item
   : map_key TOKEN_COLON map_value
   | map_item TOKEN_COMMA map_item
   ;

map_exp
   : TOKEN_L_C_BRACE map_item TOKEN_R_C_BRACE
   ;




/* Arrays */
array_item
    : atom_exp
    | bool_constant
    | null_constant
    | array_item TOKEN_COMMA array_item
    ;

array_exp
    : TOKEN_L_BRACE array_item TOKEN_R_BRACE
    ;


in_arg_list
    : /* empty */
    | logic_exp
    | arithmetic_exp
    | array_exp
    | map_exp
    | TOKEN_IDENTIFIER
    | in_arg_list TOKEN_COMMA in_arg_list
    ;

out_arg_list
    : field_ref
    | out_arg_list TOKEN_COMMA out_arg_list
    ;
    
lhs_array
    : TOKEN_L_BRACE out_arg_list TOKEN_R_BRACE
    ;

proc_call
    : TOKEN_IDENTIFIER TOKEN_L_PAREN in_arg_list TOKEN_R_PAREN
    ;

named_func_call
    : TOKEN_IDENTIFIER TOKEN_L_PAREN in_arg_list TOKEN_R_PAREN
    ;
    
func_call
    : named_func_call
    | in_array_exp
    ;

in_array_exp
    : atom_exp TOKEN_IN array_exp
    | TOKEN_L_PAREN in_array_exp TOKEN_R_PAREN
    ;
    
assignment
    : field_ref TOKEN_EQUALS arithmetic_exp
    | field_ref TOKEN_EQUALS logic_exp
    | field_ref TOKEN_EQUALS TOKEN_BLANK
    | lhs_array TOKEN_EQUALS arithmetic_exp
    | lhs_array TOKEN_EQUALS logic_exp
    | lhs_array TOKEN_EQUALS TOKEN_BLANK
    | TOKEN_IDENTIFIER TOKEN_EQUALS arithmetic_exp
    | TOKEN_IDENTIFIER TOKEN_EQUALS logic_exp
    | TOKEN_IDENTIFIER TOKEN_EQUALS TOKEN_BLANK
    ;


separator
    : TOKEN_NEW_LINE
    ;


included_file
    : TOKEN_INCLUDE TOKEN_STRING
    ;


exp
    : logic_exp
    | arithmetic_exp
    ;


statement
    : assignment
    | proc_call
    | if_statement
    | included_file
    ;


statement_list
    : /* empty */
    | statement statement_list
    | separator statement_list
    ;


if_statement
    : if_statement_start end_block
    | if_statement_start if_statement_else_if end_block
    ;

if_statement_start
    : if_statement_start_exp statement_list
    ;

if_statement_start_exp
    : TOKEN_IF logic_exp TOKEN_THEN
    ;

if_statement_else_if_exp
    : TOKEN_ELSE_IF logic_exp TOKEN_THEN
    ;


if_statement_else_if
    : TOKEN_ELSE separator statement_list
    | if_statement_else_if_exp statement_list
    | if_statement_else_if_exp statement_list if_statement_else_if
    ;


end_block
    : TOKEN_ENDIF separator
    ;
