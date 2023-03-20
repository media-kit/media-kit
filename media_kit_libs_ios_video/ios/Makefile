all: Libs/*.dylib Headers/mpv/*.h

MPV_LIBS_VERSION=v0.1.1
MPV_LIBS_SHA256SUM=651c917787963c70fef0ffbd17a7d74550820be2d771325cdb869e7f04e5103b

MPV_HEADERS_VERSION=v0.35.1
MPV_HEADERS_SHA256SUM=41df981b7b84e33a2ef4478aaf81d6f4f5c8b9cd2c0d337ac142fc20b387d1a9

.cache/libs/libmpv-${MPV_LIBS_VERSION}.tar.gz:
	mkdir -p .cache/libs
	rm -f .cache/libs/*.tmp .cache/libs/*.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${MPV_LIBS_VERSION}/libmpv-${MPV_LIBS_VERSION}-ios-universal.tar.gz \
		-o .cache/libs/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_LIBS_SHA256SUM}  .cache/libs/libmpv.tar.gz.tmp'
	mv .cache/libs/libmpv.tar.gz.tmp .cache/libs/libmpv-${MPV_LIBS_VERSION}.tar.gz
	touch .cache/libs/libmpv-${MPV_LIBS_VERSION}.tar.gz

.cache/libs/libmpv.tar.gz: .cache/libs/libmpv-${MPV_LIBS_VERSION}.tar.gz
	rm -f .cache/libs/libmpv.tar.gz
	ln -s libmpv-${MPV_LIBS_VERSION}.tar.gz .cache/libs/libmpv.tar.gz

Libs/*.dylib: .cache/libs/libmpv.tar.gz
	rm -f ./Libs/*.dylib
	tar -xvf .cache/libs/libmpv.tar.gz --strip-components 1 -C Libs
	touch Libs/*.dylib

.cache/headers/mpv-${MPV_HEADERS_VERSION}.tar.gz:
	mkdir -p .cache/headers
	rm -f .cache/headers/*.tmp .cache/headers/*.tar.gz
	curl -L \
		https://github.com/mpv-player/mpv/archive/refs/tags/${MPV_HEADERS_VERSION}.tar.gz \
		-o .cache/headers/mpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_HEADERS_SHA256SUM}  .cache/headers/mpv.tar.gz.tmp'
	mv .cache/headers/mpv.tar.gz.tmp .cache/headers/mpv-${MPV_HEADERS_VERSION}.tar.gz
	touch .cache/headers/mpv-${MPV_HEADERS_VERSION}.tar.gz

.cache/headers/mpv.tar.gz: .cache/headers/mpv-${MPV_HEADERS_VERSION}.tar.gz
	rm -f .cache/headers/mpv.tar.gz
	ln -s mpv-${MPV_HEADERS_VERSION}.tar.gz .cache/headers/mpv.tar.gz

Headers/mpv/*.h: .cache/headers/mpv.tar.gz
	tar -xvf .cache/headers/mpv.tar.gz --strip-components 2 -C Headers/mpv/ 'mpv-*/libmpv/*.h'
	touch Headers/mpv/*.h

.PHONY: clean
clean:
	rm -rf .cache
	rm -f ./Libs/*.dylib
	rm -f ./Headers/mpv/*.h
