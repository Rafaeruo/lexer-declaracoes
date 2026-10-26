/* Gramática (EBNF):
programa   = { instrucao } ; 
instrucao = declaracao | atribuicao |  if  | route | fall ;

declaracao = TIPO lista_ids [ "=" lista_expressoes ] ";" ; 
lista_ids  = ID { "," ID } ; 
lista_expressoes = valor { "," valor } ;
valor = expressao | ternario ;

if = "if" "("  expressao_de_condicao ")" bloco [ else ] ;
else = "else" bloco ;
bloco = "{" { instrucao } "}" ;
ternario = "if" "(" expressao_de_condicao ")" seta instrucoes_ternario "else" seta instrucoes_ternario ;
instrucoes_ternario = { declaracao | atribuicao } (expressao | ternario) ;
seta = "->" ;

route = "route" expressao "to" cases ;
cases = "{" { case } "}" [ else ] ;
case = (literal | ID) ":" bloco ;
fall = "fall" ";" ;

atribuicao = ID "=" valor ";" ;

expressao_de_condicao = expressao operador_relacional expressao ;
operador_relacional = "<" | "<=" | ">" | ">=" | "==" | "!=" ;

expressao = termo { ( "+" | "-" ) termo } ;
termo = fator { ( "*" | "/" ) fator } ; 
fator = literal | ID | "(" expressao ")" ;

literal = LITERAL_INT | LITERAL_FLOAT | LITERAL_STRING ;
LITERAL_INT = digito { digito } ;
LITERAL_STRING = '"'{ escape_string | caractere_string }'"' ;
caractere_string = ? qualquer caractere ASCII (dentre os imprimíveis) ? - ( '"' | "\" ) ;
escape_string = "\" ( '"' | "\" | "n" | "t" ) ;
LITERAL_FLOAT = digito { digito } "." digito { digito } ;

TIPO = "string" | "int" | "float" ; 
ID = identificador - keywords ;
identificador = letra { letra | digito } ; 
letra  = "a" | "b" | ... | "z" | "A" | "B" | ... | "Z" | "_" ; 
digito = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
keywords = TIPO | "if" | "else" | "route" | "to" | "fall" ;

// nao possui: operadores logicos (and, or), expressoes de condicao sao "unicas"
// nao possui: concatenacao de string. operador + so serve pra soma
// expressoes, que sao apenas aritmeticas nesse momento, ainda assim permitem strings como termo/fator -> isso precisa ser checado na semantica (poderia ser explicito aqui, mas igual tem que checar na semantica)
// fall pode estar em qualquer lugar sintaticamente, mas temos que checar semanticamente que vai estar so dentro de cases do route. fazer assim ajuda pra poder botar o fall nested em outras coisas dentro do case (mas sepa a gente n precisa disso?)
// pros cases, melhor nao deixar floats? e deixar so valores sem IDS? 
// pros cases, no enunciado ta ambiguo se é obrigatorio mais de um valor por case. VER
// cosnegui fazer os ternarios serem aninhados. isso ta explicito no ramo final do ternario e implicito nos outros pela atribuicao e declaracao que aceitam outros ternarios 
// ternarios so podem em atribuicoes e declaracoes, nao dentro de expressoes. Acho q de boa pra simplificar 
// declaracao com atribuicao direto com variso valores sepa nao precisa, enunciado n pede. daria pra remover pra simplificar
*/

/* 
 Este arquivo é usado como parte da compilação do parser, mas também pode ser compilado individualmente (para gerar um lexer avulso).
 Para gerar o lexer avulso, usar a flag -DSOMENTE_LEXER ao compilar (usar makefile). Com isso, ele imprime a sequencia de tokens, a tabela de simbolos
 e um resumo, usando o main() do fim deste arquivo.
*/

%option noyywrap yylineno

/* Definicoes com os mesmos nomes da gramatica, usadas no literal string.
 * caractere_string: ASCII imprimivel (espaco ate ~), exceto aspas (0x22) e barra invertida (0x5C),
 * por isso as duas faixas: de "#" ate "[" e de "]" ate "~" */
caractere_string  [ !#-\[\]-~]
escape_string     \\["\\nt]

%{
#include <stdio.h>
#include <string>
#include <vector>

#include "parser.tab.h" // codigos dos tokens (IF, ID, MENOR_IGUAL, etc.), gerado pelo Bison a partir do parser.y

// Tipo de simbolo para usar na tabela de simbolos
typedef struct {
    std::string nome;
    std::string tipo;
    // Apesar de no momento so permitirmos declaracoes e mais de uma ocorrencia indicar uma redeclaracao (erro semantico), 
    // ja salvamos a qtd de ocorrencias e linha onde aparece inicialmente a nivel de informacao
    int         linha_primeira_ocorrencia;
    int         quantidade_ocorrencias;
} Simbolo;

static std::vector<Simbolo> tabela_de_simbolos;
static int total_de_tokens        = 0;
int        total_de_erros_lexicos = 0; // nao e static porque o parser tambem consulta (para nao aceitar um programa com erro lexico)
static std::string ultimo_tipo_visto; // usado para inserir o tipo de cada simbolo na tabela de simbolos (fica errado quando as declaracoes nao estao sintaticamente corretas)

// Adiciona a ocorrencia de um simbolo na tabela de simbolos
static void registrar_simbolo(const std::string &nome, const std::string &tipo, int linha)
{
    size_t i;

    // Se ja esta na tabela, so atualiza a qtd de ocorrencias
    for (i = 0; i < tabela_de_simbolos.size(); i++) {
        if (tabela_de_simbolos[i].nome == nome) {
            tabela_de_simbolos[i].quantidade_ocorrencias++;
            return;
        }
    }

    Simbolo novo = { nome, tipo, linha, 1 };

    if (novo.tipo.empty()) {
        novo.tipo = "-";
    }

    tabela_de_simbolos.push_back(novo);
}

static void imprimir_tabela_de_simbolos(void)
{
    size_t i;

    printf("\nTABELA DE SIMBOLOS\n");

    if (tabela_de_simbolos.empty()) {
        printf("  (nenhum identificador reconhecido)\n");
        return;
    }

    printf("%4s  %-25s  %-6s  %13s  %11s\n",
           "#", "IDENTIFICADOR", "TIPO", "1a OCORRENCIA", "OCORRENCIAS");
    for (i = 0; i < tabela_de_simbolos.size(); i++) {
        printf("%4d  %-25s  %-6s  %13d  %11d\n",
               (int) (i + 1),
               tabela_de_simbolos[i].nome.c_str(),
               tabela_de_simbolos[i].tipo.c_str(),
               tabela_de_simbolos[i].linha_primeira_ocorrencia,
               tabela_de_simbolos[i].quantidade_ocorrencias);
    }
}

// Conta o token e devolve o codigo dele para o parser. No bin/lexer tambem imprime o nome do token
static int token(int codigo, const char *nome)
{
    total_de_tokens++;
#ifdef SOMENTE_LEXER
    printf("%s ", nome);
#endif
    return codigo;
}

// Igual a token(), mas imprime tambem o lexema, para tokens em que ele importa (ex.: ID(x), LITERAL_INT(10))
static int token_com_lexema(int codigo, const char *nome)
{
    total_de_tokens++;
#ifdef SOMENTE_LEXER
    printf("%s(%s) ", nome, yytext);
#endif
    return codigo;
}

// Reporta um erro lexico com o lexema e a linha. Sempre impresso, nos dois executaveis:
//   bin/lexer:  no meio da sequencia de tokens, ex.: NAO RECONHECIDO(@) na linha 1
//   bin/parser: um erro por linha, no mesmo formato dos erros sintaticos,
//               ex.: [LARP] ERRO LEXICO na linha 1: caractere nao reconhecido: @
static void erro_lexico(const char *nome, const char *descricao)
{
    total_de_erros_lexicos++;
#ifdef SOMENTE_LEXER
    printf("%s(%s) na linha %d ", nome, yytext, yylineno);
#else
    printf("[%s] ERRO LEXICO na linha %d: %s: %s\n", NOME_DA_LINGUAGEM, yylineno, descricao, yytext);
#endif
}
%}

%%

    /* Primeiro palavras reservadas de tipos (para nao serem consideradas como identificadores) */
"string"|"int"|"float" {
    ultimo_tipo_visto = yytext;
    return token_com_lexema(TIPO, "TIPO");
}

    /* Depois as demais palavras reservadas, tambem antes dos identificadores. Quando o casamento
     * tem o mesmo tamanho (ex.: "if"), vence a regra que aparece primeiro; quando o identificador
     * e mais longo (ex.: "iffy", "total"), vence o identificador pelo casamento mais longo */
"if" {
    return token(IF, "IF");
}

"else" {
    return token(ELSE, "ELSE");
}

"route" {
    return token(ROUTE, "ROUTE");
}

"to" {
    return token(TO, "TO");
}

"fall" {
    return token(FALL, "FALL");
}

    /* Segundo: identificadores */
    /* O primeiro caractere e separado dos demais para recusar nao considerar textos iniciados com numeros */
[a-zA-Z_][a-zA-Z0-9_]* {
    registrar_simbolo(yytext, ultimo_tipo_visto, yylineno);
    return token_com_lexema(ID, "ID");
}

    /* Terceiro: literais numericos. O ponto e escapado (\.) pois sozinho casaria qualquer caractere.
     * Em "3.5" as duas regras casam, mas o float vence por ser o casamento mais longo. Um numero
     * colado em letras (ex.: "2contador") vira LITERAL_INT seguido de ID; o erro fica para o parser */
[0-9]+\.[0-9]+ {
    return token_com_lexema(LITERAL_FLOAT, "LITERAL_FLOAT");
}

[0-9]+ {
    return token_com_lexema(LITERAL_INT, "LITERAL_INT");
}

    /* Quarto: literais string. Sao tres regras para o mesmo inicio (aspas):
     * 1. a string valida, exatamente como na gramatica;
     * 2. uma string fechada, mas com escape invalido (ex.: \x) ou caractere fora do ASCII imprimivel
     *    (ex.: tab, acento). Uma string valida casa as regras 1 e 2 com o mesmo tamanho, e vence
     *    a 1 por aparecer primeiro;
     * 3. uma string nao terminada (a linha ou o arquivo acaba antes das aspas de fechamento). Ela
     *    casa sempre 1 caractere a menos que as regras 1 e 2, entao so vence quando as aspas faltam.
     * Nos erros a string inteira e reportada de uma vez, para nao gerar um erro por caractere.
     * O \r fica de fora para que o CR de arquivos CRLF nao entre no texto do erro */
\"({caractere_string}|{escape_string})*\" {
    return token_com_lexema(LITERAL_STRING, "LITERAL_STRING");
}

    /* Nas duas regras de erro o parser recebe um LITERAL_STRING mesmo assim (sem contar nem imprimir
     * como token): o erro ja foi reportado aqui, e sem o token o parser acusaria um erro sintatico
     * falso, ex.: string a = "a\x"; chegaria como string a = ; */
\"([^"\\\n\r]|\\[^\n\r])*\" {
    erro_lexico("STRING INVALIDA", "string invalida");
    return LITERAL_STRING;
}

\"([^"\\\n\r]|\\[^\n\r])*\\? {
    erro_lexico("STRING NAO TERMINADA", "string nao terminada");
    return LITERAL_STRING;
}

    /* Quinto: pontuacao e operadores. Os pares que compartilham prefixo ("<" e "<=", ">" e ">=",
     * "=" e "==", "-" e "->") sao resolvidos pelo casamento mais longo, independente da ordem das regras */
"," {
    return token(VIRGULA, "VIRGULA");
}

";" {
    ultimo_tipo_visto.clear(); // o lexer guarda aqui um estado que seria do parser, so para
                               // conseguir preencher o tipo na tabela e deixar mais legivel
    return token(PONTO_VIRGULA, "PONTO_VIRGULA");
}

":" {
    return token(DOIS_PONTOS, "DOIS_PONTOS");
}

"=" {
    ultimo_tipo_visto.clear(); // depois do "=" de uma declaracao os IDs sao usos, nao declaracoes
    return token(ATRIBUICAO, "ATRIBUICAO");
}

"->" {
    return token(SETA, "SETA");
}

"(" {
    return token(ABRE_PARENTESES, "ABRE_PARENTESES");
}

")" {
    return token(FECHA_PARENTESES, "FECHA_PARENTESES");
}

"{" {
    return token(ABRE_CHAVES, "ABRE_CHAVES");
}

"}" {
    return token(FECHA_CHAVES, "FECHA_CHAVES");
}

    /* Operadores aritmeticos */
"+" {
    return token(MAIS, "MAIS");
}

"-" {
    return token(MENOS, "MENOS");
}

"*" {
    return token(VEZES, "VEZES");
}

"/" {
    return token(DIVIDIDO, "DIVIDIDO");
}

    /* Operadores relacionais, um token para cada (cada um pode ter precedencia propria no parser) */
"<" {
    return token(MENOR, "MENOR");
}

"<=" {
    return token(MENOR_IGUAL, "MENOR_IGUAL");
}

">" {
    return token(MAIOR, "MAIOR");
}

">=" {
    return token(MAIOR_IGUAL, "MAIOR_IGUAL");
}

"==" {
    return token(IGUAL, "IGUAL");
}

"!=" {
    return token(DIFERENTE, "DIFERENTE");
}

    /* A quebra de linha e descartada como token. No bin/lexer ela e impressa, so para deixar as
    quebras de linha da saida de texto iguais as do programa */
\n {
#ifdef SOMENTE_LEXER
    putchar('\n');
#endif
}

    /* Os demais brancos sao descartados tambem, mas sem printar.
    O \r acompanha o \n em arquivos gravados no Windows (CRLF) */
[ \t\r]+ ;

    /* Ultimo: qualquer outro caractere nao pertence a nenhum token previsto. O erro e
     * reportado por caractere, sem tentar adivinhar o que deveria seguir (sintaxe).
     * Nao ha return: o caractere e descartado e o parser nem fica sabendo dele */
. {
    erro_lexico("NAO RECONHECIDO", "caractere nao reconhecido");
}

%%

#ifdef SOMENTE_LEXER
int main(void)
{
    // Cada chamada de yylex() reconhece (e imprime) um token; 0 indica o fim do arquivo
    while (yylex() != 0) {
    }

    imprimir_tabela_de_simbolos();
    printf("\nRESUMO: %d tokens, %d simbolos, %d erros\n",
           total_de_tokens, (int) tabela_de_simbolos.size(), total_de_erros_lexicos);

    return total_de_erros_lexicos > 0 ? 1 : 0;
}
#endif
