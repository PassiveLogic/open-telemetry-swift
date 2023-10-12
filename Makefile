
# This Makefile may be used to build our fork of opentelemetry-swift for Linux. You may also use it
# on MacOS if you prefer the approach over Xcode (I do).

PROJECT_NAME="opentelemetry-swift-Package"

uname := $(shell uname)

SWIFTC_FLAGS += --configuration debug -Xswiftc -g
SWIFT := swift

CC := gcc
CFLAGS := -ansi -pedantic -Wall -W -Werror -g -fPIC

SRCDIR := Sources/libpl
INCDIR := $(SRCDIR)/include
LIBDIR := ./lib

SRC :=  $(wildcard $(SRCDIR)/*.c)
OBJ := $(SRC:$(SRCDIR)/%.c=$(SRCDIR)/%.o)

LIBNAME := $(LIBDIR)/libpl.so
LDFLAGS :=  -L.
LDLIBS  :=  -l$(...)

.PHONY: all ctags etags clean realclean reset resolve update

$(info Building for: [${uname}])

all: $(LIBNAME) opentelemetry

$(LIBNAME): CFLAGS += -fPIC
$(LIBNAME): LDFLAGS += -shared
$(LIBNAME): $(OBJ)
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@

$(LIBDIR)/%.o: $(SRCDIR)/%.c | $(LIBDIR)
	$(CC) $(CFLAGS) -I $(INCDIR) -o $@ -c $<

$(LIBDIR):
	@mkdir -p $@

opentelemetry: SWIFTC_FLAGS+=--configuration debug -Xswiftc -g
opentelemetry:
	${SWIFT} build $(SWIFTC_FLAGS) $(SWIFT_FLAGS) -Xlinker -L$(LIBDIR)

update: resolve
	$(SWIFT) package update

resolve:
	$(SWIFT) package resolve

ctags:
	ctags -R --languages=swift .

etags:
	etags -R --languages=swift .

reset:
	$(SWIFT) package reset

clean:
	$(SWIFT) package clean

# NB: Be careful with the realclean target on MacOS, as it will affect your other local Swift project caching.

ifeq ($(uname), Darwin)
realclean: clean
	@rm -rf .build
	@rm -rf ~/Library/Caches/org.swift.swiftpm
	@rm -rf ~/Library/org.swift.swiftpm
endif

ifeq ($(uname), Linux)
realclean: clean
	@rm -rf .build
endif
