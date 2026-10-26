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
static int total_de_tokens = 0;
static int total_de_erros  = 0;
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
%}

%%

    /* Primeiro palavras reservadas de tipos (para nao serem consideradas como identificadores) */
"string"|"int"|"float" {
    total_de_tokens++;
    ultimo_tipo_visto = yytext;
    printf("TIPO(%s) ", yytext);
}

    /* Depois as demais palavras reservadas, tambem antes dos identificadores. Quando o casamento
     * tem o mesmo tamanho (ex.: "if"), vence a regra que aparece primeiro; quando o identificador
     * e mais longo (ex.: "iffy", "total"), vence o identificador pelo casamento mais longo */
"if" {
    total_de_tokens++;
    printf("IF ");
}

"else" {
    total_de_tokens++;
    printf("ELSE ");
}

"route" {
    total_de_tokens++;
    printf("ROUTE ");
}

"to" {
    total_de_tokens++;
    printf("TO ");
}

"fall" {
    total_de_tokens++;
    printf("FALL ");
}

    /* Segundo: identificadores */
    /* O primeiro caractere e separado dos demais para recusar nao considerar textos iniciados com numeros */
[a-zA-Z_][a-zA-Z0-9_]* {
    total_de_tokens++;
    registrar_simbolo(yytext, ultimo_tipo_visto, yylineno);
    printf("ID(%s) ", yytext);
}

    /* Terceiro: literais numericos. O ponto e escapado (\.) pois sozinho casaria qualquer caractere.
     * Em "3.5" as duas regras casam, mas o float vence por ser o casamento mais longo. Um numero
     * colado em letras (ex.: "2contador") vira LITERAL_INT seguido de ID; o erro fica para o parser */
[0-9]+\.[0-9]+ {
    total_de_tokens++;
    printf("LITERAL_FLOAT(%s) ", yytext);
}

[0-9]+ {
    total_de_tokens++;
    printf("LITERAL_INT(%s) ", yytext);
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
    total_de_tokens++;
    printf("LITERAL_STRING(%s) ", yytext);
}

\"([^"\\\n\r]|\\[^\n\r])*\" {
    total_de_erros++;
    printf("STRING INVALIDA(%s) na linha %d ", yytext, yylineno);
}

\"([^"\\\n\r]|\\[^\n\r])*\\? {
    total_de_erros++;
    printf("STRING NAO TERMINADA(%s) na linha %d ", yytext, yylineno);
}

    /* Quinto: pontuacao e operadores. Os pares que compartilham prefixo ("<" e "<=", ">" e ">=",
     * "=" e "==", "-" e "->") sao resolvidos pelo casamento mais longo, independente da ordem das regras */
"," {
    total_de_tokens++;
    printf("VIRGULA ");
}

";" {
    total_de_tokens++;
    ultimo_tipo_visto.clear(); // o lexer guarda aqui um estado que seria do parser, so para
                               // conseguir preencher o tipo na tabela e deixar mais legivel
    printf("PONTO_VIRGULA ");
}

":" {
    total_de_tokens++;
    printf("DOIS_PONTOS ");
}

"=" {
    total_de_tokens++;
    ultimo_tipo_visto.clear(); // depois do "=" de uma declaracao os IDs sao usos, nao declaracoes
    printf("ATRIBUICAO ");
}

"->" {
    total_de_tokens++;
    printf("SETA ");
}

"(" {
    total_de_tokens++;
    printf("ABRE_PARENTESES ");
}

")" {
    total_de_tokens++;
    printf("FECHA_PARENTESES ");
}

"{" {
    total_de_tokens++;
    printf("ABRE_CHAVES ");
}

"}" {
    total_de_tokens++;
    printf("FECHA_CHAVES ");
}

    /* Operadores aritmeticos */
"+" {
    total_de_tokens++;
    printf("MAIS ");
}

"-" {
    total_de_tokens++;
    printf("MENOS ");
}

"*" {
    total_de_tokens++;
    printf("VEZES ");
}

"/" {
    total_de_tokens++;
    printf("DIVIDIDO ");
}

    /* Operadores relacionais, um token para cada (cada um pode ter precedencia propria no parser) */
"<" {
    total_de_tokens++;
    printf("MENOR ");
}

"<=" {
    total_de_tokens++;
    printf("MENOR_IGUAL ");
}

">" {
    total_de_tokens++;
    printf("MAIOR ");
}

">=" {
    total_de_tokens++;
    printf("MAIOR_IGUAL ");
}

"==" {
    total_de_tokens++;
    printf("IGUAL ");
}

"!=" {
    total_de_tokens++;
    printf("DIFERENTE ");
}

    /* A quebra de linha e descartada como token, mas é verificada separadamente do \t\r
    apenas para quebrar a linha da saída de texto e deixar as quebras de linha iguais as do programa */
\n {
    putchar('\n');
}

    /* Os demais brancos sao descartados tambem, mas sem printar.
    O \r acompanha o \n em arquivos gravados no Windows (CRLF) */
[ \t\r]+ ;

    /* Ultimo: qualquer outro caractere nao pertence a nenhum token previsto. O erro e
     * reportado por caractere, sem tentar adivinhar o que deveria seguir (sintaxe) */
. {
    total_de_erros++;
    printf("NAO RECONHECIDO(%s) na linha %d ", yytext, yylineno);
}

%%

int main(void)
{
    yylex();

    imprimir_tabela_de_simbolos();
    printf("\nRESUMO: %d tokens, %d simbolos, %d erros\n",
           total_de_tokens, (int) tabela_de_simbolos.size(), total_de_erros);

    return total_de_erros > 0 ? 1 : 0;
}
