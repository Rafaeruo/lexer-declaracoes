# Lexer de declaracoes

Analisador lexico para uma linguagem com apenas declaracoes de variaveis escrito em Flex.

Reconhece `TIPO` (`char`, `int`, `float`), `ID`, `VIRG` e `PONTOVIRG`, e reporta
caracteres nao reconhecidos junto com o numero da linha.

## Executar no Colab

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/Rafaeruo/lexer-declaracoes/blob/master/colab.ipynb)

## Executar localmente

Requer `flex`, `g++` e `make`.

```bash
make                                       # compila em bin/
make run FILE=test-programs/example.larp   # roda um arquivo
make test                                  # roda todos os test-programs/*.larp
make clean                                 # remove bin/
```

## Estrutura

    lexer.l           regras do analisador lexico
    Makefile          build e execucao
    test-programs/    programas de teste (.larp)
    colab.ipynb       notebook para executar no Google Colab
