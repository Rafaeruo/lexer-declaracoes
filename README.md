# Lexer de declaracoes

Analisador lexico, escrito em Flex, para uma linguagem em estilo C com declaracoes,
atribuicoes, `if`/`else`, ternario (`if (...) -> ... else -> ...`) e `route`/`fall`.

Tokens reconhecidos:

| Categoria              | Tokens                                                                              |
|------------------------|-------------------------------------------------------------------------------------|
| Tipos                  | `TIPO` (`string`, `int`, `float`)                                                   |
| Palavras reservadas    | `IF`, `ELSE`, `ROUTE`, `TO`, `FALL`                                                 |
| Identificadores        | `ID`                                                                                |
| Literais               | `LITERAL_INT`, `LITERAL_FLOAT`, `LITERAL_STRING` (escapes `\"`, `\\`, `\n`, `\t`)   |
| Pontuacao              | `VIRGULA`, `PONTO_VIRGULA`, `DOIS_PONTOS`, `ATRIBUICAO` (`=`), `SETA` (`->`), `ABRE_PARENTESES`, `FECHA_PARENTESES`, `ABRE_CHAVES`, `FECHA_CHAVES` |
| Operadores aritmeticos | `MAIS`, `MENOS`, `VEZES`, `DIVIDIDO`                                                |
| Operadores relacionais | `MENOR`, `MENOR_IGUAL`, `MAIOR`, `MAIOR_IGUAL`, `IGUAL` (`==`), `DIFERENTE` (`!=`)  |

Espacos em branco sao ignorados. Todo erro lexico e reportado com o numero da linha:
caractere que nao pertence a nenhum token (`NAO RECONHECIDO`), string com escape ou
caractere invalido (`STRING INVALIDA`) e string sem aspas de fechamento
(`STRING NAO TERMINADA`). Ao final imprime a tabela de simbolos e um resumo.

## Executar no Colab

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/Rafaeruo/lexer-declaracoes/blob/master/colab.ipynb)

## Executar localmente

Requer `flex`, `g++` e `make`.

```bash
make                                                    # compila em bin/
make run FILE=test-programs/01-declaracoes-simples.larp # roda um arquivo
make test                                               # roda todos os test-programs/*.larp
make clean                                              # remove bin/
```

O analisador le da entrada padrao. Ele tambem pode ser executado diretamente assim:
`./bin/lexer < test-programs/01-declaracoes-simples.larp`.

## Programas de teste

Os arquivos `0x` sao programas validos e devem rodar sem erros. Os `1x` contem erros.

| Arquivo                          | O que testa                                                               |
|----------------------------------|---------------------------------------------------------------------------|
| `01-declaracoes-simples`         | declaracoes individuais e em lista                                        |
| `02-identificadores`             | formatos de identificador (`_`, digitos, maiusculas, nome longo)          |
| `03-prefixos-de-reservadas`      | identificadores que comecam com palavras reservadas (`iffy`, `router`...) |
| `04-espacos-e-quebras`           | espacos, tabs e quebras de linha no meio das declaracoes                  |
| `05-inicializacao`               | declaracoes com valor inicial, incluindo em lista                         |
| `06-if-else`                     | `if`/`else` aninhados, os seis operadores relacionais e aritmetica        |
| `07-ternario`                    | ternario em declaracao e atribuicao, aninhado e com instrucoes nos ramos  |
| `08-route-fall`                  | `route` com cases de inteiro, string e ID, `fall` e `else`                |
| `09-literais`                    | inteiros, floats e strings com todos os escapes e simbolos imprimiveis    |
| `13-caracteres-invalidos`        | erro lexico: caracteres fora da linguagem (`@`, `$`, `&&`, `!`, `'`)      |
| `14-estrutura-invalida`          | erros de estrutura: o lexer nao acusa erro, fica para o parser            |
| `15-numeros-malformados`         | erro lexico: `3.`, `.5`, `1.2.3`, `1..2`                                  |
| `16-strings-invalidas`           | erro lexico: escape invalido, tab, acento, strings nao terminadas         |

## Estrutura

    clarker.l         lexer
    Makefile          comandos de build e execucao
    test-programs/    programas de teste (.larp)
    colab.ipynb       notebook para executar no Google Colab
