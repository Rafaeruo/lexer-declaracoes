# Lexer de declaracoes -- build e execucao
#
#   make            compila o lexer em bin/
#   make run FILE=x roda o lexer no arquivo x
#   make test       roda o lexer em todos os test-programs/*.larp
#   make clean      remove o diretorio bin/

FLEX  := flex
CXX   := g++
SRC   := clarker.l
BIN   := bin
TESTS := test-programs

# No Windows o g++ gera lexer.exe; se o alvo nao tiver a extensao, o make nunca
# encontra o arquivo que acabou de criar e recompila a cada invocacao.
UNAME := $(shell uname -s)
ifneq (,$(filter MINGW% MSYS% CYGWIN%,$(UNAME)))
  EXE := $(BIN)/lexer.exe
else
  EXE := $(BIN)/lexer
endif

GEN := $(BIN)/lex.yy.c

all: $(EXE)

$(BIN):
	mkdir -p $(BIN)

$(GEN): $(SRC) | $(BIN)
	$(FLEX) -o $(GEN) $(SRC)

$(EXE): $(GEN)
	$(CXX) $(GEN) -o $(EXE)

run: $(EXE)
	@./$(EXE) < $(FILE) || true
	@echo

test: $(EXE)
	@for f in $(TESTS)/*.larp; do \
		echo "=== $$f ==="; \
		./$(EXE) < "$$f" || true; \
		echo; echo; \
	done

clean:
	rm -rf $(BIN)

.PHONY: all run test clean
