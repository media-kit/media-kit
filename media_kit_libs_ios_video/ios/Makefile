all: Frameworks/MPV.xcframework Headers/mpv/*.h

MPV_LIBS_IOS_VERSION=v0.2.0
MPV_LIBS_IOS_SHA256SUM=e7d88dea134779ea43392dd0d763cbb3b6588a6b712c01164f9117c04416a05c

MPV_LIBS_IOSSIMULATOR_ARM64_VERSION=v0.2.0
MPV_LIBS_IOSSIMULATOR_ARM64_SHA256SUM=b45abddab2b92f8d8a7fd9988dd88402ac1c7e93074153273de8de5862d6eafb

MPV_LIBS_IOSSIMULATOR_AMD64_VERSION=v0.2.0
MPV_LIBS_IOSSIMULATOR_AMD64_SHA256SUM=21ba9dbb53094db72edb4189c535f7a221f1f04b1f7565da08aa855d073e14d4

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

.cache/libs/libmpv-${MPV_LIBS_IOS_VERSION}-ios.tar.gz:
	mkdir -p .cache/libs
	rm -f .cache/libs/*.tmp .cache/libs/*-ios.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${MPV_LIBS_IOS_VERSION}/libmpv-${MPV_LIBS_IOS_VERSION}-ios-arm64.tar.gz \
		-o .cache/libs/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_LIBS_IOS_SHA256SUM}  .cache/libs/libmpv.tar.gz.tmp'
	mv .cache/libs/libmpv.tar.gz.tmp .cache/libs/libmpv-${MPV_LIBS_IOS_VERSION}-ios.tar.gz
	touch .cache/libs/libmpv-${MPV_LIBS_IOS_VERSION}-ios.tar.gz

.cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz:
	mkdir -p .cache/libs
	rm -f .cache/libs/*.tmp .cache/libs/*-iossimulator-amd64.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}/libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz \
		-o .cache/libs/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_LIBS_IOSSIMULATOR_AMD64_SHA256SUM}  .cache/libs/libmpv.tar.gz.tmp'
	mv .cache/libs/libmpv.tar.gz.tmp .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz
	touch .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz

.cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz:
	mkdir -p .cache/libs
	rm -f .cache/libs/*.tmp .cache/libs/*-iossimulator-arm64.tar.gz
	curl -L \
		https://github.com/birros/libmpv-build/releases/download/${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}/libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz \
		-o .cache/libs/libmpv.tar.gz.tmp
	shasum -a 256 -c <<< '${MPV_LIBS_IOSSIMULATOR_ARM64_SHA256SUM}  .cache/libs/libmpv.tar.gz.tmp'
	mv .cache/libs/libmpv.tar.gz.tmp .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz
	touch .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz

.cache/libs/libmpv-ios.tar.gz: .cache/libs/libmpv-${MPV_LIBS_IOS_VERSION}-ios.tar.gz
	rm -f .cache/libs/libmpv-ios.tar.gz
	ln -s libmpv-${MPV_LIBS_IOS_VERSION}-ios.tar.gz .cache/libs/libmpv-ios.tar.gz

.cache/libs/libmpv-iossimulator-amd64.tar.gz: .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz
	rm -f .cache/libs/libmpv-iossimulator-amd64.tar.gz
	ln -s libmpv-${MPV_LIBS_IOSSIMULATOR_AMD64_VERSION}-iossimulator-amd64.tar.gz .cache/libs/libmpv-iossimulator-amd64.tar.gz

.cache/libs/libmpv-iossimulator-arm64.tar.gz: .cache/libs/libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz
	rm -f .cache/libs/libmpv-iossimulator-arm64.tar.gz
	ln -s libmpv-${MPV_LIBS_IOSSIMULATOR_ARM64_VERSION}-iossimulator-arm64.tar.gz .cache/libs/libmpv-iossimulator-arm64.tar.gz

.tmp/libs/libmpv-iossimulator-amd64: .cache/libs/libmpv-iossimulator-amd64.tar.gz
	mkdir -p .tmp/libs/libmpv-iossimulator-amd64
	tar \
		-xvf .cache/libs/libmpv-iossimulator-amd64.tar.gz \
		--strip-components 1 \
		-C .tmp/libs/libmpv-iossimulator-amd64/

.tmp/libs/libmpv-iossimulator-arm64: .cache/libs/libmpv-iossimulator-arm64.tar.gz
	mkdir -p .tmp/libs/libmpv-iossimulator-arm64
	tar \
		-xvf .cache/libs/libmpv-iossimulator-arm64.tar.gz \
		--strip-components 1 \
		-C .tmp/libs/libmpv-iossimulator-arm64/
	sh ./Scripts/fix_iossimulator_arm64.sh

.tmp/libs/libmpv-iossimulator-universal: .tmp/libs/libmpv-iossimulator-amd64 .tmp/libs/libmpv-iossimulator-arm64
	mkdir -p .tmp/libs/libmpv-iossimulator-universal
	sh ./Scripts/create_iossimulator_universal.sh

.tmp/libs/libmpv-iossimulator.tar.gz: .tmp/libs/libmpv-iossimulator-universal
	cd .tmp/libs && tar -czvf libmpv-iossimulator.tar.gz libmpv-iossimulator-universal

.tmp/Frameworks/ios/MPV.framework: .cache/libs/libmpv-ios.tar.gz
	rm -rf .tmp/Frameworks/ios/MPV.framework
	sh ./Scripts/create_framework.sh ".cache/libs/libmpv-ios.tar.gz" ".tmp/Frameworks/ios"
	touch .tmp/Frameworks/ios/MPV.framework

.tmp/Frameworks/iossimulator/MPV.framework: .tmp/libs/libmpv-iossimulator.tar.gz
	rm -rf .tmp/Frameworks/iossimulator/MPV.framework
	sh ./Scripts/create_framework.sh ".tmp/libs/libmpv-iossimulator.tar.gz" ".tmp/Frameworks/iossimulator"
	touch .tmp/Frameworks/iossimulator/MPV.framework

Frameworks/MPV.xcframework: .tmp/Frameworks/ios/MPV.framework .tmp/Frameworks/iossimulator/MPV.framework
	rm -rf Frameworks/MPV.xcframework
	sh ./Scripts/create_xcframework.sh
	touch Frameworks/MPV.xcframework

.PHONY: clean
clean:
	rm -rf .cache
	rm -rf .tmp
	rm -f ./Headers/mpv/*.h
	rm -rf ./Frameworks/*.xcframework
