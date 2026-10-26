# Lexer e parser -- build e execucao
#
#   make                    compila bin/lexer e bin/parser
#   make run FILE=x         roda o parser (lexer + parser) no arquivo x
#   make run-lexer FILE=x   roda so o lexer no arquivo x
#   make test               roda o parser em todos os test-programs/*.larp
#   make test-lexer         roda so o lexer em todos os test-programs/*.larp
#   make clean              remove o diretorio bin/

FLEX  := flex
BISON := bison
CXX   := g++
LEX_SRC    := clarker.l
PARSER_SRC := parser.y
BIN   := bin
TESTS := test-programs

# No Windows o g++ gera lexer.exe; se o alvo nao tiver a extensao, o make nunca
# encontra o arquivo que acabou de criar e recompila a cada invocacao.
UNAME := $(shell uname -s)
ifneq (,$(filter MINGW% MSYS% CYGWIN%,$(UNAME)))
  EXT := .exe
else
  EXT :=
endif

LEXER  := $(BIN)/lexer$(EXT)
PARSER := $(BIN)/parser$(EXT)

LEX_GEN    := $(BIN)/lex.yy.c
PARSER_GEN := $(BIN)/parser.tab.c
PARSER_H   := $(BIN)/parser.tab.h

all: $(LEXER) $(PARSER)

$(BIN):
	mkdir -p $(BIN)

# O Bison gera o parser (.c) e o header com os codigos dos tokens (.h), que o lexer inclui
$(PARSER_GEN): $(PARSER_SRC) | $(BIN)
	$(BISON) -d -o $(PARSER_GEN) $(PARSER_SRC)

$(PARSER_H): $(PARSER_GEN)

$(LEX_GEN): $(LEX_SRC) | $(BIN)
	$(FLEX) -o $(LEX_GEN) $(LEX_SRC)

# O lexer sozinho usa o main() do clarker.l; so precisa do header do Bison, nao do parser
$(LEXER): $(LEX_GEN) $(PARSER_H)
	$(CXX) -DSOMENTE_LEXER $(LEX_GEN) -o $(LEXER)

$(PARSER): $(LEX_GEN) $(PARSER_GEN) $(PARSER_H)
	$(CXX) $(PARSER_GEN) $(LEX_GEN) -o $(PARSER)

run: $(PARSER)
	@./$(PARSER) < $(FILE) || true

run-lexer: $(LEXER)
	@./$(LEXER) < $(FILE) || true
	@echo

test: $(PARSER)
	@for f in $(TESTS)/*.larp; do \
		echo "=== $$f ==="; \
		./$(PARSER) < "$$f" || true; \
		echo; \
	done

test-lexer: $(LEXER)
	@for f in $(TESTS)/*.larp; do \
		echo "=== $$f ==="; \
		./$(LEXER) < "$$f" || true; \
		echo; echo; \
	done

clean:
	rm -rf $(BIN)

.PHONY: all run run-lexer test test-lexer clean
