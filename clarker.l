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

// Terminais que terão que ser definidos pelo lexer: TIPO, ID, LITERAL_INT, LITERAL_FLOAT, LITERAL_STRING, “if”, “else”, “route”, “to”, “fall”, “=”, “;”, “,”, “:”, SETA, “(”, “)”, “{”, “}”, “+”, “-”, “*”, “/”, “<”, “<=”, “>”, “>=”, “==”, “!=”

%option noyywrap yylineno

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

    printf("%4s  %-25s  %-5s  %13s  %11s\n",
           "#", "IDENTIFICADOR", "TIPO", "1a OCORRENCIA", "OCORRENCIAS");
    for (i = 0; i < tabela_de_simbolos.size(); i++) {
        printf("%4d  %-25s  %-5s  %13d  %11d\n",
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
"char"|"int"|"float" {
    total_de_tokens++;
    ultimo_tipo_visto = yytext;
    printf("TIPO(%s) ", yytext);
}

    /* Segundo: identificadores */
    /* O primeiro caractere e separado dos demais para recusar nao considerar textos iniciados com numeros */
[a-zA-Z_][a-zA-Z0-9_]* {
    total_de_tokens++;
    registrar_simbolo(yytext, ultimo_tipo_visto, yylineno);
    printf("ID(%s) ", yytext);
}

"," {
    total_de_tokens++;
    printf("VIRG ");
}

";" {
    total_de_tokens++;
    ultimo_tipo_visto.clear(); // o lexer guarda aqui um estado que seria do parser, so para
                               // conseguir preencher o tipo na tabela e deixar mais legivel
    printf("PONTOVIRG ");
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
