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
static std::string ultimo_tipo_visto; // usado para inserir o tipo de cada simbolo na tabela de simbolos (fica errado quando as declaracoes nao estao semanticamente corretas)

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
    ultimo_tipo_visto.clear(); // praticamente uma regra semantica, mas é util pra deixar a tabela de simbolos mais legivel
    printf("PONTOVIRG ");
}

    /* A quebra de linha e descartada como token, mas é verificada separadamente do \t\r
    apenas para quebrar a linha da saída de texto e deixar as quebras de linha iguais as do programa */
\n {
    putchar('\n');
}

    /* Os demais brancos sao descartados tambem, mas sem printar. 
    O \r acompanha o \n em arquivos * gravados no Windows (CRLF) */
[ \t\r]+ ;

    /* Ultimo: Qualquer outro caractere nao pertence a nenhum token previsto. O erro e
     * reportado por caractere sem tentar adivinhar o que deveria seguir (semantica). */
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
