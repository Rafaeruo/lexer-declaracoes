%option noyywrap yylineno

%%

"char"|"int"|"float" { printf("TIPO(%s) ", yytext); }
[a-zA-Z_][a-zA-Z0-9_]* { printf("ID(%s) ", yytext); }

"," { printf("VIRG "); }
";" { printf("PONTOVIRG "); }

[ \t\n] ;

. { printf("NAO RECONHECIDO(%s) na linha %i ", yytext, yylineno); }

%%

int main(void) {
    yylex();
    return 0;
}