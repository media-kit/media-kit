all: Headers/mpv/*.h

MPV_VERSION=v0.35.1
MPV_SHA256SUM=41df981b7b84e33a2ef4478aaf81d6f4f5c8b9cd2c0d337ac142fc20b387d1a9

.cache:
	mkdir .cache

.cache/mpv-${MPV_VERSION}.tar.gz: .cache
	rm -f .cache/*.tmp .cache/*.tar.gz
	curl -L \
		https://github.com/mpv-player/mpv/archive/refs/tags/${MPV_VERSION}.tar.gz \
		-o .cache/mpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_SHA256SUM}  .cache/mpv.tar.gz.tmp'
	mv .cache/mpv.tar.gz.tmp .cache/mpv-${MPV_VERSION}.tar.gz
	touch .cache/mpv-${MPV_VERSION}.tar.gz

.cache/mpv.tar.gz: .cache/mpv-${MPV_VERSION}.tar.gz
	rm -f .cache/mpv.tar.gz
	ln -s mpv-${MPV_VERSION}.tar.gz .cache/mpv.tar.gz

Headers/mpv/*.h: .cache/mpv.tar.gz
	tar -xvf .cache/mpv.tar.gz --strip-components 2 -C Headers/mpv/ 'mpv-*/libmpv/*.h'
	touch Headers/mpv/*.h
