/* Parser (analisador sintatico) da linguagem descrita no topo do clarker.l.
 *
 * As regras abaixo sao a mesma gramatica do clarker.l, reescrita em BNF: o Bison nao aceita as
 * construcoes { repeticao } e [ opcional ] do EBNF, entao
 *   { x }  vira uma lista recursiva a esquerda que pode ser vazia: lista: %empty | lista x ;
 *   [ x ]  vira duas alternativas, uma com x e outra sem
 */

%{
#include <stdio.h>

int  yylex(void);                   // gerada pelo Flex a partir do clarker.l
void yyerror(const char *mensagem); // chamada pelo Bison quando encontra um erro de sintaxe

extern int yylineno;               // mantida pelo Flex (%option yylineno)
extern int total_de_erros_lexicos; // contado pelo clarker.l
%}

    /* Mensagens de erro dizem o que era esperado ("unexpected X, expecting Y"), em vez de so "syntax error" */
%define parse.error detailed

    /* Copiado para o parser.tab.h, que o clarker.l tambem inclui: o nome da linguagem, usado nas
     * mensagens do lexer e do parser, fica definido num lugar so */
%code provides {
#define NOME_DA_LINGUAGEM "LARP"
}

    /* Tokens (terminais), com os mesmos nomes impressos pelo lexer. O texto entre aspas é so um
     * apelido para as mensagens de erro. */
%token TIPO ID LITERAL_INT LITERAL_FLOAT LITERAL_STRING
%token IF "if" ELSE "else" ROUTE "route" TO "to" FALL "fall"
%token VIRGULA "," PONTO_VIRGULA ";" DOIS_PONTOS ":" ATRIBUICAO "=" SETA "->"
%token ABRE_PARENTESES "(" FECHA_PARENTESES ")" ABRE_CHAVES "{" FECHA_CHAVES "}"
%token MAIS "+" MENOS "-" VEZES "*" DIVIDIDO "/"
%token MENOR "<" MENOR_IGUAL "<=" MAIOR ">" MAIOR_IGUAL ">=" IGUAL "==" DIFERENTE "!="

%%

programa
    : lista_instrucoes
    ;

lista_instrucoes
    : %empty
    | lista_instrucoes instrucao
    ;

instrucao
    : declaracao
    | atribuicao
    | if
    | route
    | fall
    ;

    /* Declaracoes */

declaracao
    : TIPO lista_ids PONTO_VIRGULA
    | TIPO lista_ids ATRIBUICAO lista_expressoes PONTO_VIRGULA
    ;

lista_ids
    : ID
    | lista_ids VIRGULA ID
    ;

lista_expressoes
    : valor
    | lista_expressoes VIRGULA valor
    ;

valor
    : expressao
    | ternario
    ;

    /* if/else e ternario. Os dois comecam com IF "(" condicao ")", mas nunca aparecem no mesmo
     * lugar: o if e uma instrucao e o ternario so aparece como valor (depois de um "=") */

if
    : IF ABRE_PARENTESES expressao_de_condicao FECHA_PARENTESES bloco else_opcional
    ;

else_opcional
    : %empty
    | ELSE bloco
    ;

bloco
    : ABRE_CHAVES lista_instrucoes FECHA_CHAVES
    ;

ternario
    : IF ABRE_PARENTESES expressao_de_condicao FECHA_PARENTESES SETA instrucoes_ternario ELSE SETA instrucoes_ternario
    ;

instrucoes_ternario
    : lista_declaracoes_e_atribuicoes expressao
    | lista_declaracoes_e_atribuicoes ternario
    ;

lista_declaracoes_e_atribuicoes
    : %empty
    | lista_declaracoes_e_atribuicoes declaracao
    | lista_declaracoes_e_atribuicoes atribuicao
    ;

    /* route/fall */

route
    : ROUTE expressao TO cases
    ;

cases
    : ABRE_CHAVES lista_cases FECHA_CHAVES else_opcional
    ;

lista_cases
    : %empty
    | lista_cases case
    ;

case
    : literal DOIS_PONTOS bloco
    | ID DOIS_PONTOS bloco
    ;

fall
    : FALL PONTO_VIRGULA
    ;

    /* Atribuicao */

atribuicao
    : ID ATRIBUICAO valor PONTO_VIRGULA
    ;

    /* Expressoes. A precedencia vem da propria estrutura da gramatica: "*" e "/" ficam num nivel
     * mais baixo (termo) que "+" e "-" (expressao), entao sao agrupados primeiro. A recursao a
     * esquerda (expressao: expressao MAIS termo) faz os operadores associarem a esquerda */

expressao_de_condicao
    : expressao operador_relacional expressao
    ;

operador_relacional
    : MENOR
    | MENOR_IGUAL
    | MAIOR
    | MAIOR_IGUAL
    | IGUAL
    | DIFERENTE
    ;

expressao
    : termo
    | expressao MAIS termo
    | expressao MENOS termo
    ;

termo
    : fator
    | termo VEZES fator
    | termo DIVIDIDO fator
    ;

fator
    : literal
    | ID
    | ABRE_PARENTESES expressao FECHA_PARENTESES
    ;

literal
    : LITERAL_INT
    | LITERAL_FLOAT
    | LITERAL_STRING
    ;

%%

void yyerror(const char *mensagem)
{
    printf("[%s] ERRO SINTATICO na linha %d: %s\n", NOME_DA_LINGUAGEM, yylineno, mensagem);
}

int main(void)
{
    int resultado = yyparse(); // 0 = programa aceito, 1 = erro de sintaxe (ja reportado pelo yyerror)

    if (resultado != 0) {
        return 1;
    }

    // A estrutura esta correta, mas o lexer pode ter descartado caracteres invalidos no caminho
    if (total_de_erros_lexicos > 0) {
        printf("[%s] Estrutura sintaticamente correta, mas com %d erro(s) lexico(s)\n",
               NOME_DA_LINGUAGEM, total_de_erros_lexicos);
        return 1;
    }

    printf("[%s] Programa sintaticamente correto\n", NOME_DA_LINGUAGEM);
    return 0;
}
