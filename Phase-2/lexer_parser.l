 /* This file describes the rules for the lexer */
%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<limits.h>
    int ErrFlag = 0;
    #include "y.tab.h"
%}


 /* Declarations */

letter [a-zA-Z]
digit [0-9]
whitespace [ \t\r\f\v]+
identifier (_|{letter})({letter}|{digit}|_)*
hex [0-9a-fA-F]


 /* States */

%x PREPROCESSOR
%x MACROPREPROCESSOR
%x COMMENT
%x SLCOMMENT

%%


 /* Keywords */

"int"                               {return INT;}
"short"                             {return SHORT;}
"long"                              {return LONG;}
"char"                              {return CHAR;}
"void"                              {return VOID;}
"if"                                {return IF;}
"else"                              {return ELSE;}
"for"                               {return FOR;}
"do"                                {return DO;}
"while"                             {return WHILE;}
"goto"                              {return GOTO;}
"break"                             {return BREAK;}
"continue"                          {return CONTINUE;}
"return"                            {return RETURN;}




 /* Constants */

[0][x|X]{hex}+                      {yylval.dval = (int)strtol(yytext, NULL, 16); InsertEntry(ConstantTable, yytext , yylval.dval,"HEX",yylineno);return HEX_CONSTANT;}
[+/-]?{digit}+                      {yylval.dval = (int) atoi(yytext);InsertEntry(ConstantTable, yytext , yylval.dval,"INT",yylineno);return INT_CONSTANT;}
[+/-]?({digit}*)["."]({digit}+)     {yylval.dval = atof(yytext);InsertEntry(ConstantTable, yytext , yylval.dval,"FLOAT",yylineno);return DEC_CONSTANT;}
[+/-]?({digit}+)["."]({digit}*)     {yylval.dval = atof(yytext);InsertEntry(ConstantTable, yytext , yylval.dval,"FLOAT",yylineno);return DEC_CONSTANT;}

{identifier} {
  if(strlen(yytext) <= 32)
    {
     yylval.tbEntry = InsertEntry(SymbolTable, yytext, INT_MAX , "INT",yylineno);
      return IDENTIFIER;
    }
  else
  {
      printf("Error %d: Identifier too long,must be between 1 to 32 characters\n", yylineno);
      ErrFlag = 1;
  }
}


{digit}+({letter}|_)+               {printf("Error %d: Illegal identifier format\n", yylineno); ErrFlag = 1;}
{whitespace}                        ;


 /* Preprocessor Directives */

^"#include"                         {BEGIN PREPROCESSOR;}
<PREPROCESSOR>{whitespace}          ;
<PREPROCESSOR>"<"[^<>\n]*">"        {BEGIN INITIAL;}
<PREPROCESSOR>\"[^<>\n]*\"          {BEGIN INITIAL;}
<PREPROCESSOR>"\n"                  { yylineno++; BEGIN INITIAL; ErrFlag=1;}
<PREPROCESSOR>.                     {yyerror("Improper Header");}


 /* Macropreprocessor Directives */

^"#define"                                        {BEGIN MACROPREPROCESSOR;}
<MACROPREPROCESSOR>{whitespace}                   ;
<MACROPREPROCESSOR>({letter})({letter}|{digit})*  {BEGIN INITIAL;}
<MACROPREPROCESSOR>\n                             {yylineno++; BEGIN INITIAL;}
<MACROPREPROCESSOR>.                              {BEGIN INITIAL;ErrFlag=1;}


 /* Comments */

"/*"                                {BEGIN COMMENT;}
<COMMENT>.|{whitespace}             ;
<COMMENT>\n                         {yylineno++;}
<COMMENT>"*/"                       {BEGIN INITIAL;}
<COMMENT>"/*"                       {yyerror("Improper Comment");yyterminate();}
<COMMENT><<EOF>>                    {yyerror("Improper Comment");yyterminate();}
"//"                                {BEGIN SLCOMMENT;}
<SLCOMMENT>.                        ;
<SLCOMMENT>\n                       {yylineno++; BEGIN INITIAL;}


 /* Operators */

"+"                                 {return ADD;}
"-"                                 {return SUBTRACT;}
"*"                                 {return MULTIPLY;}
"/"                                 {return DIVIDE;}
"%"                                 {return MOD;}
"="                                 {return ASSIGN;}
"--"                                {return DECREMENT;}
"++"                                {return INCREMENT;}

"+="                                {return ADD_ASSIGN;}
"-="                                {return SUB_ASSIGN;}
"*="                                {return MUL_ASSIGN;}
"/="                                {return DIV_ASSIGN;}
"%="                                {return MOD_ASSIGN;}

">"                                 {return GREATER_THAN;}
"<"                                 {return LESSER_THAN;}
">="                                {return GREATER_EQ;}
"<="                                {return LESS_EQ;}
"=="                                {return EQUAL;}

"||"                                {return LG_OR;}
"&&"                                {return LG_AND;}
"!"                                 {return NOT;}
"!="                                {return NOT_EQ;}


 /* Strings and Characters */

\"[^\"\n]*$                         {ErrFlag=1; yyterminate();}
\"[^\"\n]*\" {
  if(yytext[yyleng-2]=='\\') {
    yyless(yyleng-1);
    yymore();
  }
  else
  {
    InsertEntry(ConstantTable,yytext,yylval.dval,"CHAR",yylineno);
    return STRING;
  }
}

\'[^\'\n]\'                         {InsertEntry(ConstantTable,yytext,yylval.dval,"CHAR",yylineno); return STRING;}


 /* Punctuators */


"\n"                                {yylineno++;}
.                                   {return yytext[0];}

%%
