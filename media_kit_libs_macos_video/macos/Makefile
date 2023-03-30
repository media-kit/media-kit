all: Frameworks/MPV.xcframework Headers/mpv/*.h

MPV_LIBS_VERSION=v0.2.0
MPV_LIBS_SHA256SUM=aeb41484867d9b726061ec9e4371d5d93e62a68578ff0b5c9a15cf4593a26128

MPV_HEADERS_VERSION=v0.35.1
MPV_HEADERS_SHA256SUM=41df981b7b84e33a2ef4478aaf81d6f4f5c8b9cd2c0d337ac142fc20b387d1a9

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

.cache/libs/libmpv-${MPV_LIBS_VERSION}-macos.tar.gz:
	mkdir -p .cache/libs
	rm -f .cache/libs/*.tmp .cache/libs/*-macos.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${MPV_LIBS_VERSION}/libmpv-${MPV_LIBS_VERSION}-macos-universal.tar.gz \
		-o .cache/libs/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_LIBS_SHA256SUM}  .cache/libs/libmpv.tar.gz.tmp'
	mv .cache/libs/libmpv.tar.gz.tmp .cache/libs/libmpv-${MPV_LIBS_VERSION}-macos.tar.gz
	touch .cache/libs/libmpv-${MPV_LIBS_VERSION}-macos.tar.gz

.cache/libs/libmpv-macos.tar.gz: .cache/libs/libmpv-${MPV_LIBS_VERSION}-macos.tar.gz
	rm -f .cache/libs/libmpv-macos.tar.gz
	ln -s libmpv-${MPV_LIBS_VERSION}-macos.tar.gz .cache/libs/libmpv-macos.tar.gz

.tmp/Frameworks/macos/MPV.framework: .cache/libs/libmpv-macos.tar.gz
	rm -rf .tmp/Frameworks/macos/MPV.framework
	sh ./Scripts/create_framework.sh
	touch .tmp/Frameworks/macos/MPV.framework

Frameworks/MPV.xcframework: .tmp/Frameworks/macos/MPV.framework
	rm -rf Frameworks/MPV.xcframework
	sh ./Scripts/create_xcframework.sh
	touch Frameworks/MPV.xcframework

.PHONY: clean
clean:
	rm -rf .cache
	rm -rf .tmp
	rm -f ./Headers/mpv/*.h
	rm -rf ./Frameworks/*.xcframework
