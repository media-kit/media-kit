all: Libs/*.dylib

LIBS_VERSION=v0.0.1
LIBS_SHA256SUM=cf8fcfdc3188fe756447d7c41eb660fb637664a4222a730b065615c95f10b121

.cache:
	mkdir .cache

.cache/libmpv-${LIBS_VERSION}.tar.gz: .cache
	rm -f .cache/*.tmp .cache/*.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${LIBS_VERSION}/libmpv-${LIBS_VERSION}-darwin-universal.tar.gz \
		-o .cache/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${LIBS_SHA256SUM}  .cache/libmpv.tar.gz.tmp'
	mv .cache/libmpv.tar.gz.tmp .cache/libmpv-${LIBS_VERSION}.tar.gz
	touch .cache/libmpv-${LIBS_VERSION}.tar.gz

.cache/libmpv.tar.gz: .cache/libmpv-${LIBS_VERSION}.tar.gz
	rm -f .cache/libmpv.tar.gz
	ln -s libmpv-${LIBS_VERSION}.tar.gz .cache/libmpv.tar.gz

Libs/*.dylib: .cache/libmpv.tar.gz
	rm -f ./Libs/*.dylib
	tar -xvf .cache/libmpv.tar.gz --strip-components 1 -C Libs

.PHONY: clean
clean:
	rm -rf .cache
	rm -f ./Libs/*.dylib
