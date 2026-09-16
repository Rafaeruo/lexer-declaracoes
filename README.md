# Lexer de declaracoes

Analisador lexico, escrito em Flex, para uma linguagem em estilo C que contempla
apenas declaracoes de variaveis.

Reconhece `TIPO` (`char`, `int`, `float`), `ID`, `VIRG` e `PONTOVIRG`, ignora os
espacos em branco e reporta com o numero da linha qualquer caractere que nao
pertenca a nenhum token. Ao final imprime a tabela de simbolos e um resumo.

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

## Estrutura

    lexer.l           lexer
    Makefile          comandos de build e execucao
    test-programs/    programas de teste (.larp)
    colab.ipynb       notebook para executar no Google Colab
